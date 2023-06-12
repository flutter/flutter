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

/// Dialogflow API - v3
///
/// Builds conversational interfaces (for example, chatbots, and voice-powered
/// apps and devices).
///
/// For more information, see <https://cloud.google.com/dialogflow/>
///
/// Create an instance of [DialogflowApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsAgentsResource]
///       - [ProjectsLocationsAgentsEntityTypesResource]
///       - [ProjectsLocationsAgentsEnvironmentsResource]
///         - [ProjectsLocationsAgentsEnvironmentsExperimentsResource]
///         - [ProjectsLocationsAgentsEnvironmentsSessionsResource]
/// - [ProjectsLocationsAgentsEnvironmentsSessionsEntityTypesResource]
///       - [ProjectsLocationsAgentsFlowsResource]
///         - [ProjectsLocationsAgentsFlowsPagesResource]
///         - [ProjectsLocationsAgentsFlowsTransitionRouteGroupsResource]
///         - [ProjectsLocationsAgentsFlowsVersionsResource]
///       - [ProjectsLocationsAgentsIntentsResource]
///       - [ProjectsLocationsAgentsSessionsResource]
///         - [ProjectsLocationsAgentsSessionsEntityTypesResource]
///       - [ProjectsLocationsAgentsTestCasesResource]
///         - [ProjectsLocationsAgentsTestCasesResultsResource]
///       - [ProjectsLocationsAgentsWebhooksResource]
///     - [ProjectsLocationsOperationsResource]
///     - [ProjectsLocationsSecuritySettingsResource]
///   - [ProjectsOperationsResource]
library dialogflow.v3;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Builds conversational interfaces (for example, chatbots, and voice-powered
/// apps and devices).
class DialogflowApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// View, manage and query your Dialogflow agents
  static const dialogflowScope = 'https://www.googleapis.com/auth/dialogflow';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  DialogflowApi(http.Client client,
      {core.String rootUrl = 'https://dialogflow.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsResource get locations =>
      ProjectsLocationsResource(_requester);
  ProjectsOperationsResource get operations =>
      ProjectsOperationsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsResource get agents =>
      ProjectsLocationsAgentsResource(_requester);
  ProjectsLocationsOperationsResource get operations =>
      ProjectsLocationsOperationsResource(_requester);
  ProjectsLocationsSecuritySettingsResource get securitySettings =>
      ProjectsLocationsSecuritySettingsResource(_requester);

  ProjectsLocationsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsAgentsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsEntityTypesResource get entityTypes =>
      ProjectsLocationsAgentsEntityTypesResource(_requester);
  ProjectsLocationsAgentsEnvironmentsResource get environments =>
      ProjectsLocationsAgentsEnvironmentsResource(_requester);
  ProjectsLocationsAgentsFlowsResource get flows =>
      ProjectsLocationsAgentsFlowsResource(_requester);
  ProjectsLocationsAgentsIntentsResource get intents =>
      ProjectsLocationsAgentsIntentsResource(_requester);
  ProjectsLocationsAgentsSessionsResource get sessions =>
      ProjectsLocationsAgentsSessionsResource(_requester);
  ProjectsLocationsAgentsTestCasesResource get testCases =>
      ProjectsLocationsAgentsTestCasesResource(_requester);
  ProjectsLocationsAgentsWebhooksResource get webhooks =>
      ProjectsLocationsAgentsWebhooksResource(_requester);

  ProjectsLocationsAgentsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates an agent in the specified location.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The location to create a agent for. Format:
  /// `projects//locations/`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Agent].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Agent> create(
    GoogleCloudDialogflowCxV3Agent request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/agents';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Agent.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified agent.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the agent to delete. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Exports the specified agent to a binary file.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the agent to export. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> export(
    GoogleCloudDialogflowCxV3ExportAgentRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':export';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified agent.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the agent. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Agent].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Agent> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Agent.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the latest agent validation result.
  ///
  /// Agent validation is performed when ValidateAgent is called.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The agent name. Format:
  /// `projects//locations//agents//validationResult`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/validationResult$`.
  ///
  /// [languageCode] - If not specified, the agent's default language is used.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3AgentValidationResult].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3AgentValidationResult>
      getValidationResult(
    core.String name, {
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3AgentValidationResult.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of all agents in the specified location.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The location to list all agents for. Format:
  /// `projects//locations/`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 100 and at most 1000.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3ListAgentsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListAgentsResponse> list(
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

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/agents';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListAgentsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified agent.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The unique identifier of the agent. Required for the
  /// Agents.UpdateAgent method. Agents.CreateAgent populates the name
  /// automatically. Format: `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [updateMask] - The mask to control which fields get updated. If the mask
  /// is not present, all fields will be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Agent].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Agent> patch(
    GoogleCloudDialogflowCxV3Agent request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Agent.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Restores the specified agent from a binary file.
  ///
  /// Replaces the current agent with a new one. Note that all existing
  /// resources in agent (e.g. intents, entity types, flows) will be removed.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the agent to restore into. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> restore(
    GoogleCloudDialogflowCxV3RestoreAgentRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':restore';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Validates the specified agent and creates or updates validation results.
  ///
  /// The agent in draft version is validated. Please call this API after the
  /// training is completed to get the complete validation results.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The agent to validate. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3AgentValidationResult].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3AgentValidationResult> validate(
    GoogleCloudDialogflowCxV3ValidateAgentRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':validate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3AgentValidationResult.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsEntityTypesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsEntityTypesResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates an entity type in the specified agent.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The agent to create a entity type for. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [languageCode] - The language of the following fields in `entity_type`: *
  /// `EntityType.entities.value` * `EntityType.entities.synonyms` *
  /// `EntityType.excluded_phrases.value` If not specified, the agent's default
  /// language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3EntityType].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3EntityType> create(
    GoogleCloudDialogflowCxV3EntityType request,
    core.String parent, {
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/entityTypes';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3EntityType.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified entity type.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the entity type to delete. Format:
  /// `projects//locations//agents//entityTypes/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/entityTypes/\[^/\]+$`.
  ///
  /// [force] - This field has no effect for entity type not being used. For
  /// entity types that are used by intents or pages: * If `force` is set to
  /// false, an error will be returned with message indicating the referencing
  /// resources. * If `force` is set to true, Dialogflow will remove the entity
  /// type, as well as any references to the entity type (i.e. Page parameter of
  /// the entity type will be changed to '@sys.any' and intent parameter of the
  /// entity type will be removed).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.bool? force,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (force != null) 'force': ['${force}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified entity type.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the entity type. Format:
  /// `projects//locations//agents//entityTypes/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/entityTypes/\[^/\]+$`.
  ///
  /// [languageCode] - The language to retrieve the entity type for. The
  /// following fields are language dependent: * `EntityType.entities.value` *
  /// `EntityType.entities.synonyms` * `EntityType.excluded_phrases.value` If
  /// not specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3EntityType].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3EntityType> get(
    core.String name, {
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3EntityType.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of all entity types in the specified agent.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The agent to list all entity types for. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [languageCode] - The language to list entity types for. The following
  /// fields are language dependent: * `EntityType.entities.value` *
  /// `EntityType.entities.synonyms` * `EntityType.excluded_phrases.value` If
  /// not specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 100 and at most 1000.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3ListEntityTypesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListEntityTypesResponse> list(
    core.String parent, {
    core.String? languageCode,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/entityTypes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListEntityTypesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified entity type.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The unique identifier of the entity type. Required for
  /// EntityTypes.UpdateEntityType. Format:
  /// `projects//locations//agents//entityTypes/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/entityTypes/\[^/\]+$`.
  ///
  /// [languageCode] - The language of the following fields in `entity_type`: *
  /// `EntityType.entities.value` * `EntityType.entities.synonyms` *
  /// `EntityType.excluded_phrases.value` If not specified, the agent's default
  /// language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [updateMask] - The mask to control which fields get updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3EntityType].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3EntityType> patch(
    GoogleCloudDialogflowCxV3EntityType request,
    core.String name, {
    core.String? languageCode,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3EntityType.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsEnvironmentsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsEnvironmentsExperimentsResource get experiments =>
      ProjectsLocationsAgentsEnvironmentsExperimentsResource(_requester);
  ProjectsLocationsAgentsEnvironmentsSessionsResource get sessions =>
      ProjectsLocationsAgentsEnvironmentsSessionsResource(_requester);

  ProjectsLocationsAgentsEnvironmentsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates an Environment in the specified Agent.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The Agent to create an Environment for. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> create(
    GoogleCloudDialogflowCxV3Environment request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/environments';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified Environment.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the Environment to delete. Format:
  /// `projects//locations//agents//environments/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified Environment.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the Environment. Format:
  /// `projects//locations//agents//environments/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Environment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Environment> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Environment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of all environments in the specified Agent.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The Agent to list all environments for. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 20 and at most 100.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3ListEnvironmentsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListEnvironmentsResponse> list(
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

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/environments';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListEnvironmentsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Looks up the history of the specified Environment.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the environment to look up the history
  /// for. Format: `projects//locations//agents//environments/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 100 and at most 1000.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleCloudDialogflowCxV3LookupEnvironmentHistoryResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3LookupEnvironmentHistoryResponse>
      lookupEnvironmentHistory(
    core.String name, {
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
        'v3/' + core.Uri.encodeFull('$name') + ':lookupEnvironmentHistory';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3LookupEnvironmentHistoryResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified Environment.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the environment. Format:
  /// `projects//locations//agents//environments/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+$`.
  ///
  /// [updateMask] - Required. The mask to control which fields get updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> patch(
    GoogleCloudDialogflowCxV3Environment request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsEnvironmentsExperimentsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsEnvironmentsExperimentsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Creates an Experiment in the specified Environment.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The Agent to create an Environment for. Format:
  /// `projects//locations//agents//environments/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Experiment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Experiment> create(
    GoogleCloudDialogflowCxV3Experiment request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/experiments';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Experiment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified Experiment.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the Environment to delete. Format:
  /// `projects//locations//agents//environments//experiments/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+/experiments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified Experiment.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the Environment. Format:
  /// `projects//locations//agents//environments//experiments/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+/experiments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Experiment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Experiment> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Experiment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of all experiments in the specified Environment.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The Environment to list all environments for. Format:
  /// `projects//locations//agents//environments/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 20 and at most 100.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3ListExperimentsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListExperimentsResponse> list(
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

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/experiments';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListExperimentsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified Experiment.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the experiment. Format:
  /// projects//locations//agents//environments//experiments/..
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+/experiments/\[^/\]+$`.
  ///
  /// [updateMask] - Required. The mask to control which fields get updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Experiment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Experiment> patch(
    GoogleCloudDialogflowCxV3Experiment request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Experiment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Starts the specified Experiment.
  ///
  /// This rpc only changes the state of experiment from PENDING to RUNNING.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the experiment to start. Format:
  /// `projects//locations//agents//environments//experiments/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+/experiments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Experiment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Experiment> start(
    GoogleCloudDialogflowCxV3StartExperimentRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':start';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Experiment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Stops the specified Experiment.
  ///
  /// This rpc only changes the state of experiment from RUNNING to DONE.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the experiment to stop. Format:
  /// `projects//locations//agents//environments//experiments/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+/experiments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Experiment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Experiment> stop(
    GoogleCloudDialogflowCxV3StopExperimentRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':stop';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Experiment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsEnvironmentsSessionsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsEnvironmentsSessionsEntityTypesResource
      get entityTypes =>
          ProjectsLocationsAgentsEnvironmentsSessionsEntityTypesResource(
              _requester);

  ProjectsLocationsAgentsEnvironmentsSessionsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Processes a natural language query and returns structured, actionable data
  /// as a result.
  ///
  /// This method is not idempotent, because it may cause session entity types
  /// to be updated, which in turn might affect results of future queries. Note:
  /// Always use agent versions for production traffic. See
  /// [Versions and environments](https://cloud.google.com/dialogflow/cx/docs/concept/version).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [session] - Required. The name of the session this query is sent to.
  /// Format: `projects//locations//agents//sessions/` or
  /// `projects//locations//agents//environments//sessions/`. If `Environment
  /// ID` is not specified, we assume default 'draft' environment. It's up to
  /// the API caller to choose an appropriate `Session ID`. It can be a random
  /// number or some type of session identifiers (preferably hashed). The length
  /// of the `Session ID` must not exceed 36 characters. For more information,
  /// see the
  /// [sessions guide](https://cloud.google.com/dialogflow/cx/docs/concept/session).
  /// Note: Always use agent versions for production traffic. See
  /// [Versions and environments](https://cloud.google.com/dialogflow/cx/docs/concept/version).
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+/sessions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3DetectIntentResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3DetectIntentResponse> detectIntent(
    GoogleCloudDialogflowCxV3DetectIntentRequest request,
    core.String session, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$session') + ':detectIntent';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3DetectIntentResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Fulfills a matched intent returned by MatchIntent.
  ///
  /// Must be called after MatchIntent, with input from MatchIntentResponse.
  /// Otherwise, the behavior is undefined.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [session] - Required. The name of the session this query is sent to.
  /// Format: `projects//locations//agents//sessions/` or
  /// `projects//locations//agents//environments//sessions/`. If `Environment
  /// ID` is not specified, we assume default 'draft' environment. It's up to
  /// the API caller to choose an appropriate `Session ID`. It can be a random
  /// number or some type of session identifiers (preferably hashed). The length
  /// of the `Session ID` must not exceed 36 characters. For more information,
  /// see the
  /// [sessions guide](https://cloud.google.com/dialogflow/cx/docs/concept/session).
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+/sessions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3FulfillIntentResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3FulfillIntentResponse> fulfillIntent(
    GoogleCloudDialogflowCxV3FulfillIntentRequest request,
    core.String session, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$session') + ':fulfillIntent';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3FulfillIntentResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns preliminary intent match results, doesn't change the session
  /// status.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [session] - Required. The name of the session this query is sent to.
  /// Format: `projects//locations//agents//sessions/` or
  /// `projects//locations//agents//environments//sessions/`. If `Environment
  /// ID` is not specified, we assume default 'draft' environment. It's up to
  /// the API caller to choose an appropriate `Session ID`. It can be a random
  /// number or some type of session identifiers (preferably hashed). The length
  /// of the `Session ID` must not exceed 36 characters. For more information,
  /// see the
  /// [sessions guide](https://cloud.google.com/dialogflow/cx/docs/concept/session).
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+/sessions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3MatchIntentResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3MatchIntentResponse> matchIntent(
    GoogleCloudDialogflowCxV3MatchIntentRequest request,
    core.String session, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$session') + ':matchIntent';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3MatchIntentResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsEnvironmentsSessionsEntityTypesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsEnvironmentsSessionsEntityTypesResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Creates a session entity type.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The session to create a session entity type for.
  /// Format: `projects//locations//agents//sessions/` or
  /// `projects//locations//agents//environments//sessions/`. If `Environment
  /// ID` is not specified, we assume default 'draft' environment.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+/sessions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3SessionEntityType].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3SessionEntityType> create(
    GoogleCloudDialogflowCxV3SessionEntityType request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/entityTypes';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3SessionEntityType.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified session entity type.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the session entity type to delete. Format:
  /// `projects//locations//agents//sessions//entityTypes/` or
  /// `projects//locations//agents//environments//sessions//entityTypes/`. If
  /// `Environment ID` is not specified, we assume default 'draft' environment.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+/sessions/\[^/\]+/entityTypes/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified session entity type.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the session entity type. Format:
  /// `projects//locations//agents//sessions//entityTypes/` or
  /// `projects//locations//agents//environments//sessions//entityTypes/`. If
  /// `Environment ID` is not specified, we assume default 'draft' environment.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+/sessions/\[^/\]+/entityTypes/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3SessionEntityType].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3SessionEntityType> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3SessionEntityType.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of all session entity types in the specified session.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The session to list all session entity types from.
  /// Format: `projects//locations//agents//sessions/` or
  /// `projects//locations//agents//environments//sessions/`. If `Environment
  /// ID` is not specified, we assume default 'draft' environment.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+/sessions/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 100 and at most 1000.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleCloudDialogflowCxV3ListSessionEntityTypesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListSessionEntityTypesResponse> list(
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

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/entityTypes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListSessionEntityTypesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified session entity type.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The unique identifier of the session entity type.
  /// Format: `projects//locations//agents//sessions//entityTypes/` or
  /// `projects//locations//agents//environments//sessions//entityTypes/`. If
  /// `Environment ID` is not specified, we assume default 'draft' environment.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/environments/\[^/\]+/sessions/\[^/\]+/entityTypes/\[^/\]+$`.
  ///
  /// [updateMask] - The mask to control which fields get updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3SessionEntityType].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3SessionEntityType> patch(
    GoogleCloudDialogflowCxV3SessionEntityType request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3SessionEntityType.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsFlowsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsFlowsPagesResource get pages =>
      ProjectsLocationsAgentsFlowsPagesResource(_requester);
  ProjectsLocationsAgentsFlowsTransitionRouteGroupsResource
      get transitionRouteGroups =>
          ProjectsLocationsAgentsFlowsTransitionRouteGroupsResource(_requester);
  ProjectsLocationsAgentsFlowsVersionsResource get versions =>
      ProjectsLocationsAgentsFlowsVersionsResource(_requester);

  ProjectsLocationsAgentsFlowsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a flow in the specified agent.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The agent to create a flow for. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [languageCode] - The language of the following fields in `flow`: *
  /// `Flow.event_handlers.trigger_fulfillment.messages` *
  /// `Flow.event_handlers.trigger_fulfillment.conditional_cases` *
  /// `Flow.transition_routes.trigger_fulfillment.messages` *
  /// `Flow.transition_routes.trigger_fulfillment.conditional_cases` If not
  /// specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Flow].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Flow> create(
    GoogleCloudDialogflowCxV3Flow request,
    core.String parent, {
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/flows';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Flow.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a specified flow.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the flow to delete. Format:
  /// `projects//locations//agents//flows/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+$`.
  ///
  /// [force] - This field has no effect for flows with no incoming transitions.
  /// For flows with incoming transitions: * If `force` is set to false, an
  /// error will be returned with message indicating the incoming transitions. *
  /// If `force` is set to true, Dialogflow will remove the flow, as well as any
  /// transitions to the flow (i.e. Target flow in event handlers or Target flow
  /// in transition routes that point to this flow will be cleared).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.bool? force,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (force != null) 'force': ['${force}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Exports the specified flow to a binary file.
  ///
  /// Note that resources (e.g. intents, entities, webhooks) that the flow
  /// references will also be exported.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the flow to export. Format:
  /// `projects//locations//agents//flows/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> export(
    GoogleCloudDialogflowCxV3ExportFlowRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':export';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified flow.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the flow to get. Format:
  /// `projects//locations//agents//flows/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+$`.
  ///
  /// [languageCode] - The language to retrieve the flow for. The following
  /// fields are language dependent: *
  /// `Flow.event_handlers.trigger_fulfillment.messages` *
  /// `Flow.event_handlers.trigger_fulfillment.conditional_cases` *
  /// `Flow.transition_routes.trigger_fulfillment.messages` *
  /// `Flow.transition_routes.trigger_fulfillment.conditional_cases` If not
  /// specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Flow].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Flow> get(
    core.String name, {
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Flow.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the latest flow validation result.
  ///
  /// Flow validation is performed when ValidateFlow is called.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The flow name. Format:
  /// `projects//locations//agents//flows//validationResult`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+/validationResult$`.
  ///
  /// [languageCode] - If not specified, the agent's default language is used.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3FlowValidationResult].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3FlowValidationResult>
      getValidationResult(
    core.String name, {
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3FlowValidationResult.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Imports the specified flow to the specified agent from a binary file.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The agent to import the flow into. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> import(
    GoogleCloudDialogflowCxV3ImportFlowRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/flows:import';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of all flows in the specified agent.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The agent containing the flows. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [languageCode] - The language to list flows for. The following fields are
  /// language dependent: * `Flow.event_handlers.trigger_fulfillment.messages` *
  /// `Flow.event_handlers.trigger_fulfillment.conditional_cases` *
  /// `Flow.transition_routes.trigger_fulfillment.messages` *
  /// `Flow.transition_routes.trigger_fulfillment.conditional_cases` If not
  /// specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 100 and at most 1000.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3ListFlowsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListFlowsResponse> list(
    core.String parent, {
    core.String? languageCode,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/flows';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListFlowsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified flow.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The unique identifier of the flow. Format:
  /// `projects//locations//agents//flows/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+$`.
  ///
  /// [languageCode] - The language of the following fields in `flow`: *
  /// `Flow.event_handlers.trigger_fulfillment.messages` *
  /// `Flow.event_handlers.trigger_fulfillment.conditional_cases` *
  /// `Flow.transition_routes.trigger_fulfillment.messages` *
  /// `Flow.transition_routes.trigger_fulfillment.conditional_cases` If not
  /// specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [updateMask] - Required. The mask to control which fields get updated. If
  /// `update_mask` is not specified, an error will be returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Flow].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Flow> patch(
    GoogleCloudDialogflowCxV3Flow request,
    core.String name, {
    core.String? languageCode,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Flow.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Trains the specified flow.
  ///
  /// Note that only the flow in 'draft' environment is trained.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The flow to train. Format:
  /// `projects//locations//agents//flows/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> train(
    GoogleCloudDialogflowCxV3TrainFlowRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':train';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Validates the specified flow and creates or updates validation results.
  ///
  /// Please call this API after the training is completed to get the complete
  /// validation results.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The flow to validate. Format:
  /// `projects//locations//agents//flows/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3FlowValidationResult].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3FlowValidationResult> validate(
    GoogleCloudDialogflowCxV3ValidateFlowRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':validate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3FlowValidationResult.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsFlowsPagesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsFlowsPagesResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a page in the specified flow.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The flow to create a page for. Format:
  /// `projects//locations//agents//flows/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+$`.
  ///
  /// [languageCode] - The language of the following fields in `page`: *
  /// `Page.entry_fulfillment.messages` *
  /// `Page.entry_fulfillment.conditional_cases` *
  /// `Page.event_handlers.trigger_fulfillment.messages` *
  /// `Page.event_handlers.trigger_fulfillment.conditional_cases` *
  /// `Page.form.parameters.fill_behavior.initial_prompt_fulfillment.messages` *
  /// `Page.form.parameters.fill_behavior.initial_prompt_fulfillment.conditional_cases`
  /// * `Page.form.parameters.fill_behavior.reprompt_event_handlers.messages` *
  /// `Page.form.parameters.fill_behavior.reprompt_event_handlers.conditional_cases`
  /// * `Page.transition_routes.trigger_fulfillment.messages` *
  /// `Page.transition_routes.trigger_fulfillment.conditional_cases` If not
  /// specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Page].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Page> create(
    GoogleCloudDialogflowCxV3Page request,
    core.String parent, {
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/pages';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Page.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified page.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the page to delete. Format:
  /// `projects//locations//agents//Flows//pages/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+/pages/\[^/\]+$`.
  ///
  /// [force] - This field has no effect for pages with no incoming transitions.
  /// For pages with incoming transitions: * If `force` is set to false, an
  /// error will be returned with message indicating the incoming transitions. *
  /// If `force` is set to true, Dialogflow will remove the page, as well as any
  /// transitions to the page (i.e. Target page in event handlers or Target page
  /// in transition routes that point to this page will be cleared).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.bool? force,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (force != null) 'force': ['${force}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified page.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the page. Format:
  /// `projects//locations//agents//flows//pages/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+/pages/\[^/\]+$`.
  ///
  /// [languageCode] - The language to retrieve the page for. The following
  /// fields are language dependent: * `Page.entry_fulfillment.messages` *
  /// `Page.entry_fulfillment.conditional_cases` *
  /// `Page.event_handlers.trigger_fulfillment.messages` *
  /// `Page.event_handlers.trigger_fulfillment.conditional_cases` *
  /// `Page.form.parameters.fill_behavior.initial_prompt_fulfillment.messages` *
  /// `Page.form.parameters.fill_behavior.initial_prompt_fulfillment.conditional_cases`
  /// * `Page.form.parameters.fill_behavior.reprompt_event_handlers.messages` *
  /// `Page.form.parameters.fill_behavior.reprompt_event_handlers.conditional_cases`
  /// * `Page.transition_routes.trigger_fulfillment.messages` *
  /// `Page.transition_routes.trigger_fulfillment.conditional_cases` If not
  /// specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Page].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Page> get(
    core.String name, {
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Page.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of all pages in the specified flow.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The flow to list all pages for. Format:
  /// `projects//locations//agents//flows/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+$`.
  ///
  /// [languageCode] - The language to list pages for. The following fields are
  /// language dependent: * `Page.entry_fulfillment.messages` *
  /// `Page.entry_fulfillment.conditional_cases` *
  /// `Page.event_handlers.trigger_fulfillment.messages` *
  /// `Page.event_handlers.trigger_fulfillment.conditional_cases` *
  /// `Page.form.parameters.fill_behavior.initial_prompt_fulfillment.messages` *
  /// `Page.form.parameters.fill_behavior.initial_prompt_fulfillment.conditional_cases`
  /// * `Page.form.parameters.fill_behavior.reprompt_event_handlers.messages` *
  /// `Page.form.parameters.fill_behavior.reprompt_event_handlers.conditional_cases`
  /// * `Page.transition_routes.trigger_fulfillment.messages` *
  /// `Page.transition_routes.trigger_fulfillment.conditional_cases` If not
  /// specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 100 and at most 1000.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3ListPagesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListPagesResponse> list(
    core.String parent, {
    core.String? languageCode,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/pages';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListPagesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified page.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The unique identifier of the page. Required for the
  /// Pages.UpdatePage method. Pages.CreatePage populates the name
  /// automatically. Format: `projects//locations//agents//flows//pages/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+/pages/\[^/\]+$`.
  ///
  /// [languageCode] - The language of the following fields in `page`: *
  /// `Page.entry_fulfillment.messages` *
  /// `Page.entry_fulfillment.conditional_cases` *
  /// `Page.event_handlers.trigger_fulfillment.messages` *
  /// `Page.event_handlers.trigger_fulfillment.conditional_cases` *
  /// `Page.form.parameters.fill_behavior.initial_prompt_fulfillment.messages` *
  /// `Page.form.parameters.fill_behavior.initial_prompt_fulfillment.conditional_cases`
  /// * `Page.form.parameters.fill_behavior.reprompt_event_handlers.messages` *
  /// `Page.form.parameters.fill_behavior.reprompt_event_handlers.conditional_cases`
  /// * `Page.transition_routes.trigger_fulfillment.messages` *
  /// `Page.transition_routes.trigger_fulfillment.conditional_cases` If not
  /// specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [updateMask] - The mask to control which fields get updated. If the mask
  /// is not present, all fields will be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Page].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Page> patch(
    GoogleCloudDialogflowCxV3Page request,
    core.String name, {
    core.String? languageCode,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Page.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsFlowsTransitionRouteGroupsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsFlowsTransitionRouteGroupsResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Creates an TransitionRouteGroup in the specified flow.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The flow to create an TransitionRouteGroup for.
  /// Format: `projects//locations//agents//flows/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+$`.
  ///
  /// [languageCode] - The language of the following fields in
  /// `TransitionRouteGroup`: *
  /// `TransitionRouteGroup.transition_routes.trigger_fulfillment.messages` *
  /// `TransitionRouteGroup.transition_routes.trigger_fulfillment.conditional_cases`
  /// If not specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3TransitionRouteGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3TransitionRouteGroup> create(
    GoogleCloudDialogflowCxV3TransitionRouteGroup request,
    core.String parent, {
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v3/' + core.Uri.encodeFull('$parent') + '/transitionRouteGroups';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3TransitionRouteGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified TransitionRouteGroup.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the TransitionRouteGroup to delete. Format:
  /// `projects//locations//agents//flows//transitionRouteGroups/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+/transitionRouteGroups/\[^/\]+$`.
  ///
  /// [force] - This field has no effect for transition route group that no page
  /// is using. If the transition route group is referenced by any page: * If
  /// `force` is set to false, an error will be returned with message indicating
  /// pages that reference the transition route group. * If `force` is set to
  /// true, Dialogflow will remove the transition route group, as well as any
  /// reference to it.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.bool? force,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (force != null) 'force': ['${force}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified TransitionRouteGroup.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the TransitionRouteGroup. Format:
  /// `projects//locations//agents//flows//transitionRouteGroups/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+/transitionRouteGroups/\[^/\]+$`.
  ///
  /// [languageCode] - The language to retrieve the transition route group for.
  /// The following fields are language dependent: *
  /// `TransitionRouteGroup.transition_routes.trigger_fulfillment.messages` *
  /// `TransitionRouteGroup.transition_routes.trigger_fulfillment.conditional_cases`
  /// If not specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3TransitionRouteGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3TransitionRouteGroup> get(
    core.String name, {
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3TransitionRouteGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of all transition route groups in the specified flow.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The flow to list all transition route groups for.
  /// Format: `projects//locations//agents//flows/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+$`.
  ///
  /// [languageCode] - The language to list transition route groups for. The
  /// following fields are language dependent: *
  /// `TransitionRouteGroup.transition_routes.trigger_fulfillment.messages` *
  /// `TransitionRouteGroup.transition_routes.trigger_fulfillment.conditional_cases`
  /// If not specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 100 and at most 1000.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleCloudDialogflowCxV3ListTransitionRouteGroupsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListTransitionRouteGroupsResponse> list(
    core.String parent, {
    core.String? languageCode,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v3/' + core.Uri.encodeFull('$parent') + '/transitionRouteGroups';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListTransitionRouteGroupsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified TransitionRouteGroup.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The unique identifier of the transition route group.
  /// TransitionRouteGroups.CreateTransitionRouteGroup populates the name
  /// automatically. Format:
  /// `projects//locations//agents//flows//transitionRouteGroups/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+/transitionRouteGroups/\[^/\]+$`.
  ///
  /// [languageCode] - The language of the following fields in
  /// `TransitionRouteGroup`: *
  /// `TransitionRouteGroup.transition_routes.trigger_fulfillment.messages` *
  /// `TransitionRouteGroup.transition_routes.trigger_fulfillment.conditional_cases`
  /// If not specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [updateMask] - The mask to control which fields get updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3TransitionRouteGroup].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3TransitionRouteGroup> patch(
    GoogleCloudDialogflowCxV3TransitionRouteGroup request,
    core.String name, {
    core.String? languageCode,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3TransitionRouteGroup.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsFlowsVersionsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsFlowsVersionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a Version in the specified Flow.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The Flow to create an Version for. Format:
  /// `projects//locations//agents//flows/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> create(
    GoogleCloudDialogflowCxV3Version request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/versions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified Version.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the Version to delete. Format:
  /// `projects//locations//agents//flows//versions/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+/versions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified Version.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the Version. Format:
  /// `projects//locations//agents//flows//versions/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+/versions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Version].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Version> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Version.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of all versions in the specified Flow.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The Flow to list all versions for. Format:
  /// `projects//locations//agents//flows/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 20 and at most 100.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3ListVersionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListVersionsResponse> list(
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

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/versions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListVersionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Loads resources in the specified version to the draft flow.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The Version to be loaded to draft flow. Format:
  /// `projects//locations//agents//flows//versions/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+/versions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> load(
    GoogleCloudDialogflowCxV3LoadVersionRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':load';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified Version.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Format: projects//locations//agents//flows//versions/. Version ID
  /// is a self-increasing number generated by Dialogflow upon version creation.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/flows/\[^/\]+/versions/\[^/\]+$`.
  ///
  /// [updateMask] - Required. The mask to control which fields get updated.
  /// Currently only `description` and `display_name` can be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Version].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Version> patch(
    GoogleCloudDialogflowCxV3Version request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Version.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsIntentsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsIntentsResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates an intent in the specified agent.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The agent to create an intent for. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [languageCode] - The language of the following fields in `intent`: *
  /// `Intent.training_phrases.parts.text` If not specified, the agent's default
  /// language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Intent].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Intent> create(
    GoogleCloudDialogflowCxV3Intent request,
    core.String parent, {
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/intents';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Intent.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified intent.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the intent to delete. Format:
  /// `projects//locations//agents//intents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/intents/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified intent.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the intent. Format:
  /// `projects//locations//agents//intents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/intents/\[^/\]+$`.
  ///
  /// [languageCode] - The language to retrieve the intent for. The following
  /// fields are language dependent: * `Intent.training_phrases.parts.text` If
  /// not specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Intent].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Intent> get(
    core.String name, {
    core.String? languageCode,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Intent.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of all intents in the specified agent.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The agent to list all intents for. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [intentView] - The resource view to apply to the returned intent.
  /// Possible string values are:
  /// - "INTENT_VIEW_UNSPECIFIED" : Not specified. Treated as INTENT_VIEW_FULL.
  /// - "INTENT_VIEW_PARTIAL" : Training phrases field is not populated in the
  /// response.
  /// - "INTENT_VIEW_FULL" : All fields are populated.
  ///
  /// [languageCode] - The language to list intents for. The following fields
  /// are language dependent: * `Intent.training_phrases.parts.text` If not
  /// specified, the agent's default language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 100 and at most 1000.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3ListIntentsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListIntentsResponse> list(
    core.String parent, {
    core.String? intentView,
    core.String? languageCode,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (intentView != null) 'intentView': [intentView],
      if (languageCode != null) 'languageCode': [languageCode],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/intents';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListIntentsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified intent.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The unique identifier of the intent. Required for the
  /// Intents.UpdateIntent method. Intents.CreateIntent populates the name
  /// automatically. Format: `projects//locations//agents//intents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/intents/\[^/\]+$`.
  ///
  /// [languageCode] - The language of the following fields in `intent`: *
  /// `Intent.training_phrases.parts.text` If not specified, the agent's default
  /// language is used.
  /// [Many languages](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// are supported. Note: languages must be enabled in the agent before they
  /// can be used.
  ///
  /// [updateMask] - The mask to control which fields get updated. If the mask
  /// is not present, all fields will be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Intent].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Intent> patch(
    GoogleCloudDialogflowCxV3Intent request,
    core.String name, {
    core.String? languageCode,
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (languageCode != null) 'languageCode': [languageCode],
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Intent.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsSessionsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsSessionsEntityTypesResource get entityTypes =>
      ProjectsLocationsAgentsSessionsEntityTypesResource(_requester);

  ProjectsLocationsAgentsSessionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Processes a natural language query and returns structured, actionable data
  /// as a result.
  ///
  /// This method is not idempotent, because it may cause session entity types
  /// to be updated, which in turn might affect results of future queries. Note:
  /// Always use agent versions for production traffic. See
  /// [Versions and environments](https://cloud.google.com/dialogflow/cx/docs/concept/version).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [session] - Required. The name of the session this query is sent to.
  /// Format: `projects//locations//agents//sessions/` or
  /// `projects//locations//agents//environments//sessions/`. If `Environment
  /// ID` is not specified, we assume default 'draft' environment. It's up to
  /// the API caller to choose an appropriate `Session ID`. It can be a random
  /// number or some type of session identifiers (preferably hashed). The length
  /// of the `Session ID` must not exceed 36 characters. For more information,
  /// see the
  /// [sessions guide](https://cloud.google.com/dialogflow/cx/docs/concept/session).
  /// Note: Always use agent versions for production traffic. See
  /// [Versions and environments](https://cloud.google.com/dialogflow/cx/docs/concept/version).
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/sessions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3DetectIntentResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3DetectIntentResponse> detectIntent(
    GoogleCloudDialogflowCxV3DetectIntentRequest request,
    core.String session, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$session') + ':detectIntent';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3DetectIntentResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Fulfills a matched intent returned by MatchIntent.
  ///
  /// Must be called after MatchIntent, with input from MatchIntentResponse.
  /// Otherwise, the behavior is undefined.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [session] - Required. The name of the session this query is sent to.
  /// Format: `projects//locations//agents//sessions/` or
  /// `projects//locations//agents//environments//sessions/`. If `Environment
  /// ID` is not specified, we assume default 'draft' environment. It's up to
  /// the API caller to choose an appropriate `Session ID`. It can be a random
  /// number or some type of session identifiers (preferably hashed). The length
  /// of the `Session ID` must not exceed 36 characters. For more information,
  /// see the
  /// [sessions guide](https://cloud.google.com/dialogflow/cx/docs/concept/session).
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/sessions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3FulfillIntentResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3FulfillIntentResponse> fulfillIntent(
    GoogleCloudDialogflowCxV3FulfillIntentRequest request,
    core.String session, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$session') + ':fulfillIntent';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3FulfillIntentResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns preliminary intent match results, doesn't change the session
  /// status.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [session] - Required. The name of the session this query is sent to.
  /// Format: `projects//locations//agents//sessions/` or
  /// `projects//locations//agents//environments//sessions/`. If `Environment
  /// ID` is not specified, we assume default 'draft' environment. It's up to
  /// the API caller to choose an appropriate `Session ID`. It can be a random
  /// number or some type of session identifiers (preferably hashed). The length
  /// of the `Session ID` must not exceed 36 characters. For more information,
  /// see the
  /// [sessions guide](https://cloud.google.com/dialogflow/cx/docs/concept/session).
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/sessions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3MatchIntentResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3MatchIntentResponse> matchIntent(
    GoogleCloudDialogflowCxV3MatchIntentRequest request,
    core.String session, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$session') + ':matchIntent';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3MatchIntentResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsSessionsEntityTypesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsSessionsEntityTypesResource(
      commons.ApiRequester client)
      : _requester = client;

  /// Creates a session entity type.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The session to create a session entity type for.
  /// Format: `projects//locations//agents//sessions/` or
  /// `projects//locations//agents//environments//sessions/`. If `Environment
  /// ID` is not specified, we assume default 'draft' environment.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/sessions/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3SessionEntityType].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3SessionEntityType> create(
    GoogleCloudDialogflowCxV3SessionEntityType request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/entityTypes';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3SessionEntityType.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified session entity type.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the session entity type to delete. Format:
  /// `projects//locations//agents//sessions//entityTypes/` or
  /// `projects//locations//agents//environments//sessions//entityTypes/`. If
  /// `Environment ID` is not specified, we assume default 'draft' environment.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/sessions/\[^/\]+/entityTypes/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified session entity type.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the session entity type. Format:
  /// `projects//locations//agents//sessions//entityTypes/` or
  /// `projects//locations//agents//environments//sessions//entityTypes/`. If
  /// `Environment ID` is not specified, we assume default 'draft' environment.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/sessions/\[^/\]+/entityTypes/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3SessionEntityType].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3SessionEntityType> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3SessionEntityType.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of all session entity types in the specified session.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The session to list all session entity types from.
  /// Format: `projects//locations//agents//sessions/` or
  /// `projects//locations//agents//environments//sessions/`. If `Environment
  /// ID` is not specified, we assume default 'draft' environment.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/sessions/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 100 and at most 1000.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleCloudDialogflowCxV3ListSessionEntityTypesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListSessionEntityTypesResponse> list(
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

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/entityTypes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListSessionEntityTypesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified session entity type.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The unique identifier of the session entity type.
  /// Format: `projects//locations//agents//sessions//entityTypes/` or
  /// `projects//locations//agents//environments//sessions//entityTypes/`. If
  /// `Environment ID` is not specified, we assume default 'draft' environment.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/sessions/\[^/\]+/entityTypes/\[^/\]+$`.
  ///
  /// [updateMask] - The mask to control which fields get updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3SessionEntityType].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3SessionEntityType> patch(
    GoogleCloudDialogflowCxV3SessionEntityType request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3SessionEntityType.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsTestCasesResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsTestCasesResultsResource get results =>
      ProjectsLocationsAgentsTestCasesResultsResource(_requester);

  ProjectsLocationsAgentsTestCasesResource(commons.ApiRequester client)
      : _requester = client;

  /// Batch deletes test cases.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The agent to delete test cases from. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> batchDelete(
    GoogleCloudDialogflowCxV3BatchDeleteTestCasesRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v3/' + core.Uri.encodeFull('$parent') + '/testCases:batchDelete';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Kicks off a batch run of test cases.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. Agent name. Format: `projects//locations//agents/ `.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> batchRun(
    GoogleCloudDialogflowCxV3BatchRunTestCasesRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/testCases:batchRun';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Calculates the test coverage for an agent.
  ///
  /// Request parameters:
  ///
  /// [agent] - Required. The agent to calculate coverage for. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [type] - Required. The type of coverage requested.
  /// Possible string values are:
  /// - "COVERAGE_TYPE_UNSPECIFIED" : Should never be used.
  /// - "INTENT" : Intent coverage.
  /// - "PAGE_TRANSITION" : Page transition coverage.
  /// - "TRANSITION_ROUTE_GROUP" : Transition route group coverage.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3CalculateCoverageResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3CalculateCoverageResponse>
      calculateCoverage(
    core.String agent, {
    core.String? type,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (type != null) 'type': [type],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v3/' + core.Uri.encodeFull('$agent') + '/testCases:calculateCoverage';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3CalculateCoverageResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates a test case for the given agent.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The agent to create the test case for. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3TestCase].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3TestCase> create(
    GoogleCloudDialogflowCxV3TestCase request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/testCases';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3TestCase.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Exports the test cases under the agent to a Cloud Storage bucket or a
  /// local file.
  ///
  /// Filter can be applied to export a subset of test cases.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The agent where to export test cases from. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> export(
    GoogleCloudDialogflowCxV3ExportTestCasesRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/testCases:export';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a test case.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the testcase. Format:
  /// `projects//locations//agents//testCases/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/testCases/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3TestCase].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3TestCase> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3TestCase.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Imports the test cases from a Cloud Storage bucket or a local file.
  ///
  /// It always creates new test cases and won't overwite any existing ones. The
  /// provided ID in the imported test case is neglected.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The agent to import test cases to. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> import(
    GoogleCloudDialogflowCxV3ImportTestCasesRequest request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/testCases:import';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Fetches a list of test cases for a given agent.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The agent to list all pages for. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 20. Note that when TestCaseView = FULL, the maximum page size
  /// allowed is 20. When TestCaseView = BASIC, the maximum page size allowed is
  /// 500.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [view] - Specifies whether response should include all fields or just the
  /// metadata.
  /// Possible string values are:
  /// - "TEST_CASE_VIEW_UNSPECIFIED" : The default / unset value. The API will
  /// default to the BASIC view.
  /// - "BASIC" : Include basic metadata about the test case, but not the
  /// conversation turns. This is the default value.
  /// - "FULL" : Include everything.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3ListTestCasesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListTestCasesResponse> list(
    core.String parent, {
    core.int? pageSize,
    core.String? pageToken,
    core.String? view,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (view != null) 'view': [view],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/testCases';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListTestCasesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified test case.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The unique identifier of the test case. TestCases.CreateTestCase
  /// will populate the name automatically. Otherwise use format:
  /// `projects//locations//agents/ /testCases/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/testCases/\[^/\]+$`.
  ///
  /// [updateMask] - Required. The mask to specify which fields should be
  /// updated. The `creationTime` and `lastTestResult` cannot be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3TestCase].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3TestCase> patch(
    GoogleCloudDialogflowCxV3TestCase request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3TestCase.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Kicks off a test case run.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Format of test case name to run: `projects//locations/
  /// /agents//testCases/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/testCases/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> run(
    GoogleCloudDialogflowCxV3RunTestCaseRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':run';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsTestCasesResultsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsTestCasesResultsResource(commons.ApiRequester client)
      : _requester = client;

  /// Gets a test case result.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the testcase. Format:
  /// `projects//locations//agents//testCases//results/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/testCases/\[^/\]+/results/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3TestCaseResult].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3TestCaseResult> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3TestCaseResult.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Fetches a list of results for a given test case.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The test case to list results for. Format:
  /// `projects//locations//agents// testCases/`. Specify a `-` as a wildcard
  /// for TestCase ID to list results across multiple test cases.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/testCases/\[^/\]+$`.
  ///
  /// [filter] - The filter expression used to filter test case results. See
  /// [API Filtering](https://aip.dev/160). The expression is case insensitive.
  /// Only 'AND' is supported for logical operators. The supported syntax is
  /// listed below in detail: \[AND \] ... \[AND latest\] The supported fields
  /// and operators are: field operator `environment` `=`, `IN` (Use value
  /// `draft` for draft environment) `test_time` `>`, `<` `latest` only returns
  /// the latest test result in all results for each test case. Examples: *
  /// "environment=draft AND latest" matches the latest test result for each
  /// test case in the draft environment. * "environment IN (e1,e2)" matches any
  /// test case results with an environment resource name of either "e1" or
  /// "e2". * "test_time > 1602540713" matches any test case results with test
  /// time later than a unix timestamp in seconds 1602540713.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 100 and at most 1000.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3ListTestCaseResultsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListTestCaseResultsResponse> list(
    core.String parent, {
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

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/results';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListTestCaseResultsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsAgentsWebhooksResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsAgentsWebhooksResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a webhook in the specified agent.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The agent to create a webhook for. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Webhook].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Webhook> create(
    GoogleCloudDialogflowCxV3Webhook request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/webhooks';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Webhook.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified webhook.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the webhook to delete. Format:
  /// `projects//locations//agents//webhooks/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/webhooks/\[^/\]+$`.
  ///
  /// [force] - This field has no effect for webhook not being used. For
  /// webhooks that are used by pages/flows/transition route groups: * If
  /// `force` is set to false, an error will be returned with message indicating
  /// the referenced resources. * If `force` is set to true, Dialogflow will
  /// remove the webhook, as well as any references to the webhook (i.e. Webhook
  /// and tagin fulfillments that point to this webhook will be removed).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.bool? force,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (force != null) 'force': ['${force}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified webhook.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the webhook. Format:
  /// `projects//locations//agents//webhooks/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/webhooks/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Webhook].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Webhook> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Webhook.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of all webhooks in the specified agent.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The agent to list all webhooks for. Format:
  /// `projects//locations//agents/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 100 and at most 1000.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3ListWebhooksResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListWebhooksResponse> list(
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

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/webhooks';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListWebhooksResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified webhook.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The unique identifier of the webhook. Required for the
  /// Webhooks.UpdateWebhook method. Webhooks.CreateWebhook populates the name
  /// automatically. Format: `projects//locations//agents//webhooks/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/agents/\[^/\]+/webhooks/\[^/\]+$`.
  ///
  /// [updateMask] - The mask to control which fields get updated. If the mask
  /// is not present, all fields will be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3Webhook].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3Webhook> patch(
    GoogleCloudDialogflowCxV3Webhook request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3Webhook.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsOperationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsOperationsResource(commons.ApiRequester client)
      : _requester = client;

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
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be cancelled.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> cancel(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':cancel';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
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
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
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
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
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
  /// Completes with a [GoogleLongrunningListOperationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningListOperationsResponse> list(
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

    final _url = 'v3/' + core.Uri.encodeFull('$name') + '/operations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleLongrunningListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsLocationsSecuritySettingsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsSecuritySettingsResource(commons.ApiRequester client)
      : _requester = client;

  /// Create security settings in the specified location.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The location to create an SecuritySettings for.
  /// Format: `projects//locations/`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3SecuritySettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3SecuritySettings> create(
    GoogleCloudDialogflowCxV3SecuritySettings request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/securitySettings';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3SecuritySettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified SecuritySettings.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the SecuritySettings to delete. Format:
  /// `projects//locations//securitySettings/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/securitySettings/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> delete(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves the specified SecuritySettings.
  ///
  /// The returned settings may be stale by up to 1 minute.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the settings. Format:
  /// `projects//locations//securitySettings/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/securitySettings/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3SecuritySettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3SecuritySettings> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3SecuritySettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of all security settings in the specified location.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The location to list all security settings for.
  /// Format: `projects//locations/`.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [pageSize] - The maximum number of items to return in a single page. By
  /// default 20 and at most 100.
  ///
  /// [pageToken] - The next_page_token value returned from a previous list
  /// request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3ListSecuritySettingsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3ListSecuritySettingsResponse> list(
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

    final _url = 'v3/' + core.Uri.encodeFull('$parent') + '/securitySettings';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3ListSecuritySettingsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified SecuritySettings.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Resource name of the settings. Format:
  /// `projects//locations//securitySettings/`.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/securitySettings/\[^/\]+$`.
  ///
  /// [updateMask] - Required. The mask to control which fields get updated. If
  /// the mask is not present, all fields will be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudDialogflowCxV3SecuritySettings].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudDialogflowCxV3SecuritySettings> patch(
    GoogleCloudDialogflowCxV3SecuritySettings request,
    core.String name, {
    core.String? updateMask,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (updateMask != null) 'updateMask': [updateMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'PATCH',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudDialogflowCxV3SecuritySettings.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsOperationsResource {
  final commons.ApiRequester _requester;

  ProjectsOperationsResource(commons.ApiRequester client) : _requester = client;

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
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be cancelled.
  /// Value must have pattern `^projects/\[^/\]+/operations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleProtobufEmpty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleProtobufEmpty> cancel(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name') + ':cancel';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the latest state of a long-running operation.
  ///
  /// Clients can use this method to poll the operation result at intervals as
  /// recommended by the API service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource.
  /// Value must have pattern `^projects/\[^/\]+/operations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v3/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
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
  /// Value must have pattern `^projects/\[^/\]+$`.
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
  /// Completes with a [GoogleLongrunningListOperationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningListOperationsResponse> list(
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

    final _url = 'v3/' + core.Uri.encodeFull('$name') + '/operations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleLongrunningListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Agents are best described as Natural Language Understanding (NLU) modules
/// that transform user requests into actionable data.
///
/// You can include agents in your app, product, or service to determine user
/// intent and respond to the user in a natural way. After you create an agent,
/// you can add Intents, Entity Types, Flows, Fulfillments, Webhooks, and so on
/// to manage the conversation flows..
class GoogleCloudDialogflowCxV3Agent {
  /// The URI of the agent's avatar.
  ///
  /// Avatars are used throughout the Dialogflow console and in the self-hosted
  /// [Web Demo](https://cloud.google.com/dialogflow/docs/integrations/web-demo)
  /// integration.
  core.String? avatarUri;

  /// The default language of the agent as a language tag.
  ///
  /// See
  /// [Language Support](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// for a list of the currently supported language codes. This field cannot be
  /// set by the Agents.UpdateAgent method.
  ///
  /// Immutable.
  core.String? defaultLanguageCode;

  /// The description of the agent.
  ///
  /// The maximum length is 500 characters. If exceeded, the request is
  /// rejected.
  core.String? description;

  /// The human-readable name of the agent, unique within the location.
  ///
  /// Required.
  core.String? displayName;

  /// Indicates if automatic spell correction is enabled in detect intent
  /// requests.
  core.bool? enableSpellCorrection;

  /// Indicates if stackdriver logging is enabled for the agent.
  core.bool? enableStackdriverLogging;

  /// The unique identifier of the agent.
  ///
  /// Required for the Agents.UpdateAgent method. Agents.CreateAgent populates
  /// the name automatically. Format: `projects//locations//agents/`.
  core.String? name;

  /// Name of the SecuritySettings reference for the agent.
  ///
  /// Format: `projects//locations//securitySettings/`.
  core.String? securitySettings;

  /// Speech recognition related settings.
  GoogleCloudDialogflowCxV3SpeechToTextSettings? speechToTextSettings;

  /// Name of the start flow in this agent.
  ///
  /// A start flow will be automatically created when the agent is created, and
  /// can only be deleted by deleting the agent. Format:
  /// `projects//locations//agents//flows/`.
  ///
  /// Immutable.
  core.String? startFlow;

  /// The list of all languages supported by the agent (except for the
  /// `default_language_code`).
  core.List<core.String>? supportedLanguageCodes;

  /// The time zone of the agent from the
  /// [time zone database](https://www.iana.org/time-zones), e.g.,
  /// America/New_York, Europe/Paris.
  ///
  /// Required.
  core.String? timeZone;

  GoogleCloudDialogflowCxV3Agent();

  GoogleCloudDialogflowCxV3Agent.fromJson(core.Map _json) {
    if (_json.containsKey('avatarUri')) {
      avatarUri = _json['avatarUri'] as core.String;
    }
    if (_json.containsKey('defaultLanguageCode')) {
      defaultLanguageCode = _json['defaultLanguageCode'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('enableSpellCorrection')) {
      enableSpellCorrection = _json['enableSpellCorrection'] as core.bool;
    }
    if (_json.containsKey('enableStackdriverLogging')) {
      enableStackdriverLogging = _json['enableStackdriverLogging'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('securitySettings')) {
      securitySettings = _json['securitySettings'] as core.String;
    }
    if (_json.containsKey('speechToTextSettings')) {
      speechToTextSettings =
          GoogleCloudDialogflowCxV3SpeechToTextSettings.fromJson(
              _json['speechToTextSettings']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startFlow')) {
      startFlow = _json['startFlow'] as core.String;
    }
    if (_json.containsKey('supportedLanguageCodes')) {
      supportedLanguageCodes = (_json['supportedLanguageCodes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('timeZone')) {
      timeZone = _json['timeZone'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (avatarUri != null) 'avatarUri': avatarUri!,
        if (defaultLanguageCode != null)
          'defaultLanguageCode': defaultLanguageCode!,
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (enableSpellCorrection != null)
          'enableSpellCorrection': enableSpellCorrection!,
        if (enableStackdriverLogging != null)
          'enableStackdriverLogging': enableStackdriverLogging!,
        if (name != null) 'name': name!,
        if (securitySettings != null) 'securitySettings': securitySettings!,
        if (speechToTextSettings != null)
          'speechToTextSettings': speechToTextSettings!.toJson(),
        if (startFlow != null) 'startFlow': startFlow!,
        if (supportedLanguageCodes != null)
          'supportedLanguageCodes': supportedLanguageCodes!,
        if (timeZone != null) 'timeZone': timeZone!,
      };
}

/// The response message for Agents.GetAgentValidationResult.
class GoogleCloudDialogflowCxV3AgentValidationResult {
  /// Contains all flow validation results.
  core.List<GoogleCloudDialogflowCxV3FlowValidationResult>?
      flowValidationResults;

  /// The unique identifier of the agent validation result.
  ///
  /// Format: `projects//locations//agents//validationResult`.
  core.String? name;

  GoogleCloudDialogflowCxV3AgentValidationResult();

  GoogleCloudDialogflowCxV3AgentValidationResult.fromJson(core.Map _json) {
    if (_json.containsKey('flowValidationResults')) {
      flowValidationResults = (_json['flowValidationResults'] as core.List)
          .map<GoogleCloudDialogflowCxV3FlowValidationResult>((value) =>
              GoogleCloudDialogflowCxV3FlowValidationResult.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (flowValidationResults != null)
          'flowValidationResults':
              flowValidationResults!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
      };
}

/// Represents the natural speech audio to be processed.
class GoogleCloudDialogflowCxV3AudioInput {
  /// The natural language speech audio to be processed.
  ///
  /// A single request can contain up to 1 minute of speech audio data. The
  /// transcribed text cannot contain more than 256 bytes. For non-streaming
  /// audio detect intent, both `config` and `audio` must be provided. For
  /// streaming audio detect intent, `config` must be provided in the first
  /// request and `audio` must be provided in all following requests.
  core.String? audio;
  core.List<core.int> get audioAsBytes => convert.base64.decode(audio!);

  set audioAsBytes(core.List<core.int> _bytes) {
    audio =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Instructs the speech recognizer how to process the speech audio.
  ///
  /// Required.
  GoogleCloudDialogflowCxV3InputAudioConfig? config;

  GoogleCloudDialogflowCxV3AudioInput();

  GoogleCloudDialogflowCxV3AudioInput.fromJson(core.Map _json) {
    if (_json.containsKey('audio')) {
      audio = _json['audio'] as core.String;
    }
    if (_json.containsKey('config')) {
      config = GoogleCloudDialogflowCxV3InputAudioConfig.fromJson(
          _json['config'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audio != null) 'audio': audio!,
        if (config != null) 'config': config!.toJson(),
      };
}

/// The request message for TestCases.BatchDeleteTestCases.
class GoogleCloudDialogflowCxV3BatchDeleteTestCasesRequest {
  /// Format of test case names: `projects//locations/ /agents//testCases/`.
  ///
  /// Required.
  core.List<core.String>? names;

  GoogleCloudDialogflowCxV3BatchDeleteTestCasesRequest();

  GoogleCloudDialogflowCxV3BatchDeleteTestCasesRequest.fromJson(
      core.Map _json) {
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

/// Metadata returned for the TestCases.BatchRunTestCases long running
/// operation.
class GoogleCloudDialogflowCxV3BatchRunTestCasesMetadata {
  /// The test errors.
  core.List<GoogleCloudDialogflowCxV3TestError>? errors;

  GoogleCloudDialogflowCxV3BatchRunTestCasesMetadata();

  GoogleCloudDialogflowCxV3BatchRunTestCasesMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<GoogleCloudDialogflowCxV3TestError>((value) =>
              GoogleCloudDialogflowCxV3TestError.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
      };
}

/// The request message for TestCases.BatchRunTestCases.
class GoogleCloudDialogflowCxV3BatchRunTestCasesRequest {
  /// If not set, draft environment is assumed.
  ///
  /// Format: `projects//locations//agents//environments/`.
  ///
  /// Optional.
  core.String? environment;

  /// Format: `projects//locations//agents//testCases/`.
  ///
  /// Required.
  core.List<core.String>? testCases;

  GoogleCloudDialogflowCxV3BatchRunTestCasesRequest();

  GoogleCloudDialogflowCxV3BatchRunTestCasesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('environment')) {
      environment = _json['environment'] as core.String;
    }
    if (_json.containsKey('testCases')) {
      testCases = (_json['testCases'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (environment != null) 'environment': environment!,
        if (testCases != null) 'testCases': testCases!,
      };
}

/// The response message for TestCases.BatchRunTestCases.
class GoogleCloudDialogflowCxV3BatchRunTestCasesResponse {
  /// The test case results.
  ///
  /// The detailed conversation turns are empty in this response.
  core.List<GoogleCloudDialogflowCxV3TestCaseResult>? results;

  GoogleCloudDialogflowCxV3BatchRunTestCasesResponse();

  GoogleCloudDialogflowCxV3BatchRunTestCasesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('results')) {
      results = (_json['results'] as core.List)
          .map<GoogleCloudDialogflowCxV3TestCaseResult>((value) =>
              GoogleCloudDialogflowCxV3TestCaseResult.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (results != null)
          'results': results!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for TestCases.CalculateCoverage.
class GoogleCloudDialogflowCxV3CalculateCoverageResponse {
  /// The agent to calculate coverage for.
  ///
  /// Format: `projects//locations//agents/`.
  core.String? agent;

  /// Intent coverage.
  GoogleCloudDialogflowCxV3IntentCoverage? intentCoverage;

  /// Transition route group coverage.
  GoogleCloudDialogflowCxV3TransitionRouteGroupCoverage? routeGroupCoverage;

  /// Transition (excluding transition route groups) coverage.
  GoogleCloudDialogflowCxV3TransitionCoverage? transitionCoverage;

  GoogleCloudDialogflowCxV3CalculateCoverageResponse();

  GoogleCloudDialogflowCxV3CalculateCoverageResponse.fromJson(core.Map _json) {
    if (_json.containsKey('agent')) {
      agent = _json['agent'] as core.String;
    }
    if (_json.containsKey('intentCoverage')) {
      intentCoverage = GoogleCloudDialogflowCxV3IntentCoverage.fromJson(
          _json['intentCoverage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('routeGroupCoverage')) {
      routeGroupCoverage =
          GoogleCloudDialogflowCxV3TransitionRouteGroupCoverage.fromJson(
              _json['routeGroupCoverage']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('transitionCoverage')) {
      transitionCoverage = GoogleCloudDialogflowCxV3TransitionCoverage.fromJson(
          _json['transitionCoverage'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (agent != null) 'agent': agent!,
        if (intentCoverage != null) 'intentCoverage': intentCoverage!.toJson(),
        if (routeGroupCoverage != null)
          'routeGroupCoverage': routeGroupCoverage!.toJson(),
        if (transitionCoverage != null)
          'transitionCoverage': transitionCoverage!.toJson(),
      };
}

/// One interaction between a human and virtual agent.
///
/// The human provides some input and the virtual agent provides a response.
class GoogleCloudDialogflowCxV3ConversationTurn {
  /// The user input.
  GoogleCloudDialogflowCxV3ConversationTurnUserInput? userInput;

  /// The virtual agent output.
  GoogleCloudDialogflowCxV3ConversationTurnVirtualAgentOutput?
      virtualAgentOutput;

  GoogleCloudDialogflowCxV3ConversationTurn();

  GoogleCloudDialogflowCxV3ConversationTurn.fromJson(core.Map _json) {
    if (_json.containsKey('userInput')) {
      userInput = GoogleCloudDialogflowCxV3ConversationTurnUserInput.fromJson(
          _json['userInput'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('virtualAgentOutput')) {
      virtualAgentOutput =
          GoogleCloudDialogflowCxV3ConversationTurnVirtualAgentOutput.fromJson(
              _json['virtualAgentOutput']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (userInput != null) 'userInput': userInput!.toJson(),
        if (virtualAgentOutput != null)
          'virtualAgentOutput': virtualAgentOutput!.toJson(),
      };
}

/// The input from the human user.
class GoogleCloudDialogflowCxV3ConversationTurnUserInput {
  /// Parameters that need to be injected into the conversation during intent
  /// detection.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? injectedParameters;

  /// Supports text input, event input, dtmf input in the test case.
  GoogleCloudDialogflowCxV3QueryInput? input;

  /// If webhooks should be allowed to trigger in response to the user
  /// utterance.
  ///
  /// Often if parameters are injected, webhooks should not be enabled.
  core.bool? isWebhookEnabled;

  GoogleCloudDialogflowCxV3ConversationTurnUserInput();

  GoogleCloudDialogflowCxV3ConversationTurnUserInput.fromJson(core.Map _json) {
    if (_json.containsKey('injectedParameters')) {
      injectedParameters =
          (_json['injectedParameters'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('input')) {
      input = GoogleCloudDialogflowCxV3QueryInput.fromJson(
          _json['input'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('isWebhookEnabled')) {
      isWebhookEnabled = _json['isWebhookEnabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (injectedParameters != null)
          'injectedParameters': injectedParameters!,
        if (input != null) 'input': input!.toJson(),
        if (isWebhookEnabled != null) 'isWebhookEnabled': isWebhookEnabled!,
      };
}

/// The output from the virtual agent.
class GoogleCloudDialogflowCxV3ConversationTurnVirtualAgentOutput {
  /// The Page on which the utterance was spoken.
  ///
  /// Only name and displayName will be set.
  GoogleCloudDialogflowCxV3Page? currentPage;

  /// Input only.
  ///
  /// The diagnostic info output for the turn.
  ///
  /// Required.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? diagnosticInfo;

  /// If this is part of a result conversation turn, the list of differences
  /// between the original run and the replay for this output, if any.
  ///
  /// Output only.
  core.List<GoogleCloudDialogflowCxV3TestRunDifference>? differences;

  /// The session parameters available to the bot at this point.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? sessionParameters;

  /// Response error from the agent in the test result.
  ///
  /// If set, other output is empty.
  GoogleRpcStatus? status;

  /// The text responses from the agent for the turn.
  core.List<GoogleCloudDialogflowCxV3ResponseMessageText>? textResponses;

  /// The Intent that triggered the response.
  ///
  /// Only name and displayName will be set.
  GoogleCloudDialogflowCxV3Intent? triggeredIntent;

  GoogleCloudDialogflowCxV3ConversationTurnVirtualAgentOutput();

  GoogleCloudDialogflowCxV3ConversationTurnVirtualAgentOutput.fromJson(
      core.Map _json) {
    if (_json.containsKey('currentPage')) {
      currentPage = GoogleCloudDialogflowCxV3Page.fromJson(
          _json['currentPage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('diagnosticInfo')) {
      diagnosticInfo =
          (_json['diagnosticInfo'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('differences')) {
      differences = (_json['differences'] as core.List)
          .map<GoogleCloudDialogflowCxV3TestRunDifference>((value) =>
              GoogleCloudDialogflowCxV3TestRunDifference.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('sessionParameters')) {
      sessionParameters =
          (_json['sessionParameters'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('status')) {
      status = GoogleRpcStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textResponses')) {
      textResponses = (_json['textResponses'] as core.List)
          .map<GoogleCloudDialogflowCxV3ResponseMessageText>((value) =>
              GoogleCloudDialogflowCxV3ResponseMessageText.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('triggeredIntent')) {
      triggeredIntent = GoogleCloudDialogflowCxV3Intent.fromJson(
          _json['triggeredIntent'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentPage != null) 'currentPage': currentPage!.toJson(),
        if (diagnosticInfo != null) 'diagnosticInfo': diagnosticInfo!,
        if (differences != null)
          'differences': differences!.map((value) => value.toJson()).toList(),
        if (sessionParameters != null) 'sessionParameters': sessionParameters!,
        if (status != null) 'status': status!.toJson(),
        if (textResponses != null)
          'textResponses':
              textResponses!.map((value) => value.toJson()).toList(),
        if (triggeredIntent != null)
          'triggeredIntent': triggeredIntent!.toJson(),
      };
}

/// Metadata for CreateDocument operation.
class GoogleCloudDialogflowCxV3CreateDocumentOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowCxV3GenericKnowledgeOperationMetadata? genericMetadata;

  GoogleCloudDialogflowCxV3CreateDocumentOperationMetadata();

  GoogleCloudDialogflowCxV3CreateDocumentOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowCxV3GenericKnowledgeOperationMetadata.fromJson(
              _json['genericMetadata'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// Metadata associated with the long running operation for
/// Versions.CreateVersion.
class GoogleCloudDialogflowCxV3CreateVersionOperationMetadata {
  /// Name of the created version.
  ///
  /// Format: `projects//locations//agents//flows//versions/`.
  core.String? version;

  GoogleCloudDialogflowCxV3CreateVersionOperationMetadata();

  GoogleCloudDialogflowCxV3CreateVersionOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (version != null) 'version': version!,
      };
}

/// Metadata for DeleteDocument operation.
class GoogleCloudDialogflowCxV3DeleteDocumentOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowCxV3GenericKnowledgeOperationMetadata? genericMetadata;

  GoogleCloudDialogflowCxV3DeleteDocumentOperationMetadata();

  GoogleCloudDialogflowCxV3DeleteDocumentOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowCxV3GenericKnowledgeOperationMetadata.fromJson(
              _json['genericMetadata'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// The request to detect user's intent.
class GoogleCloudDialogflowCxV3DetectIntentRequest {
  /// Instructs the speech synthesizer how to generate the output audio.
  GoogleCloudDialogflowCxV3OutputAudioConfig? outputAudioConfig;

  /// The input specification.
  ///
  /// Required.
  GoogleCloudDialogflowCxV3QueryInput? queryInput;

  /// The parameters of this query.
  GoogleCloudDialogflowCxV3QueryParameters? queryParams;

  GoogleCloudDialogflowCxV3DetectIntentRequest();

  GoogleCloudDialogflowCxV3DetectIntentRequest.fromJson(core.Map _json) {
    if (_json.containsKey('outputAudioConfig')) {
      outputAudioConfig = GoogleCloudDialogflowCxV3OutputAudioConfig.fromJson(
          _json['outputAudioConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('queryInput')) {
      queryInput = GoogleCloudDialogflowCxV3QueryInput.fromJson(
          _json['queryInput'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('queryParams')) {
      queryParams = GoogleCloudDialogflowCxV3QueryParameters.fromJson(
          _json['queryParams'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (outputAudioConfig != null)
          'outputAudioConfig': outputAudioConfig!.toJson(),
        if (queryInput != null) 'queryInput': queryInput!.toJson(),
        if (queryParams != null) 'queryParams': queryParams!.toJson(),
      };
}

/// The message returned from the DetectIntent method.
class GoogleCloudDialogflowCxV3DetectIntentResponse {
  /// The audio data bytes encoded as specified in the request.
  ///
  /// Note: The output audio is generated based on the values of default
  /// platform text responses found in the `query_result.response_messages`
  /// field. If multiple default text responses exist, they will be concatenated
  /// when generating audio. If no default platform text responses exist, the
  /// generated audio content will be empty. In some scenarios, multiple output
  /// audio fields may be present in the response structure. In these cases,
  /// only the top-most-level audio output has content.
  core.String? outputAudio;
  core.List<core.int> get outputAudioAsBytes =>
      convert.base64.decode(outputAudio!);

  set outputAudioAsBytes(core.List<core.int> _bytes) {
    outputAudio =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The config used by the speech synthesizer to generate the output audio.
  GoogleCloudDialogflowCxV3OutputAudioConfig? outputAudioConfig;

  /// The result of the conversational query.
  GoogleCloudDialogflowCxV3QueryResult? queryResult;

  /// The unique identifier of the response.
  ///
  /// It can be used to locate a response in the training example set or for
  /// reporting issues.
  ///
  /// Output only.
  core.String? responseId;

  GoogleCloudDialogflowCxV3DetectIntentResponse();

  GoogleCloudDialogflowCxV3DetectIntentResponse.fromJson(core.Map _json) {
    if (_json.containsKey('outputAudio')) {
      outputAudio = _json['outputAudio'] as core.String;
    }
    if (_json.containsKey('outputAudioConfig')) {
      outputAudioConfig = GoogleCloudDialogflowCxV3OutputAudioConfig.fromJson(
          _json['outputAudioConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('queryResult')) {
      queryResult = GoogleCloudDialogflowCxV3QueryResult.fromJson(
          _json['queryResult'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('responseId')) {
      responseId = _json['responseId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (outputAudio != null) 'outputAudio': outputAudio!,
        if (outputAudioConfig != null)
          'outputAudioConfig': outputAudioConfig!.toJson(),
        if (queryResult != null) 'queryResult': queryResult!.toJson(),
        if (responseId != null) 'responseId': responseId!,
      };
}

/// Represents the input for dtmf event.
class GoogleCloudDialogflowCxV3DtmfInput {
  /// The dtmf digits.
  core.String? digits;

  /// The finish digit (if any).
  core.String? finishDigit;

  GoogleCloudDialogflowCxV3DtmfInput();

  GoogleCloudDialogflowCxV3DtmfInput.fromJson(core.Map _json) {
    if (_json.containsKey('digits')) {
      digits = _json['digits'] as core.String;
    }
    if (_json.containsKey('finishDigit')) {
      finishDigit = _json['finishDigit'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (digits != null) 'digits': digits!,
        if (finishDigit != null) 'finishDigit': finishDigit!,
      };
}

/// Entities are extracted from user input and represent parameters that are
/// meaningful to your application.
///
/// For example, a date range, a proper name such as a geographic location or
/// landmark, and so on. Entities represent actionable data for your
/// application. When you define an entity, you can also include synonyms that
/// all map to that entity. For example, "soft drink", "soda", "pop", and so on.
/// There are three types of entities: * **System** - entities that are defined
/// by the Dialogflow API for common data types such as date, time, currency,
/// and so on. A system entity is represented by the `EntityType` type. *
/// **Custom** - entities that are defined by you that represent actionable data
/// that is meaningful to your application. For example, you could define a
/// `pizza.sauce` entity for red or white pizza sauce, a `pizza.cheese` entity
/// for the different types of cheese on a pizza, a `pizza.topping` entity for
/// different toppings, and so on. A custom entity is represented by the
/// `EntityType` type. * **User** - entities that are built for an individual
/// user such as favorites, preferences, playlists, and so on. A user entity is
/// represented by the SessionEntityType type. For more information about entity
/// types, see the
/// [Dialogflow documentation](https://cloud.google.com/dialogflow/docs/entities-overview).
class GoogleCloudDialogflowCxV3EntityType {
  /// Indicates whether the entity type can be automatically expanded.
  /// Possible string values are:
  /// - "AUTO_EXPANSION_MODE_UNSPECIFIED" : Auto expansion disabled for the
  /// entity.
  /// - "AUTO_EXPANSION_MODE_DEFAULT" : Allows an agent to recognize values that
  /// have not been explicitly listed in the entity.
  core.String? autoExpansionMode;

  /// The human-readable name of the entity type, unique within the agent.
  ///
  /// Required.
  core.String? displayName;

  /// Enables fuzzy entity extraction during classification.
  core.bool? enableFuzzyExtraction;

  /// The collection of entity entries associated with the entity type.
  core.List<GoogleCloudDialogflowCxV3EntityTypeEntity>? entities;

  /// Collection of exceptional words and phrases that shouldn't be matched.
  ///
  /// For example, if you have a size entity type with entry `giant`(an
  /// adjective), you might consider adding `giants`(a noun) as an exclusion. If
  /// the kind of entity type is `KIND_MAP`, then the phrases specified by
  /// entities and excluded phrases should be mutually exclusive.
  core.List<GoogleCloudDialogflowCxV3EntityTypeExcludedPhrase>? excludedPhrases;

  /// Indicates the kind of entity type.
  ///
  /// Required.
  /// Possible string values are:
  /// - "KIND_UNSPECIFIED" : Not specified. This value should be never used.
  /// - "KIND_MAP" : Map entity types allow mapping of a group of synonyms to a
  /// canonical value.
  /// - "KIND_LIST" : List entity types contain a set of entries that do not map
  /// to canonical values. However, list entity types can contain references to
  /// other entity types (with or without aliases).
  /// - "KIND_REGEXP" : Regexp entity types allow to specify regular expressions
  /// in entries values.
  core.String? kind;

  /// The unique identifier of the entity type.
  ///
  /// Required for EntityTypes.UpdateEntityType. Format:
  /// `projects//locations//agents//entityTypes/`.
  core.String? name;

  /// Indicates whether parameters of the entity type should be redacted in log.
  ///
  /// If redaction is enabled, page parameters and intent parameters referring
  /// to the entity type will be replaced by parameter name when logging.
  core.bool? redact;

  GoogleCloudDialogflowCxV3EntityType();

  GoogleCloudDialogflowCxV3EntityType.fromJson(core.Map _json) {
    if (_json.containsKey('autoExpansionMode')) {
      autoExpansionMode = _json['autoExpansionMode'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('enableFuzzyExtraction')) {
      enableFuzzyExtraction = _json['enableFuzzyExtraction'] as core.bool;
    }
    if (_json.containsKey('entities')) {
      entities = (_json['entities'] as core.List)
          .map<GoogleCloudDialogflowCxV3EntityTypeEntity>((value) =>
              GoogleCloudDialogflowCxV3EntityTypeEntity.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('excludedPhrases')) {
      excludedPhrases = (_json['excludedPhrases'] as core.List)
          .map<GoogleCloudDialogflowCxV3EntityTypeExcludedPhrase>((value) =>
              GoogleCloudDialogflowCxV3EntityTypeExcludedPhrase.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('redact')) {
      redact = _json['redact'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoExpansionMode != null) 'autoExpansionMode': autoExpansionMode!,
        if (displayName != null) 'displayName': displayName!,
        if (enableFuzzyExtraction != null)
          'enableFuzzyExtraction': enableFuzzyExtraction!,
        if (entities != null)
          'entities': entities!.map((value) => value.toJson()).toList(),
        if (excludedPhrases != null)
          'excludedPhrases':
              excludedPhrases!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (redact != null) 'redact': redact!,
      };
}

/// An **entity entry** for an associated entity type.
class GoogleCloudDialogflowCxV3EntityTypeEntity {
  /// A collection of value synonyms.
  ///
  /// For example, if the entity type is *vegetable*, and `value` is
  /// *scallions*, a synonym could be *green onions*. For `KIND_LIST` entity
  /// types: * This collection must contain exactly one synonym equal to
  /// `value`.
  ///
  /// Required.
  core.List<core.String>? synonyms;

  /// The primary value associated with this entity entry.
  ///
  /// For example, if the entity type is *vegetable*, the value could be
  /// *scallions*. For `KIND_MAP` entity types: * A canonical value to be used
  /// in place of synonyms. For `KIND_LIST` entity types: * A string that can
  /// contain references to other entity types (with or without aliases).
  ///
  /// Required.
  core.String? value;

  GoogleCloudDialogflowCxV3EntityTypeEntity();

  GoogleCloudDialogflowCxV3EntityTypeEntity.fromJson(core.Map _json) {
    if (_json.containsKey('synonyms')) {
      synonyms = (_json['synonyms'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (synonyms != null) 'synonyms': synonyms!,
        if (value != null) 'value': value!,
      };
}

/// An excluded entity phrase that should not be matched.
class GoogleCloudDialogflowCxV3EntityTypeExcludedPhrase {
  /// The word or phrase to be excluded.
  ///
  /// Required.
  core.String? value;

  GoogleCloudDialogflowCxV3EntityTypeExcludedPhrase();

  GoogleCloudDialogflowCxV3EntityTypeExcludedPhrase.fromJson(core.Map _json) {
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (value != null) 'value': value!,
      };
}

/// Represents an environment for an agent.
///
/// You can create multiple versions of your agent and publish them to separate
/// environments. When you edit an agent, you are editing the draft agent. At
/// any point, you can save the draft agent as an agent version, which is an
/// immutable snapshot of your agent. When you save the draft agent, it is
/// published to the default environment. When you create agent versions, you
/// can publish them to custom environments. You can create a variety of custom
/// environments for testing, development, production, etc.
class GoogleCloudDialogflowCxV3Environment {
  /// The human-readable description of the environment.
  ///
  /// The maximum length is 500 characters. If exceeded, the request is
  /// rejected.
  core.String? description;

  /// The human-readable name of the environment (unique in an agent).
  ///
  /// Limit of 64 characters.
  ///
  /// Required.
  core.String? displayName;

  /// The name of the environment.
  ///
  /// Format: `projects//locations//agents//environments/`.
  core.String? name;

  /// Update time of this environment.
  ///
  /// Output only.
  core.String? updateTime;

  /// A list of configurations for flow versions.
  ///
  /// You should include version configs for all flows that are reachable from
  /// `Start Flow` in the agent. Otherwise, an error will be returned.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowCxV3EnvironmentVersionConfig>? versionConfigs;

  GoogleCloudDialogflowCxV3Environment();

  GoogleCloudDialogflowCxV3Environment.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('versionConfigs')) {
      versionConfigs = (_json['versionConfigs'] as core.List)
          .map<GoogleCloudDialogflowCxV3EnvironmentVersionConfig>((value) =>
              GoogleCloudDialogflowCxV3EnvironmentVersionConfig.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (name != null) 'name': name!,
        if (updateTime != null) 'updateTime': updateTime!,
        if (versionConfigs != null)
          'versionConfigs':
              versionConfigs!.map((value) => value.toJson()).toList(),
      };
}

/// Configuration for the version.
class GoogleCloudDialogflowCxV3EnvironmentVersionConfig {
  /// Format: projects//locations//agents//flows//versions/.
  ///
  /// Required.
  core.String? version;

  GoogleCloudDialogflowCxV3EnvironmentVersionConfig();

  GoogleCloudDialogflowCxV3EnvironmentVersionConfig.fromJson(core.Map _json) {
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (version != null) 'version': version!,
      };
}

/// An event handler specifies an event that can be handled during a session.
///
/// When the specified event happens, the following actions are taken in order:
/// * If there is a `trigger_fulfillment` associated with the event, it will be
/// called. * If there is a `target_page` associated with the event, the session
/// will transition into the specified page. * If there is a `target_flow`
/// associated with the event, the session will transition into the specified
/// flow.
class GoogleCloudDialogflowCxV3EventHandler {
  /// The name of the event to handle.
  ///
  /// Required.
  core.String? event;

  /// The unique identifier of this event handler.
  ///
  /// Output only.
  core.String? name;

  /// The target flow to transition to.
  ///
  /// Format: `projects//locations//agents//flows/`.
  core.String? targetFlow;

  /// The target page to transition to.
  ///
  /// Format: `projects//locations//agents//flows//pages/`.
  core.String? targetPage;

  /// The fulfillment to call when the event occurs.
  ///
  /// Handling webhook errors with a fulfillment enabled with webhook could
  /// cause infinite loop. It is invalid to specify such fulfillment for a
  /// handler handling webhooks.
  GoogleCloudDialogflowCxV3Fulfillment? triggerFulfillment;

  GoogleCloudDialogflowCxV3EventHandler();

  GoogleCloudDialogflowCxV3EventHandler.fromJson(core.Map _json) {
    if (_json.containsKey('event')) {
      event = _json['event'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('targetFlow')) {
      targetFlow = _json['targetFlow'] as core.String;
    }
    if (_json.containsKey('targetPage')) {
      targetPage = _json['targetPage'] as core.String;
    }
    if (_json.containsKey('triggerFulfillment')) {
      triggerFulfillment = GoogleCloudDialogflowCxV3Fulfillment.fromJson(
          _json['triggerFulfillment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (event != null) 'event': event!,
        if (name != null) 'name': name!,
        if (targetFlow != null) 'targetFlow': targetFlow!,
        if (targetPage != null) 'targetPage': targetPage!,
        if (triggerFulfillment != null)
          'triggerFulfillment': triggerFulfillment!.toJson(),
      };
}

/// Represents the event to trigger.
class GoogleCloudDialogflowCxV3EventInput {
  /// Name of the event.
  core.String? event;

  GoogleCloudDialogflowCxV3EventInput();

  GoogleCloudDialogflowCxV3EventInput.fromJson(core.Map _json) {
    if (_json.containsKey('event')) {
      event = _json['event'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (event != null) 'event': event!,
      };
}

/// Represents an experiment in an environment.
class GoogleCloudDialogflowCxV3Experiment {
  /// Creation time of this experiment.
  core.String? createTime;

  /// The definition of the experiment.
  GoogleCloudDialogflowCxV3ExperimentDefinition? definition;

  /// The human-readable description of the experiment.
  core.String? description;

  /// The human-readable name of the experiment (unique in an environment).
  ///
  /// Limit of 64 characters.
  ///
  /// Required.
  core.String? displayName;

  /// End time of this experiment.
  core.String? endTime;

  /// Maximum number of days to run the experiment/rollout.
  ///
  /// If auto-rollout is not enabled, default value and maximum will be 30 days.
  /// If auto-rollout is enabled, default value and maximum will be 6 days.
  core.String? experimentLength;

  /// Last update time of this experiment.
  core.String? lastUpdateTime;

  /// The name of the experiment.
  ///
  /// Format: projects//locations//agents//environments//experiments/..
  core.String? name;

  /// Inference result of the experiment.
  GoogleCloudDialogflowCxV3ExperimentResult? result;

  /// Start time of this experiment.
  core.String? startTime;

  /// The current state of the experiment.
  ///
  /// Transition triggered by Expriments.StartExperiment: PENDING->RUNNING.
  /// Transition triggered by Expriments.CancelExperiment: PENDING->CANCELLED or
  /// RUNNING->CANCELLED.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : State unspecified.
  /// - "DRAFT" : The experiment is created but not started yet.
  /// - "RUNNING" : The experiment is running.
  /// - "DONE" : The experiment is done.
  core.String? state;

  /// The history of updates to the experiment variants.
  core.List<GoogleCloudDialogflowCxV3VariantsHistory>? variantsHistory;

  GoogleCloudDialogflowCxV3Experiment();

  GoogleCloudDialogflowCxV3Experiment.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('definition')) {
      definition = GoogleCloudDialogflowCxV3ExperimentDefinition.fromJson(
          _json['definition'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('experimentLength')) {
      experimentLength = _json['experimentLength'] as core.String;
    }
    if (_json.containsKey('lastUpdateTime')) {
      lastUpdateTime = _json['lastUpdateTime'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('result')) {
      result = GoogleCloudDialogflowCxV3ExperimentResult.fromJson(
          _json['result'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('variantsHistory')) {
      variantsHistory = (_json['variantsHistory'] as core.List)
          .map<GoogleCloudDialogflowCxV3VariantsHistory>((value) =>
              GoogleCloudDialogflowCxV3VariantsHistory.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (definition != null) 'definition': definition!.toJson(),
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (endTime != null) 'endTime': endTime!,
        if (experimentLength != null) 'experimentLength': experimentLength!,
        if (lastUpdateTime != null) 'lastUpdateTime': lastUpdateTime!,
        if (name != null) 'name': name!,
        if (result != null) 'result': result!.toJson(),
        if (startTime != null) 'startTime': startTime!,
        if (state != null) 'state': state!,
        if (variantsHistory != null)
          'variantsHistory':
              variantsHistory!.map((value) => value.toJson()).toList(),
      };
}

/// Definition of the experiment.
class GoogleCloudDialogflowCxV3ExperimentDefinition {
  /// The condition defines which subset of sessions are selected for this
  /// experiment.
  ///
  /// If not specified, all sessions are eligible. E.g.
  /// "query_input.language_code=en" See the
  /// [conditions reference](https://cloud.google.com/dialogflow/cx/docs/reference/condition).
  core.String? condition;

  /// The flow versions as the variants of this experiment.
  GoogleCloudDialogflowCxV3VersionVariants? versionVariants;

  GoogleCloudDialogflowCxV3ExperimentDefinition();

  GoogleCloudDialogflowCxV3ExperimentDefinition.fromJson(core.Map _json) {
    if (_json.containsKey('condition')) {
      condition = _json['condition'] as core.String;
    }
    if (_json.containsKey('versionVariants')) {
      versionVariants = GoogleCloudDialogflowCxV3VersionVariants.fromJson(
          _json['versionVariants'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (condition != null) 'condition': condition!,
        if (versionVariants != null)
          'versionVariants': versionVariants!.toJson(),
      };
}

/// The inference result which includes an objective metric to optimize and the
/// confidence interval.
class GoogleCloudDialogflowCxV3ExperimentResult {
  /// The last time the experiment's stats data was updated.
  ///
  /// Will have default value if stats have never been computed for this
  /// experiment.
  core.String? lastUpdateTime;

  /// Version variants and metrics.
  core.List<GoogleCloudDialogflowCxV3ExperimentResultVersionMetrics>?
      versionMetrics;

  GoogleCloudDialogflowCxV3ExperimentResult();

  GoogleCloudDialogflowCxV3ExperimentResult.fromJson(core.Map _json) {
    if (_json.containsKey('lastUpdateTime')) {
      lastUpdateTime = _json['lastUpdateTime'] as core.String;
    }
    if (_json.containsKey('versionMetrics')) {
      versionMetrics = (_json['versionMetrics'] as core.List)
          .map<GoogleCloudDialogflowCxV3ExperimentResultVersionMetrics>(
              (value) => GoogleCloudDialogflowCxV3ExperimentResultVersionMetrics
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lastUpdateTime != null) 'lastUpdateTime': lastUpdateTime!,
        if (versionMetrics != null)
          'versionMetrics':
              versionMetrics!.map((value) => value.toJson()).toList(),
      };
}

/// A confidence interval is a range of possible values for the experiment
/// objective you are trying to measure.
class GoogleCloudDialogflowCxV3ExperimentResultConfidenceInterval {
  /// The confidence level used to construct the interval, i.e. there is X%
  /// chance that the true value is within this interval.
  core.double? confidenceLevel;

  /// Lower bound of the interval.
  core.double? lowerBound;

  /// The percent change between an experiment metric's value and the value for
  /// its control.
  core.double? ratio;

  /// Upper bound of the interval.
  core.double? upperBound;

  GoogleCloudDialogflowCxV3ExperimentResultConfidenceInterval();

  GoogleCloudDialogflowCxV3ExperimentResultConfidenceInterval.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidenceLevel')) {
      confidenceLevel = (_json['confidenceLevel'] as core.num).toDouble();
    }
    if (_json.containsKey('lowerBound')) {
      lowerBound = (_json['lowerBound'] as core.num).toDouble();
    }
    if (_json.containsKey('ratio')) {
      ratio = (_json['ratio'] as core.num).toDouble();
    }
    if (_json.containsKey('upperBound')) {
      upperBound = (_json['upperBound'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidenceLevel != null) 'confidenceLevel': confidenceLevel!,
        if (lowerBound != null) 'lowerBound': lowerBound!,
        if (ratio != null) 'ratio': ratio!,
        if (upperBound != null) 'upperBound': upperBound!,
      };
}

/// Metric and corresponding confidence intervals.
class GoogleCloudDialogflowCxV3ExperimentResultMetric {
  /// The probability that the treatment is better than all other treatments in
  /// the experiment
  GoogleCloudDialogflowCxV3ExperimentResultConfidenceInterval?
      confidenceInterval;

  /// Count value of a metric.
  core.double? count;

  /// Count-based metric type.
  ///
  /// Only one of type or count_type is specified in each Metric.
  /// Possible string values are:
  /// - "COUNT_TYPE_UNSPECIFIED" : Count type unspecified.
  /// - "TOTAL_NO_MATCH_COUNT" : Total number of occurrences of a 'NO_MATCH'.
  /// - "TOTAL_TURN_COUNT" : Total number of turn counts.
  /// - "AVERAGE_TURN_COUNT" : Average turn count in a session.
  core.String? countType;

  /// Ratio value of a metric.
  core.double? ratio;

  /// Ratio-based metric type.
  ///
  /// Only one of type or count_type is specified in each Metric.
  /// Possible string values are:
  /// - "METRIC_UNSPECIFIED" : Metric unspecified.
  /// - "CONTAINED_SESSION_NO_CALLBACK_RATE" : Percentage of contained sessions
  /// without user calling back in 24 hours.
  /// - "LIVE_AGENT_HANDOFF_RATE" : Percentage of sessions that were handed to a
  /// human agent.
  /// - "CALLBACK_SESSION_RATE" : Percentage of sessions with the same user
  /// calling back.
  /// - "ABANDONED_SESSION_RATE" : Percentage of sessions where user hung up.
  /// - "SESSION_END_RATE" : Percentage of sessions reached Dialogflow
  /// 'END_PAGE' or 'END_SESSION'.
  core.String? type;

  GoogleCloudDialogflowCxV3ExperimentResultMetric();

  GoogleCloudDialogflowCxV3ExperimentResultMetric.fromJson(core.Map _json) {
    if (_json.containsKey('confidenceInterval')) {
      confidenceInterval =
          GoogleCloudDialogflowCxV3ExperimentResultConfidenceInterval.fromJson(
              _json['confidenceInterval']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('count')) {
      count = (_json['count'] as core.num).toDouble();
    }
    if (_json.containsKey('countType')) {
      countType = _json['countType'] as core.String;
    }
    if (_json.containsKey('ratio')) {
      ratio = (_json['ratio'] as core.num).toDouble();
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidenceInterval != null)
          'confidenceInterval': confidenceInterval!.toJson(),
        if (count != null) 'count': count!,
        if (countType != null) 'countType': countType!,
        if (ratio != null) 'ratio': ratio!,
        if (type != null) 'type': type!,
      };
}

/// Version variant and associated metrics.
class GoogleCloudDialogflowCxV3ExperimentResultVersionMetrics {
  /// The metrics and corresponding confidence intervals in the inference
  /// result.
  core.List<GoogleCloudDialogflowCxV3ExperimentResultMetric>? metrics;

  /// Number of sessions that were allocated to this version.
  core.int? sessionCount;

  /// The name of the flow Version.
  ///
  /// Format: `projects//locations//agents//flows//versions/`.
  core.String? version;

  GoogleCloudDialogflowCxV3ExperimentResultVersionMetrics();

  GoogleCloudDialogflowCxV3ExperimentResultVersionMetrics.fromJson(
      core.Map _json) {
    if (_json.containsKey('metrics')) {
      metrics = (_json['metrics'] as core.List)
          .map<GoogleCloudDialogflowCxV3ExperimentResultMetric>((value) =>
              GoogleCloudDialogflowCxV3ExperimentResultMetric.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('sessionCount')) {
      sessionCount = _json['sessionCount'] as core.int;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (metrics != null)
          'metrics': metrics!.map((value) => value.toJson()).toList(),
        if (sessionCount != null) 'sessionCount': sessionCount!,
        if (version != null) 'version': version!,
      };
}

/// The request message for Agents.ExportAgent.
class GoogleCloudDialogflowCxV3ExportAgentRequest {
  /// The [Google Cloud Storage](https://cloud.google.com/storage/docs/) URI to
  /// export the agent to.
  ///
  /// The format of this URI must be `gs:///`. If left unspecified, the
  /// serialized agent is returned inline.
  ///
  /// Optional.
  core.String? agentUri;

  /// Environment name.
  ///
  /// If not set, draft environment is assumed. Format:
  /// `projects//locations//agents//environments/`.
  ///
  /// Optional.
  core.String? environment;

  GoogleCloudDialogflowCxV3ExportAgentRequest();

  GoogleCloudDialogflowCxV3ExportAgentRequest.fromJson(core.Map _json) {
    if (_json.containsKey('agentUri')) {
      agentUri = _json['agentUri'] as core.String;
    }
    if (_json.containsKey('environment')) {
      environment = _json['environment'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (agentUri != null) 'agentUri': agentUri!,
        if (environment != null) 'environment': environment!,
      };
}

/// The response message for Agents.ExportAgent.
class GoogleCloudDialogflowCxV3ExportAgentResponse {
  /// Uncompressed raw byte content for agent.
  core.String? agentContent;
  core.List<core.int> get agentContentAsBytes =>
      convert.base64.decode(agentContent!);

  set agentContentAsBytes(core.List<core.int> _bytes) {
    agentContent =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The URI to a file containing the exported agent.
  ///
  /// This field is populated only if `agent_uri` is specified in
  /// ExportAgentRequest.
  core.String? agentUri;

  GoogleCloudDialogflowCxV3ExportAgentResponse();

  GoogleCloudDialogflowCxV3ExportAgentResponse.fromJson(core.Map _json) {
    if (_json.containsKey('agentContent')) {
      agentContent = _json['agentContent'] as core.String;
    }
    if (_json.containsKey('agentUri')) {
      agentUri = _json['agentUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (agentContent != null) 'agentContent': agentContent!,
        if (agentUri != null) 'agentUri': agentUri!,
      };
}

/// The request message for Flows.ExportFlow.
class GoogleCloudDialogflowCxV3ExportFlowRequest {
  /// The [Google Cloud Storage](https://cloud.google.com/storage/docs/) URI to
  /// export the flow to.
  ///
  /// The format of this URI must be `gs:///`. If left unspecified, the
  /// serialized flow is returned inline.
  ///
  /// Optional.
  core.String? flowUri;

  /// Whether to export flows referenced by the specified flow.
  ///
  /// Optional.
  core.bool? includeReferencedFlows;

  GoogleCloudDialogflowCxV3ExportFlowRequest();

  GoogleCloudDialogflowCxV3ExportFlowRequest.fromJson(core.Map _json) {
    if (_json.containsKey('flowUri')) {
      flowUri = _json['flowUri'] as core.String;
    }
    if (_json.containsKey('includeReferencedFlows')) {
      includeReferencedFlows = _json['includeReferencedFlows'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (flowUri != null) 'flowUri': flowUri!,
        if (includeReferencedFlows != null)
          'includeReferencedFlows': includeReferencedFlows!,
      };
}

/// The response message for Flows.ExportFlow.
class GoogleCloudDialogflowCxV3ExportFlowResponse {
  /// Uncompressed raw byte content for flow.
  core.String? flowContent;
  core.List<core.int> get flowContentAsBytes =>
      convert.base64.decode(flowContent!);

  set flowContentAsBytes(core.List<core.int> _bytes) {
    flowContent =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The URI to a file containing the exported flow.
  ///
  /// This field is populated only if `flow_uri` is specified in
  /// ExportFlowRequest.
  core.String? flowUri;

  GoogleCloudDialogflowCxV3ExportFlowResponse();

  GoogleCloudDialogflowCxV3ExportFlowResponse.fromJson(core.Map _json) {
    if (_json.containsKey('flowContent')) {
      flowContent = _json['flowContent'] as core.String;
    }
    if (_json.containsKey('flowUri')) {
      flowUri = _json['flowUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (flowContent != null) 'flowContent': flowContent!,
        if (flowUri != null) 'flowUri': flowUri!,
      };
}

/// Metadata returned for the TestCases.ExportTestCases long running operation.
class GoogleCloudDialogflowCxV3ExportTestCasesMetadata {
  GoogleCloudDialogflowCxV3ExportTestCasesMetadata();

  GoogleCloudDialogflowCxV3ExportTestCasesMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The request message for TestCases.ExportTestCases.
class GoogleCloudDialogflowCxV3ExportTestCasesRequest {
  /// The data format of the exported test cases.
  ///
  /// If not specified, `BLOB` is assumed.
  /// Possible string values are:
  /// - "DATA_FORMAT_UNSPECIFIED" : Unspecified format.
  /// - "BLOB" : Raw bytes.
  /// - "JSON" : JSON format.
  core.String? dataFormat;

  /// The filter expression used to filter exported test cases, see
  /// [API Filtering](https://aip.dev/160).
  ///
  /// The expression is case insensitive and supports the following syntax: name
  /// = \[OR name = \] ... For example: * "name = t1 OR name = t2" matches the
  /// test case with the exact resource name "t1" or "t2".
  core.String? filter;

  /// The [Google Cloud Storage](https://cloud.google.com/storage/docs/) URI to
  /// export the test cases to.
  ///
  /// The format of this URI must be `gs:///`. If unspecified, the serialized
  /// test cases is returned inline.
  core.String? gcsUri;

  GoogleCloudDialogflowCxV3ExportTestCasesRequest();

  GoogleCloudDialogflowCxV3ExportTestCasesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('dataFormat')) {
      dataFormat = _json['dataFormat'] as core.String;
    }
    if (_json.containsKey('filter')) {
      filter = _json['filter'] as core.String;
    }
    if (_json.containsKey('gcsUri')) {
      gcsUri = _json['gcsUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dataFormat != null) 'dataFormat': dataFormat!,
        if (filter != null) 'filter': filter!,
        if (gcsUri != null) 'gcsUri': gcsUri!,
      };
}

/// The response message for TestCases.ExportTestCases.
class GoogleCloudDialogflowCxV3ExportTestCasesResponse {
  /// Uncompressed raw byte content for test cases.
  core.String? content;
  core.List<core.int> get contentAsBytes => convert.base64.decode(content!);

  set contentAsBytes(core.List<core.int> _bytes) {
    content =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The URI to a file containing the exported test cases.
  ///
  /// This field is populated only if `gcs_uri` is specified in
  /// ExportTestCasesRequest.
  core.String? gcsUri;

  GoogleCloudDialogflowCxV3ExportTestCasesResponse();

  GoogleCloudDialogflowCxV3ExportTestCasesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('gcsUri')) {
      gcsUri = _json['gcsUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!,
        if (gcsUri != null) 'gcsUri': gcsUri!,
      };
}

/// Flows represents the conversation flows when you build your chatbot agent.
///
/// A flow consists of many pages connected by the transition routes.
/// Conversations always start with the built-in Start Flow (with an all-0 ID).
/// Transition routes can direct the conversation session from the current flow
/// (parent flow) to another flow (sub flow). When the sub flow is finished,
/// Dialogflow will bring the session back to the parent flow, where the sub
/// flow is started. Usually, when a transition route is followed by a matched
/// intent, the intent will be "consumed". This means the intent won't activate
/// more transition routes. However, when the followed transition route moves
/// the conversation session into a different flow, the matched intent can be
/// carried over and to be consumed in the target flow.
class GoogleCloudDialogflowCxV3Flow {
  /// The description of the flow.
  ///
  /// The maximum length is 500 characters. If exceeded, the request is
  /// rejected.
  core.String? description;

  /// The human-readable name of the flow.
  ///
  /// Required.
  core.String? displayName;

  /// A flow's event handlers serve two purposes: * They are responsible for
  /// handling events (e.g. no match, webhook errors) in the flow.
  ///
  /// * They are inherited by every page's event handlers, which can be used to
  /// handle common events regardless of the current page. Event handlers
  /// defined in the page have higher priority than those defined in the flow.
  /// Unlike transition_routes, these handlers are evaluated on a first-match
  /// basis. The first one that matches the event get executed, with the rest
  /// being ignored.
  core.List<GoogleCloudDialogflowCxV3EventHandler>? eventHandlers;

  /// The unique identifier of the flow.
  ///
  /// Format: `projects//locations//agents//flows/`.
  core.String? name;

  /// NLU related settings of the flow.
  GoogleCloudDialogflowCxV3NluSettings? nluSettings;

  /// A flow's transition route group serve two purposes: * They are responsible
  /// for matching the user's first utterances in the flow.
  ///
  /// * They are inherited by every page's transition route groups. Transition
  /// route groups defined in the page have higher priority than those defined
  /// in the flow.
  /// Format:`projects//locations//agents//flows//transitionRouteGroups/`.
  core.List<core.String>? transitionRouteGroups;

  /// A flow's transition routes serve two purposes: * They are responsible for
  /// matching the user's first utterances in the flow.
  ///
  /// * They are inherited by every page's transition routes and can support use
  /// cases such as the user saying "help" or "can I talk to a human?", which
  /// can be handled in a common way regardless of the current page. Transition
  /// routes defined in the page have higher priority than those defined in the
  /// flow. TransitionRoutes are evalauted in the following order: *
  /// TransitionRoutes with intent specified.. * TransitionRoutes with only
  /// condition specified. TransitionRoutes with intent specified are inherited
  /// by pages in the flow.
  core.List<GoogleCloudDialogflowCxV3TransitionRoute>? transitionRoutes;

  GoogleCloudDialogflowCxV3Flow();

  GoogleCloudDialogflowCxV3Flow.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('eventHandlers')) {
      eventHandlers = (_json['eventHandlers'] as core.List)
          .map<GoogleCloudDialogflowCxV3EventHandler>((value) =>
              GoogleCloudDialogflowCxV3EventHandler.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nluSettings')) {
      nluSettings = GoogleCloudDialogflowCxV3NluSettings.fromJson(
          _json['nluSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('transitionRouteGroups')) {
      transitionRouteGroups = (_json['transitionRouteGroups'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('transitionRoutes')) {
      transitionRoutes = (_json['transitionRoutes'] as core.List)
          .map<GoogleCloudDialogflowCxV3TransitionRoute>((value) =>
              GoogleCloudDialogflowCxV3TransitionRoute.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (eventHandlers != null)
          'eventHandlers':
              eventHandlers!.map((value) => value.toJson()).toList(),
        if (name != null) 'name': name!,
        if (nluSettings != null) 'nluSettings': nluSettings!.toJson(),
        if (transitionRouteGroups != null)
          'transitionRouteGroups': transitionRouteGroups!,
        if (transitionRoutes != null)
          'transitionRoutes':
              transitionRoutes!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for Flows.GetFlowValidationResult.
class GoogleCloudDialogflowCxV3FlowValidationResult {
  /// The unique identifier of the flow validation result.
  ///
  /// Format: `projects//locations//agents//flows//validationResult`.
  core.String? name;

  /// Last time the flow was validated.
  core.String? updateTime;

  /// Contains all validation messages.
  core.List<GoogleCloudDialogflowCxV3ValidationMessage>? validationMessages;

  GoogleCloudDialogflowCxV3FlowValidationResult();

  GoogleCloudDialogflowCxV3FlowValidationResult.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('validationMessages')) {
      validationMessages = (_json['validationMessages'] as core.List)
          .map<GoogleCloudDialogflowCxV3ValidationMessage>((value) =>
              GoogleCloudDialogflowCxV3ValidationMessage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (updateTime != null) 'updateTime': updateTime!,
        if (validationMessages != null)
          'validationMessages':
              validationMessages!.map((value) => value.toJson()).toList(),
      };
}

/// A form is a data model that groups related parameters that can be collected
/// from the user.
///
/// The process in which the agent prompts the user and collects parameter
/// values from the user is called form filling. A form can be added to a page.
/// When form filling is done, the filled parameters will be written to the
/// session.
class GoogleCloudDialogflowCxV3Form {
  /// Parameters to collect from the user.
  core.List<GoogleCloudDialogflowCxV3FormParameter>? parameters;

  GoogleCloudDialogflowCxV3Form();

  GoogleCloudDialogflowCxV3Form.fromJson(core.Map _json) {
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<GoogleCloudDialogflowCxV3FormParameter>((value) =>
              GoogleCloudDialogflowCxV3FormParameter.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
      };
}

/// Represents a form parameter.
class GoogleCloudDialogflowCxV3FormParameter {
  /// The default value of an optional parameter.
  ///
  /// If the parameter is required, the default value will be ignored.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? defaultValue;

  /// The human-readable name of the parameter, unique within the form.
  ///
  /// Required.
  core.String? displayName;

  /// The entity type of the parameter.
  ///
  /// Format: `projects/-/locations/-/agents/-/entityTypes/` for system entity
  /// types (for example,
  /// `projects/-/locations/-/agents/-/entityTypes/sys.date`), or
  /// `projects//locations//agents//entityTypes/` for developer entity types.
  ///
  /// Required.
  core.String? entityType;

  /// Defines fill behavior for the parameter.
  ///
  /// Required.
  GoogleCloudDialogflowCxV3FormParameterFillBehavior? fillBehavior;

  /// Indicates whether the parameter represents a list of values.
  core.bool? isList;

  /// Indicates whether the parameter content should be redacted in log.
  ///
  /// If redaction is enabled, the parameter content will be replaced by
  /// parameter name during logging. Note: the parameter content is subject to
  /// redaction if either parameter level redaction or entity type level
  /// redaction is enabled.
  core.bool? redact;

  /// Indicates whether the parameter is required.
  ///
  /// Optional parameters will not trigger prompts; however, they are filled if
  /// the user specifies them. Required parameters must be filled before form
  /// filling concludes.
  core.bool? required;

  GoogleCloudDialogflowCxV3FormParameter();

  GoogleCloudDialogflowCxV3FormParameter.fromJson(core.Map _json) {
    if (_json.containsKey('defaultValue')) {
      defaultValue = _json['defaultValue'] as core.Object;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('entityType')) {
      entityType = _json['entityType'] as core.String;
    }
    if (_json.containsKey('fillBehavior')) {
      fillBehavior =
          GoogleCloudDialogflowCxV3FormParameterFillBehavior.fromJson(
              _json['fillBehavior'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('isList')) {
      isList = _json['isList'] as core.bool;
    }
    if (_json.containsKey('redact')) {
      redact = _json['redact'] as core.bool;
    }
    if (_json.containsKey('required')) {
      required = _json['required'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (defaultValue != null) 'defaultValue': defaultValue!,
        if (displayName != null) 'displayName': displayName!,
        if (entityType != null) 'entityType': entityType!,
        if (fillBehavior != null) 'fillBehavior': fillBehavior!.toJson(),
        if (isList != null) 'isList': isList!,
        if (redact != null) 'redact': redact!,
        if (required != null) 'required': required!,
      };
}

/// Configuration for how the filling of a parameter should be handled.
class GoogleCloudDialogflowCxV3FormParameterFillBehavior {
  /// The fulfillment to provide the initial prompt that the agent can present
  /// to the user in order to fill the parameter.
  ///
  /// Required.
  GoogleCloudDialogflowCxV3Fulfillment? initialPromptFulfillment;

  /// The handlers for parameter-level events, used to provide reprompt for the
  /// parameter or transition to a different page/flow.
  ///
  /// The supported events are: * `sys.no-match-`, where N can be from 1 to 6 *
  /// `sys.no-match-default` * `sys.no-input-`, where N can be from 1 to 6 *
  /// `sys.no-input-default` * `sys.invalid-parameter`
  /// `initial_prompt_fulfillment` provides the first prompt for the parameter.
  /// If the user's response does not fill the parameter, a no-match/no-input
  /// event will be triggered, and the fulfillment associated with the
  /// `sys.no-match-1`/`sys.no-input-1` handler (if defined) will be called to
  /// provide a prompt. The `sys.no-match-2`/`sys.no-input-2` handler (if
  /// defined) will respond to the next no-match/no-input event, and so on. A
  /// `sys.no-match-default` or `sys.no-input-default` handler will be used to
  /// handle all following no-match/no-input events after all numbered
  /// no-match/no-input handlers for the parameter are consumed. A
  /// `sys.invalid-parameter` handler can be defined to handle the case where
  /// the parameter values have been `invalidated` by webhook. For example, if
  /// the user's response fill the parameter, however the parameter was
  /// invalidated by webhook, the fulfillment associated with the
  /// `sys.invalid-parameter` handler (if defined) will be called to provide a
  /// prompt. If the event handler for the corresponding event can't be found on
  /// the parameter, `initial_prompt_fulfillment` will be re-prompted.
  core.List<GoogleCloudDialogflowCxV3EventHandler>? repromptEventHandlers;

  GoogleCloudDialogflowCxV3FormParameterFillBehavior();

  GoogleCloudDialogflowCxV3FormParameterFillBehavior.fromJson(core.Map _json) {
    if (_json.containsKey('initialPromptFulfillment')) {
      initialPromptFulfillment = GoogleCloudDialogflowCxV3Fulfillment.fromJson(
          _json['initialPromptFulfillment']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('repromptEventHandlers')) {
      repromptEventHandlers = (_json['repromptEventHandlers'] as core.List)
          .map<GoogleCloudDialogflowCxV3EventHandler>((value) =>
              GoogleCloudDialogflowCxV3EventHandler.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (initialPromptFulfillment != null)
          'initialPromptFulfillment': initialPromptFulfillment!.toJson(),
        if (repromptEventHandlers != null)
          'repromptEventHandlers':
              repromptEventHandlers!.map((value) => value.toJson()).toList(),
      };
}

/// Request of FulfillIntent
class GoogleCloudDialogflowCxV3FulfillIntentRequest {
  /// The matched intent/event to fulfill.
  GoogleCloudDialogflowCxV3Match? match;

  /// Must be same as the corresponding MatchIntent request, otherwise the
  /// behavior is undefined.
  GoogleCloudDialogflowCxV3MatchIntentRequest? matchIntentRequest;

  /// Instructs the speech synthesizer how to generate output audio.
  GoogleCloudDialogflowCxV3OutputAudioConfig? outputAudioConfig;

  GoogleCloudDialogflowCxV3FulfillIntentRequest();

  GoogleCloudDialogflowCxV3FulfillIntentRequest.fromJson(core.Map _json) {
    if (_json.containsKey('match')) {
      match = GoogleCloudDialogflowCxV3Match.fromJson(
          _json['match'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('matchIntentRequest')) {
      matchIntentRequest = GoogleCloudDialogflowCxV3MatchIntentRequest.fromJson(
          _json['matchIntentRequest'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('outputAudioConfig')) {
      outputAudioConfig = GoogleCloudDialogflowCxV3OutputAudioConfig.fromJson(
          _json['outputAudioConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (match != null) 'match': match!.toJson(),
        if (matchIntentRequest != null)
          'matchIntentRequest': matchIntentRequest!.toJson(),
        if (outputAudioConfig != null)
          'outputAudioConfig': outputAudioConfig!.toJson(),
      };
}

/// Response of FulfillIntent
class GoogleCloudDialogflowCxV3FulfillIntentResponse {
  /// The audio data bytes encoded as specified in the request.
  ///
  /// Note: The output audio is generated based on the values of default
  /// platform text responses found in the `query_result.response_messages`
  /// field. If multiple default text responses exist, they will be concatenated
  /// when generating audio. If no default platform text responses exist, the
  /// generated audio content will be empty. In some scenarios, multiple output
  /// audio fields may be present in the response structure. In these cases,
  /// only the top-most-level audio output has content.
  core.String? outputAudio;
  core.List<core.int> get outputAudioAsBytes =>
      convert.base64.decode(outputAudio!);

  set outputAudioAsBytes(core.List<core.int> _bytes) {
    outputAudio =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The config used by the speech synthesizer to generate the output audio.
  GoogleCloudDialogflowCxV3OutputAudioConfig? outputAudioConfig;

  /// The result of the conversational query.
  GoogleCloudDialogflowCxV3QueryResult? queryResult;

  /// The unique identifier of the response.
  ///
  /// It can be used to locate a response in the training example set or for
  /// reporting issues.
  ///
  /// Output only.
  core.String? responseId;

  GoogleCloudDialogflowCxV3FulfillIntentResponse();

  GoogleCloudDialogflowCxV3FulfillIntentResponse.fromJson(core.Map _json) {
    if (_json.containsKey('outputAudio')) {
      outputAudio = _json['outputAudio'] as core.String;
    }
    if (_json.containsKey('outputAudioConfig')) {
      outputAudioConfig = GoogleCloudDialogflowCxV3OutputAudioConfig.fromJson(
          _json['outputAudioConfig'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('queryResult')) {
      queryResult = GoogleCloudDialogflowCxV3QueryResult.fromJson(
          _json['queryResult'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('responseId')) {
      responseId = _json['responseId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (outputAudio != null) 'outputAudio': outputAudio!,
        if (outputAudioConfig != null)
          'outputAudioConfig': outputAudioConfig!.toJson(),
        if (queryResult != null) 'queryResult': queryResult!.toJson(),
        if (responseId != null) 'responseId': responseId!,
      };
}

/// A fulfillment can do one or more of the following actions at the same time:
/// * Generate rich message responses.
///
/// * Set parameter values. * Call the webhook. Fulfillments can be called at
/// various stages in the Page or Form lifecycle. For example, when a
/// DetectIntentRequest drives a session to enter a new page, the page's entry
/// fulfillment can add a static response to the QueryResult in the returning
/// DetectIntentResponse, call the webhook (for example, to load user data from
/// a database), or both.
class GoogleCloudDialogflowCxV3Fulfillment {
  /// Conditional cases for this fulfillment.
  core.List<GoogleCloudDialogflowCxV3FulfillmentConditionalCases>?
      conditionalCases;

  /// The list of rich message responses to present to the user.
  core.List<GoogleCloudDialogflowCxV3ResponseMessage>? messages;

  /// Set parameter values before executing the webhook.
  core.List<GoogleCloudDialogflowCxV3FulfillmentSetParameterAction>?
      setParameterActions;

  /// The tag used by the webhook to identify which fulfillment is being called.
  ///
  /// This field is required if `webhook` is specified.
  core.String? tag;

  /// The webhook to call.
  ///
  /// Format: `projects//locations//agents//webhooks/`.
  core.String? webhook;

  GoogleCloudDialogflowCxV3Fulfillment();

  GoogleCloudDialogflowCxV3Fulfillment.fromJson(core.Map _json) {
    if (_json.containsKey('conditionalCases')) {
      conditionalCases = (_json['conditionalCases'] as core.List)
          .map<GoogleCloudDialogflowCxV3FulfillmentConditionalCases>((value) =>
              GoogleCloudDialogflowCxV3FulfillmentConditionalCases.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('messages')) {
      messages = (_json['messages'] as core.List)
          .map<GoogleCloudDialogflowCxV3ResponseMessage>((value) =>
              GoogleCloudDialogflowCxV3ResponseMessage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('setParameterActions')) {
      setParameterActions = (_json['setParameterActions'] as core.List)
          .map<GoogleCloudDialogflowCxV3FulfillmentSetParameterAction>(
              (value) => GoogleCloudDialogflowCxV3FulfillmentSetParameterAction
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('tag')) {
      tag = _json['tag'] as core.String;
    }
    if (_json.containsKey('webhook')) {
      webhook = _json['webhook'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conditionalCases != null)
          'conditionalCases':
              conditionalCases!.map((value) => value.toJson()).toList(),
        if (messages != null)
          'messages': messages!.map((value) => value.toJson()).toList(),
        if (setParameterActions != null)
          'setParameterActions':
              setParameterActions!.map((value) => value.toJson()).toList(),
        if (tag != null) 'tag': tag!,
        if (webhook != null) 'webhook': webhook!,
      };
}

/// A list of cascading if-else conditions.
///
/// Cases are mutually exclusive. The first one with a matching condition is
/// selected, all the rest ignored.
class GoogleCloudDialogflowCxV3FulfillmentConditionalCases {
  /// A list of cascading if-else conditions.
  core.List<GoogleCloudDialogflowCxV3FulfillmentConditionalCasesCase>? cases;

  GoogleCloudDialogflowCxV3FulfillmentConditionalCases();

  GoogleCloudDialogflowCxV3FulfillmentConditionalCases.fromJson(
      core.Map _json) {
    if (_json.containsKey('cases')) {
      cases = (_json['cases'] as core.List)
          .map<GoogleCloudDialogflowCxV3FulfillmentConditionalCasesCase>(
              (value) =>
                  GoogleCloudDialogflowCxV3FulfillmentConditionalCasesCase
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cases != null)
          'cases': cases!.map((value) => value.toJson()).toList(),
      };
}

/// Each case has a Boolean condition.
///
/// When it is evaluated to be True, the corresponding messages will be selected
/// and evaluated recursively.
class GoogleCloudDialogflowCxV3FulfillmentConditionalCasesCase {
  /// A list of case content.
  core.List<
          GoogleCloudDialogflowCxV3FulfillmentConditionalCasesCaseCaseContent>?
      caseContent;

  /// The condition to activate and select this case.
  ///
  /// Empty means the condition is always true. The condition is evaluated
  /// against form parameters or session parameters. See the
  /// [conditions reference](https://cloud.google.com/dialogflow/cx/docs/reference/condition).
  core.String? condition;

  GoogleCloudDialogflowCxV3FulfillmentConditionalCasesCase();

  GoogleCloudDialogflowCxV3FulfillmentConditionalCasesCase.fromJson(
      core.Map _json) {
    if (_json.containsKey('caseContent')) {
      caseContent = (_json['caseContent'] as core.List)
          .map<GoogleCloudDialogflowCxV3FulfillmentConditionalCasesCaseCaseContent>(
              (value) =>
                  GoogleCloudDialogflowCxV3FulfillmentConditionalCasesCaseCaseContent
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('condition')) {
      condition = _json['condition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (caseContent != null)
          'caseContent': caseContent!.map((value) => value.toJson()).toList(),
        if (condition != null) 'condition': condition!,
      };
}

/// The list of messages or conditional cases to activate for this case.
class GoogleCloudDialogflowCxV3FulfillmentConditionalCasesCaseCaseContent {
  /// Additional cases to be evaluated.
  GoogleCloudDialogflowCxV3FulfillmentConditionalCases? additionalCases;

  /// Returned message.
  GoogleCloudDialogflowCxV3ResponseMessage? message;

  GoogleCloudDialogflowCxV3FulfillmentConditionalCasesCaseCaseContent();

  GoogleCloudDialogflowCxV3FulfillmentConditionalCasesCaseCaseContent.fromJson(
      core.Map _json) {
    if (_json.containsKey('additionalCases')) {
      additionalCases =
          GoogleCloudDialogflowCxV3FulfillmentConditionalCases.fromJson(
              _json['additionalCases'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('message')) {
      message = GoogleCloudDialogflowCxV3ResponseMessage.fromJson(
          _json['message'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalCases != null)
          'additionalCases': additionalCases!.toJson(),
        if (message != null) 'message': message!.toJson(),
      };
}

/// Setting a parameter value.
class GoogleCloudDialogflowCxV3FulfillmentSetParameterAction {
  /// Display name of the parameter.
  core.String? parameter;

  /// The new value of the parameter.
  ///
  /// A null value clears the parameter.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? value;

  GoogleCloudDialogflowCxV3FulfillmentSetParameterAction();

  GoogleCloudDialogflowCxV3FulfillmentSetParameterAction.fromJson(
      core.Map _json) {
    if (_json.containsKey('parameter')) {
      parameter = _json['parameter'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parameter != null) 'parameter': parameter!,
        if (value != null) 'value': value!,
      };
}

/// Metadata in google::longrunning::Operation for Knowledge operations.
class GoogleCloudDialogflowCxV3GenericKnowledgeOperationMetadata {
  /// The current state of this operation.
  ///
  /// Required. Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : State unspecified.
  /// - "PENDING" : The operation has been created.
  /// - "RUNNING" : The operation is currently running.
  /// - "DONE" : The operation is done, either cancelled or completed.
  core.String? state;

  GoogleCloudDialogflowCxV3GenericKnowledgeOperationMetadata();

  GoogleCloudDialogflowCxV3GenericKnowledgeOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (state != null) 'state': state!,
      };
}

/// Metadata for ImportDocuments operation.
class GoogleCloudDialogflowCxV3ImportDocumentsOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowCxV3GenericKnowledgeOperationMetadata? genericMetadata;

  GoogleCloudDialogflowCxV3ImportDocumentsOperationMetadata();

  GoogleCloudDialogflowCxV3ImportDocumentsOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowCxV3GenericKnowledgeOperationMetadata.fromJson(
              _json['genericMetadata'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// Response message for Documents.ImportDocuments.
class GoogleCloudDialogflowCxV3ImportDocumentsResponse {
  /// Includes details about skipped documents or any other warnings.
  core.List<GoogleRpcStatus>? warnings;

  GoogleCloudDialogflowCxV3ImportDocumentsResponse();

  GoogleCloudDialogflowCxV3ImportDocumentsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('warnings')) {
      warnings = (_json['warnings'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (warnings != null)
          'warnings': warnings!.map((value) => value.toJson()).toList(),
      };
}

/// The request message for Flows.ImportFlow.
class GoogleCloudDialogflowCxV3ImportFlowRequest {
  /// Uncompressed raw byte content for flow.
  core.String? flowContent;
  core.List<core.int> get flowContentAsBytes =>
      convert.base64.decode(flowContent!);

  set flowContentAsBytes(core.List<core.int> _bytes) {
    flowContent =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The [Google Cloud Storage](https://cloud.google.com/storage/docs/) URI to
  /// import flow from.
  ///
  /// The format of this URI must be `gs:///`.
  core.String? flowUri;

  /// Flow import mode.
  ///
  /// If not specified, `KEEP` is assumed.
  /// Possible string values are:
  /// - "IMPORT_OPTION_UNSPECIFIED" : Unspecified. Treated as `KEEP`.
  /// - "KEEP" : Always respect settings in exported flow content. It may cause
  /// a import failure if some settings (e.g. custom NLU) are not supported in
  /// the agent to import into.
  /// - "FALLBACK" : Fallback to default settings if some settings are not
  /// supported in the agent to import into. E.g. Standard NLU will be used if
  /// custom NLU is not available.
  core.String? importOption;

  GoogleCloudDialogflowCxV3ImportFlowRequest();

  GoogleCloudDialogflowCxV3ImportFlowRequest.fromJson(core.Map _json) {
    if (_json.containsKey('flowContent')) {
      flowContent = _json['flowContent'] as core.String;
    }
    if (_json.containsKey('flowUri')) {
      flowUri = _json['flowUri'] as core.String;
    }
    if (_json.containsKey('importOption')) {
      importOption = _json['importOption'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (flowContent != null) 'flowContent': flowContent!,
        if (flowUri != null) 'flowUri': flowUri!,
        if (importOption != null) 'importOption': importOption!,
      };
}

/// The response message for Flows.ImportFlow.
class GoogleCloudDialogflowCxV3ImportFlowResponse {
  /// The unique identifier of the new flow.
  ///
  /// Format: `projects//locations//agents//flows/`.
  core.String? flow;

  GoogleCloudDialogflowCxV3ImportFlowResponse();

  GoogleCloudDialogflowCxV3ImportFlowResponse.fromJson(core.Map _json) {
    if (_json.containsKey('flow')) {
      flow = _json['flow'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (flow != null) 'flow': flow!,
      };
}

/// Metadata returned for the TestCases.ImportTestCases long running operation.
class GoogleCloudDialogflowCxV3ImportTestCasesMetadata {
  /// Errors for failed test cases.
  core.List<GoogleCloudDialogflowCxV3TestCaseError>? errors;

  GoogleCloudDialogflowCxV3ImportTestCasesMetadata();

  GoogleCloudDialogflowCxV3ImportTestCasesMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<GoogleCloudDialogflowCxV3TestCaseError>((value) =>
              GoogleCloudDialogflowCxV3TestCaseError.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
      };
}

/// The request message for TestCases.ImportTestCases.
class GoogleCloudDialogflowCxV3ImportTestCasesRequest {
  /// Uncompressed raw byte content for test cases.
  core.String? content;
  core.List<core.int> get contentAsBytes => convert.base64.decode(content!);

  set contentAsBytes(core.List<core.int> _bytes) {
    content =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The [Google Cloud Storage](https://cloud.google.com/storage/docs/) URI to
  /// import test cases from.
  ///
  /// The format of this URI must be `gs:///`.
  core.String? gcsUri;

  GoogleCloudDialogflowCxV3ImportTestCasesRequest();

  GoogleCloudDialogflowCxV3ImportTestCasesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('gcsUri')) {
      gcsUri = _json['gcsUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!,
        if (gcsUri != null) 'gcsUri': gcsUri!,
      };
}

/// The response message for TestCases.ImportTestCases.
class GoogleCloudDialogflowCxV3ImportTestCasesResponse {
  /// The unique identifiers of the new test cases.
  ///
  /// Format: `projects//locations//agents//testCases/`.
  core.List<core.String>? names;

  GoogleCloudDialogflowCxV3ImportTestCasesResponse();

  GoogleCloudDialogflowCxV3ImportTestCasesResponse.fromJson(core.Map _json) {
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

/// Instructs the speech recognizer on how to process the audio content.
class GoogleCloudDialogflowCxV3InputAudioConfig {
  /// Audio encoding of the audio content to process.
  ///
  /// Required.
  /// Possible string values are:
  /// - "AUDIO_ENCODING_UNSPECIFIED" : Not specified.
  /// - "AUDIO_ENCODING_LINEAR_16" : Uncompressed 16-bit signed little-endian
  /// samples (Linear PCM).
  /// - "AUDIO_ENCODING_FLAC" :
  /// \[`FLAC`\](https://xiph.org/flac/documentation.html) (Free Lossless Audio
  /// Codec) is the recommended encoding because it is lossless (therefore
  /// recognition is not compromised) and requires only about half the bandwidth
  /// of `LINEAR16`. `FLAC` stream encoding supports 16-bit and 24-bit samples,
  /// however, not all fields in `STREAMINFO` are supported.
  /// - "AUDIO_ENCODING_MULAW" : 8-bit samples that compand 14-bit audio samples
  /// using G.711 PCMU/mu-law.
  /// - "AUDIO_ENCODING_AMR" : Adaptive Multi-Rate Narrowband codec.
  /// `sample_rate_hertz` must be 8000.
  /// - "AUDIO_ENCODING_AMR_WB" : Adaptive Multi-Rate Wideband codec.
  /// `sample_rate_hertz` must be 16000.
  /// - "AUDIO_ENCODING_OGG_OPUS" : Opus encoded audio frames in Ogg container
  /// ([OggOpus](https://wiki.xiph.org/OggOpus)). `sample_rate_hertz` must be
  /// 16000.
  /// - "AUDIO_ENCODING_SPEEX_WITH_HEADER_BYTE" : Although the use of lossy
  /// encodings is not recommended, if a very low bitrate encoding is required,
  /// `OGG_OPUS` is highly preferred over Speex encoding. The
  /// [Speex](https://speex.org/) encoding supported by Dialogflow API has a
  /// header byte in each block, as in MIME type
  /// `audio/x-speex-with-header-byte`. It is a variant of the RTP Speex
  /// encoding defined in [RFC 5574](https://tools.ietf.org/html/rfc5574). The
  /// stream is a sequence of blocks, one block per RTP packet. Each block
  /// starts with a byte containing the length of the block, in bytes, followed
  /// by one or more frames of Speex data, padded to an integral number of bytes
  /// (octets) as specified in RFC 5574. In other words, each RTP header is
  /// replaced with a single byte containing the block length. Only Speex
  /// wideband is supported. `sample_rate_hertz` must be 16000.
  core.String? audioEncoding;

  /// If `true`, Dialogflow returns SpeechWordInfo in StreamingRecognitionResult
  /// with information about the recognized speech words, e.g. start and end
  /// time offsets.
  ///
  /// If false or unspecified, Speech doesn't return any word-level information.
  ///
  /// Optional.
  core.bool? enableWordInfo;

  /// Which Speech model to select for the given request.
  ///
  /// Select the model best suited to your domain to get best results. If a
  /// model is not explicitly specified, then we auto-select a model based on
  /// the parameters in the InputAudioConfig. If enhanced speech model is
  /// enabled for the agent and an enhanced version of the specified model for
  /// the language does not exist, then the speech is recognized using the
  /// standard version of the specified model. Refer to
  /// [Cloud Speech API documentation](https://cloud.google.com/speech-to-text/docs/basics#select-model)
  /// for more details.
  ///
  /// Optional.
  core.String? model;

  /// Which variant of the Speech model to use.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "SPEECH_MODEL_VARIANT_UNSPECIFIED" : No model variant specified. In this
  /// case Dialogflow defaults to USE_BEST_AVAILABLE.
  /// - "USE_BEST_AVAILABLE" : Use the best available variant of the Speech
  /// model that the caller is eligible for. Please see the
  /// [Dialogflow docs](https://cloud.google.com/dialogflow/docs/data-logging)
  /// for how to make your project eligible for enhanced models.
  /// - "USE_STANDARD" : Use standard model variant even if an enhanced model is
  /// available. See the
  /// [Cloud Speech documentation](https://cloud.google.com/speech-to-text/docs/enhanced-models)
  /// for details about enhanced models.
  /// - "USE_ENHANCED" : Use an enhanced model variant: * If an enhanced variant
  /// does not exist for the given model and request language, Dialogflow falls
  /// back to the standard variant. The
  /// [Cloud Speech documentation](https://cloud.google.com/speech-to-text/docs/enhanced-models)
  /// describes which models have enhanced variants. * If the API caller isn't
  /// eligible for enhanced models, Dialogflow returns an error. Please see the
  /// [Dialogflow docs](https://cloud.google.com/dialogflow/docs/data-logging)
  /// for how to make your project eligible.
  core.String? modelVariant;

  /// A list of strings containing words and phrases that the speech recognizer
  /// should recognize with higher likelihood.
  ///
  /// See
  /// [the Cloud Speech documentation](https://cloud.google.com/speech-to-text/docs/basics#phrase-hints)
  /// for more details.
  ///
  /// Optional.
  core.List<core.String>? phraseHints;

  /// Sample rate (in Hertz) of the audio content sent in the query.
  ///
  /// Refer to
  /// [Cloud Speech API documentation](https://cloud.google.com/speech-to-text/docs/basics)
  /// for more details.
  core.int? sampleRateHertz;

  /// If `false` (default), recognition does not cease until the client closes
  /// the stream.
  ///
  /// If `true`, the recognizer will detect a single spoken utterance in input
  /// audio. Recognition ceases when it detects the audio's voice has stopped or
  /// paused. In this case, once a detected intent is received, the client
  /// should close the stream and start a new request with a new stream as
  /// needed. Note: This setting is relevant only for streaming methods.
  ///
  /// Optional.
  core.bool? singleUtterance;

  GoogleCloudDialogflowCxV3InputAudioConfig();

  GoogleCloudDialogflowCxV3InputAudioConfig.fromJson(core.Map _json) {
    if (_json.containsKey('audioEncoding')) {
      audioEncoding = _json['audioEncoding'] as core.String;
    }
    if (_json.containsKey('enableWordInfo')) {
      enableWordInfo = _json['enableWordInfo'] as core.bool;
    }
    if (_json.containsKey('model')) {
      model = _json['model'] as core.String;
    }
    if (_json.containsKey('modelVariant')) {
      modelVariant = _json['modelVariant'] as core.String;
    }
    if (_json.containsKey('phraseHints')) {
      phraseHints = (_json['phraseHints'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('sampleRateHertz')) {
      sampleRateHertz = _json['sampleRateHertz'] as core.int;
    }
    if (_json.containsKey('singleUtterance')) {
      singleUtterance = _json['singleUtterance'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audioEncoding != null) 'audioEncoding': audioEncoding!,
        if (enableWordInfo != null) 'enableWordInfo': enableWordInfo!,
        if (model != null) 'model': model!,
        if (modelVariant != null) 'modelVariant': modelVariant!,
        if (phraseHints != null) 'phraseHints': phraseHints!,
        if (sampleRateHertz != null) 'sampleRateHertz': sampleRateHertz!,
        if (singleUtterance != null) 'singleUtterance': singleUtterance!,
      };
}

/// An intent represents a user's intent to interact with a conversational
/// agent.
///
/// You can provide information for the Dialogflow API to use to match user
/// input to an intent by adding training phrases (i.e., examples of user input)
/// to your intent.
class GoogleCloudDialogflowCxV3Intent {
  /// Human readable description for better understanding an intent like its
  /// scope, content, result etc.
  ///
  /// Maximum character limit: 140 characters.
  core.String? description;

  /// The human-readable name of the intent, unique within the agent.
  ///
  /// Required.
  core.String? displayName;

  /// Indicates whether this is a fallback intent.
  ///
  /// Currently only default fallback intent is allowed in the agent, which is
  /// added upon agent creation. Adding training phrases to fallback intent is
  /// useful in the case of requests that are mistakenly matched, since training
  /// phrases assigned to fallback intents act as negative examples that
  /// triggers no-match event.
  core.bool? isFallback;

  /// The key/value metadata to label an intent.
  ///
  /// Labels can contain lowercase letters, digits and the symbols '-' and '_'.
  /// International characters are allowed, including letters from unicase
  /// alphabets. Keys must start with a letter. Keys and values can be no longer
  /// than 63 characters and no more than 128 bytes. Prefix "sys." is reserved
  /// for Dialogflow defined labels. Currently allowed Dialogflow defined labels
  /// include: * sys.head * sys.contextual The above labels do not require
  /// value. "sys.head" means the intent is a head intent. "sys.contextual"
  /// means the intent is a contextual intent.
  core.Map<core.String, core.String>? labels;

  /// The unique identifier of the intent.
  ///
  /// Required for the Intents.UpdateIntent method. Intents.CreateIntent
  /// populates the name automatically. Format:
  /// `projects//locations//agents//intents/`.
  core.String? name;

  /// The collection of parameters associated with the intent.
  core.List<GoogleCloudDialogflowCxV3IntentParameter>? parameters;

  /// The priority of this intent.
  ///
  /// Higher numbers represent higher priorities. - If the supplied value is
  /// unspecified or 0, the service translates the value to 500,000, which
  /// corresponds to the `Normal` priority in the console. - If the supplied
  /// value is negative, the intent is ignored in runtime detect intent
  /// requests.
  core.int? priority;

  /// The collection of training phrases the agent is trained on to identify the
  /// intent.
  core.List<GoogleCloudDialogflowCxV3IntentTrainingPhrase>? trainingPhrases;

  GoogleCloudDialogflowCxV3Intent();

  GoogleCloudDialogflowCxV3Intent.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('isFallback')) {
      isFallback = _json['isFallback'] as core.bool;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<GoogleCloudDialogflowCxV3IntentParameter>((value) =>
              GoogleCloudDialogflowCxV3IntentParameter.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('priority')) {
      priority = _json['priority'] as core.int;
    }
    if (_json.containsKey('trainingPhrases')) {
      trainingPhrases = (_json['trainingPhrases'] as core.List)
          .map<GoogleCloudDialogflowCxV3IntentTrainingPhrase>((value) =>
              GoogleCloudDialogflowCxV3IntentTrainingPhrase.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (isFallback != null) 'isFallback': isFallback!,
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
        if (priority != null) 'priority': priority!,
        if (trainingPhrases != null)
          'trainingPhrases':
              trainingPhrases!.map((value) => value.toJson()).toList(),
      };
}

/// Intent coverage represents the percentage of all possible intents in the
/// agent that are triggered in any of a parent's test cases.
class GoogleCloudDialogflowCxV3IntentCoverage {
  /// The percent of intents in the agent that are covered.
  core.double? coverageScore;

  /// The list of Intents present in the agent
  core.List<GoogleCloudDialogflowCxV3IntentCoverageIntent>? intents;

  GoogleCloudDialogflowCxV3IntentCoverage();

  GoogleCloudDialogflowCxV3IntentCoverage.fromJson(core.Map _json) {
    if (_json.containsKey('coverageScore')) {
      coverageScore = (_json['coverageScore'] as core.num).toDouble();
    }
    if (_json.containsKey('intents')) {
      intents = (_json['intents'] as core.List)
          .map<GoogleCloudDialogflowCxV3IntentCoverageIntent>((value) =>
              GoogleCloudDialogflowCxV3IntentCoverageIntent.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (coverageScore != null) 'coverageScore': coverageScore!,
        if (intents != null)
          'intents': intents!.map((value) => value.toJson()).toList(),
      };
}

/// The agent's intent.
class GoogleCloudDialogflowCxV3IntentCoverageIntent {
  /// Whether or not the intent is covered by at least one of the agent's test
  /// cases.
  core.bool? covered;

  /// The intent full resource name
  core.String? intent;

  GoogleCloudDialogflowCxV3IntentCoverageIntent();

  GoogleCloudDialogflowCxV3IntentCoverageIntent.fromJson(core.Map _json) {
    if (_json.containsKey('covered')) {
      covered = _json['covered'] as core.bool;
    }
    if (_json.containsKey('intent')) {
      intent = _json['intent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (covered != null) 'covered': covered!,
        if (intent != null) 'intent': intent!,
      };
}

/// Represents the intent to trigger programmatically rather than as a result of
/// natural language processing.
class GoogleCloudDialogflowCxV3IntentInput {
  /// The unique identifier of the intent.
  ///
  /// Format: `projects//locations//agents//intents/`.
  ///
  /// Required.
  core.String? intent;

  GoogleCloudDialogflowCxV3IntentInput();

  GoogleCloudDialogflowCxV3IntentInput.fromJson(core.Map _json) {
    if (_json.containsKey('intent')) {
      intent = _json['intent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (intent != null) 'intent': intent!,
      };
}

/// Represents an intent parameter.
class GoogleCloudDialogflowCxV3IntentParameter {
  /// The entity type of the parameter.
  ///
  /// Format: `projects/-/locations/-/agents/-/entityTypes/` for system entity
  /// types (for example,
  /// `projects/-/locations/-/agents/-/entityTypes/sys.date`), or
  /// `projects//locations//agents//entityTypes/` for developer entity types.
  ///
  /// Required.
  core.String? entityType;

  /// The unique identifier of the parameter.
  ///
  /// This field is used by training phrases to annotate their parts.
  ///
  /// Required.
  core.String? id;

  /// Indicates whether the parameter represents a list of values.
  core.bool? isList;

  /// Indicates whether the parameter content should be redacted in log.
  ///
  /// If redaction is enabled, the parameter content will be replaced by
  /// parameter name during logging. Note: the parameter content is subject to
  /// redaction if either parameter level redaction or entity type level
  /// redaction is enabled.
  core.bool? redact;

  GoogleCloudDialogflowCxV3IntentParameter();

  GoogleCloudDialogflowCxV3IntentParameter.fromJson(core.Map _json) {
    if (_json.containsKey('entityType')) {
      entityType = _json['entityType'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('isList')) {
      isList = _json['isList'] as core.bool;
    }
    if (_json.containsKey('redact')) {
      redact = _json['redact'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entityType != null) 'entityType': entityType!,
        if (id != null) 'id': id!,
        if (isList != null) 'isList': isList!,
        if (redact != null) 'redact': redact!,
      };
}

/// Represents an example that the agent is trained on to identify the intent.
class GoogleCloudDialogflowCxV3IntentTrainingPhrase {
  /// The unique identifier of the training phrase.
  ///
  /// Output only.
  core.String? id;

  /// The ordered list of training phrase parts.
  ///
  /// The parts are concatenated in order to form the training phrase. Note: The
  /// API does not automatically annotate training phrases like the Dialogflow
  /// Console does. Note: Do not forget to include whitespace at part
  /// boundaries, so the training phrase is well formatted when the parts are
  /// concatenated. If the training phrase does not need to be annotated with
  /// parameters, you just need a single part with only the Part.text field set.
  /// If you want to annotate the training phrase, you must create multiple
  /// parts, where the fields of each part are populated in one of two ways: -
  /// `Part.text` is set to a part of the phrase that has no parameters. -
  /// `Part.text` is set to a part of the phrase that you want to annotate, and
  /// the `parameter_id` field is set.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowCxV3IntentTrainingPhrasePart>? parts;

  /// Indicates how many times this example was added to the intent.
  core.int? repeatCount;

  GoogleCloudDialogflowCxV3IntentTrainingPhrase();

  GoogleCloudDialogflowCxV3IntentTrainingPhrase.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('parts')) {
      parts = (_json['parts'] as core.List)
          .map<GoogleCloudDialogflowCxV3IntentTrainingPhrasePart>((value) =>
              GoogleCloudDialogflowCxV3IntentTrainingPhrasePart.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('repeatCount')) {
      repeatCount = _json['repeatCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (parts != null)
          'parts': parts!.map((value) => value.toJson()).toList(),
        if (repeatCount != null) 'repeatCount': repeatCount!,
      };
}

/// Represents a part of a training phrase.
class GoogleCloudDialogflowCxV3IntentTrainingPhrasePart {
  /// The parameter used to annotate this part of the training phrase.
  ///
  /// This field is required for annotated parts of the training phrase.
  core.String? parameterId;

  /// The text for this part.
  ///
  /// Required.
  core.String? text;

  GoogleCloudDialogflowCxV3IntentTrainingPhrasePart();

  GoogleCloudDialogflowCxV3IntentTrainingPhrasePart.fromJson(core.Map _json) {
    if (_json.containsKey('parameterId')) {
      parameterId = _json['parameterId'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parameterId != null) 'parameterId': parameterId!,
        if (text != null) 'text': text!,
      };
}

/// The response message for Agents.ListAgents.
class GoogleCloudDialogflowCxV3ListAgentsResponse {
  /// The list of agents.
  ///
  /// There will be a maximum number of items returned based on the page_size
  /// field in the request.
  core.List<GoogleCloudDialogflowCxV3Agent>? agents;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  GoogleCloudDialogflowCxV3ListAgentsResponse();

  GoogleCloudDialogflowCxV3ListAgentsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('agents')) {
      agents = (_json['agents'] as core.List)
          .map<GoogleCloudDialogflowCxV3Agent>((value) =>
              GoogleCloudDialogflowCxV3Agent.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (agents != null)
          'agents': agents!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response message for EntityTypes.ListEntityTypes.
class GoogleCloudDialogflowCxV3ListEntityTypesResponse {
  /// The list of entity types.
  ///
  /// There will be a maximum number of items returned based on the page_size
  /// field in the request.
  core.List<GoogleCloudDialogflowCxV3EntityType>? entityTypes;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  GoogleCloudDialogflowCxV3ListEntityTypesResponse();

  GoogleCloudDialogflowCxV3ListEntityTypesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('entityTypes')) {
      entityTypes = (_json['entityTypes'] as core.List)
          .map<GoogleCloudDialogflowCxV3EntityType>((value) =>
              GoogleCloudDialogflowCxV3EntityType.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entityTypes != null)
          'entityTypes': entityTypes!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response message for Environments.ListEnvironments.
class GoogleCloudDialogflowCxV3ListEnvironmentsResponse {
  /// The list of environments.
  ///
  /// There will be a maximum number of items returned based on the page_size
  /// field in the request. The list may in some cases be empty or contain fewer
  /// entries than page_size even if this isn't the last page.
  core.List<GoogleCloudDialogflowCxV3Environment>? environments;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  GoogleCloudDialogflowCxV3ListEnvironmentsResponse();

  GoogleCloudDialogflowCxV3ListEnvironmentsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('environments')) {
      environments = (_json['environments'] as core.List)
          .map<GoogleCloudDialogflowCxV3Environment>((value) =>
              GoogleCloudDialogflowCxV3Environment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (environments != null)
          'environments': environments!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response message for Experiments.ListExperiments.
class GoogleCloudDialogflowCxV3ListExperimentsResponse {
  /// The list of experiments.
  ///
  /// There will be a maximum number of items returned based on the page_size
  /// field in the request. The list may in some cases be empty or contain fewer
  /// entries than page_size even if this isn't the last page.
  core.List<GoogleCloudDialogflowCxV3Experiment>? experiments;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  GoogleCloudDialogflowCxV3ListExperimentsResponse();

  GoogleCloudDialogflowCxV3ListExperimentsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('experiments')) {
      experiments = (_json['experiments'] as core.List)
          .map<GoogleCloudDialogflowCxV3Experiment>((value) =>
              GoogleCloudDialogflowCxV3Experiment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (experiments != null)
          'experiments': experiments!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response message for Flows.ListFlows.
class GoogleCloudDialogflowCxV3ListFlowsResponse {
  /// The list of flows.
  ///
  /// There will be a maximum number of items returned based on the page_size
  /// field in the request.
  core.List<GoogleCloudDialogflowCxV3Flow>? flows;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  GoogleCloudDialogflowCxV3ListFlowsResponse();

  GoogleCloudDialogflowCxV3ListFlowsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('flows')) {
      flows = (_json['flows'] as core.List)
          .map<GoogleCloudDialogflowCxV3Flow>((value) =>
              GoogleCloudDialogflowCxV3Flow.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (flows != null)
          'flows': flows!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response message for Intents.ListIntents.
class GoogleCloudDialogflowCxV3ListIntentsResponse {
  /// The list of intents.
  ///
  /// There will be a maximum number of items returned based on the page_size
  /// field in the request.
  core.List<GoogleCloudDialogflowCxV3Intent>? intents;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  GoogleCloudDialogflowCxV3ListIntentsResponse();

  GoogleCloudDialogflowCxV3ListIntentsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('intents')) {
      intents = (_json['intents'] as core.List)
          .map<GoogleCloudDialogflowCxV3Intent>((value) =>
              GoogleCloudDialogflowCxV3Intent.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (intents != null)
          'intents': intents!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// The response message for Pages.ListPages.
class GoogleCloudDialogflowCxV3ListPagesResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// The list of pages.
  ///
  /// There will be a maximum number of items returned based on the page_size
  /// field in the request.
  core.List<GoogleCloudDialogflowCxV3Page>? pages;

  GoogleCloudDialogflowCxV3ListPagesResponse();

  GoogleCloudDialogflowCxV3ListPagesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('pages')) {
      pages = (_json['pages'] as core.List)
          .map<GoogleCloudDialogflowCxV3Page>((value) =>
              GoogleCloudDialogflowCxV3Page.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (pages != null)
          'pages': pages!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for SecuritySettings.ListSecuritySettings.
class GoogleCloudDialogflowCxV3ListSecuritySettingsResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// The list of security settings.
  core.List<GoogleCloudDialogflowCxV3SecuritySettings>? securitySettings;

  GoogleCloudDialogflowCxV3ListSecuritySettingsResponse();

  GoogleCloudDialogflowCxV3ListSecuritySettingsResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('securitySettings')) {
      securitySettings = (_json['securitySettings'] as core.List)
          .map<GoogleCloudDialogflowCxV3SecuritySettings>((value) =>
              GoogleCloudDialogflowCxV3SecuritySettings.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (securitySettings != null)
          'securitySettings':
              securitySettings!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for SessionEntityTypes.ListSessionEntityTypes.
class GoogleCloudDialogflowCxV3ListSessionEntityTypesResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// The list of session entity types.
  ///
  /// There will be a maximum number of items returned based on the page_size
  /// field in the request.
  core.List<GoogleCloudDialogflowCxV3SessionEntityType>? sessionEntityTypes;

  GoogleCloudDialogflowCxV3ListSessionEntityTypesResponse();

  GoogleCloudDialogflowCxV3ListSessionEntityTypesResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('sessionEntityTypes')) {
      sessionEntityTypes = (_json['sessionEntityTypes'] as core.List)
          .map<GoogleCloudDialogflowCxV3SessionEntityType>((value) =>
              GoogleCloudDialogflowCxV3SessionEntityType.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (sessionEntityTypes != null)
          'sessionEntityTypes':
              sessionEntityTypes!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for TestCases.ListTestCaseResults.
class GoogleCloudDialogflowCxV3ListTestCaseResultsResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// The list of test case results.
  core.List<GoogleCloudDialogflowCxV3TestCaseResult>? testCaseResults;

  GoogleCloudDialogflowCxV3ListTestCaseResultsResponse();

  GoogleCloudDialogflowCxV3ListTestCaseResultsResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('testCaseResults')) {
      testCaseResults = (_json['testCaseResults'] as core.List)
          .map<GoogleCloudDialogflowCxV3TestCaseResult>((value) =>
              GoogleCloudDialogflowCxV3TestCaseResult.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (testCaseResults != null)
          'testCaseResults':
              testCaseResults!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for TestCases.ListTestCases.
class GoogleCloudDialogflowCxV3ListTestCasesResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// The list of test cases.
  ///
  /// There will be a maximum number of items returned based on the page_size
  /// field in the request.
  core.List<GoogleCloudDialogflowCxV3TestCase>? testCases;

  GoogleCloudDialogflowCxV3ListTestCasesResponse();

  GoogleCloudDialogflowCxV3ListTestCasesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('testCases')) {
      testCases = (_json['testCases'] as core.List)
          .map<GoogleCloudDialogflowCxV3TestCase>((value) =>
              GoogleCloudDialogflowCxV3TestCase.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (testCases != null)
          'testCases': testCases!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for TransitionRouteGroups.ListTransitionRouteGroups.
class GoogleCloudDialogflowCxV3ListTransitionRouteGroupsResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// The list of transition route groups.
  ///
  /// There will be a maximum number of items returned based on the page_size
  /// field in the request. The list may in some cases be empty or contain fewer
  /// entries than page_size even if this isn't the last page.
  core.List<GoogleCloudDialogflowCxV3TransitionRouteGroup>?
      transitionRouteGroups;

  GoogleCloudDialogflowCxV3ListTransitionRouteGroupsResponse();

  GoogleCloudDialogflowCxV3ListTransitionRouteGroupsResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('transitionRouteGroups')) {
      transitionRouteGroups = (_json['transitionRouteGroups'] as core.List)
          .map<GoogleCloudDialogflowCxV3TransitionRouteGroup>((value) =>
              GoogleCloudDialogflowCxV3TransitionRouteGroup.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (transitionRouteGroups != null)
          'transitionRouteGroups':
              transitionRouteGroups!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for Versions.ListVersions.
class GoogleCloudDialogflowCxV3ListVersionsResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// A list of versions.
  ///
  /// There will be a maximum number of items returned based on the page_size
  /// field in the request. The list may in some cases be empty or contain fewer
  /// entries than page_size even if this isn't the last page.
  core.List<GoogleCloudDialogflowCxV3Version>? versions;

  GoogleCloudDialogflowCxV3ListVersionsResponse();

  GoogleCloudDialogflowCxV3ListVersionsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('versions')) {
      versions = (_json['versions'] as core.List)
          .map<GoogleCloudDialogflowCxV3Version>((value) =>
              GoogleCloudDialogflowCxV3Version.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (versions != null)
          'versions': versions!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for Webhooks.ListWebhooks.
class GoogleCloudDialogflowCxV3ListWebhooksResponse {
  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  /// The list of webhooks.
  ///
  /// There will be a maximum number of items returned based on the page_size
  /// field in the request.
  core.List<GoogleCloudDialogflowCxV3Webhook>? webhooks;

  GoogleCloudDialogflowCxV3ListWebhooksResponse();

  GoogleCloudDialogflowCxV3ListWebhooksResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('webhooks')) {
      webhooks = (_json['webhooks'] as core.List)
          .map<GoogleCloudDialogflowCxV3Webhook>((value) =>
              GoogleCloudDialogflowCxV3Webhook.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (webhooks != null)
          'webhooks': webhooks!.map((value) => value.toJson()).toList(),
      };
}

/// The request message for Versions.LoadVersion.
class GoogleCloudDialogflowCxV3LoadVersionRequest {
  /// This field is used to prevent accidental overwrite of other agent
  /// resources, which can potentially impact other flow's behavior.
  ///
  /// If `allow_override_agent_resources` is false, conflicted agent-level
  /// resources will not be overridden (i.e. intents, entities, webhooks).
  core.bool? allowOverrideAgentResources;

  GoogleCloudDialogflowCxV3LoadVersionRequest();

  GoogleCloudDialogflowCxV3LoadVersionRequest.fromJson(core.Map _json) {
    if (_json.containsKey('allowOverrideAgentResources')) {
      allowOverrideAgentResources =
          _json['allowOverrideAgentResources'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowOverrideAgentResources != null)
          'allowOverrideAgentResources': allowOverrideAgentResources!,
      };
}

/// The response message for Environments.LookupEnvironmentHistory.
class GoogleCloudDialogflowCxV3LookupEnvironmentHistoryResponse {
  /// Represents a list of snapshots for an environment.
  ///
  /// Time of the snapshots is stored in `update_time`.
  core.List<GoogleCloudDialogflowCxV3Environment>? environments;

  /// Token to retrieve the next page of results, or empty if there are no more
  /// results in the list.
  core.String? nextPageToken;

  GoogleCloudDialogflowCxV3LookupEnvironmentHistoryResponse();

  GoogleCloudDialogflowCxV3LookupEnvironmentHistoryResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('environments')) {
      environments = (_json['environments'] as core.List)
          .map<GoogleCloudDialogflowCxV3Environment>((value) =>
              GoogleCloudDialogflowCxV3Environment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (environments != null)
          'environments': environments!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Represents one match result of MatchIntent.
class GoogleCloudDialogflowCxV3Match {
  /// The confidence of this match.
  ///
  /// Values range from 0.0 (completely uncertain) to 1.0 (completely certain).
  /// This value is for informational purpose only and is only used to help
  /// match the best intent within the classification threshold. This value may
  /// change for the same end-user expression at any time due to a model
  /// retraining or change in implementation.
  core.double? confidence;

  /// The event that matched the query.
  ///
  /// Only filled for `EVENT` match type.
  core.String? event;

  /// The Intent that matched the query.
  ///
  /// Some, not all fields are filled in this message, including but not limited
  /// to: `name` and `display_name`. Only filled for `INTENT` match type.
  GoogleCloudDialogflowCxV3Intent? intent;

  /// Type of this Match.
  /// Possible string values are:
  /// - "MATCH_TYPE_UNSPECIFIED" : Not specified. Should never be used.
  /// - "INTENT" : The query was matched to an intent.
  /// - "DIRECT_INTENT" : The query directly triggered an intent.
  /// - "PARAMETER_FILLING" : The query was used for parameter filling.
  /// - "NO_MATCH" : No match was found for the query.
  /// - "NO_INPUT" : Indicates an empty query.
  /// - "EVENT" : The query directly triggered an event.
  core.String? matchType;

  /// The collection of parameters extracted from the query.
  ///
  /// Depending on your protocol or client library language, this is a map,
  /// associative array, symbol table, dictionary, or JSON object composed of a
  /// collection of (MapKey, MapValue) pairs: - MapKey type: string - MapKey
  /// value: parameter name - MapValue type: - If parameter's entity type is a
  /// composite entity: map - Else: depending on parameter value type, could be
  /// one of string, number, boolean, null, list or map - MapValue value: - If
  /// parameter's entity type is a composite entity: map from composite entity
  /// property names to property values - Else: parameter value
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? parameters;

  /// Final text input which was matched during MatchIntent.
  ///
  /// This value can be different from original input sent in request because of
  /// spelling correction or other processing.
  core.String? resolvedInput;

  GoogleCloudDialogflowCxV3Match();

  GoogleCloudDialogflowCxV3Match.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('event')) {
      event = _json['event'] as core.String;
    }
    if (_json.containsKey('intent')) {
      intent = GoogleCloudDialogflowCxV3Intent.fromJson(
          _json['intent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('matchType')) {
      matchType = _json['matchType'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters =
          (_json['parameters'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('resolvedInput')) {
      resolvedInput = _json['resolvedInput'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (event != null) 'event': event!,
        if (intent != null) 'intent': intent!.toJson(),
        if (matchType != null) 'matchType': matchType!,
        if (parameters != null) 'parameters': parameters!,
        if (resolvedInput != null) 'resolvedInput': resolvedInput!,
      };
}

/// Request of MatchIntent.
class GoogleCloudDialogflowCxV3MatchIntentRequest {
  /// The input specification.
  ///
  /// Required.
  GoogleCloudDialogflowCxV3QueryInput? queryInput;

  /// The parameters of this query.
  GoogleCloudDialogflowCxV3QueryParameters? queryParams;

  GoogleCloudDialogflowCxV3MatchIntentRequest();

  GoogleCloudDialogflowCxV3MatchIntentRequest.fromJson(core.Map _json) {
    if (_json.containsKey('queryInput')) {
      queryInput = GoogleCloudDialogflowCxV3QueryInput.fromJson(
          _json['queryInput'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('queryParams')) {
      queryParams = GoogleCloudDialogflowCxV3QueryParameters.fromJson(
          _json['queryParams'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (queryInput != null) 'queryInput': queryInput!.toJson(),
        if (queryParams != null) 'queryParams': queryParams!.toJson(),
      };
}

/// Response of MatchIntent.
class GoogleCloudDialogflowCxV3MatchIntentResponse {
  /// The current Page.
  ///
  /// Some, not all fields are filled in this message, including but not limited
  /// to `name` and `display_name`.
  GoogleCloudDialogflowCxV3Page? currentPage;

  /// Match results, if more than one, ordered descendingly by the confidence we
  /// have that the particular intent matches the query.
  core.List<GoogleCloudDialogflowCxV3Match>? matches;

  /// If natural language text was provided as input, this field will contain a
  /// copy of the text.
  core.String? text;

  /// If natural language speech audio was provided as input, this field will
  /// contain the transcript for the audio.
  core.String? transcript;

  /// If an event was provided as input, this field will contain a copy of the
  /// event name.
  core.String? triggerEvent;

  /// If an intent was provided as input, this field will contain a copy of the
  /// intent identifier.
  ///
  /// Format: `projects//locations//agents//intents/`.
  core.String? triggerIntent;

  GoogleCloudDialogflowCxV3MatchIntentResponse();

  GoogleCloudDialogflowCxV3MatchIntentResponse.fromJson(core.Map _json) {
    if (_json.containsKey('currentPage')) {
      currentPage = GoogleCloudDialogflowCxV3Page.fromJson(
          _json['currentPage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('matches')) {
      matches = (_json['matches'] as core.List)
          .map<GoogleCloudDialogflowCxV3Match>((value) =>
              GoogleCloudDialogflowCxV3Match.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
    if (_json.containsKey('transcript')) {
      transcript = _json['transcript'] as core.String;
    }
    if (_json.containsKey('triggerEvent')) {
      triggerEvent = _json['triggerEvent'] as core.String;
    }
    if (_json.containsKey('triggerIntent')) {
      triggerIntent = _json['triggerIntent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentPage != null) 'currentPage': currentPage!.toJson(),
        if (matches != null)
          'matches': matches!.map((value) => value.toJson()).toList(),
        if (text != null) 'text': text!,
        if (transcript != null) 'transcript': transcript!,
        if (triggerEvent != null) 'triggerEvent': triggerEvent!,
        if (triggerIntent != null) 'triggerIntent': triggerIntent!,
      };
}

/// Settings related to NLU.
class GoogleCloudDialogflowCxV3NluSettings {
  /// To filter out false positive results and still get variety in matched
  /// natural language inputs for your agent, you can tune the machine learning
  /// classification threshold.
  ///
  /// If the returned score value is less than the threshold value, then a
  /// no-match event will be triggered. The score values range from 0.0
  /// (completely uncertain) to 1.0 (completely certain). If set to 0.0, the
  /// default of 0.3 is used.
  core.double? classificationThreshold;

  /// Indicates NLU model training mode.
  /// Possible string values are:
  /// - "MODEL_TRAINING_MODE_UNSPECIFIED" : Not specified.
  /// `MODEL_TRAINING_MODE_AUTOMATIC` will be used.
  /// - "MODEL_TRAINING_MODE_AUTOMATIC" : NLU model training is automatically
  /// triggered when a flow gets modified. User can also manually trigger model
  /// training in this mode.
  /// - "MODEL_TRAINING_MODE_MANUAL" : User needs to manually trigger NLU model
  /// training. Best for large flows whose models take long time to train.
  core.String? modelTrainingMode;

  /// Indicates the type of NLU model.
  /// Possible string values are:
  /// - "MODEL_TYPE_UNSPECIFIED" : Not specified. `MODEL_TYPE_STANDARD` will be
  /// used.
  /// - "MODEL_TYPE_STANDARD" : Use standard NLU model.
  /// - "MODEL_TYPE_ADVANCED" : Use advanced NLU model.
  core.String? modelType;

  GoogleCloudDialogflowCxV3NluSettings();

  GoogleCloudDialogflowCxV3NluSettings.fromJson(core.Map _json) {
    if (_json.containsKey('classificationThreshold')) {
      classificationThreshold =
          (_json['classificationThreshold'] as core.num).toDouble();
    }
    if (_json.containsKey('modelTrainingMode')) {
      modelTrainingMode = _json['modelTrainingMode'] as core.String;
    }
    if (_json.containsKey('modelType')) {
      modelType = _json['modelType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (classificationThreshold != null)
          'classificationThreshold': classificationThreshold!,
        if (modelTrainingMode != null) 'modelTrainingMode': modelTrainingMode!,
        if (modelType != null) 'modelType': modelType!,
      };
}

/// Instructs the speech synthesizer how to generate the output audio content.
class GoogleCloudDialogflowCxV3OutputAudioConfig {
  /// Audio encoding of the synthesized audio content.
  ///
  /// Required.
  /// Possible string values are:
  /// - "OUTPUT_AUDIO_ENCODING_UNSPECIFIED" : Not specified.
  /// - "OUTPUT_AUDIO_ENCODING_LINEAR_16" : Uncompressed 16-bit signed
  /// little-endian samples (Linear PCM). Audio content returned as LINEAR16
  /// also contains a WAV header.
  /// - "OUTPUT_AUDIO_ENCODING_MP3" : MP3 audio at 32kbps.
  /// - "OUTPUT_AUDIO_ENCODING_MP3_64_KBPS" : MP3 audio at 64kbps.
  /// - "OUTPUT_AUDIO_ENCODING_OGG_OPUS" : Opus encoded audio wrapped in an ogg
  /// container. The result will be a file which can be played natively on
  /// Android, and in browsers (at least Chrome and Firefox). The quality of the
  /// encoding is considerably higher than MP3 while using approximately the
  /// same bitrate.
  /// - "OUTPUT_AUDIO_ENCODING_MULAW" : 8-bit samples that compand 14-bit audio
  /// samples using G.711 PCMU/mu-law.
  core.String? audioEncoding;

  /// The synthesis sample rate (in hertz) for this audio.
  ///
  /// If not provided, then the synthesizer will use the default sample rate
  /// based on the audio encoding. If this is different from the voice's natural
  /// sample rate, then the synthesizer will honor this request by converting to
  /// the desired sample rate (which might result in worse audio quality).
  ///
  /// Optional.
  core.int? sampleRateHertz;

  /// Configuration of how speech should be synthesized.
  ///
  /// Optional.
  GoogleCloudDialogflowCxV3SynthesizeSpeechConfig? synthesizeSpeechConfig;

  GoogleCloudDialogflowCxV3OutputAudioConfig();

  GoogleCloudDialogflowCxV3OutputAudioConfig.fromJson(core.Map _json) {
    if (_json.containsKey('audioEncoding')) {
      audioEncoding = _json['audioEncoding'] as core.String;
    }
    if (_json.containsKey('sampleRateHertz')) {
      sampleRateHertz = _json['sampleRateHertz'] as core.int;
    }
    if (_json.containsKey('synthesizeSpeechConfig')) {
      synthesizeSpeechConfig =
          GoogleCloudDialogflowCxV3SynthesizeSpeechConfig.fromJson(
              _json['synthesizeSpeechConfig']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audioEncoding != null) 'audioEncoding': audioEncoding!,
        if (sampleRateHertz != null) 'sampleRateHertz': sampleRateHertz!,
        if (synthesizeSpeechConfig != null)
          'synthesizeSpeechConfig': synthesizeSpeechConfig!.toJson(),
      };
}

/// A Dialogflow CX conversation (session) can be described and visualized as a
/// state machine.
///
/// The states of a CX session are represented by pages. For each flow, you
/// define many pages, where your combined pages can handle a complete
/// conversation on the topics the flow is designed for. At any given moment,
/// exactly one page is the current page, the current page is considered active,
/// and the flow associated with that page is considered active. Every flow has
/// a special start page. When a flow initially becomes active, the start page
/// page becomes the current page. For each conversational turn, the current
/// page will either stay the same or transition to another page. You configure
/// each page to collect information from the end-user that is relevant for the
/// conversational state represented by the page. For more information, see the
/// [Page guide](https://cloud.google.com/dialogflow/cx/docs/concept/page).
class GoogleCloudDialogflowCxV3Page {
  /// The human-readable name of the page, unique within the agent.
  ///
  /// Required.
  core.String? displayName;

  /// The fulfillment to call when the session is entering the page.
  GoogleCloudDialogflowCxV3Fulfillment? entryFulfillment;

  /// Handlers associated with the page to handle events such as webhook errors,
  /// no match or no input.
  core.List<GoogleCloudDialogflowCxV3EventHandler>? eventHandlers;

  /// The form associated with the page, used for collecting parameters relevant
  /// to the page.
  GoogleCloudDialogflowCxV3Form? form;

  /// The unique identifier of the page.
  ///
  /// Required for the Pages.UpdatePage method. Pages.CreatePage populates the
  /// name automatically. Format: `projects//locations//agents//flows//pages/`.
  core.String? name;

  /// Ordered list of `TransitionRouteGroups` associated with the page.
  ///
  /// Transition route groups must be unique within a page. * If multiple
  /// transition routes within a page scope refer to the same intent, then the
  /// precedence order is: page's transition route -> page's transition route
  /// group -> flow's transition routes. * If multiple transition route groups
  /// within a page contain the same intent, then the first group in the ordered
  /// list takes precedence.
  /// Format:`projects//locations//agents//flows//transitionRouteGroups/`.
  core.List<core.String>? transitionRouteGroups;

  /// A list of transitions for the transition rules of this page.
  ///
  /// They route the conversation to another page in the same flow, or another
  /// flow. When we are in a certain page, the TransitionRoutes are evalauted in
  /// the following order: * TransitionRoutes defined in the page with intent
  /// specified. * TransitionRoutes defined in the transition route groups with
  /// intent specified. * TransitionRoutes defined in flow with intent
  /// specified. * TransitionRoutes defined in the transition route groups with
  /// intent specified. * TransitionRoutes defined in the page with only
  /// condition specified. * TransitionRoutes defined in the transition route
  /// groups with only condition specified.
  core.List<GoogleCloudDialogflowCxV3TransitionRoute>? transitionRoutes;

  GoogleCloudDialogflowCxV3Page();

  GoogleCloudDialogflowCxV3Page.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('entryFulfillment')) {
      entryFulfillment = GoogleCloudDialogflowCxV3Fulfillment.fromJson(
          _json['entryFulfillment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('eventHandlers')) {
      eventHandlers = (_json['eventHandlers'] as core.List)
          .map<GoogleCloudDialogflowCxV3EventHandler>((value) =>
              GoogleCloudDialogflowCxV3EventHandler.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('form')) {
      form = GoogleCloudDialogflowCxV3Form.fromJson(
          _json['form'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('transitionRouteGroups')) {
      transitionRouteGroups = (_json['transitionRouteGroups'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('transitionRoutes')) {
      transitionRoutes = (_json['transitionRoutes'] as core.List)
          .map<GoogleCloudDialogflowCxV3TransitionRoute>((value) =>
              GoogleCloudDialogflowCxV3TransitionRoute.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (entryFulfillment != null)
          'entryFulfillment': entryFulfillment!.toJson(),
        if (eventHandlers != null)
          'eventHandlers':
              eventHandlers!.map((value) => value.toJson()).toList(),
        if (form != null) 'form': form!.toJson(),
        if (name != null) 'name': name!,
        if (transitionRouteGroups != null)
          'transitionRouteGroups': transitionRouteGroups!,
        if (transitionRoutes != null)
          'transitionRoutes':
              transitionRoutes!.map((value) => value.toJson()).toList(),
      };
}

/// Represents page information communicated to and from the webhook.
class GoogleCloudDialogflowCxV3PageInfo {
  /// Always present for WebhookRequest.
  ///
  /// Ignored for WebhookResponse. The unique identifier of the current page.
  /// Format: `projects//locations//agents//flows//pages/`.
  core.String? currentPage;

  /// Optional for both WebhookRequest and WebhookResponse.
  ///
  /// Information about the form.
  GoogleCloudDialogflowCxV3PageInfoFormInfo? formInfo;

  GoogleCloudDialogflowCxV3PageInfo();

  GoogleCloudDialogflowCxV3PageInfo.fromJson(core.Map _json) {
    if (_json.containsKey('currentPage')) {
      currentPage = _json['currentPage'] as core.String;
    }
    if (_json.containsKey('formInfo')) {
      formInfo = GoogleCloudDialogflowCxV3PageInfoFormInfo.fromJson(
          _json['formInfo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentPage != null) 'currentPage': currentPage!,
        if (formInfo != null) 'formInfo': formInfo!.toJson(),
      };
}

/// Represents form information.
class GoogleCloudDialogflowCxV3PageInfoFormInfo {
  /// Optional for both WebhookRequest and WebhookResponse.
  ///
  /// The parameters contained in the form. Note that the webhook cannot add or
  /// remove any form parameter.
  core.List<GoogleCloudDialogflowCxV3PageInfoFormInfoParameterInfo>?
      parameterInfo;

  GoogleCloudDialogflowCxV3PageInfoFormInfo();

  GoogleCloudDialogflowCxV3PageInfoFormInfo.fromJson(core.Map _json) {
    if (_json.containsKey('parameterInfo')) {
      parameterInfo = (_json['parameterInfo'] as core.List)
          .map<GoogleCloudDialogflowCxV3PageInfoFormInfoParameterInfo>(
              (value) => GoogleCloudDialogflowCxV3PageInfoFormInfoParameterInfo
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parameterInfo != null)
          'parameterInfo':
              parameterInfo!.map((value) => value.toJson()).toList(),
      };
}

/// Represents parameter information.
class GoogleCloudDialogflowCxV3PageInfoFormInfoParameterInfo {
  /// Always present for WebhookRequest.
  ///
  /// Required for WebhookResponse. The human-readable name of the parameter,
  /// unique within the form. This field cannot be modified by the webhook.
  core.String? displayName;

  /// Optional for WebhookRequest.
  ///
  /// Ignored for WebhookResponse. Indicates if the parameter value was just
  /// collected on the last conversation turn.
  core.bool? justCollected;

  /// Optional for both WebhookRequest and WebhookResponse.
  ///
  /// Indicates whether the parameter is required. Optional parameters will not
  /// trigger prompts; however, they are filled if the user specifies them.
  /// Required parameters must be filled before form filling concludes.
  core.bool? required;

  /// Always present for WebhookRequest.
  ///
  /// Required for WebhookResponse. The state of the parameter. This field can
  /// be set to INVALID by the webhook to invalidate the parameter; other values
  /// set by the webhook will be ignored.
  /// Possible string values are:
  /// - "PARAMETER_STATE_UNSPECIFIED" : Not specified. This value should be
  /// never used.
  /// - "EMPTY" : Indicates that the parameter does not have a value.
  /// - "INVALID" : Indicates that the parameter value is invalid. This field
  /// can be used by the webhook to invalidate the parameter and ask the server
  /// to collect it from the user again.
  /// - "FILLED" : Indicates that the parameter has a value.
  core.String? state;

  /// Optional for both WebhookRequest and WebhookResponse.
  ///
  /// The value of the parameter. This field can be set by the webhook to change
  /// the parameter value.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? value;

  GoogleCloudDialogflowCxV3PageInfoFormInfoParameterInfo();

  GoogleCloudDialogflowCxV3PageInfoFormInfoParameterInfo.fromJson(
      core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('justCollected')) {
      justCollected = _json['justCollected'] as core.bool;
    }
    if (_json.containsKey('required')) {
      required = _json['required'] as core.bool;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (justCollected != null) 'justCollected': justCollected!,
        if (required != null) 'required': required!,
        if (state != null) 'state': state!,
        if (value != null) 'value': value!,
      };
}

/// Represents the query input.
///
/// It can contain one of: 1. A conversational query in the form of text. 2. An
/// intent query that specifies which intent to trigger. 3. Natural language
/// speech audio to be processed. 4. An event to be triggered.
class GoogleCloudDialogflowCxV3QueryInput {
  /// The natural language speech audio to be processed.
  GoogleCloudDialogflowCxV3AudioInput? audio;

  /// The DTMF event to be handled.
  GoogleCloudDialogflowCxV3DtmfInput? dtmf;

  /// The event to be triggered.
  GoogleCloudDialogflowCxV3EventInput? event;

  /// The intent to be triggered.
  GoogleCloudDialogflowCxV3IntentInput? intent;

  /// The language of the input.
  ///
  /// See
  /// [Language Support](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// for a list of the currently supported language codes. Note that queries in
  /// the same session do not necessarily need to specify the same language.
  ///
  /// Required.
  core.String? languageCode;

  /// The natural language text to be processed.
  GoogleCloudDialogflowCxV3TextInput? text;

  GoogleCloudDialogflowCxV3QueryInput();

  GoogleCloudDialogflowCxV3QueryInput.fromJson(core.Map _json) {
    if (_json.containsKey('audio')) {
      audio = GoogleCloudDialogflowCxV3AudioInput.fromJson(
          _json['audio'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dtmf')) {
      dtmf = GoogleCloudDialogflowCxV3DtmfInput.fromJson(
          _json['dtmf'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('event')) {
      event = GoogleCloudDialogflowCxV3EventInput.fromJson(
          _json['event'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('intent')) {
      intent = GoogleCloudDialogflowCxV3IntentInput.fromJson(
          _json['intent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = GoogleCloudDialogflowCxV3TextInput.fromJson(
          _json['text'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audio != null) 'audio': audio!.toJson(),
        if (dtmf != null) 'dtmf': dtmf!.toJson(),
        if (event != null) 'event': event!.toJson(),
        if (intent != null) 'intent': intent!.toJson(),
        if (languageCode != null) 'languageCode': languageCode!,
        if (text != null) 'text': text!.toJson(),
      };
}

/// Represents the parameters of a conversational query.
class GoogleCloudDialogflowCxV3QueryParameters {
  /// Configures whether sentiment analysis should be performed.
  ///
  /// If not provided, sentiment analysis is not performed.
  core.bool? analyzeQueryTextSentiment;

  /// The unique identifier of the page to override the current page in the
  /// session.
  ///
  /// Format: `projects//locations//agents//pages/`. If `current_page` is
  /// specified, the previous state of the session will be ignored by
  /// Dialogflow, including the previous page and the previous session
  /// parameters. In most cases, current_page and parameters should be
  /// configured together to direct a session to a specific state.
  core.String? currentPage;

  /// Whether to disable webhook calls for this request.
  core.bool? disableWebhook;

  /// The geo location of this conversational query.
  GoogleTypeLatLng? geoLocation;

  /// Additional parameters to be put into session parameters.
  ///
  /// To remove a parameter from the session, clients should explicitly set the
  /// parameter value to null. You can reference the session parameters in the
  /// agent with the following format: $session.params.parameter-id. Depending
  /// on your protocol or client library language, this is a map, associative
  /// array, symbol table, dictionary, or JSON object composed of a collection
  /// of (MapKey, MapValue) pairs: - MapKey type: string - MapKey value:
  /// parameter name - MapValue type: - If parameter's entity type is a
  /// composite entity: map - Else: depending on parameter value type, could be
  /// one of string, number, boolean, null, list or map - MapValue value: - If
  /// parameter's entity type is a composite entity: map from composite entity
  /// property names to property values - Else: parameter value
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? parameters;

  /// This field can be used to pass custom data into the webhook associated
  /// with the agent.
  ///
  /// Arbitrary JSON objects are supported. Some integrations that query a
  /// Dialogflow agent may provide additional information in the payload. In
  /// particular, for the Dialogflow Phone Gateway integration, this field has
  /// the form: ``` { "telephony": { "caller_id": "+18558363987" } } ```
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? payload;

  /// Additional session entity types to replace or extend developer entity
  /// types with.
  ///
  /// The entity synonyms apply to all languages and persist for the session of
  /// this query.
  core.List<GoogleCloudDialogflowCxV3SessionEntityType>? sessionEntityTypes;

  /// The time zone of this conversational query from the
  /// [time zone database](https://www.iana.org/time-zones), e.g.,
  /// America/New_York, Europe/Paris.
  ///
  /// If not provided, the time zone specified in the agent is used.
  core.String? timeZone;

  /// This field can be used to pass HTTP headers for a webhook call.
  ///
  /// These headers will be sent to webhook along with the headers that have
  /// been configured through Dialogflow web console. The headers defined within
  /// this field will overwrite the headers configured through Dialogflow
  /// console if there is a conflict. Header names are case-insensitive.
  /// Google's specified headers are not allowed. Including: "Host",
  /// "Content-Length", "Connection", "From", "User-Agent", "Accept-Encoding",
  /// "If-Modified-Since", "If-None-Match", "X-Forwarded-For", etc.
  core.Map<core.String, core.String>? webhookHeaders;

  GoogleCloudDialogflowCxV3QueryParameters();

  GoogleCloudDialogflowCxV3QueryParameters.fromJson(core.Map _json) {
    if (_json.containsKey('analyzeQueryTextSentiment')) {
      analyzeQueryTextSentiment =
          _json['analyzeQueryTextSentiment'] as core.bool;
    }
    if (_json.containsKey('currentPage')) {
      currentPage = _json['currentPage'] as core.String;
    }
    if (_json.containsKey('disableWebhook')) {
      disableWebhook = _json['disableWebhook'] as core.bool;
    }
    if (_json.containsKey('geoLocation')) {
      geoLocation = GoogleTypeLatLng.fromJson(
          _json['geoLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('parameters')) {
      parameters =
          (_json['parameters'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('payload')) {
      payload = (_json['payload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('sessionEntityTypes')) {
      sessionEntityTypes = (_json['sessionEntityTypes'] as core.List)
          .map<GoogleCloudDialogflowCxV3SessionEntityType>((value) =>
              GoogleCloudDialogflowCxV3SessionEntityType.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('timeZone')) {
      timeZone = _json['timeZone'] as core.String;
    }
    if (_json.containsKey('webhookHeaders')) {
      webhookHeaders =
          (_json['webhookHeaders'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (analyzeQueryTextSentiment != null)
          'analyzeQueryTextSentiment': analyzeQueryTextSentiment!,
        if (currentPage != null) 'currentPage': currentPage!,
        if (disableWebhook != null) 'disableWebhook': disableWebhook!,
        if (geoLocation != null) 'geoLocation': geoLocation!.toJson(),
        if (parameters != null) 'parameters': parameters!,
        if (payload != null) 'payload': payload!,
        if (sessionEntityTypes != null)
          'sessionEntityTypes':
              sessionEntityTypes!.map((value) => value.toJson()).toList(),
        if (timeZone != null) 'timeZone': timeZone!,
        if (webhookHeaders != null) 'webhookHeaders': webhookHeaders!,
      };
}

/// Represents the result of a conversational query.
class GoogleCloudDialogflowCxV3QueryResult {
  /// The current Page.
  ///
  /// Some, not all fields are filled in this message, including but not limited
  /// to `name` and `display_name`.
  GoogleCloudDialogflowCxV3Page? currentPage;

  /// The free-form diagnostic info.
  ///
  /// For example, this field could contain webhook call latency. The string
  /// keys of the Struct's fields map can change without notice.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? diagnosticInfo;

  /// The Intent that matched the conversational query.
  ///
  /// Some, not all fields are filled in this message, including but not limited
  /// to: `name` and `display_name`. This field is deprecated, please use
  /// QueryResult.match instead.
  GoogleCloudDialogflowCxV3Intent? intent;

  /// The intent detection confidence.
  ///
  /// Values range from 0.0 (completely uncertain) to 1.0 (completely certain).
  /// This value is for informational purpose only and is only used to help
  /// match the best intent within the classification threshold. This value may
  /// change for the same end-user expression at any time due to a model
  /// retraining or change in implementation. This field is deprecated, please
  /// use QueryResult.match instead.
  core.double? intentDetectionConfidence;

  /// The language that was triggered during intent detection.
  ///
  /// See
  /// [Language Support](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// for a list of the currently supported language codes.
  core.String? languageCode;

  /// Intent match result, could be an intent or an event.
  GoogleCloudDialogflowCxV3Match? match;

  /// The collected session parameters.
  ///
  /// Depending on your protocol or client library language, this is a map,
  /// associative array, symbol table, dictionary, or JSON object composed of a
  /// collection of (MapKey, MapValue) pairs: - MapKey type: string - MapKey
  /// value: parameter name - MapValue type: - If parameter's entity type is a
  /// composite entity: map - Else: depending on parameter value type, could be
  /// one of string, number, boolean, null, list or map - MapValue value: - If
  /// parameter's entity type is a composite entity: map from composite entity
  /// property names to property values - Else: parameter value
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? parameters;

  /// The list of rich messages returned to the client.
  ///
  /// Responses vary from simple text messages to more sophisticated, structured
  /// payloads used to drive complex logic.
  core.List<GoogleCloudDialogflowCxV3ResponseMessage>? responseMessages;

  /// The sentiment analyss result, which depends on
  /// `analyze_query_text_sentiment`, specified in the request.
  GoogleCloudDialogflowCxV3SentimentAnalysisResult? sentimentAnalysisResult;

  /// If natural language text was provided as input, this field will contain a
  /// copy of the text.
  core.String? text;

  /// If natural language speech audio was provided as input, this field will
  /// contain the transcript for the audio.
  core.String? transcript;

  /// If an event was provided as input, this field will contain the name of the
  /// event.
  core.String? triggerEvent;

  /// If an intent was provided as input, this field will contain a copy of the
  /// intent identifier.
  ///
  /// Format: `projects//locations//agents//intents/`.
  core.String? triggerIntent;

  /// The list of webhook payload in WebhookResponse.payload, in the order of
  /// call sequence.
  ///
  /// If some webhook call fails or doesn't return any payload, an empty
  /// `Struct` would be used instead.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Map<core.String, core.Object>>? webhookPayloads;

  /// The list of webhook call status in the order of call sequence.
  core.List<GoogleRpcStatus>? webhookStatuses;

  GoogleCloudDialogflowCxV3QueryResult();

  GoogleCloudDialogflowCxV3QueryResult.fromJson(core.Map _json) {
    if (_json.containsKey('currentPage')) {
      currentPage = GoogleCloudDialogflowCxV3Page.fromJson(
          _json['currentPage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('diagnosticInfo')) {
      diagnosticInfo =
          (_json['diagnosticInfo'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('intent')) {
      intent = GoogleCloudDialogflowCxV3Intent.fromJson(
          _json['intent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('intentDetectionConfidence')) {
      intentDetectionConfidence =
          (_json['intentDetectionConfidence'] as core.num).toDouble();
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('match')) {
      match = GoogleCloudDialogflowCxV3Match.fromJson(
          _json['match'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('parameters')) {
      parameters =
          (_json['parameters'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('responseMessages')) {
      responseMessages = (_json['responseMessages'] as core.List)
          .map<GoogleCloudDialogflowCxV3ResponseMessage>((value) =>
              GoogleCloudDialogflowCxV3ResponseMessage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('sentimentAnalysisResult')) {
      sentimentAnalysisResult =
          GoogleCloudDialogflowCxV3SentimentAnalysisResult.fromJson(
              _json['sentimentAnalysisResult']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
    if (_json.containsKey('transcript')) {
      transcript = _json['transcript'] as core.String;
    }
    if (_json.containsKey('triggerEvent')) {
      triggerEvent = _json['triggerEvent'] as core.String;
    }
    if (_json.containsKey('triggerIntent')) {
      triggerIntent = _json['triggerIntent'] as core.String;
    }
    if (_json.containsKey('webhookPayloads')) {
      webhookPayloads = (_json['webhookPayloads'] as core.List)
          .map<core.Map<core.String, core.Object>>(
              (value) => (value as core.Map<core.String, core.dynamic>).map(
                    (key, item) => core.MapEntry(
                      key,
                      item as core.Object,
                    ),
                  ))
          .toList();
    }
    if (_json.containsKey('webhookStatuses')) {
      webhookStatuses = (_json['webhookStatuses'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentPage != null) 'currentPage': currentPage!.toJson(),
        if (diagnosticInfo != null) 'diagnosticInfo': diagnosticInfo!,
        if (intent != null) 'intent': intent!.toJson(),
        if (intentDetectionConfidence != null)
          'intentDetectionConfidence': intentDetectionConfidence!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (match != null) 'match': match!.toJson(),
        if (parameters != null) 'parameters': parameters!,
        if (responseMessages != null)
          'responseMessages':
              responseMessages!.map((value) => value.toJson()).toList(),
        if (sentimentAnalysisResult != null)
          'sentimentAnalysisResult': sentimentAnalysisResult!.toJson(),
        if (text != null) 'text': text!,
        if (transcript != null) 'transcript': transcript!,
        if (triggerEvent != null) 'triggerEvent': triggerEvent!,
        if (triggerIntent != null) 'triggerIntent': triggerIntent!,
        if (webhookPayloads != null) 'webhookPayloads': webhookPayloads!,
        if (webhookStatuses != null)
          'webhookStatuses':
              webhookStatuses!.map((value) => value.toJson()).toList(),
      };
}

/// Metadata for ReloadDocument operation.
class GoogleCloudDialogflowCxV3ReloadDocumentOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowCxV3GenericKnowledgeOperationMetadata? genericMetadata;

  GoogleCloudDialogflowCxV3ReloadDocumentOperationMetadata();

  GoogleCloudDialogflowCxV3ReloadDocumentOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowCxV3GenericKnowledgeOperationMetadata.fromJson(
              _json['genericMetadata'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// Resource name and display name.
class GoogleCloudDialogflowCxV3ResourceName {
  /// Display name.
  core.String? displayName;

  /// Name.
  core.String? name;

  GoogleCloudDialogflowCxV3ResourceName();

  GoogleCloudDialogflowCxV3ResourceName.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (name != null) 'name': name!,
      };
}

/// Represents a response message that can be returned by a conversational
/// agent.
///
/// Response messages are also used for output audio synthesis. The approach is
/// as follows: * If at least one OutputAudioText response is present, then all
/// OutputAudioText responses are linearly concatenated, and the result is used
/// for output audio synthesis. * If the OutputAudioText responses are a mixture
/// of text and SSML, then the concatenated result is treated as SSML;
/// otherwise, the result is treated as either text or SSML as appropriate. The
/// agent designer should ideally use either text or SSML consistently
/// throughout the bot design. * Otherwise, all Text responses are linearly
/// concatenated, and the result is used for output audio synthesis. This
/// approach allows for more sophisticated user experience scenarios, where the
/// text displayed to the user may differ from what is heard.
class GoogleCloudDialogflowCxV3ResponseMessage {
  /// Indicates that the conversation succeeded.
  GoogleCloudDialogflowCxV3ResponseMessageConversationSuccess?
      conversationSuccess;

  /// A signal that indicates the interaction with the Dialogflow agent has
  /// ended.
  ///
  /// This message is generated by Dialogflow only when the conversation reaches
  /// `END_SESSION` page. It is not supposed to be defined by the user. It's
  /// guaranteed that there is at most one such message in each response.
  ///
  /// Output only.
  GoogleCloudDialogflowCxV3ResponseMessageEndInteraction? endInteraction;

  /// Hands off conversation to a human agent.
  GoogleCloudDialogflowCxV3ResponseMessageLiveAgentHandoff? liveAgentHandoff;

  /// An audio response message composed of both the synthesized Dialogflow
  /// agent responses and responses defined via play_audio.
  ///
  /// This message is generated by Dialogflow only and not supposed to be
  /// defined by the user.
  ///
  /// Output only.
  GoogleCloudDialogflowCxV3ResponseMessageMixedAudio? mixedAudio;

  /// A text or ssml response that is preferentially used for TTS output audio
  /// synthesis, as described in the comment on the ResponseMessage message.
  GoogleCloudDialogflowCxV3ResponseMessageOutputAudioText? outputAudioText;

  /// Returns a response containing a custom, platform-specific payload.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? payload;

  /// Signal that the client should play an audio clip hosted at a
  /// client-specific URI.
  ///
  /// Dialogflow uses this to construct mixed_audio. However, Dialogflow itself
  /// does not try to read or process the URI in any way.
  GoogleCloudDialogflowCxV3ResponseMessagePlayAudio? playAudio;

  /// Returns a text response.
  GoogleCloudDialogflowCxV3ResponseMessageText? text;

  GoogleCloudDialogflowCxV3ResponseMessage();

  GoogleCloudDialogflowCxV3ResponseMessage.fromJson(core.Map _json) {
    if (_json.containsKey('conversationSuccess')) {
      conversationSuccess =
          GoogleCloudDialogflowCxV3ResponseMessageConversationSuccess.fromJson(
              _json['conversationSuccess']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('endInteraction')) {
      endInteraction =
          GoogleCloudDialogflowCxV3ResponseMessageEndInteraction.fromJson(
              _json['endInteraction'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('liveAgentHandoff')) {
      liveAgentHandoff =
          GoogleCloudDialogflowCxV3ResponseMessageLiveAgentHandoff.fromJson(
              _json['liveAgentHandoff'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mixedAudio')) {
      mixedAudio = GoogleCloudDialogflowCxV3ResponseMessageMixedAudio.fromJson(
          _json['mixedAudio'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('outputAudioText')) {
      outputAudioText =
          GoogleCloudDialogflowCxV3ResponseMessageOutputAudioText.fromJson(
              _json['outputAudioText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('payload')) {
      payload = (_json['payload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('playAudio')) {
      playAudio = GoogleCloudDialogflowCxV3ResponseMessagePlayAudio.fromJson(
          _json['playAudio'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = GoogleCloudDialogflowCxV3ResponseMessageText.fromJson(
          _json['text'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conversationSuccess != null)
          'conversationSuccess': conversationSuccess!.toJson(),
        if (endInteraction != null) 'endInteraction': endInteraction!.toJson(),
        if (liveAgentHandoff != null)
          'liveAgentHandoff': liveAgentHandoff!.toJson(),
        if (mixedAudio != null) 'mixedAudio': mixedAudio!.toJson(),
        if (outputAudioText != null)
          'outputAudioText': outputAudioText!.toJson(),
        if (payload != null) 'payload': payload!,
        if (playAudio != null) 'playAudio': playAudio!.toJson(),
        if (text != null) 'text': text!.toJson(),
      };
}

/// Indicates that the conversation succeeded, i.e., the bot handled the issue
/// that the customer talked to it about.
///
/// Dialogflow only uses this to determine which conversations should be counted
/// as successful and doesn't process the metadata in this message in any way.
/// Note that Dialogflow also considers conversations that get to the
/// conversation end page as successful even if they don't return
/// ConversationSuccess. You may set this, for example: * In the
/// entry_fulfillment of a Page if entering the page indicates that the
/// conversation succeeded. * In a webhook response when you determine that you
/// handled the customer issue.
class GoogleCloudDialogflowCxV3ResponseMessageConversationSuccess {
  /// Custom metadata.
  ///
  /// Dialogflow doesn't impose any structure on this.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  GoogleCloudDialogflowCxV3ResponseMessageConversationSuccess();

  GoogleCloudDialogflowCxV3ResponseMessageConversationSuccess.fromJson(
      core.Map _json) {
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (metadata != null) 'metadata': metadata!,
      };
}

/// Indicates that interaction with the Dialogflow agent has ended.
///
/// This message is generated by Dialogflow only and not supposed to be defined
/// by the user.
class GoogleCloudDialogflowCxV3ResponseMessageEndInteraction {
  GoogleCloudDialogflowCxV3ResponseMessageEndInteraction();

  GoogleCloudDialogflowCxV3ResponseMessageEndInteraction.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Indicates that the conversation should be handed off to a live agent.
///
/// Dialogflow only uses this to determine which conversations were handed off
/// to a human agent for measurement purposes. What else to do with this signal
/// is up to you and your handoff procedures. You may set this, for example: *
/// In the entry_fulfillment of a Page if entering the page indicates something
/// went extremely wrong in the conversation. * In a webhook response when you
/// determine that the customer issue can only be handled by a human.
class GoogleCloudDialogflowCxV3ResponseMessageLiveAgentHandoff {
  /// Custom metadata for your handoff procedure.
  ///
  /// Dialogflow doesn't impose any structure on this.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  GoogleCloudDialogflowCxV3ResponseMessageLiveAgentHandoff();

  GoogleCloudDialogflowCxV3ResponseMessageLiveAgentHandoff.fromJson(
      core.Map _json) {
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (metadata != null) 'metadata': metadata!,
      };
}

/// Represents an audio message that is composed of both segments synthesized
/// from the Dialogflow agent prompts and ones hosted externally at the
/// specified URIs.
///
/// The external URIs are specified via play_audio. This message is generated by
/// Dialogflow only and not supposed to be defined by the user.
class GoogleCloudDialogflowCxV3ResponseMessageMixedAudio {
  /// Segments this audio response is composed of.
  core.List<GoogleCloudDialogflowCxV3ResponseMessageMixedAudioSegment>?
      segments;

  GoogleCloudDialogflowCxV3ResponseMessageMixedAudio();

  GoogleCloudDialogflowCxV3ResponseMessageMixedAudio.fromJson(core.Map _json) {
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudDialogflowCxV3ResponseMessageMixedAudioSegment>(
              (value) =>
                  GoogleCloudDialogflowCxV3ResponseMessageMixedAudioSegment
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
      };
}

/// Represents one segment of audio.
class GoogleCloudDialogflowCxV3ResponseMessageMixedAudioSegment {
  /// Whether the playback of this segment can be interrupted by the end user's
  /// speech and the client should then start the next Dialogflow request.
  ///
  /// Output only.
  core.bool? allowPlaybackInterruption;

  /// Raw audio synthesized from the Dialogflow agent's response using the
  /// output config specified in the request.
  core.String? audio;
  core.List<core.int> get audioAsBytes => convert.base64.decode(audio!);

  set audioAsBytes(core.List<core.int> _bytes) {
    audio =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Client-specific URI that points to an audio clip accessible to the client.
  ///
  /// Dialogflow does not impose any validation on it.
  core.String? uri;

  GoogleCloudDialogflowCxV3ResponseMessageMixedAudioSegment();

  GoogleCloudDialogflowCxV3ResponseMessageMixedAudioSegment.fromJson(
      core.Map _json) {
    if (_json.containsKey('allowPlaybackInterruption')) {
      allowPlaybackInterruption =
          _json['allowPlaybackInterruption'] as core.bool;
    }
    if (_json.containsKey('audio')) {
      audio = _json['audio'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowPlaybackInterruption != null)
          'allowPlaybackInterruption': allowPlaybackInterruption!,
        if (audio != null) 'audio': audio!,
        if (uri != null) 'uri': uri!,
      };
}

/// A text or ssml response that is preferentially used for TTS output audio
/// synthesis, as described in the comment on the ResponseMessage message.
class GoogleCloudDialogflowCxV3ResponseMessageOutputAudioText {
  /// Whether the playback of this message can be interrupted by the end user's
  /// speech and the client can then starts the next Dialogflow request.
  ///
  /// Output only.
  core.bool? allowPlaybackInterruption;

  /// The SSML text to be synthesized.
  ///
  /// For more information, see \[SSML\](/speech/text-to-speech/docs/ssml).
  core.String? ssml;

  /// The raw text to be synthesized.
  core.String? text;

  GoogleCloudDialogflowCxV3ResponseMessageOutputAudioText();

  GoogleCloudDialogflowCxV3ResponseMessageOutputAudioText.fromJson(
      core.Map _json) {
    if (_json.containsKey('allowPlaybackInterruption')) {
      allowPlaybackInterruption =
          _json['allowPlaybackInterruption'] as core.bool;
    }
    if (_json.containsKey('ssml')) {
      ssml = _json['ssml'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowPlaybackInterruption != null)
          'allowPlaybackInterruption': allowPlaybackInterruption!,
        if (ssml != null) 'ssml': ssml!,
        if (text != null) 'text': text!,
      };
}

/// Specifies an audio clip to be played by the client as part of the response.
class GoogleCloudDialogflowCxV3ResponseMessagePlayAudio {
  /// Whether the playback of this message can be interrupted by the end user's
  /// speech and the client can then starts the next Dialogflow request.
  ///
  /// Output only.
  core.bool? allowPlaybackInterruption;

  /// URI of the audio clip.
  ///
  /// Dialogflow does not impose any validation on this value. It is specific to
  /// the client that reads it.
  ///
  /// Required.
  core.String? audioUri;

  GoogleCloudDialogflowCxV3ResponseMessagePlayAudio();

  GoogleCloudDialogflowCxV3ResponseMessagePlayAudio.fromJson(core.Map _json) {
    if (_json.containsKey('allowPlaybackInterruption')) {
      allowPlaybackInterruption =
          _json['allowPlaybackInterruption'] as core.bool;
    }
    if (_json.containsKey('audioUri')) {
      audioUri = _json['audioUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowPlaybackInterruption != null)
          'allowPlaybackInterruption': allowPlaybackInterruption!,
        if (audioUri != null) 'audioUri': audioUri!,
      };
}

/// The text response message.
class GoogleCloudDialogflowCxV3ResponseMessageText {
  /// Whether the playback of this message can be interrupted by the end user's
  /// speech and the client can then starts the next Dialogflow request.
  ///
  /// Output only.
  core.bool? allowPlaybackInterruption;

  /// A collection of text responses.
  ///
  /// Required.
  core.List<core.String>? text;

  GoogleCloudDialogflowCxV3ResponseMessageText();

  GoogleCloudDialogflowCxV3ResponseMessageText.fromJson(core.Map _json) {
    if (_json.containsKey('allowPlaybackInterruption')) {
      allowPlaybackInterruption =
          _json['allowPlaybackInterruption'] as core.bool;
    }
    if (_json.containsKey('text')) {
      text = (_json['text'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowPlaybackInterruption != null)
          'allowPlaybackInterruption': allowPlaybackInterruption!,
        if (text != null) 'text': text!,
      };
}

/// The request message for Agents.RestoreAgent.
class GoogleCloudDialogflowCxV3RestoreAgentRequest {
  /// Uncompressed raw byte content for agent.
  core.String? agentContent;
  core.List<core.int> get agentContentAsBytes =>
      convert.base64.decode(agentContent!);

  set agentContentAsBytes(core.List<core.int> _bytes) {
    agentContent =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The [Google Cloud Storage](https://cloud.google.com/storage/docs/) URI to
  /// restore agent from.
  ///
  /// The format of this URI must be `gs:///`.
  core.String? agentUri;

  /// Agent restore mode.
  ///
  /// If not specified, `KEEP` is assumed.
  /// Possible string values are:
  /// - "RESTORE_OPTION_UNSPECIFIED" : Unspecified. Treated as KEEP.
  /// - "KEEP" : Always respect the settings from the exported agent file. It
  /// may cause a restoration failure if some settings (e.g. model type) are not
  /// supported in the target agent.
  /// - "FALLBACK" : Fallback to default settings if some settings are not
  /// supported in the target agent.
  core.String? restoreOption;

  GoogleCloudDialogflowCxV3RestoreAgentRequest();

  GoogleCloudDialogflowCxV3RestoreAgentRequest.fromJson(core.Map _json) {
    if (_json.containsKey('agentContent')) {
      agentContent = _json['agentContent'] as core.String;
    }
    if (_json.containsKey('agentUri')) {
      agentUri = _json['agentUri'] as core.String;
    }
    if (_json.containsKey('restoreOption')) {
      restoreOption = _json['restoreOption'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (agentContent != null) 'agentContent': agentContent!,
        if (agentUri != null) 'agentUri': agentUri!,
        if (restoreOption != null) 'restoreOption': restoreOption!,
      };
}

/// Metadata returned for the TestCases.RunTestCase long running operation.
class GoogleCloudDialogflowCxV3RunTestCaseMetadata {
  GoogleCloudDialogflowCxV3RunTestCaseMetadata();

  GoogleCloudDialogflowCxV3RunTestCaseMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The request message for TestCases.RunTestCase.
class GoogleCloudDialogflowCxV3RunTestCaseRequest {
  /// Environment name.
  ///
  /// If not set, draft environment is assumed. Format:
  /// `projects//locations//agents//environments/`.
  ///
  /// Optional.
  core.String? environment;

  GoogleCloudDialogflowCxV3RunTestCaseRequest();

  GoogleCloudDialogflowCxV3RunTestCaseRequest.fromJson(core.Map _json) {
    if (_json.containsKey('environment')) {
      environment = _json['environment'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (environment != null) 'environment': environment!,
      };
}

/// The response message for TestCases.RunTestCase.
class GoogleCloudDialogflowCxV3RunTestCaseResponse {
  /// The result.
  GoogleCloudDialogflowCxV3TestCaseResult? result;

  GoogleCloudDialogflowCxV3RunTestCaseResponse();

  GoogleCloudDialogflowCxV3RunTestCaseResponse.fromJson(core.Map _json) {
    if (_json.containsKey('result')) {
      result = GoogleCloudDialogflowCxV3TestCaseResult.fromJson(
          _json['result'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (result != null) 'result': result!.toJson(),
      };
}

/// Represents the settings related to security issues, such as data redaction
/// and data retention.
///
/// It may take hours for updates on the settings to propagate to all the
/// related components and take effect.
class GoogleCloudDialogflowCxV3SecuritySettings {
  /// The human-readable name of the security settings, unique within the
  /// location.
  ///
  /// Required.
  core.String? displayName;

  /// DLP inspect template name.
  ///
  /// Use this template to define inspect base settings. If empty, we use the
  /// default DLP inspect config. The template name will have one of the
  /// following formats: `projects/PROJECT_ID/inspectTemplates/TEMPLATE_ID` OR
  /// `organizations/ORGANIZATION_ID/inspectTemplates/TEMPLATE_ID`
  core.String? inspectTemplate;

  /// Resource name of the settings.
  ///
  /// Format: `projects//locations//securitySettings/`.
  ///
  /// Required.
  core.String? name;

  /// List of types of data to remove when retention settings triggers purge.
  core.List<core.String>? purgeDataTypes;

  /// Defines the data for which Dialogflow applies redaction.
  ///
  /// Dialogflow does not redact data that it does not have access to – for
  /// example, Cloud logging.
  /// Possible string values are:
  /// - "REDACTION_SCOPE_UNSPECIFIED" : Don't redact any kind of data.
  /// - "REDACT_DISK_STORAGE" : On data to be written to disk or similar devices
  /// that are capable of holding data even if power is disconnected. This
  /// includes data that are temporarily saved on disk.
  core.String? redactionScope;

  /// Strategy that defines how we do redaction.
  /// Possible string values are:
  /// - "REDACTION_STRATEGY_UNSPECIFIED" : Do not redact.
  /// - "REDACT_WITH_SERVICE" : Call redaction service to clean up the data to
  /// be persisted.
  core.String? redactionStrategy;

  /// Retains data in interaction logging for the specified number of days.
  ///
  /// This does not apply to Cloud logging, which is owned by the user - not
  /// Dialogflow. User must Set a value lower than Dialogflow's default 30d TTL.
  /// Setting a value higher than that has no effect. A missing value or setting
  /// to 0 also means we use Dialogflow's default TTL. Note: Interaction logging
  /// is a limited access feature. Talk to your Google representative to check
  /// availability for you.
  core.int? retentionWindowDays;

  GoogleCloudDialogflowCxV3SecuritySettings();

  GoogleCloudDialogflowCxV3SecuritySettings.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('inspectTemplate')) {
      inspectTemplate = _json['inspectTemplate'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('purgeDataTypes')) {
      purgeDataTypes = (_json['purgeDataTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('redactionScope')) {
      redactionScope = _json['redactionScope'] as core.String;
    }
    if (_json.containsKey('redactionStrategy')) {
      redactionStrategy = _json['redactionStrategy'] as core.String;
    }
    if (_json.containsKey('retentionWindowDays')) {
      retentionWindowDays = _json['retentionWindowDays'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (inspectTemplate != null) 'inspectTemplate': inspectTemplate!,
        if (name != null) 'name': name!,
        if (purgeDataTypes != null) 'purgeDataTypes': purgeDataTypes!,
        if (redactionScope != null) 'redactionScope': redactionScope!,
        if (redactionStrategy != null) 'redactionStrategy': redactionStrategy!,
        if (retentionWindowDays != null)
          'retentionWindowDays': retentionWindowDays!,
      };
}

/// The result of sentiment analysis.
///
/// Sentiment analysis inspects user input and identifies the prevailing
/// subjective opinion, especially to determine a user's attitude as positive,
/// negative, or neutral.
class GoogleCloudDialogflowCxV3SentimentAnalysisResult {
  /// A non-negative number in the \[0, +inf) range, which represents the
  /// absolute magnitude of sentiment, regardless of score (positive or
  /// negative).
  core.double? magnitude;

  /// Sentiment score between -1.0 (negative sentiment) and 1.0 (positive
  /// sentiment).
  core.double? score;

  GoogleCloudDialogflowCxV3SentimentAnalysisResult();

  GoogleCloudDialogflowCxV3SentimentAnalysisResult.fromJson(core.Map _json) {
    if (_json.containsKey('magnitude')) {
      magnitude = (_json['magnitude'] as core.num).toDouble();
    }
    if (_json.containsKey('score')) {
      score = (_json['score'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (magnitude != null) 'magnitude': magnitude!,
        if (score != null) 'score': score!,
      };
}

/// Session entity types are referred to as **User** entity types and are
/// entities that are built for an individual user such as favorites,
/// preferences, playlists, and so on.
///
/// You can redefine a session entity type at the session level to extend or
/// replace a custom entity type at the user session level (we refer to the
/// entity types defined at the agent level as "custom entity types"). Note:
/// session entity types apply to all queries, regardless of the language. For
/// more information about entity types, see the
/// [Dialogflow documentation](https://cloud.google.com/dialogflow/docs/entities-overview).
class GoogleCloudDialogflowCxV3SessionEntityType {
  /// The collection of entities to override or supplement the custom entity
  /// type.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowCxV3EntityTypeEntity>? entities;

  /// Indicates whether the additional data should override or supplement the
  /// custom entity type definition.
  ///
  /// Required.
  /// Possible string values are:
  /// - "ENTITY_OVERRIDE_MODE_UNSPECIFIED" : Not specified. This value should be
  /// never used.
  /// - "ENTITY_OVERRIDE_MODE_OVERRIDE" : The collection of session entities
  /// overrides the collection of entities in the corresponding custom entity
  /// type.
  /// - "ENTITY_OVERRIDE_MODE_SUPPLEMENT" : The collection of session entities
  /// extends the collection of entities in the corresponding custom entity
  /// type. Note: Even in this override mode calls to `ListSessionEntityTypes`,
  /// `GetSessionEntityType`, `CreateSessionEntityType` and
  /// `UpdateSessionEntityType` only return the additional entities added in
  /// this session entity type. If you want to get the supplemented list, please
  /// call EntityTypes.GetEntityType on the custom entity type and merge.
  core.String? entityOverrideMode;

  /// The unique identifier of the session entity type.
  ///
  /// Format: `projects//locations//agents//sessions//entityTypes/` or
  /// `projects//locations//agents//environments//sessions//entityTypes/`. If
  /// `Environment ID` is not specified, we assume default 'draft' environment.
  ///
  /// Required.
  core.String? name;

  GoogleCloudDialogflowCxV3SessionEntityType();

  GoogleCloudDialogflowCxV3SessionEntityType.fromJson(core.Map _json) {
    if (_json.containsKey('entities')) {
      entities = (_json['entities'] as core.List)
          .map<GoogleCloudDialogflowCxV3EntityTypeEntity>((value) =>
              GoogleCloudDialogflowCxV3EntityTypeEntity.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('entityOverrideMode')) {
      entityOverrideMode = _json['entityOverrideMode'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entities != null)
          'entities': entities!.map((value) => value.toJson()).toList(),
        if (entityOverrideMode != null)
          'entityOverrideMode': entityOverrideMode!,
        if (name != null) 'name': name!,
      };
}

/// Represents session information communicated to and from the webhook.
class GoogleCloudDialogflowCxV3SessionInfo {
  /// Optional for WebhookRequest.
  ///
  /// Optional for WebhookResponse. All parameters collected from forms and
  /// intents during the session. Parameters can be created, updated, or removed
  /// by the webhook. To remove a parameter from the session, the webhook should
  /// explicitly set the parameter value to null in WebhookResponse. The map is
  /// keyed by parameters' display names.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? parameters;

  /// Always present for WebhookRequest.
  ///
  /// Ignored for WebhookResponse. The unique identifier of the session. This
  /// field can be used by the webhook to identify a session. Format:
  /// `projects//locations//agents//sessions/` or
  /// `projects//locations//agents//environments//sessions/` if environment is
  /// specified.
  core.String? session;

  GoogleCloudDialogflowCxV3SessionInfo();

  GoogleCloudDialogflowCxV3SessionInfo.fromJson(core.Map _json) {
    if (_json.containsKey('parameters')) {
      parameters =
          (_json['parameters'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('session')) {
      session = _json['session'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parameters != null) 'parameters': parameters!,
        if (session != null) 'session': session!,
      };
}

/// Settings related to speech recognition.
class GoogleCloudDialogflowCxV3SpeechToTextSettings {
  /// Whether to use speech adaptation for speech recognition.
  core.bool? enableSpeechAdaptation;

  GoogleCloudDialogflowCxV3SpeechToTextSettings();

  GoogleCloudDialogflowCxV3SpeechToTextSettings.fromJson(core.Map _json) {
    if (_json.containsKey('enableSpeechAdaptation')) {
      enableSpeechAdaptation = _json['enableSpeechAdaptation'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enableSpeechAdaptation != null)
          'enableSpeechAdaptation': enableSpeechAdaptation!,
      };
}

/// The request message for Experiments.StartExperiment.
class GoogleCloudDialogflowCxV3StartExperimentRequest {
  GoogleCloudDialogflowCxV3StartExperimentRequest();

  GoogleCloudDialogflowCxV3StartExperimentRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The request message for Experiments.StopExperiment.
class GoogleCloudDialogflowCxV3StopExperimentRequest {
  GoogleCloudDialogflowCxV3StopExperimentRequest();

  GoogleCloudDialogflowCxV3StopExperimentRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Configuration of how speech should be synthesized.
class GoogleCloudDialogflowCxV3SynthesizeSpeechConfig {
  /// An identifier which selects 'audio effects' profiles that are applied on
  /// (post synthesized) text to speech.
  ///
  /// Effects are applied on top of each other in the order they are given.
  ///
  /// Optional.
  core.List<core.String>? effectsProfileId;

  /// Speaking pitch, in the range \[-20.0, 20.0\].
  ///
  /// 20 means increase 20 semitones from the original pitch. -20 means decrease
  /// 20 semitones from the original pitch.
  ///
  /// Optional.
  core.double? pitch;

  /// Speaking rate/speed, in the range \[0.25, 4.0\].
  ///
  /// 1.0 is the normal native speed supported by the specific voice. 2.0 is
  /// twice as fast, and 0.5 is half as fast. If unset(0.0), defaults to the
  /// native 1.0 speed. Any other values < 0.25 or > 4.0 will return an error.
  ///
  /// Optional.
  core.double? speakingRate;

  /// The desired voice of the synthesized audio.
  ///
  /// Optional.
  GoogleCloudDialogflowCxV3VoiceSelectionParams? voice;

  /// Volume gain (in dB) of the normal native volume supported by the specific
  /// voice, in the range \[-96.0, 16.0\].
  ///
  /// If unset, or set to a value of 0.0 (dB), will play at normal native signal
  /// amplitude. A value of -6.0 (dB) will play at approximately half the
  /// amplitude of the normal native signal amplitude. A value of +6.0 (dB) will
  /// play at approximately twice the amplitude of the normal native signal
  /// amplitude. We strongly recommend not to exceed +10 (dB) as there's usually
  /// no effective increase in loudness for any value greater than that.
  ///
  /// Optional.
  core.double? volumeGainDb;

  GoogleCloudDialogflowCxV3SynthesizeSpeechConfig();

  GoogleCloudDialogflowCxV3SynthesizeSpeechConfig.fromJson(core.Map _json) {
    if (_json.containsKey('effectsProfileId')) {
      effectsProfileId = (_json['effectsProfileId'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('pitch')) {
      pitch = (_json['pitch'] as core.num).toDouble();
    }
    if (_json.containsKey('speakingRate')) {
      speakingRate = (_json['speakingRate'] as core.num).toDouble();
    }
    if (_json.containsKey('voice')) {
      voice = GoogleCloudDialogflowCxV3VoiceSelectionParams.fromJson(
          _json['voice'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('volumeGainDb')) {
      volumeGainDb = (_json['volumeGainDb'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (effectsProfileId != null) 'effectsProfileId': effectsProfileId!,
        if (pitch != null) 'pitch': pitch!,
        if (speakingRate != null) 'speakingRate': speakingRate!,
        if (voice != null) 'voice': voice!.toJson(),
        if (volumeGainDb != null) 'volumeGainDb': volumeGainDb!,
      };
}

/// Represents a test case.
class GoogleCloudDialogflowCxV3TestCase {
  /// When the test was created.
  ///
  /// Output only.
  core.String? creationTime;

  /// The human-readable name of the test case, unique within the agent.
  ///
  /// Limit of 200 characters.
  ///
  /// Required.
  core.String? displayName;

  /// The latest test result.
  GoogleCloudDialogflowCxV3TestCaseResult? lastTestResult;

  /// The unique identifier of the test case.
  ///
  /// TestCases.CreateTestCase will populate the name automatically. Otherwise
  /// use format: `projects//locations//agents/ /testCases/`.
  core.String? name;

  /// Additional freeform notes about the test case.
  ///
  /// Limit of 400 characters.
  core.String? notes;

  /// Tags are short descriptions that users may apply to test cases for
  /// organizational and filtering purposes.
  ///
  /// Each tag should start with "#" and has a limit of 30 characters.
  core.List<core.String>? tags;

  /// The conversation turns uttered when the test case was created, in
  /// chronological order.
  ///
  /// These include the canonical set of agent utterances that should occur when
  /// the agent is working properly.
  core.List<GoogleCloudDialogflowCxV3ConversationTurn>?
      testCaseConversationTurns;

  /// Config for the test case.
  GoogleCloudDialogflowCxV3TestConfig? testConfig;

  GoogleCloudDialogflowCxV3TestCase();

  GoogleCloudDialogflowCxV3TestCase.fromJson(core.Map _json) {
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('lastTestResult')) {
      lastTestResult = GoogleCloudDialogflowCxV3TestCaseResult.fromJson(
          _json['lastTestResult'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('notes')) {
      notes = _json['notes'] as core.String;
    }
    if (_json.containsKey('tags')) {
      tags = (_json['tags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('testCaseConversationTurns')) {
      testCaseConversationTurns =
          (_json['testCaseConversationTurns'] as core.List)
              .map<GoogleCloudDialogflowCxV3ConversationTurn>((value) =>
                  GoogleCloudDialogflowCxV3ConversationTurn.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('testConfig')) {
      testConfig = GoogleCloudDialogflowCxV3TestConfig.fromJson(
          _json['testConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creationTime != null) 'creationTime': creationTime!,
        if (displayName != null) 'displayName': displayName!,
        if (lastTestResult != null) 'lastTestResult': lastTestResult!.toJson(),
        if (name != null) 'name': name!,
        if (notes != null) 'notes': notes!,
        if (tags != null) 'tags': tags!,
        if (testCaseConversationTurns != null)
          'testCaseConversationTurns': testCaseConversationTurns!
              .map((value) => value.toJson())
              .toList(),
        if (testConfig != null) 'testConfig': testConfig!.toJson(),
      };
}

/// Error info for importing a test.
class GoogleCloudDialogflowCxV3TestCaseError {
  /// The status associated with the test case.
  GoogleRpcStatus? status;

  /// The test case.
  GoogleCloudDialogflowCxV3TestCase? testCase;

  GoogleCloudDialogflowCxV3TestCaseError();

  GoogleCloudDialogflowCxV3TestCaseError.fromJson(core.Map _json) {
    if (_json.containsKey('status')) {
      status = GoogleRpcStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('testCase')) {
      testCase = GoogleCloudDialogflowCxV3TestCase.fromJson(
          _json['testCase'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (status != null) 'status': status!.toJson(),
        if (testCase != null) 'testCase': testCase!.toJson(),
      };
}

/// Represents a result from running a test case in an agent environment.
class GoogleCloudDialogflowCxV3TestCaseResult {
  /// The conversation turns uttered during the test case replay in
  /// chronological order.
  core.List<GoogleCloudDialogflowCxV3ConversationTurn>? conversationTurns;

  /// Environment where the test was run.
  ///
  /// If not set, it indicates the draft environment.
  core.String? environment;

  /// The resource name for the test case result.
  ///
  /// Format: `projects//locations//agents//testCases/ /results/`.
  core.String? name;

  /// Whether the test case passed in the agent environment.
  /// Possible string values are:
  /// - "TEST_RESULT_UNSPECIFIED" : Not specified. Should never be used.
  /// - "PASSED" : The test passed.
  /// - "FAILED" : The test did not pass.
  core.String? testResult;

  /// The time that the test was run.
  core.String? testTime;

  GoogleCloudDialogflowCxV3TestCaseResult();

  GoogleCloudDialogflowCxV3TestCaseResult.fromJson(core.Map _json) {
    if (_json.containsKey('conversationTurns')) {
      conversationTurns = (_json['conversationTurns'] as core.List)
          .map<GoogleCloudDialogflowCxV3ConversationTurn>((value) =>
              GoogleCloudDialogflowCxV3ConversationTurn.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('environment')) {
      environment = _json['environment'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('testResult')) {
      testResult = _json['testResult'] as core.String;
    }
    if (_json.containsKey('testTime')) {
      testTime = _json['testTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conversationTurns != null)
          'conversationTurns':
              conversationTurns!.map((value) => value.toJson()).toList(),
        if (environment != null) 'environment': environment!,
        if (name != null) 'name': name!,
        if (testResult != null) 'testResult': testResult!,
        if (testTime != null) 'testTime': testTime!,
      };
}

/// Represents configurations for a test case.
class GoogleCloudDialogflowCxV3TestConfig {
  /// Flow name.
  ///
  /// If not set, default start flow is assumed. Format:
  /// `projects//locations//agents//flows/`.
  core.String? flow;

  /// Session parameters to be compared when calculating differences.
  core.List<core.String>? trackingParameters;

  GoogleCloudDialogflowCxV3TestConfig();

  GoogleCloudDialogflowCxV3TestConfig.fromJson(core.Map _json) {
    if (_json.containsKey('flow')) {
      flow = _json['flow'] as core.String;
    }
    if (_json.containsKey('trackingParameters')) {
      trackingParameters = (_json['trackingParameters'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (flow != null) 'flow': flow!,
        if (trackingParameters != null)
          'trackingParameters': trackingParameters!,
      };
}

/// Error info for running a test.
class GoogleCloudDialogflowCxV3TestError {
  /// The status associated with the test.
  GoogleRpcStatus? status;

  /// The test case resource name.
  core.String? testCase;

  /// The timestamp when the test was completed.
  core.String? testTime;

  GoogleCloudDialogflowCxV3TestError();

  GoogleCloudDialogflowCxV3TestError.fromJson(core.Map _json) {
    if (_json.containsKey('status')) {
      status = GoogleRpcStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('testCase')) {
      testCase = _json['testCase'] as core.String;
    }
    if (_json.containsKey('testTime')) {
      testTime = _json['testTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (status != null) 'status': status!.toJson(),
        if (testCase != null) 'testCase': testCase!,
        if (testTime != null) 'testTime': testTime!,
      };
}

/// The description of differences between original and replayed agent output.
class GoogleCloudDialogflowCxV3TestRunDifference {
  /// A description of the diff, showing the actual output vs expected output.
  core.String? description;

  /// The type of diff.
  /// Possible string values are:
  /// - "DIFF_TYPE_UNSPECIFIED" : Should never be used.
  /// - "INTENT" : The intent.
  /// - "PAGE" : The page.
  /// - "PARAMETERS" : The parameters.
  /// - "UTTERANCE" : The message utterance.
  core.String? type;

  GoogleCloudDialogflowCxV3TestRunDifference();

  GoogleCloudDialogflowCxV3TestRunDifference.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (type != null) 'type': type!,
      };
}

/// Represents the natural language text to be processed.
class GoogleCloudDialogflowCxV3TextInput {
  /// The UTF-8 encoded natural language text to be processed.
  ///
  /// Text length must not exceed 256 characters.
  ///
  /// Required.
  core.String? text;

  GoogleCloudDialogflowCxV3TextInput();

  GoogleCloudDialogflowCxV3TextInput.fromJson(core.Map _json) {
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (text != null) 'text': text!,
      };
}

/// The request message for Flows.TrainFlow.
class GoogleCloudDialogflowCxV3TrainFlowRequest {
  GoogleCloudDialogflowCxV3TrainFlowRequest();

  GoogleCloudDialogflowCxV3TrainFlowRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Transition coverage represents the percentage of all possible page
/// transitions (page-level transition routes and event handlers, excluding
/// transition route groups) present within any of a parent's test cases.
class GoogleCloudDialogflowCxV3TransitionCoverage {
  /// The percent of transitions in the agent that are covered.
  core.double? coverageScore;

  /// The list of Transitions present in the agent.
  core.List<GoogleCloudDialogflowCxV3TransitionCoverageTransition>? transitions;

  GoogleCloudDialogflowCxV3TransitionCoverage();

  GoogleCloudDialogflowCxV3TransitionCoverage.fromJson(core.Map _json) {
    if (_json.containsKey('coverageScore')) {
      coverageScore = (_json['coverageScore'] as core.num).toDouble();
    }
    if (_json.containsKey('transitions')) {
      transitions = (_json['transitions'] as core.List)
          .map<GoogleCloudDialogflowCxV3TransitionCoverageTransition>((value) =>
              GoogleCloudDialogflowCxV3TransitionCoverageTransition.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (coverageScore != null) 'coverageScore': coverageScore!,
        if (transitions != null)
          'transitions': transitions!.map((value) => value.toJson()).toList(),
      };
}

/// A transition in a page.
class GoogleCloudDialogflowCxV3TransitionCoverageTransition {
  /// Whether or not the transition is covered by at least one of the agent's
  /// test cases.
  core.bool? covered;

  /// Event handler.
  GoogleCloudDialogflowCxV3EventHandler? eventHandler;

  /// The index of a transition in the transition list.
  ///
  /// Starting from 0.
  core.int? index;

  /// The start node of a transition.
  GoogleCloudDialogflowCxV3TransitionCoverageTransitionNode? source;

  /// The end node of a transition.
  GoogleCloudDialogflowCxV3TransitionCoverageTransitionNode? target;

  /// Intent route or condition route.
  GoogleCloudDialogflowCxV3TransitionRoute? transitionRoute;

  GoogleCloudDialogflowCxV3TransitionCoverageTransition();

  GoogleCloudDialogflowCxV3TransitionCoverageTransition.fromJson(
      core.Map _json) {
    if (_json.containsKey('covered')) {
      covered = _json['covered'] as core.bool;
    }
    if (_json.containsKey('eventHandler')) {
      eventHandler = GoogleCloudDialogflowCxV3EventHandler.fromJson(
          _json['eventHandler'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('index')) {
      index = _json['index'] as core.int;
    }
    if (_json.containsKey('source')) {
      source =
          GoogleCloudDialogflowCxV3TransitionCoverageTransitionNode.fromJson(
              _json['source'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('target')) {
      target =
          GoogleCloudDialogflowCxV3TransitionCoverageTransitionNode.fromJson(
              _json['target'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('transitionRoute')) {
      transitionRoute = GoogleCloudDialogflowCxV3TransitionRoute.fromJson(
          _json['transitionRoute'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (covered != null) 'covered': covered!,
        if (eventHandler != null) 'eventHandler': eventHandler!.toJson(),
        if (index != null) 'index': index!,
        if (source != null) 'source': source!.toJson(),
        if (target != null) 'target': target!.toJson(),
        if (transitionRoute != null)
          'transitionRoute': transitionRoute!.toJson(),
      };
}

/// The source or target of a transition.
class GoogleCloudDialogflowCxV3TransitionCoverageTransitionNode {
  /// Indicates a transition to a Flow.
  ///
  /// Only some fields such as name and displayname will be set.
  GoogleCloudDialogflowCxV3Flow? flow;

  /// Indicates a transition to a Page.
  ///
  /// Only some fields such as name and displayname will be set.
  GoogleCloudDialogflowCxV3Page? page;

  GoogleCloudDialogflowCxV3TransitionCoverageTransitionNode();

  GoogleCloudDialogflowCxV3TransitionCoverageTransitionNode.fromJson(
      core.Map _json) {
    if (_json.containsKey('flow')) {
      flow = GoogleCloudDialogflowCxV3Flow.fromJson(
          _json['flow'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('page')) {
      page = GoogleCloudDialogflowCxV3Page.fromJson(
          _json['page'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (flow != null) 'flow': flow!.toJson(),
        if (page != null) 'page': page!.toJson(),
      };
}

/// A transition route specifies a intent that can be matched and/or a data
/// condition that can be evaluated during a session.
///
/// When a specified transition is matched, the following actions are taken in
/// order: * If there is a `trigger_fulfillment` associated with the transition,
/// it will be called. * If there is a `target_page` associated with the
/// transition, the session will transition into the specified page. * If there
/// is a `target_flow` associated with the transition, the session will
/// transition into the specified flow.
class GoogleCloudDialogflowCxV3TransitionRoute {
  /// The condition to evaluate against form parameters or session parameters.
  ///
  /// See the
  /// [conditions reference](https://cloud.google.com/dialogflow/cx/docs/reference/condition).
  /// At least one of `intent` or `condition` must be specified. When both
  /// `intent` and `condition` are specified, the transition can only happen
  /// when both are fulfilled.
  core.String? condition;

  /// The unique identifier of an Intent.
  ///
  /// Format: `projects//locations//agents//intents/`. Indicates that the
  /// transition can only happen when the given intent is matched. At least one
  /// of `intent` or `condition` must be specified. When both `intent` and
  /// `condition` are specified, the transition can only happen when both are
  /// fulfilled.
  core.String? intent;

  /// The unique identifier of this transition route.
  ///
  /// Output only.
  core.String? name;

  /// The target flow to transition to.
  ///
  /// Format: `projects//locations//agents//flows/`.
  core.String? targetFlow;

  /// The target page to transition to.
  ///
  /// Format: `projects//locations//agents//flows//pages/`.
  core.String? targetPage;

  /// The fulfillment to call when the condition is satisfied.
  ///
  /// At least one of `trigger_fulfillment` and `target` must be specified. When
  /// both are defined, `trigger_fulfillment` is executed first.
  GoogleCloudDialogflowCxV3Fulfillment? triggerFulfillment;

  GoogleCloudDialogflowCxV3TransitionRoute();

  GoogleCloudDialogflowCxV3TransitionRoute.fromJson(core.Map _json) {
    if (_json.containsKey('condition')) {
      condition = _json['condition'] as core.String;
    }
    if (_json.containsKey('intent')) {
      intent = _json['intent'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('targetFlow')) {
      targetFlow = _json['targetFlow'] as core.String;
    }
    if (_json.containsKey('targetPage')) {
      targetPage = _json['targetPage'] as core.String;
    }
    if (_json.containsKey('triggerFulfillment')) {
      triggerFulfillment = GoogleCloudDialogflowCxV3Fulfillment.fromJson(
          _json['triggerFulfillment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (condition != null) 'condition': condition!,
        if (intent != null) 'intent': intent!,
        if (name != null) 'name': name!,
        if (targetFlow != null) 'targetFlow': targetFlow!,
        if (targetPage != null) 'targetPage': targetPage!,
        if (triggerFulfillment != null)
          'triggerFulfillment': triggerFulfillment!.toJson(),
      };
}

/// An TransitionRouteGroup represents a group of `TransitionRoutes` to be used
/// by a Page.
class GoogleCloudDialogflowCxV3TransitionRouteGroup {
  /// The human-readable name of the transition route group, unique within the
  /// Agent.
  ///
  /// The display name can be no longer than 30 characters.
  ///
  /// Required.
  core.String? displayName;

  /// The unique identifier of the transition route group.
  ///
  /// TransitionRouteGroups.CreateTransitionRouteGroup populates the name
  /// automatically. Format:
  /// `projects//locations//agents//flows//transitionRouteGroups/`.
  core.String? name;

  /// Transition routes associated with the TransitionRouteGroup.
  core.List<GoogleCloudDialogflowCxV3TransitionRoute>? transitionRoutes;

  GoogleCloudDialogflowCxV3TransitionRouteGroup();

  GoogleCloudDialogflowCxV3TransitionRouteGroup.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('transitionRoutes')) {
      transitionRoutes = (_json['transitionRoutes'] as core.List)
          .map<GoogleCloudDialogflowCxV3TransitionRoute>((value) =>
              GoogleCloudDialogflowCxV3TransitionRoute.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (name != null) 'name': name!,
        if (transitionRoutes != null)
          'transitionRoutes':
              transitionRoutes!.map((value) => value.toJson()).toList(),
      };
}

/// Transition route group coverage represents the percentage of all possible
/// transition routes present within any of a parent's test cases.
///
/// The results are grouped by the transition route group.
class GoogleCloudDialogflowCxV3TransitionRouteGroupCoverage {
  /// The percent of transition routes in all the transition route groups that
  /// are covered.
  core.double? coverageScore;

  /// Transition route group coverages.
  core.List<GoogleCloudDialogflowCxV3TransitionRouteGroupCoverageCoverage>?
      coverages;

  GoogleCloudDialogflowCxV3TransitionRouteGroupCoverage();

  GoogleCloudDialogflowCxV3TransitionRouteGroupCoverage.fromJson(
      core.Map _json) {
    if (_json.containsKey('coverageScore')) {
      coverageScore = (_json['coverageScore'] as core.num).toDouble();
    }
    if (_json.containsKey('coverages')) {
      coverages = (_json['coverages'] as core.List)
          .map<GoogleCloudDialogflowCxV3TransitionRouteGroupCoverageCoverage>(
              (value) =>
                  GoogleCloudDialogflowCxV3TransitionRouteGroupCoverageCoverage
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (coverageScore != null) 'coverageScore': coverageScore!,
        if (coverages != null)
          'coverages': coverages!.map((value) => value.toJson()).toList(),
      };
}

/// Coverage result message for one transition route group.
class GoogleCloudDialogflowCxV3TransitionRouteGroupCoverageCoverage {
  /// The percent of transition routes in the transition route group that are
  /// covered.
  core.double? coverageScore;

  /// Transition route group metadata.
  ///
  /// Only name and displayName will be set.
  GoogleCloudDialogflowCxV3TransitionRouteGroup? routeGroup;

  /// The list of transition routes and coverage in the transition route group.
  core.List<
          GoogleCloudDialogflowCxV3TransitionRouteGroupCoverageCoverageTransition>?
      transitions;

  GoogleCloudDialogflowCxV3TransitionRouteGroupCoverageCoverage();

  GoogleCloudDialogflowCxV3TransitionRouteGroupCoverageCoverage.fromJson(
      core.Map _json) {
    if (_json.containsKey('coverageScore')) {
      coverageScore = (_json['coverageScore'] as core.num).toDouble();
    }
    if (_json.containsKey('routeGroup')) {
      routeGroup = GoogleCloudDialogflowCxV3TransitionRouteGroup.fromJson(
          _json['routeGroup'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('transitions')) {
      transitions = (_json['transitions'] as core.List)
          .map<GoogleCloudDialogflowCxV3TransitionRouteGroupCoverageCoverageTransition>(
              (value) =>
                  GoogleCloudDialogflowCxV3TransitionRouteGroupCoverageCoverageTransition
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (coverageScore != null) 'coverageScore': coverageScore!,
        if (routeGroup != null) 'routeGroup': routeGroup!.toJson(),
        if (transitions != null)
          'transitions': transitions!.map((value) => value.toJson()).toList(),
      };
}

/// A transition coverage in a transition route group.
class GoogleCloudDialogflowCxV3TransitionRouteGroupCoverageCoverageTransition {
  /// Whether or not the transition route is covered by at least one of the
  /// agent's test cases.
  core.bool? covered;

  /// Intent route or condition route.
  GoogleCloudDialogflowCxV3TransitionRoute? transitionRoute;

  GoogleCloudDialogflowCxV3TransitionRouteGroupCoverageCoverageTransition();

  GoogleCloudDialogflowCxV3TransitionRouteGroupCoverageCoverageTransition.fromJson(
      core.Map _json) {
    if (_json.containsKey('covered')) {
      covered = _json['covered'] as core.bool;
    }
    if (_json.containsKey('transitionRoute')) {
      transitionRoute = GoogleCloudDialogflowCxV3TransitionRoute.fromJson(
          _json['transitionRoute'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (covered != null) 'covered': covered!,
        if (transitionRoute != null)
          'transitionRoute': transitionRoute!.toJson(),
      };
}

/// Metadata for UpdateDocument operation.
class GoogleCloudDialogflowCxV3UpdateDocumentOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowCxV3GenericKnowledgeOperationMetadata? genericMetadata;

  GoogleCloudDialogflowCxV3UpdateDocumentOperationMetadata();

  GoogleCloudDialogflowCxV3UpdateDocumentOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowCxV3GenericKnowledgeOperationMetadata.fromJson(
              _json['genericMetadata'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// The request message for Agents.ValidateAgent.
class GoogleCloudDialogflowCxV3ValidateAgentRequest {
  /// If not specified, the agent's default language is used.
  core.String? languageCode;

  GoogleCloudDialogflowCxV3ValidateAgentRequest();

  GoogleCloudDialogflowCxV3ValidateAgentRequest.fromJson(core.Map _json) {
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (languageCode != null) 'languageCode': languageCode!,
      };
}

/// The request message for Flows.ValidateFlow.
class GoogleCloudDialogflowCxV3ValidateFlowRequest {
  /// If not specified, the agent's default language is used.
  core.String? languageCode;

  GoogleCloudDialogflowCxV3ValidateFlowRequest();

  GoogleCloudDialogflowCxV3ValidateFlowRequest.fromJson(core.Map _json) {
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (languageCode != null) 'languageCode': languageCode!,
      };
}

/// Agent/flow validation message.
class GoogleCloudDialogflowCxV3ValidationMessage {
  /// The message detail.
  core.String? detail;

  /// The resource names of the resources where the message is found.
  core.List<GoogleCloudDialogflowCxV3ResourceName>? resourceNames;

  /// The type of the resources where the message is found.
  /// Possible string values are:
  /// - "RESOURCE_TYPE_UNSPECIFIED" : Unspecified.
  /// - "AGENT" : Agent.
  /// - "INTENT" : Intent.
  /// - "INTENT_TRAINING_PHRASE" : Intent training phrase.
  /// - "INTENT_PARAMETER" : Intent parameter.
  /// - "INTENTS" : Multiple intents.
  /// - "INTENT_TRAINING_PHRASES" : Multiple training phrases.
  /// - "ENTITY_TYPE" : Entity type.
  /// - "ENTITY_TYPES" : Multiple entity types.
  /// - "WEBHOOK" : Webhook.
  /// - "FLOW" : Flow.
  /// - "PAGE" : Page.
  /// - "PAGES" : Multiple pages.
  /// - "TRANSITION_ROUTE_GROUP" : Transition route group.
  core.String? resourceType;

  /// The names of the resources where the message is found.
  core.List<core.String>? resources;

  /// Indicates the severity of the message.
  /// Possible string values are:
  /// - "SEVERITY_UNSPECIFIED" : Unspecified.
  /// - "INFO" : The agent doesn't follow Dialogflow best practices.
  /// - "WARNING" : The agent may not behave as expected.
  /// - "ERROR" : The agent may experience failures.
  core.String? severity;

  GoogleCloudDialogflowCxV3ValidationMessage();

  GoogleCloudDialogflowCxV3ValidationMessage.fromJson(core.Map _json) {
    if (_json.containsKey('detail')) {
      detail = _json['detail'] as core.String;
    }
    if (_json.containsKey('resourceNames')) {
      resourceNames = (_json['resourceNames'] as core.List)
          .map<GoogleCloudDialogflowCxV3ResourceName>((value) =>
              GoogleCloudDialogflowCxV3ResourceName.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('resourceType')) {
      resourceType = _json['resourceType'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (detail != null) 'detail': detail!,
        if (resourceNames != null)
          'resourceNames':
              resourceNames!.map((value) => value.toJson()).toList(),
        if (resourceType != null) 'resourceType': resourceType!,
        if (resources != null) 'resources': resources!,
        if (severity != null) 'severity': severity!,
      };
}

/// The history of variants update.
class GoogleCloudDialogflowCxV3VariantsHistory {
  /// Update time of the variants.
  core.String? updateTime;

  /// The flow versions as the variants.
  GoogleCloudDialogflowCxV3VersionVariants? versionVariants;

  GoogleCloudDialogflowCxV3VariantsHistory();

  GoogleCloudDialogflowCxV3VariantsHistory.fromJson(core.Map _json) {
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
    if (_json.containsKey('versionVariants')) {
      versionVariants = GoogleCloudDialogflowCxV3VersionVariants.fromJson(
          _json['versionVariants'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (updateTime != null) 'updateTime': updateTime!,
        if (versionVariants != null)
          'versionVariants': versionVariants!.toJson(),
      };
}

/// Represents a version of a flow.
class GoogleCloudDialogflowCxV3Version {
  /// Create time of the version.
  ///
  /// Output only.
  core.String? createTime;

  /// The description of the version.
  ///
  /// The maximum length is 500 characters. If exceeded, the request is
  /// rejected.
  core.String? description;

  /// The human-readable name of the version.
  ///
  /// Limit of 64 characters.
  ///
  /// Required.
  core.String? displayName;

  /// Format: projects//locations//agents//flows//versions/.
  ///
  /// Version ID is a self-increasing number generated by Dialogflow upon
  /// version creation.
  core.String? name;

  /// The NLU settings of the flow at version creation.
  ///
  /// Output only.
  GoogleCloudDialogflowCxV3NluSettings? nluSettings;

  /// The state of this version.
  ///
  /// This field is read-only and cannot be set by create and update methods.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Not specified. This value is not used.
  /// - "RUNNING" : Version is not ready to serve (e.g. training is running).
  /// - "SUCCEEDED" : Training has succeeded and this version is ready to serve.
  /// - "FAILED" : Version training failed.
  core.String? state;

  GoogleCloudDialogflowCxV3Version();

  GoogleCloudDialogflowCxV3Version.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('nluSettings')) {
      nluSettings = GoogleCloudDialogflowCxV3NluSettings.fromJson(
          _json['nluSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (name != null) 'name': name!,
        if (nluSettings != null) 'nluSettings': nluSettings!.toJson(),
        if (state != null) 'state': state!,
      };
}

/// A list of flow version variants.
class GoogleCloudDialogflowCxV3VersionVariants {
  /// A list of flow version variants.
  core.List<GoogleCloudDialogflowCxV3VersionVariantsVariant>? variants;

  GoogleCloudDialogflowCxV3VersionVariants();

  GoogleCloudDialogflowCxV3VersionVariants.fromJson(core.Map _json) {
    if (_json.containsKey('variants')) {
      variants = (_json['variants'] as core.List)
          .map<GoogleCloudDialogflowCxV3VersionVariantsVariant>((value) =>
              GoogleCloudDialogflowCxV3VersionVariantsVariant.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (variants != null)
          'variants': variants!.map((value) => value.toJson()).toList(),
      };
}

/// A single flow version with specified traffic allocation.
class GoogleCloudDialogflowCxV3VersionVariantsVariant {
  /// Whether the variant is for the control group.
  core.bool? isControlGroup;

  /// Percentage of the traffic which should be routed to this version of flow.
  ///
  /// Traffic allocation for a single flow must sum up to 1.0.
  core.double? trafficAllocation;

  /// The name of the flow version.
  ///
  /// Format: `projects//locations//agents//flows//versions/`.
  core.String? version;

  GoogleCloudDialogflowCxV3VersionVariantsVariant();

  GoogleCloudDialogflowCxV3VersionVariantsVariant.fromJson(core.Map _json) {
    if (_json.containsKey('isControlGroup')) {
      isControlGroup = _json['isControlGroup'] as core.bool;
    }
    if (_json.containsKey('trafficAllocation')) {
      trafficAllocation = (_json['trafficAllocation'] as core.num).toDouble();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (isControlGroup != null) 'isControlGroup': isControlGroup!,
        if (trafficAllocation != null) 'trafficAllocation': trafficAllocation!,
        if (version != null) 'version': version!,
      };
}

/// Description of which voice to use for speech synthesis.
class GoogleCloudDialogflowCxV3VoiceSelectionParams {
  /// The name of the voice.
  ///
  /// If not set, the service will choose a voice based on the other parameters
  /// such as language_code and ssml_gender. For the list of available voices,
  /// please refer to
  /// [Supported voices and languages](https://cloud.google.com/text-to-speech/docs/voices).
  ///
  /// Optional.
  core.String? name;

  /// The preferred gender of the voice.
  ///
  /// If not set, the service will choose a voice based on the other parameters
  /// such as language_code and name. Note that this is only a preference, not
  /// requirement. If a voice of the appropriate gender is not available, the
  /// synthesizer substitutes a voice with a different gender rather than
  /// failing the request.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "SSML_VOICE_GENDER_UNSPECIFIED" : An unspecified gender, which means
  /// that the client doesn't care which gender the selected voice will have.
  /// - "SSML_VOICE_GENDER_MALE" : A male voice.
  /// - "SSML_VOICE_GENDER_FEMALE" : A female voice.
  /// - "SSML_VOICE_GENDER_NEUTRAL" : A gender-neutral voice.
  core.String? ssmlGender;

  GoogleCloudDialogflowCxV3VoiceSelectionParams();

  GoogleCloudDialogflowCxV3VoiceSelectionParams.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('ssmlGender')) {
      ssmlGender = _json['ssmlGender'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (ssmlGender != null) 'ssmlGender': ssmlGender!,
      };
}

/// Webhooks host the developer's business logic.
///
/// During a session, webhooks allow the developer to use the data extracted by
/// Dialogflow's natural language processing to generate dynamic responses,
/// validate collected data, or trigger actions on the backend.
class GoogleCloudDialogflowCxV3Webhook {
  /// Indicates whether the webhook is disabled.
  core.bool? disabled;

  /// The human-readable name of the webhook, unique within the agent.
  ///
  /// Required.
  core.String? displayName;

  /// Configuration for a generic web service.
  GoogleCloudDialogflowCxV3WebhookGenericWebService? genericWebService;

  /// The unique identifier of the webhook.
  ///
  /// Required for the Webhooks.UpdateWebhook method. Webhooks.CreateWebhook
  /// populates the name automatically. Format:
  /// `projects//locations//agents//webhooks/`.
  core.String? name;

  /// Configuration for a
  /// [Service Directory](https://cloud.google.com/service-directory) service.
  GoogleCloudDialogflowCxV3WebhookServiceDirectoryConfig? serviceDirectory;

  /// Webhook execution timeout.
  ///
  /// Execution is considered failed if Dialogflow doesn't receive a response
  /// from webhook at the end of the timeout period. Defaults to 5 seconds,
  /// maximum allowed timeout is 30 seconds.
  core.String? timeout;

  GoogleCloudDialogflowCxV3Webhook();

  GoogleCloudDialogflowCxV3Webhook.fromJson(core.Map _json) {
    if (_json.containsKey('disabled')) {
      disabled = _json['disabled'] as core.bool;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('genericWebService')) {
      genericWebService =
          GoogleCloudDialogflowCxV3WebhookGenericWebService.fromJson(
              _json['genericWebService']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('serviceDirectory')) {
      serviceDirectory =
          GoogleCloudDialogflowCxV3WebhookServiceDirectoryConfig.fromJson(
              _json['serviceDirectory'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeout')) {
      timeout = _json['timeout'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (disabled != null) 'disabled': disabled!,
        if (displayName != null) 'displayName': displayName!,
        if (genericWebService != null)
          'genericWebService': genericWebService!.toJson(),
        if (name != null) 'name': name!,
        if (serviceDirectory != null)
          'serviceDirectory': serviceDirectory!.toJson(),
        if (timeout != null) 'timeout': timeout!,
      };
}

/// Represents configuration for a generic web service.
class GoogleCloudDialogflowCxV3WebhookGenericWebService {
  /// The password for HTTP Basic authentication.
  core.String? password;

  /// The HTTP request headers to send together with webhook requests.
  core.Map<core.String, core.String>? requestHeaders;

  /// The webhook URI for receiving POST requests.
  ///
  /// It must use https protocol.
  ///
  /// Required.
  core.String? uri;

  /// The user name for HTTP Basic authentication.
  core.String? username;

  GoogleCloudDialogflowCxV3WebhookGenericWebService();

  GoogleCloudDialogflowCxV3WebhookGenericWebService.fromJson(core.Map _json) {
    if (_json.containsKey('password')) {
      password = _json['password'] as core.String;
    }
    if (_json.containsKey('requestHeaders')) {
      requestHeaders =
          (_json['requestHeaders'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
    if (_json.containsKey('username')) {
      username = _json['username'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (password != null) 'password': password!,
        if (requestHeaders != null) 'requestHeaders': requestHeaders!,
        if (uri != null) 'uri': uri!,
        if (username != null) 'username': username!,
      };
}

/// The request message for a webhook call.
///
/// The request is sent as a JSON object and the field names will be presented
/// in camel cases.
class GoogleCloudDialogflowCxV3WebhookRequest {
  /// Always present.
  ///
  /// The unique identifier of the DetectIntentResponse that will be returned to
  /// the API caller.
  core.String? detectIntentResponseId;

  /// Always present.
  ///
  /// Information about the fulfillment that triggered this webhook call.
  GoogleCloudDialogflowCxV3WebhookRequestFulfillmentInfo? fulfillmentInfo;

  /// Information about the last matched intent.
  GoogleCloudDialogflowCxV3WebhookRequestIntentInfo? intentInfo;

  /// The language code specified in the original request.
  core.String? languageCode;

  /// The list of rich message responses to present to the user.
  ///
  /// Webhook can choose to append or replace this list in
  /// WebhookResponse.fulfillment_response;
  core.List<GoogleCloudDialogflowCxV3ResponseMessage>? messages;

  /// Information about page status.
  GoogleCloudDialogflowCxV3PageInfo? pageInfo;

  /// Custom data set in QueryParameters.payload.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? payload;

  /// The sentiment analysis result of the current user request.
  ///
  /// The field is filled when sentiment analysis is configured to be enabled
  /// for the request.
  GoogleCloudDialogflowCxV3WebhookRequestSentimentAnalysisResult?
      sentimentAnalysisResult;

  /// Information about session status.
  GoogleCloudDialogflowCxV3SessionInfo? sessionInfo;

  /// If natural language text was provided as input, this field will contain a
  /// copy of the text.
  core.String? text;

  /// If natural language speech audio was provided as input, this field will
  /// contain the transcript for the audio.
  core.String? transcript;

  /// If an event was provided as input, this field will contain the name of the
  /// event.
  core.String? triggerEvent;

  /// If an intent was provided as input, this field will contain a copy of the
  /// intent identifier.
  ///
  /// Format: `projects//locations//agents//intents/`.
  core.String? triggerIntent;

  GoogleCloudDialogflowCxV3WebhookRequest();

  GoogleCloudDialogflowCxV3WebhookRequest.fromJson(core.Map _json) {
    if (_json.containsKey('detectIntentResponseId')) {
      detectIntentResponseId = _json['detectIntentResponseId'] as core.String;
    }
    if (_json.containsKey('fulfillmentInfo')) {
      fulfillmentInfo =
          GoogleCloudDialogflowCxV3WebhookRequestFulfillmentInfo.fromJson(
              _json['fulfillmentInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('intentInfo')) {
      intentInfo = GoogleCloudDialogflowCxV3WebhookRequestIntentInfo.fromJson(
          _json['intentInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('messages')) {
      messages = (_json['messages'] as core.List)
          .map<GoogleCloudDialogflowCxV3ResponseMessage>((value) =>
              GoogleCloudDialogflowCxV3ResponseMessage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('pageInfo')) {
      pageInfo = GoogleCloudDialogflowCxV3PageInfo.fromJson(
          _json['pageInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('payload')) {
      payload = (_json['payload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('sentimentAnalysisResult')) {
      sentimentAnalysisResult =
          GoogleCloudDialogflowCxV3WebhookRequestSentimentAnalysisResult
              .fromJson(_json['sentimentAnalysisResult']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sessionInfo')) {
      sessionInfo = GoogleCloudDialogflowCxV3SessionInfo.fromJson(
          _json['sessionInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
    if (_json.containsKey('transcript')) {
      transcript = _json['transcript'] as core.String;
    }
    if (_json.containsKey('triggerEvent')) {
      triggerEvent = _json['triggerEvent'] as core.String;
    }
    if (_json.containsKey('triggerIntent')) {
      triggerIntent = _json['triggerIntent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (detectIntentResponseId != null)
          'detectIntentResponseId': detectIntentResponseId!,
        if (fulfillmentInfo != null)
          'fulfillmentInfo': fulfillmentInfo!.toJson(),
        if (intentInfo != null) 'intentInfo': intentInfo!.toJson(),
        if (languageCode != null) 'languageCode': languageCode!,
        if (messages != null)
          'messages': messages!.map((value) => value.toJson()).toList(),
        if (pageInfo != null) 'pageInfo': pageInfo!.toJson(),
        if (payload != null) 'payload': payload!,
        if (sentimentAnalysisResult != null)
          'sentimentAnalysisResult': sentimentAnalysisResult!.toJson(),
        if (sessionInfo != null) 'sessionInfo': sessionInfo!.toJson(),
        if (text != null) 'text': text!,
        if (transcript != null) 'transcript': transcript!,
        if (triggerEvent != null) 'triggerEvent': triggerEvent!,
        if (triggerIntent != null) 'triggerIntent': triggerIntent!,
      };
}

/// Represents fulfillment information communicated to the webhook.
class GoogleCloudDialogflowCxV3WebhookRequestFulfillmentInfo {
  /// Always present.
  ///
  /// The tag used to identify which fulfillment is being called.
  core.String? tag;

  GoogleCloudDialogflowCxV3WebhookRequestFulfillmentInfo();

  GoogleCloudDialogflowCxV3WebhookRequestFulfillmentInfo.fromJson(
      core.Map _json) {
    if (_json.containsKey('tag')) {
      tag = _json['tag'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tag != null) 'tag': tag!,
      };
}

/// Represents intent information communicated to the webhook.
class GoogleCloudDialogflowCxV3WebhookRequestIntentInfo {
  /// The confidence of the matched intent.
  ///
  /// Values range from 0.0 (completely uncertain) to 1.0 (completely certain).
  core.double? confidence;

  /// Always present.
  ///
  /// The display name of the last matched intent.
  core.String? displayName;

  /// Always present.
  ///
  /// The unique identifier of the last matched intent. Format:
  /// `projects//locations//agents//intents/`.
  core.String? lastMatchedIntent;

  /// Parameters identified as a result of intent matching.
  ///
  /// This is a map of the name of the identified parameter to the value of the
  /// parameter identified from the user's utterance. All parameters defined in
  /// the matched intent that are identified will be surfaced here.
  core.Map<core.String,
          GoogleCloudDialogflowCxV3WebhookRequestIntentInfoIntentParameterValue>?
      parameters;

  GoogleCloudDialogflowCxV3WebhookRequestIntentInfo();

  GoogleCloudDialogflowCxV3WebhookRequestIntentInfo.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('lastMatchedIntent')) {
      lastMatchedIntent = _json['lastMatchedIntent'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters =
          (_json['parameters'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          GoogleCloudDialogflowCxV3WebhookRequestIntentInfoIntentParameterValue
              .fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (displayName != null) 'displayName': displayName!,
        if (lastMatchedIntent != null) 'lastMatchedIntent': lastMatchedIntent!,
        if (parameters != null)
          'parameters':
              parameters!.map((key, item) => core.MapEntry(key, item.toJson())),
      };
}

/// Represents a value for an intent parameter.
class GoogleCloudDialogflowCxV3WebhookRequestIntentInfoIntentParameterValue {
  /// Always present.
  ///
  /// Original text value extracted from user utterance.
  core.String? originalValue;

  /// Always present.
  ///
  /// Structured value for the parameter extracted from user utterance.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? resolvedValue;

  GoogleCloudDialogflowCxV3WebhookRequestIntentInfoIntentParameterValue();

  GoogleCloudDialogflowCxV3WebhookRequestIntentInfoIntentParameterValue.fromJson(
      core.Map _json) {
    if (_json.containsKey('originalValue')) {
      originalValue = _json['originalValue'] as core.String;
    }
    if (_json.containsKey('resolvedValue')) {
      resolvedValue = _json['resolvedValue'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (originalValue != null) 'originalValue': originalValue!,
        if (resolvedValue != null) 'resolvedValue': resolvedValue!,
      };
}

/// Represents the result of sentiment analysis.
class GoogleCloudDialogflowCxV3WebhookRequestSentimentAnalysisResult {
  /// A non-negative number in the \[0, +inf) range, which represents the
  /// absolute magnitude of sentiment, regardless of score (positive or
  /// negative).
  core.double? magnitude;

  /// Sentiment score between -1.0 (negative sentiment) and 1.0 (positive
  /// sentiment).
  core.double? score;

  GoogleCloudDialogflowCxV3WebhookRequestSentimentAnalysisResult();

  GoogleCloudDialogflowCxV3WebhookRequestSentimentAnalysisResult.fromJson(
      core.Map _json) {
    if (_json.containsKey('magnitude')) {
      magnitude = (_json['magnitude'] as core.num).toDouble();
    }
    if (_json.containsKey('score')) {
      score = (_json['score'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (magnitude != null) 'magnitude': magnitude!,
        if (score != null) 'score': score!,
      };
}

/// The response message for a webhook call.
class GoogleCloudDialogflowCxV3WebhookResponse {
  /// The fulfillment response to send to the user.
  ///
  /// This field can be omitted by the webhook if it does not intend to send any
  /// response to the user.
  GoogleCloudDialogflowCxV3WebhookResponseFulfillmentResponse?
      fulfillmentResponse;

  /// Information about page status.
  ///
  /// This field can be omitted by the webhook if it does not intend to modify
  /// page status.
  GoogleCloudDialogflowCxV3PageInfo? pageInfo;

  /// Value to append directly to QueryResult.webhook_payloads.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? payload;

  /// Information about session status.
  ///
  /// This field can be omitted by the webhook if it does not intend to modify
  /// session status.
  GoogleCloudDialogflowCxV3SessionInfo? sessionInfo;

  /// The target flow to transition to.
  ///
  /// Format: `projects//locations//agents//flows/`.
  core.String? targetFlow;

  /// The target page to transition to.
  ///
  /// Format: `projects//locations//agents//flows//pages/`.
  core.String? targetPage;

  GoogleCloudDialogflowCxV3WebhookResponse();

  GoogleCloudDialogflowCxV3WebhookResponse.fromJson(core.Map _json) {
    if (_json.containsKey('fulfillmentResponse')) {
      fulfillmentResponse =
          GoogleCloudDialogflowCxV3WebhookResponseFulfillmentResponse.fromJson(
              _json['fulfillmentResponse']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pageInfo')) {
      pageInfo = GoogleCloudDialogflowCxV3PageInfo.fromJson(
          _json['pageInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('payload')) {
      payload = (_json['payload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('sessionInfo')) {
      sessionInfo = GoogleCloudDialogflowCxV3SessionInfo.fromJson(
          _json['sessionInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('targetFlow')) {
      targetFlow = _json['targetFlow'] as core.String;
    }
    if (_json.containsKey('targetPage')) {
      targetPage = _json['targetPage'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fulfillmentResponse != null)
          'fulfillmentResponse': fulfillmentResponse!.toJson(),
        if (pageInfo != null) 'pageInfo': pageInfo!.toJson(),
        if (payload != null) 'payload': payload!,
        if (sessionInfo != null) 'sessionInfo': sessionInfo!.toJson(),
        if (targetFlow != null) 'targetFlow': targetFlow!,
        if (targetPage != null) 'targetPage': targetPage!,
      };
}

/// Represents a fulfillment response to the user.
class GoogleCloudDialogflowCxV3WebhookResponseFulfillmentResponse {
  /// Merge behavior for `messages`.
  /// Possible string values are:
  /// - "MERGE_BEHAVIOR_UNSPECIFIED" : Not specified. `APPEND` will be used.
  /// - "APPEND" : `messages` will be appended to the list of messages waiting
  /// to be sent to the user.
  /// - "REPLACE" : `messages` will replace the list of messages waiting to be
  /// sent to the user.
  core.String? mergeBehavior;

  /// The list of rich message responses to present to the user.
  core.List<GoogleCloudDialogflowCxV3ResponseMessage>? messages;

  GoogleCloudDialogflowCxV3WebhookResponseFulfillmentResponse();

  GoogleCloudDialogflowCxV3WebhookResponseFulfillmentResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('mergeBehavior')) {
      mergeBehavior = _json['mergeBehavior'] as core.String;
    }
    if (_json.containsKey('messages')) {
      messages = (_json['messages'] as core.List)
          .map<GoogleCloudDialogflowCxV3ResponseMessage>((value) =>
              GoogleCloudDialogflowCxV3ResponseMessage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mergeBehavior != null) 'mergeBehavior': mergeBehavior!,
        if (messages != null)
          'messages': messages!.map((value) => value.toJson()).toList(),
      };
}

/// Represents configuration for a
/// [Service Directory](https://cloud.google.com/service-directory) service.
class GoogleCloudDialogflowCxV3WebhookServiceDirectoryConfig {
  /// Generic Service configuration of this webhook.
  GoogleCloudDialogflowCxV3WebhookGenericWebService? genericWebService;

  /// The name of
  /// [Service Directory](https://cloud.google.com/service-directory) service.
  ///
  /// Format: `projects//locations//namespaces//services/`. `Location ID` of the
  /// service directory must be the same as the location of the agent.
  ///
  /// Required.
  core.String? service;

  GoogleCloudDialogflowCxV3WebhookServiceDirectoryConfig();

  GoogleCloudDialogflowCxV3WebhookServiceDirectoryConfig.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericWebService')) {
      genericWebService =
          GoogleCloudDialogflowCxV3WebhookGenericWebService.fromJson(
              _json['genericWebService']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('service')) {
      service = _json['service'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericWebService != null)
          'genericWebService': genericWebService!.toJson(),
        if (service != null) 'service': service!,
      };
}

/// Represents the natural speech audio to be processed.
class GoogleCloudDialogflowCxV3beta1AudioInput {
  /// The natural language speech audio to be processed.
  ///
  /// A single request can contain up to 1 minute of speech audio data. The
  /// transcribed text cannot contain more than 256 bytes. For non-streaming
  /// audio detect intent, both `config` and `audio` must be provided. For
  /// streaming audio detect intent, `config` must be provided in the first
  /// request and `audio` must be provided in all following requests.
  core.String? audio;
  core.List<core.int> get audioAsBytes => convert.base64.decode(audio!);

  set audioAsBytes(core.List<core.int> _bytes) {
    audio =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Instructs the speech recognizer how to process the speech audio.
  ///
  /// Required.
  GoogleCloudDialogflowCxV3beta1InputAudioConfig? config;

  GoogleCloudDialogflowCxV3beta1AudioInput();

  GoogleCloudDialogflowCxV3beta1AudioInput.fromJson(core.Map _json) {
    if (_json.containsKey('audio')) {
      audio = _json['audio'] as core.String;
    }
    if (_json.containsKey('config')) {
      config = GoogleCloudDialogflowCxV3beta1InputAudioConfig.fromJson(
          _json['config'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audio != null) 'audio': audio!,
        if (config != null) 'config': config!.toJson(),
      };
}

/// Metadata returned for the TestCases.BatchRunTestCases long running
/// operation.
class GoogleCloudDialogflowCxV3beta1BatchRunTestCasesMetadata {
  /// The test errors.
  core.List<GoogleCloudDialogflowCxV3beta1TestError>? errors;

  GoogleCloudDialogflowCxV3beta1BatchRunTestCasesMetadata();

  GoogleCloudDialogflowCxV3beta1BatchRunTestCasesMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1TestError>((value) =>
              GoogleCloudDialogflowCxV3beta1TestError.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for TestCases.BatchRunTestCases.
class GoogleCloudDialogflowCxV3beta1BatchRunTestCasesResponse {
  /// The test case results.
  ///
  /// The detailed conversation turns are empty in this response.
  core.List<GoogleCloudDialogflowCxV3beta1TestCaseResult>? results;

  GoogleCloudDialogflowCxV3beta1BatchRunTestCasesResponse();

  GoogleCloudDialogflowCxV3beta1BatchRunTestCasesResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('results')) {
      results = (_json['results'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1TestCaseResult>((value) =>
              GoogleCloudDialogflowCxV3beta1TestCaseResult.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (results != null)
          'results': results!.map((value) => value.toJson()).toList(),
      };
}

/// One interaction between a human and virtual agent.
///
/// The human provides some input and the virtual agent provides a response.
class GoogleCloudDialogflowCxV3beta1ConversationTurn {
  /// The user input.
  GoogleCloudDialogflowCxV3beta1ConversationTurnUserInput? userInput;

  /// The virtual agent output.
  GoogleCloudDialogflowCxV3beta1ConversationTurnVirtualAgentOutput?
      virtualAgentOutput;

  GoogleCloudDialogflowCxV3beta1ConversationTurn();

  GoogleCloudDialogflowCxV3beta1ConversationTurn.fromJson(core.Map _json) {
    if (_json.containsKey('userInput')) {
      userInput =
          GoogleCloudDialogflowCxV3beta1ConversationTurnUserInput.fromJson(
              _json['userInput'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('virtualAgentOutput')) {
      virtualAgentOutput =
          GoogleCloudDialogflowCxV3beta1ConversationTurnVirtualAgentOutput
              .fromJson(_json['virtualAgentOutput']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (userInput != null) 'userInput': userInput!.toJson(),
        if (virtualAgentOutput != null)
          'virtualAgentOutput': virtualAgentOutput!.toJson(),
      };
}

/// The input from the human user.
class GoogleCloudDialogflowCxV3beta1ConversationTurnUserInput {
  /// Parameters that need to be injected into the conversation during intent
  /// detection.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? injectedParameters;

  /// Supports text input, event input, dtmf input in the test case.
  GoogleCloudDialogflowCxV3beta1QueryInput? input;

  /// If webhooks should be allowed to trigger in response to the user
  /// utterance.
  ///
  /// Often if parameters are injected, webhooks should not be enabled.
  core.bool? isWebhookEnabled;

  GoogleCloudDialogflowCxV3beta1ConversationTurnUserInput();

  GoogleCloudDialogflowCxV3beta1ConversationTurnUserInput.fromJson(
      core.Map _json) {
    if (_json.containsKey('injectedParameters')) {
      injectedParameters =
          (_json['injectedParameters'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('input')) {
      input = GoogleCloudDialogflowCxV3beta1QueryInput.fromJson(
          _json['input'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('isWebhookEnabled')) {
      isWebhookEnabled = _json['isWebhookEnabled'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (injectedParameters != null)
          'injectedParameters': injectedParameters!,
        if (input != null) 'input': input!.toJson(),
        if (isWebhookEnabled != null) 'isWebhookEnabled': isWebhookEnabled!,
      };
}

/// The output from the virtual agent.
class GoogleCloudDialogflowCxV3beta1ConversationTurnVirtualAgentOutput {
  /// The Page on which the utterance was spoken.
  ///
  /// Only name and displayName will be set.
  GoogleCloudDialogflowCxV3beta1Page? currentPage;

  /// Input only.
  ///
  /// The diagnostic info output for the turn.
  ///
  /// Required.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? diagnosticInfo;

  /// If this is part of a result conversation turn, the list of differences
  /// between the original run and the replay for this output, if any.
  ///
  /// Output only.
  core.List<GoogleCloudDialogflowCxV3beta1TestRunDifference>? differences;

  /// The session parameters available to the bot at this point.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? sessionParameters;

  /// Response error from the agent in the test result.
  ///
  /// If set, other output is empty.
  GoogleRpcStatus? status;

  /// The text responses from the agent for the turn.
  core.List<GoogleCloudDialogflowCxV3beta1ResponseMessageText>? textResponses;

  /// The Intent that triggered the response.
  ///
  /// Only name and displayName will be set.
  GoogleCloudDialogflowCxV3beta1Intent? triggeredIntent;

  GoogleCloudDialogflowCxV3beta1ConversationTurnVirtualAgentOutput();

  GoogleCloudDialogflowCxV3beta1ConversationTurnVirtualAgentOutput.fromJson(
      core.Map _json) {
    if (_json.containsKey('currentPage')) {
      currentPage = GoogleCloudDialogflowCxV3beta1Page.fromJson(
          _json['currentPage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('diagnosticInfo')) {
      diagnosticInfo =
          (_json['diagnosticInfo'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('differences')) {
      differences = (_json['differences'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1TestRunDifference>((value) =>
              GoogleCloudDialogflowCxV3beta1TestRunDifference.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('sessionParameters')) {
      sessionParameters =
          (_json['sessionParameters'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('status')) {
      status = GoogleRpcStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textResponses')) {
      textResponses = (_json['textResponses'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1ResponseMessageText>((value) =>
              GoogleCloudDialogflowCxV3beta1ResponseMessageText.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('triggeredIntent')) {
      triggeredIntent = GoogleCloudDialogflowCxV3beta1Intent.fromJson(
          _json['triggeredIntent'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentPage != null) 'currentPage': currentPage!.toJson(),
        if (diagnosticInfo != null) 'diagnosticInfo': diagnosticInfo!,
        if (differences != null)
          'differences': differences!.map((value) => value.toJson()).toList(),
        if (sessionParameters != null) 'sessionParameters': sessionParameters!,
        if (status != null) 'status': status!.toJson(),
        if (textResponses != null)
          'textResponses':
              textResponses!.map((value) => value.toJson()).toList(),
        if (triggeredIntent != null)
          'triggeredIntent': triggeredIntent!.toJson(),
      };
}

/// Metadata for CreateDocument operation.
class GoogleCloudDialogflowCxV3beta1CreateDocumentOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowCxV3beta1GenericKnowledgeOperationMetadata?
      genericMetadata;

  GoogleCloudDialogflowCxV3beta1CreateDocumentOperationMetadata();

  GoogleCloudDialogflowCxV3beta1CreateDocumentOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowCxV3beta1GenericKnowledgeOperationMetadata
              .fromJson(_json['genericMetadata']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// Metadata associated with the long running operation for
/// Versions.CreateVersion.
class GoogleCloudDialogflowCxV3beta1CreateVersionOperationMetadata {
  /// Name of the created version.
  ///
  /// Format: `projects//locations//agents//flows//versions/`.
  core.String? version;

  GoogleCloudDialogflowCxV3beta1CreateVersionOperationMetadata();

  GoogleCloudDialogflowCxV3beta1CreateVersionOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (version != null) 'version': version!,
      };
}

/// Metadata for DeleteDocument operation.
class GoogleCloudDialogflowCxV3beta1DeleteDocumentOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowCxV3beta1GenericKnowledgeOperationMetadata?
      genericMetadata;

  GoogleCloudDialogflowCxV3beta1DeleteDocumentOperationMetadata();

  GoogleCloudDialogflowCxV3beta1DeleteDocumentOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowCxV3beta1GenericKnowledgeOperationMetadata
              .fromJson(_json['genericMetadata']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// Represents the input for dtmf event.
class GoogleCloudDialogflowCxV3beta1DtmfInput {
  /// The dtmf digits.
  core.String? digits;

  /// The finish digit (if any).
  core.String? finishDigit;

  GoogleCloudDialogflowCxV3beta1DtmfInput();

  GoogleCloudDialogflowCxV3beta1DtmfInput.fromJson(core.Map _json) {
    if (_json.containsKey('digits')) {
      digits = _json['digits'] as core.String;
    }
    if (_json.containsKey('finishDigit')) {
      finishDigit = _json['finishDigit'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (digits != null) 'digits': digits!,
        if (finishDigit != null) 'finishDigit': finishDigit!,
      };
}

/// An event handler specifies an event that can be handled during a session.
///
/// When the specified event happens, the following actions are taken in order:
/// * If there is a `trigger_fulfillment` associated with the event, it will be
/// called. * If there is a `target_page` associated with the event, the session
/// will transition into the specified page. * If there is a `target_flow`
/// associated with the event, the session will transition into the specified
/// flow.
class GoogleCloudDialogflowCxV3beta1EventHandler {
  /// The name of the event to handle.
  ///
  /// Required.
  core.String? event;

  /// The unique identifier of this event handler.
  ///
  /// Output only.
  core.String? name;

  /// The target flow to transition to.
  ///
  /// Format: `projects//locations//agents//flows/`.
  core.String? targetFlow;

  /// The target page to transition to.
  ///
  /// Format: `projects//locations//agents//flows//pages/`.
  core.String? targetPage;

  /// The fulfillment to call when the event occurs.
  ///
  /// Handling webhook errors with a fulfillment enabled with webhook could
  /// cause infinite loop. It is invalid to specify such fulfillment for a
  /// handler handling webhooks.
  GoogleCloudDialogflowCxV3beta1Fulfillment? triggerFulfillment;

  GoogleCloudDialogflowCxV3beta1EventHandler();

  GoogleCloudDialogflowCxV3beta1EventHandler.fromJson(core.Map _json) {
    if (_json.containsKey('event')) {
      event = _json['event'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('targetFlow')) {
      targetFlow = _json['targetFlow'] as core.String;
    }
    if (_json.containsKey('targetPage')) {
      targetPage = _json['targetPage'] as core.String;
    }
    if (_json.containsKey('triggerFulfillment')) {
      triggerFulfillment = GoogleCloudDialogflowCxV3beta1Fulfillment.fromJson(
          _json['triggerFulfillment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (event != null) 'event': event!,
        if (name != null) 'name': name!,
        if (targetFlow != null) 'targetFlow': targetFlow!,
        if (targetPage != null) 'targetPage': targetPage!,
        if (triggerFulfillment != null)
          'triggerFulfillment': triggerFulfillment!.toJson(),
      };
}

/// Represents the event to trigger.
class GoogleCloudDialogflowCxV3beta1EventInput {
  /// Name of the event.
  core.String? event;

  GoogleCloudDialogflowCxV3beta1EventInput();

  GoogleCloudDialogflowCxV3beta1EventInput.fromJson(core.Map _json) {
    if (_json.containsKey('event')) {
      event = _json['event'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (event != null) 'event': event!,
      };
}

/// The response message for Agents.ExportAgent.
class GoogleCloudDialogflowCxV3beta1ExportAgentResponse {
  /// Uncompressed raw byte content for agent.
  core.String? agentContent;
  core.List<core.int> get agentContentAsBytes =>
      convert.base64.decode(agentContent!);

  set agentContentAsBytes(core.List<core.int> _bytes) {
    agentContent =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The URI to a file containing the exported agent.
  ///
  /// This field is populated only if `agent_uri` is specified in
  /// ExportAgentRequest.
  core.String? agentUri;

  GoogleCloudDialogflowCxV3beta1ExportAgentResponse();

  GoogleCloudDialogflowCxV3beta1ExportAgentResponse.fromJson(core.Map _json) {
    if (_json.containsKey('agentContent')) {
      agentContent = _json['agentContent'] as core.String;
    }
    if (_json.containsKey('agentUri')) {
      agentUri = _json['agentUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (agentContent != null) 'agentContent': agentContent!,
        if (agentUri != null) 'agentUri': agentUri!,
      };
}

/// The response message for Flows.ExportFlow.
class GoogleCloudDialogflowCxV3beta1ExportFlowResponse {
  /// Uncompressed raw byte content for flow.
  core.String? flowContent;
  core.List<core.int> get flowContentAsBytes =>
      convert.base64.decode(flowContent!);

  set flowContentAsBytes(core.List<core.int> _bytes) {
    flowContent =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The URI to a file containing the exported flow.
  ///
  /// This field is populated only if `flow_uri` is specified in
  /// ExportFlowRequest.
  core.String? flowUri;

  GoogleCloudDialogflowCxV3beta1ExportFlowResponse();

  GoogleCloudDialogflowCxV3beta1ExportFlowResponse.fromJson(core.Map _json) {
    if (_json.containsKey('flowContent')) {
      flowContent = _json['flowContent'] as core.String;
    }
    if (_json.containsKey('flowUri')) {
      flowUri = _json['flowUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (flowContent != null) 'flowContent': flowContent!,
        if (flowUri != null) 'flowUri': flowUri!,
      };
}

/// Metadata returned for the TestCases.ExportTestCases long running operation.
class GoogleCloudDialogflowCxV3beta1ExportTestCasesMetadata {
  GoogleCloudDialogflowCxV3beta1ExportTestCasesMetadata();

  GoogleCloudDialogflowCxV3beta1ExportTestCasesMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The response message for TestCases.ExportTestCases.
class GoogleCloudDialogflowCxV3beta1ExportTestCasesResponse {
  /// Uncompressed raw byte content for test cases.
  core.String? content;
  core.List<core.int> get contentAsBytes => convert.base64.decode(content!);

  set contentAsBytes(core.List<core.int> _bytes) {
    content =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The URI to a file containing the exported test cases.
  ///
  /// This field is populated only if `gcs_uri` is specified in
  /// ExportTestCasesRequest.
  core.String? gcsUri;

  GoogleCloudDialogflowCxV3beta1ExportTestCasesResponse();

  GoogleCloudDialogflowCxV3beta1ExportTestCasesResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('gcsUri')) {
      gcsUri = _json['gcsUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!,
        if (gcsUri != null) 'gcsUri': gcsUri!,
      };
}

/// A form is a data model that groups related parameters that can be collected
/// from the user.
///
/// The process in which the agent prompts the user and collects parameter
/// values from the user is called form filling. A form can be added to a page.
/// When form filling is done, the filled parameters will be written to the
/// session.
class GoogleCloudDialogflowCxV3beta1Form {
  /// Parameters to collect from the user.
  core.List<GoogleCloudDialogflowCxV3beta1FormParameter>? parameters;

  GoogleCloudDialogflowCxV3beta1Form();

  GoogleCloudDialogflowCxV3beta1Form.fromJson(core.Map _json) {
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1FormParameter>((value) =>
              GoogleCloudDialogflowCxV3beta1FormParameter.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
      };
}

/// Represents a form parameter.
class GoogleCloudDialogflowCxV3beta1FormParameter {
  /// The default value of an optional parameter.
  ///
  /// If the parameter is required, the default value will be ignored.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? defaultValue;

  /// The human-readable name of the parameter, unique within the form.
  ///
  /// Required.
  core.String? displayName;

  /// The entity type of the parameter.
  ///
  /// Format: `projects/-/locations/-/agents/-/entityTypes/` for system entity
  /// types (for example,
  /// `projects/-/locations/-/agents/-/entityTypes/sys.date`), or
  /// `projects//locations//agents//entityTypes/` for developer entity types.
  ///
  /// Required.
  core.String? entityType;

  /// Defines fill behavior for the parameter.
  ///
  /// Required.
  GoogleCloudDialogflowCxV3beta1FormParameterFillBehavior? fillBehavior;

  /// Indicates whether the parameter represents a list of values.
  core.bool? isList;

  /// Indicates whether the parameter content should be redacted in log.
  ///
  /// If redaction is enabled, the parameter content will be replaced by
  /// parameter name during logging. Note: the parameter content is subject to
  /// redaction if either parameter level redaction or entity type level
  /// redaction is enabled.
  core.bool? redact;

  /// Indicates whether the parameter is required.
  ///
  /// Optional parameters will not trigger prompts; however, they are filled if
  /// the user specifies them. Required parameters must be filled before form
  /// filling concludes.
  core.bool? required;

  GoogleCloudDialogflowCxV3beta1FormParameter();

  GoogleCloudDialogflowCxV3beta1FormParameter.fromJson(core.Map _json) {
    if (_json.containsKey('defaultValue')) {
      defaultValue = _json['defaultValue'] as core.Object;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('entityType')) {
      entityType = _json['entityType'] as core.String;
    }
    if (_json.containsKey('fillBehavior')) {
      fillBehavior =
          GoogleCloudDialogflowCxV3beta1FormParameterFillBehavior.fromJson(
              _json['fillBehavior'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('isList')) {
      isList = _json['isList'] as core.bool;
    }
    if (_json.containsKey('redact')) {
      redact = _json['redact'] as core.bool;
    }
    if (_json.containsKey('required')) {
      required = _json['required'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (defaultValue != null) 'defaultValue': defaultValue!,
        if (displayName != null) 'displayName': displayName!,
        if (entityType != null) 'entityType': entityType!,
        if (fillBehavior != null) 'fillBehavior': fillBehavior!.toJson(),
        if (isList != null) 'isList': isList!,
        if (redact != null) 'redact': redact!,
        if (required != null) 'required': required!,
      };
}

/// Configuration for how the filling of a parameter should be handled.
class GoogleCloudDialogflowCxV3beta1FormParameterFillBehavior {
  /// The fulfillment to provide the initial prompt that the agent can present
  /// to the user in order to fill the parameter.
  ///
  /// Required.
  GoogleCloudDialogflowCxV3beta1Fulfillment? initialPromptFulfillment;

  /// The handlers for parameter-level events, used to provide reprompt for the
  /// parameter or transition to a different page/flow.
  ///
  /// The supported events are: * `sys.no-match-`, where N can be from 1 to 6 *
  /// `sys.no-match-default` * `sys.no-input-`, where N can be from 1 to 6 *
  /// `sys.no-input-default` * `sys.invalid-parameter`
  /// `initial_prompt_fulfillment` provides the first prompt for the parameter.
  /// If the user's response does not fill the parameter, a no-match/no-input
  /// event will be triggered, and the fulfillment associated with the
  /// `sys.no-match-1`/`sys.no-input-1` handler (if defined) will be called to
  /// provide a prompt. The `sys.no-match-2`/`sys.no-input-2` handler (if
  /// defined) will respond to the next no-match/no-input event, and so on. A
  /// `sys.no-match-default` or `sys.no-input-default` handler will be used to
  /// handle all following no-match/no-input events after all numbered
  /// no-match/no-input handlers for the parameter are consumed. A
  /// `sys.invalid-parameter` handler can be defined to handle the case where
  /// the parameter values have been `invalidated` by webhook. For example, if
  /// the user's response fill the parameter, however the parameter was
  /// invalidated by webhook, the fulfillment associated with the
  /// `sys.invalid-parameter` handler (if defined) will be called to provide a
  /// prompt. If the event handler for the corresponding event can't be found on
  /// the parameter, `initial_prompt_fulfillment` will be re-prompted.
  core.List<GoogleCloudDialogflowCxV3beta1EventHandler>? repromptEventHandlers;

  GoogleCloudDialogflowCxV3beta1FormParameterFillBehavior();

  GoogleCloudDialogflowCxV3beta1FormParameterFillBehavior.fromJson(
      core.Map _json) {
    if (_json.containsKey('initialPromptFulfillment')) {
      initialPromptFulfillment =
          GoogleCloudDialogflowCxV3beta1Fulfillment.fromJson(
              _json['initialPromptFulfillment']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('repromptEventHandlers')) {
      repromptEventHandlers = (_json['repromptEventHandlers'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1EventHandler>((value) =>
              GoogleCloudDialogflowCxV3beta1EventHandler.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (initialPromptFulfillment != null)
          'initialPromptFulfillment': initialPromptFulfillment!.toJson(),
        if (repromptEventHandlers != null)
          'repromptEventHandlers':
              repromptEventHandlers!.map((value) => value.toJson()).toList(),
      };
}

/// A fulfillment can do one or more of the following actions at the same time:
/// * Generate rich message responses.
///
/// * Set parameter values. * Call the webhook. Fulfillments can be called at
/// various stages in the Page or Form lifecycle. For example, when a
/// DetectIntentRequest drives a session to enter a new page, the page's entry
/// fulfillment can add a static response to the QueryResult in the returning
/// DetectIntentResponse, call the webhook (for example, to load user data from
/// a database), or both.
class GoogleCloudDialogflowCxV3beta1Fulfillment {
  /// Conditional cases for this fulfillment.
  core.List<GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCases>?
      conditionalCases;

  /// The list of rich message responses to present to the user.
  core.List<GoogleCloudDialogflowCxV3beta1ResponseMessage>? messages;

  /// Set parameter values before executing the webhook.
  core.List<GoogleCloudDialogflowCxV3beta1FulfillmentSetParameterAction>?
      setParameterActions;

  /// The tag used by the webhook to identify which fulfillment is being called.
  ///
  /// This field is required if `webhook` is specified.
  core.String? tag;

  /// The webhook to call.
  ///
  /// Format: `projects//locations//agents//webhooks/`.
  core.String? webhook;

  GoogleCloudDialogflowCxV3beta1Fulfillment();

  GoogleCloudDialogflowCxV3beta1Fulfillment.fromJson(core.Map _json) {
    if (_json.containsKey('conditionalCases')) {
      conditionalCases = (_json['conditionalCases'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCases>(
              (value) =>
                  GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCases
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('messages')) {
      messages = (_json['messages'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1ResponseMessage>((value) =>
              GoogleCloudDialogflowCxV3beta1ResponseMessage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('setParameterActions')) {
      setParameterActions = (_json['setParameterActions'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1FulfillmentSetParameterAction>(
              (value) =>
                  GoogleCloudDialogflowCxV3beta1FulfillmentSetParameterAction
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('tag')) {
      tag = _json['tag'] as core.String;
    }
    if (_json.containsKey('webhook')) {
      webhook = _json['webhook'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conditionalCases != null)
          'conditionalCases':
              conditionalCases!.map((value) => value.toJson()).toList(),
        if (messages != null)
          'messages': messages!.map((value) => value.toJson()).toList(),
        if (setParameterActions != null)
          'setParameterActions':
              setParameterActions!.map((value) => value.toJson()).toList(),
        if (tag != null) 'tag': tag!,
        if (webhook != null) 'webhook': webhook!,
      };
}

/// A list of cascading if-else conditions.
///
/// Cases are mutually exclusive. The first one with a matching condition is
/// selected, all the rest ignored.
class GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCases {
  /// A list of cascading if-else conditions.
  core.List<GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCasesCase>?
      cases;

  GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCases();

  GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCases.fromJson(
      core.Map _json) {
    if (_json.containsKey('cases')) {
      cases = (_json['cases'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCasesCase>(
              (value) =>
                  GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCasesCase
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cases != null)
          'cases': cases!.map((value) => value.toJson()).toList(),
      };
}

/// Each case has a Boolean condition.
///
/// When it is evaluated to be True, the corresponding messages will be selected
/// and evaluated recursively.
class GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCasesCase {
  /// A list of case content.
  core.List<
          GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCasesCaseCaseContent>?
      caseContent;

  /// The condition to activate and select this case.
  ///
  /// Empty means the condition is always true. The condition is evaluated
  /// against form parameters or session parameters. See the
  /// [conditions reference](https://cloud.google.com/dialogflow/cx/docs/reference/condition).
  core.String? condition;

  GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCasesCase();

  GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCasesCase.fromJson(
      core.Map _json) {
    if (_json.containsKey('caseContent')) {
      caseContent = (_json['caseContent'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCasesCaseCaseContent>(
              (value) =>
                  GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCasesCaseCaseContent
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('condition')) {
      condition = _json['condition'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (caseContent != null)
          'caseContent': caseContent!.map((value) => value.toJson()).toList(),
        if (condition != null) 'condition': condition!,
      };
}

/// The list of messages or conditional cases to activate for this case.
class GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCasesCaseCaseContent {
  /// Additional cases to be evaluated.
  GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCases? additionalCases;

  /// Returned message.
  GoogleCloudDialogflowCxV3beta1ResponseMessage? message;

  GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCasesCaseCaseContent();

  GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCasesCaseCaseContent.fromJson(
      core.Map _json) {
    if (_json.containsKey('additionalCases')) {
      additionalCases =
          GoogleCloudDialogflowCxV3beta1FulfillmentConditionalCases.fromJson(
              _json['additionalCases'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('message')) {
      message = GoogleCloudDialogflowCxV3beta1ResponseMessage.fromJson(
          _json['message'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additionalCases != null)
          'additionalCases': additionalCases!.toJson(),
        if (message != null) 'message': message!.toJson(),
      };
}

/// Setting a parameter value.
class GoogleCloudDialogflowCxV3beta1FulfillmentSetParameterAction {
  /// Display name of the parameter.
  core.String? parameter;

  /// The new value of the parameter.
  ///
  /// A null value clears the parameter.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? value;

  GoogleCloudDialogflowCxV3beta1FulfillmentSetParameterAction();

  GoogleCloudDialogflowCxV3beta1FulfillmentSetParameterAction.fromJson(
      core.Map _json) {
    if (_json.containsKey('parameter')) {
      parameter = _json['parameter'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parameter != null) 'parameter': parameter!,
        if (value != null) 'value': value!,
      };
}

/// Metadata in google::longrunning::Operation for Knowledge operations.
class GoogleCloudDialogflowCxV3beta1GenericKnowledgeOperationMetadata {
  /// The current state of this operation.
  ///
  /// Required. Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : State unspecified.
  /// - "PENDING" : The operation has been created.
  /// - "RUNNING" : The operation is currently running.
  /// - "DONE" : The operation is done, either cancelled or completed.
  core.String? state;

  GoogleCloudDialogflowCxV3beta1GenericKnowledgeOperationMetadata();

  GoogleCloudDialogflowCxV3beta1GenericKnowledgeOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (state != null) 'state': state!,
      };
}

/// Metadata for ImportDocuments operation.
class GoogleCloudDialogflowCxV3beta1ImportDocumentsOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowCxV3beta1GenericKnowledgeOperationMetadata?
      genericMetadata;

  GoogleCloudDialogflowCxV3beta1ImportDocumentsOperationMetadata();

  GoogleCloudDialogflowCxV3beta1ImportDocumentsOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowCxV3beta1GenericKnowledgeOperationMetadata
              .fromJson(_json['genericMetadata']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// Response message for Documents.ImportDocuments.
class GoogleCloudDialogflowCxV3beta1ImportDocumentsResponse {
  /// Includes details about skipped documents or any other warnings.
  core.List<GoogleRpcStatus>? warnings;

  GoogleCloudDialogflowCxV3beta1ImportDocumentsResponse();

  GoogleCloudDialogflowCxV3beta1ImportDocumentsResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('warnings')) {
      warnings = (_json['warnings'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (warnings != null)
          'warnings': warnings!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for Flows.ImportFlow.
class GoogleCloudDialogflowCxV3beta1ImportFlowResponse {
  /// The unique identifier of the new flow.
  ///
  /// Format: `projects//locations//agents//flows/`.
  core.String? flow;

  GoogleCloudDialogflowCxV3beta1ImportFlowResponse();

  GoogleCloudDialogflowCxV3beta1ImportFlowResponse.fromJson(core.Map _json) {
    if (_json.containsKey('flow')) {
      flow = _json['flow'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (flow != null) 'flow': flow!,
      };
}

/// Metadata returned for the TestCases.ImportTestCases long running operation.
class GoogleCloudDialogflowCxV3beta1ImportTestCasesMetadata {
  /// Errors for failed test cases.
  core.List<GoogleCloudDialogflowCxV3beta1TestCaseError>? errors;

  GoogleCloudDialogflowCxV3beta1ImportTestCasesMetadata();

  GoogleCloudDialogflowCxV3beta1ImportTestCasesMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('errors')) {
      errors = (_json['errors'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1TestCaseError>((value) =>
              GoogleCloudDialogflowCxV3beta1TestCaseError.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (errors != null)
          'errors': errors!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for TestCases.ImportTestCases.
class GoogleCloudDialogflowCxV3beta1ImportTestCasesResponse {
  /// The unique identifiers of the new test cases.
  ///
  /// Format: `projects//locations//agents//testCases/`.
  core.List<core.String>? names;

  GoogleCloudDialogflowCxV3beta1ImportTestCasesResponse();

  GoogleCloudDialogflowCxV3beta1ImportTestCasesResponse.fromJson(
      core.Map _json) {
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

/// Instructs the speech recognizer on how to process the audio content.
class GoogleCloudDialogflowCxV3beta1InputAudioConfig {
  /// Audio encoding of the audio content to process.
  ///
  /// Required.
  /// Possible string values are:
  /// - "AUDIO_ENCODING_UNSPECIFIED" : Not specified.
  /// - "AUDIO_ENCODING_LINEAR_16" : Uncompressed 16-bit signed little-endian
  /// samples (Linear PCM).
  /// - "AUDIO_ENCODING_FLAC" :
  /// \[`FLAC`\](https://xiph.org/flac/documentation.html) (Free Lossless Audio
  /// Codec) is the recommended encoding because it is lossless (therefore
  /// recognition is not compromised) and requires only about half the bandwidth
  /// of `LINEAR16`. `FLAC` stream encoding supports 16-bit and 24-bit samples,
  /// however, not all fields in `STREAMINFO` are supported.
  /// - "AUDIO_ENCODING_MULAW" : 8-bit samples that compand 14-bit audio samples
  /// using G.711 PCMU/mu-law.
  /// - "AUDIO_ENCODING_AMR" : Adaptive Multi-Rate Narrowband codec.
  /// `sample_rate_hertz` must be 8000.
  /// - "AUDIO_ENCODING_AMR_WB" : Adaptive Multi-Rate Wideband codec.
  /// `sample_rate_hertz` must be 16000.
  /// - "AUDIO_ENCODING_OGG_OPUS" : Opus encoded audio frames in Ogg container
  /// ([OggOpus](https://wiki.xiph.org/OggOpus)). `sample_rate_hertz` must be
  /// 16000.
  /// - "AUDIO_ENCODING_SPEEX_WITH_HEADER_BYTE" : Although the use of lossy
  /// encodings is not recommended, if a very low bitrate encoding is required,
  /// `OGG_OPUS` is highly preferred over Speex encoding. The
  /// [Speex](https://speex.org/) encoding supported by Dialogflow API has a
  /// header byte in each block, as in MIME type
  /// `audio/x-speex-with-header-byte`. It is a variant of the RTP Speex
  /// encoding defined in [RFC 5574](https://tools.ietf.org/html/rfc5574). The
  /// stream is a sequence of blocks, one block per RTP packet. Each block
  /// starts with a byte containing the length of the block, in bytes, followed
  /// by one or more frames of Speex data, padded to an integral number of bytes
  /// (octets) as specified in RFC 5574. In other words, each RTP header is
  /// replaced with a single byte containing the block length. Only Speex
  /// wideband is supported. `sample_rate_hertz` must be 16000.
  core.String? audioEncoding;

  /// If `true`, Dialogflow returns SpeechWordInfo in StreamingRecognitionResult
  /// with information about the recognized speech words, e.g. start and end
  /// time offsets.
  ///
  /// If false or unspecified, Speech doesn't return any word-level information.
  ///
  /// Optional.
  core.bool? enableWordInfo;

  /// Which Speech model to select for the given request.
  ///
  /// Select the model best suited to your domain to get best results. If a
  /// model is not explicitly specified, then we auto-select a model based on
  /// the parameters in the InputAudioConfig. If enhanced speech model is
  /// enabled for the agent and an enhanced version of the specified model for
  /// the language does not exist, then the speech is recognized using the
  /// standard version of the specified model. Refer to
  /// [Cloud Speech API documentation](https://cloud.google.com/speech-to-text/docs/basics#select-model)
  /// for more details.
  ///
  /// Optional.
  core.String? model;

  /// Which variant of the Speech model to use.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "SPEECH_MODEL_VARIANT_UNSPECIFIED" : No model variant specified. In this
  /// case Dialogflow defaults to USE_BEST_AVAILABLE.
  /// - "USE_BEST_AVAILABLE" : Use the best available variant of the Speech
  /// model that the caller is eligible for. Please see the
  /// [Dialogflow docs](https://cloud.google.com/dialogflow/docs/data-logging)
  /// for how to make your project eligible for enhanced models.
  /// - "USE_STANDARD" : Use standard model variant even if an enhanced model is
  /// available. See the
  /// [Cloud Speech documentation](https://cloud.google.com/speech-to-text/docs/enhanced-models)
  /// for details about enhanced models.
  /// - "USE_ENHANCED" : Use an enhanced model variant: * If an enhanced variant
  /// does not exist for the given model and request language, Dialogflow falls
  /// back to the standard variant. The
  /// [Cloud Speech documentation](https://cloud.google.com/speech-to-text/docs/enhanced-models)
  /// describes which models have enhanced variants. * If the API caller isn't
  /// eligible for enhanced models, Dialogflow returns an error. Please see the
  /// [Dialogflow docs](https://cloud.google.com/dialogflow/docs/data-logging)
  /// for how to make your project eligible.
  core.String? modelVariant;

  /// A list of strings containing words and phrases that the speech recognizer
  /// should recognize with higher likelihood.
  ///
  /// See
  /// [the Cloud Speech documentation](https://cloud.google.com/speech-to-text/docs/basics#phrase-hints)
  /// for more details.
  ///
  /// Optional.
  core.List<core.String>? phraseHints;

  /// Sample rate (in Hertz) of the audio content sent in the query.
  ///
  /// Refer to
  /// [Cloud Speech API documentation](https://cloud.google.com/speech-to-text/docs/basics)
  /// for more details.
  core.int? sampleRateHertz;

  /// If `false` (default), recognition does not cease until the client closes
  /// the stream.
  ///
  /// If `true`, the recognizer will detect a single spoken utterance in input
  /// audio. Recognition ceases when it detects the audio's voice has stopped or
  /// paused. In this case, once a detected intent is received, the client
  /// should close the stream and start a new request with a new stream as
  /// needed. Note: This setting is relevant only for streaming methods.
  ///
  /// Optional.
  core.bool? singleUtterance;

  GoogleCloudDialogflowCxV3beta1InputAudioConfig();

  GoogleCloudDialogflowCxV3beta1InputAudioConfig.fromJson(core.Map _json) {
    if (_json.containsKey('audioEncoding')) {
      audioEncoding = _json['audioEncoding'] as core.String;
    }
    if (_json.containsKey('enableWordInfo')) {
      enableWordInfo = _json['enableWordInfo'] as core.bool;
    }
    if (_json.containsKey('model')) {
      model = _json['model'] as core.String;
    }
    if (_json.containsKey('modelVariant')) {
      modelVariant = _json['modelVariant'] as core.String;
    }
    if (_json.containsKey('phraseHints')) {
      phraseHints = (_json['phraseHints'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('sampleRateHertz')) {
      sampleRateHertz = _json['sampleRateHertz'] as core.int;
    }
    if (_json.containsKey('singleUtterance')) {
      singleUtterance = _json['singleUtterance'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audioEncoding != null) 'audioEncoding': audioEncoding!,
        if (enableWordInfo != null) 'enableWordInfo': enableWordInfo!,
        if (model != null) 'model': model!,
        if (modelVariant != null) 'modelVariant': modelVariant!,
        if (phraseHints != null) 'phraseHints': phraseHints!,
        if (sampleRateHertz != null) 'sampleRateHertz': sampleRateHertz!,
        if (singleUtterance != null) 'singleUtterance': singleUtterance!,
      };
}

/// An intent represents a user's intent to interact with a conversational
/// agent.
///
/// You can provide information for the Dialogflow API to use to match user
/// input to an intent by adding training phrases (i.e., examples of user input)
/// to your intent.
class GoogleCloudDialogflowCxV3beta1Intent {
  /// Human readable description for better understanding an intent like its
  /// scope, content, result etc.
  ///
  /// Maximum character limit: 140 characters.
  core.String? description;

  /// The human-readable name of the intent, unique within the agent.
  ///
  /// Required.
  core.String? displayName;

  /// Indicates whether this is a fallback intent.
  ///
  /// Currently only default fallback intent is allowed in the agent, which is
  /// added upon agent creation. Adding training phrases to fallback intent is
  /// useful in the case of requests that are mistakenly matched, since training
  /// phrases assigned to fallback intents act as negative examples that
  /// triggers no-match event.
  core.bool? isFallback;

  /// The key/value metadata to label an intent.
  ///
  /// Labels can contain lowercase letters, digits and the symbols '-' and '_'.
  /// International characters are allowed, including letters from unicase
  /// alphabets. Keys must start with a letter. Keys and values can be no longer
  /// than 63 characters and no more than 128 bytes. Prefix "sys-" is reserved
  /// for Dialogflow defined labels. Currently allowed Dialogflow defined labels
  /// include: * sys-head * sys-contextual The above labels do not require
  /// value. "sys-head" means the intent is a head intent. "sys-contextual"
  /// means the intent is a contextual intent.
  core.Map<core.String, core.String>? labels;

  /// The unique identifier of the intent.
  ///
  /// Required for the Intents.UpdateIntent method. Intents.CreateIntent
  /// populates the name automatically. Format:
  /// `projects//locations//agents//intents/`.
  core.String? name;

  /// The collection of parameters associated with the intent.
  core.List<GoogleCloudDialogflowCxV3beta1IntentParameter>? parameters;

  /// The priority of this intent.
  ///
  /// Higher numbers represent higher priorities. - If the supplied value is
  /// unspecified or 0, the service translates the value to 500,000, which
  /// corresponds to the `Normal` priority in the console. - If the supplied
  /// value is negative, the intent is ignored in runtime detect intent
  /// requests.
  core.int? priority;

  /// The collection of training phrases the agent is trained on to identify the
  /// intent.
  core.List<GoogleCloudDialogflowCxV3beta1IntentTrainingPhrase>?
      trainingPhrases;

  GoogleCloudDialogflowCxV3beta1Intent();

  GoogleCloudDialogflowCxV3beta1Intent.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('isFallback')) {
      isFallback = _json['isFallback'] as core.bool;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1IntentParameter>((value) =>
              GoogleCloudDialogflowCxV3beta1IntentParameter.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('priority')) {
      priority = _json['priority'] as core.int;
    }
    if (_json.containsKey('trainingPhrases')) {
      trainingPhrases = (_json['trainingPhrases'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1IntentTrainingPhrase>((value) =>
              GoogleCloudDialogflowCxV3beta1IntentTrainingPhrase.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (isFallback != null) 'isFallback': isFallback!,
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
        if (priority != null) 'priority': priority!,
        if (trainingPhrases != null)
          'trainingPhrases':
              trainingPhrases!.map((value) => value.toJson()).toList(),
      };
}

/// Represents the intent to trigger programmatically rather than as a result of
/// natural language processing.
class GoogleCloudDialogflowCxV3beta1IntentInput {
  /// The unique identifier of the intent.
  ///
  /// Format: `projects//locations//agents//intents/`.
  ///
  /// Required.
  core.String? intent;

  GoogleCloudDialogflowCxV3beta1IntentInput();

  GoogleCloudDialogflowCxV3beta1IntentInput.fromJson(core.Map _json) {
    if (_json.containsKey('intent')) {
      intent = _json['intent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (intent != null) 'intent': intent!,
      };
}

/// Represents an intent parameter.
class GoogleCloudDialogflowCxV3beta1IntentParameter {
  /// The entity type of the parameter.
  ///
  /// Format: `projects/-/locations/-/agents/-/entityTypes/` for system entity
  /// types (for example,
  /// `projects/-/locations/-/agents/-/entityTypes/sys.date`), or
  /// `projects//locations//agents//entityTypes/` for developer entity types.
  ///
  /// Required.
  core.String? entityType;

  /// The unique identifier of the parameter.
  ///
  /// This field is used by training phrases to annotate their parts.
  ///
  /// Required.
  core.String? id;

  /// Indicates whether the parameter represents a list of values.
  core.bool? isList;

  /// Indicates whether the parameter content should be redacted in log.
  ///
  /// If redaction is enabled, the parameter content will be replaced by
  /// parameter name during logging. Note: the parameter content is subject to
  /// redaction if either parameter level redaction or entity type level
  /// redaction is enabled.
  core.bool? redact;

  GoogleCloudDialogflowCxV3beta1IntentParameter();

  GoogleCloudDialogflowCxV3beta1IntentParameter.fromJson(core.Map _json) {
    if (_json.containsKey('entityType')) {
      entityType = _json['entityType'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('isList')) {
      isList = _json['isList'] as core.bool;
    }
    if (_json.containsKey('redact')) {
      redact = _json['redact'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entityType != null) 'entityType': entityType!,
        if (id != null) 'id': id!,
        if (isList != null) 'isList': isList!,
        if (redact != null) 'redact': redact!,
      };
}

/// Represents an example that the agent is trained on to identify the intent.
class GoogleCloudDialogflowCxV3beta1IntentTrainingPhrase {
  /// The unique identifier of the training phrase.
  ///
  /// Output only.
  core.String? id;

  /// The ordered list of training phrase parts.
  ///
  /// The parts are concatenated in order to form the training phrase. Note: The
  /// API does not automatically annotate training phrases like the Dialogflow
  /// Console does. Note: Do not forget to include whitespace at part
  /// boundaries, so the training phrase is well formatted when the parts are
  /// concatenated. If the training phrase does not need to be annotated with
  /// parameters, you just need a single part with only the Part.text field set.
  /// If you want to annotate the training phrase, you must create multiple
  /// parts, where the fields of each part are populated in one of two ways: -
  /// `Part.text` is set to a part of the phrase that has no parameters. -
  /// `Part.text` is set to a part of the phrase that you want to annotate, and
  /// the `parameter_id` field is set.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowCxV3beta1IntentTrainingPhrasePart>? parts;

  /// Indicates how many times this example was added to the intent.
  core.int? repeatCount;

  GoogleCloudDialogflowCxV3beta1IntentTrainingPhrase();

  GoogleCloudDialogflowCxV3beta1IntentTrainingPhrase.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('parts')) {
      parts = (_json['parts'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1IntentTrainingPhrasePart>(
              (value) => GoogleCloudDialogflowCxV3beta1IntentTrainingPhrasePart
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('repeatCount')) {
      repeatCount = _json['repeatCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (parts != null)
          'parts': parts!.map((value) => value.toJson()).toList(),
        if (repeatCount != null) 'repeatCount': repeatCount!,
      };
}

/// Represents a part of a training phrase.
class GoogleCloudDialogflowCxV3beta1IntentTrainingPhrasePart {
  /// The parameter used to annotate this part of the training phrase.
  ///
  /// This field is required for annotated parts of the training phrase.
  core.String? parameterId;

  /// The text for this part.
  ///
  /// Required.
  core.String? text;

  GoogleCloudDialogflowCxV3beta1IntentTrainingPhrasePart();

  GoogleCloudDialogflowCxV3beta1IntentTrainingPhrasePart.fromJson(
      core.Map _json) {
    if (_json.containsKey('parameterId')) {
      parameterId = _json['parameterId'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parameterId != null) 'parameterId': parameterId!,
        if (text != null) 'text': text!,
      };
}

/// A Dialogflow CX conversation (session) can be described and visualized as a
/// state machine.
///
/// The states of a CX session are represented by pages. For each flow, you
/// define many pages, where your combined pages can handle a complete
/// conversation on the topics the flow is designed for. At any given moment,
/// exactly one page is the current page, the current page is considered active,
/// and the flow associated with that page is considered active. Every flow has
/// a special start page. When a flow initially becomes active, the start page
/// page becomes the current page. For each conversational turn, the current
/// page will either stay the same or transition to another page. You configure
/// each page to collect information from the end-user that is relevant for the
/// conversational state represented by the page. For more information, see the
/// [Page guide](https://cloud.google.com/dialogflow/cx/docs/concept/page).
class GoogleCloudDialogflowCxV3beta1Page {
  /// The human-readable name of the page, unique within the agent.
  ///
  /// Required.
  core.String? displayName;

  /// The fulfillment to call when the session is entering the page.
  GoogleCloudDialogflowCxV3beta1Fulfillment? entryFulfillment;

  /// Handlers associated with the page to handle events such as webhook errors,
  /// no match or no input.
  core.List<GoogleCloudDialogflowCxV3beta1EventHandler>? eventHandlers;

  /// The form associated with the page, used for collecting parameters relevant
  /// to the page.
  GoogleCloudDialogflowCxV3beta1Form? form;

  /// The unique identifier of the page.
  ///
  /// Required for the Pages.UpdatePage method. Pages.CreatePage populates the
  /// name automatically. Format: `projects//locations//agents//flows//pages/`.
  core.String? name;

  /// Ordered list of `TransitionRouteGroups` associated with the page.
  ///
  /// Transition route groups must be unique within a page. * If multiple
  /// transition routes within a page scope refer to the same intent, then the
  /// precedence order is: page's transition route -> page's transition route
  /// group -> flow's transition routes. * If multiple transition route groups
  /// within a page contain the same intent, then the first group in the ordered
  /// list takes precedence.
  /// Format:`projects//locations//agents//flows//transitionRouteGroups/`.
  core.List<core.String>? transitionRouteGroups;

  /// A list of transitions for the transition rules of this page.
  ///
  /// They route the conversation to another page in the same flow, or another
  /// flow. When we are in a certain page, the TransitionRoutes are evalauted in
  /// the following order: * TransitionRoutes defined in the page with intent
  /// specified. * TransitionRoutes defined in the transition route groups with
  /// intent specified. * TransitionRoutes defined in flow with intent
  /// specified. * TransitionRoutes defined in the transition route groups with
  /// intent specified. * TransitionRoutes defined in the page with only
  /// condition specified. * TransitionRoutes defined in the transition route
  /// groups with only condition specified.
  core.List<GoogleCloudDialogflowCxV3beta1TransitionRoute>? transitionRoutes;

  GoogleCloudDialogflowCxV3beta1Page();

  GoogleCloudDialogflowCxV3beta1Page.fromJson(core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('entryFulfillment')) {
      entryFulfillment = GoogleCloudDialogflowCxV3beta1Fulfillment.fromJson(
          _json['entryFulfillment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('eventHandlers')) {
      eventHandlers = (_json['eventHandlers'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1EventHandler>((value) =>
              GoogleCloudDialogflowCxV3beta1EventHandler.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('form')) {
      form = GoogleCloudDialogflowCxV3beta1Form.fromJson(
          _json['form'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('transitionRouteGroups')) {
      transitionRouteGroups = (_json['transitionRouteGroups'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('transitionRoutes')) {
      transitionRoutes = (_json['transitionRoutes'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1TransitionRoute>((value) =>
              GoogleCloudDialogflowCxV3beta1TransitionRoute.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (entryFulfillment != null)
          'entryFulfillment': entryFulfillment!.toJson(),
        if (eventHandlers != null)
          'eventHandlers':
              eventHandlers!.map((value) => value.toJson()).toList(),
        if (form != null) 'form': form!.toJson(),
        if (name != null) 'name': name!,
        if (transitionRouteGroups != null)
          'transitionRouteGroups': transitionRouteGroups!,
        if (transitionRoutes != null)
          'transitionRoutes':
              transitionRoutes!.map((value) => value.toJson()).toList(),
      };
}

/// Represents page information communicated to and from the webhook.
class GoogleCloudDialogflowCxV3beta1PageInfo {
  /// Always present for WebhookRequest.
  ///
  /// Ignored for WebhookResponse. The unique identifier of the current page.
  /// Format: `projects//locations//agents//flows//pages/`.
  core.String? currentPage;

  /// Optional for both WebhookRequest and WebhookResponse.
  ///
  /// Information about the form.
  GoogleCloudDialogflowCxV3beta1PageInfoFormInfo? formInfo;

  GoogleCloudDialogflowCxV3beta1PageInfo();

  GoogleCloudDialogflowCxV3beta1PageInfo.fromJson(core.Map _json) {
    if (_json.containsKey('currentPage')) {
      currentPage = _json['currentPage'] as core.String;
    }
    if (_json.containsKey('formInfo')) {
      formInfo = GoogleCloudDialogflowCxV3beta1PageInfoFormInfo.fromJson(
          _json['formInfo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentPage != null) 'currentPage': currentPage!,
        if (formInfo != null) 'formInfo': formInfo!.toJson(),
      };
}

/// Represents form information.
class GoogleCloudDialogflowCxV3beta1PageInfoFormInfo {
  /// Optional for both WebhookRequest and WebhookResponse.
  ///
  /// The parameters contained in the form. Note that the webhook cannot add or
  /// remove any form parameter.
  core.List<GoogleCloudDialogflowCxV3beta1PageInfoFormInfoParameterInfo>?
      parameterInfo;

  GoogleCloudDialogflowCxV3beta1PageInfoFormInfo();

  GoogleCloudDialogflowCxV3beta1PageInfoFormInfo.fromJson(core.Map _json) {
    if (_json.containsKey('parameterInfo')) {
      parameterInfo = (_json['parameterInfo'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1PageInfoFormInfoParameterInfo>(
              (value) =>
                  GoogleCloudDialogflowCxV3beta1PageInfoFormInfoParameterInfo
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parameterInfo != null)
          'parameterInfo':
              parameterInfo!.map((value) => value.toJson()).toList(),
      };
}

/// Represents parameter information.
class GoogleCloudDialogflowCxV3beta1PageInfoFormInfoParameterInfo {
  /// Always present for WebhookRequest.
  ///
  /// Required for WebhookResponse. The human-readable name of the parameter,
  /// unique within the form. This field cannot be modified by the webhook.
  core.String? displayName;

  /// Optional for WebhookRequest.
  ///
  /// Ignored for WebhookResponse. Indicates if the parameter value was just
  /// collected on the last conversation turn.
  core.bool? justCollected;

  /// Optional for both WebhookRequest and WebhookResponse.
  ///
  /// Indicates whether the parameter is required. Optional parameters will not
  /// trigger prompts; however, they are filled if the user specifies them.
  /// Required parameters must be filled before form filling concludes.
  core.bool? required;

  /// Always present for WebhookRequest.
  ///
  /// Required for WebhookResponse. The state of the parameter. This field can
  /// be set to INVALID by the webhook to invalidate the parameter; other values
  /// set by the webhook will be ignored.
  /// Possible string values are:
  /// - "PARAMETER_STATE_UNSPECIFIED" : Not specified. This value should be
  /// never used.
  /// - "EMPTY" : Indicates that the parameter does not have a value.
  /// - "INVALID" : Indicates that the parameter value is invalid. This field
  /// can be used by the webhook to invalidate the parameter and ask the server
  /// to collect it from the user again.
  /// - "FILLED" : Indicates that the parameter has a value.
  core.String? state;

  /// Optional for both WebhookRequest and WebhookResponse.
  ///
  /// The value of the parameter. This field can be set by the webhook to change
  /// the parameter value.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? value;

  GoogleCloudDialogflowCxV3beta1PageInfoFormInfoParameterInfo();

  GoogleCloudDialogflowCxV3beta1PageInfoFormInfoParameterInfo.fromJson(
      core.Map _json) {
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('justCollected')) {
      justCollected = _json['justCollected'] as core.bool;
    }
    if (_json.containsKey('required')) {
      required = _json['required'] as core.bool;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName!,
        if (justCollected != null) 'justCollected': justCollected!,
        if (required != null) 'required': required!,
        if (state != null) 'state': state!,
        if (value != null) 'value': value!,
      };
}

/// Represents the query input.
///
/// It can contain one of: 1. A conversational query in the form of text. 2. An
/// intent query that specifies which intent to trigger. 3. Natural language
/// speech audio to be processed. 4. An event to be triggered.
class GoogleCloudDialogflowCxV3beta1QueryInput {
  /// The natural language speech audio to be processed.
  GoogleCloudDialogflowCxV3beta1AudioInput? audio;

  /// The DTMF event to be handled.
  GoogleCloudDialogflowCxV3beta1DtmfInput? dtmf;

  /// The event to be triggered.
  GoogleCloudDialogflowCxV3beta1EventInput? event;

  /// The intent to be triggered.
  GoogleCloudDialogflowCxV3beta1IntentInput? intent;

  /// The language of the input.
  ///
  /// See
  /// [Language Support](https://cloud.google.com/dialogflow/cx/docs/reference/language)
  /// for a list of the currently supported language codes. Note that queries in
  /// the same session do not necessarily need to specify the same language.
  ///
  /// Required.
  core.String? languageCode;

  /// The natural language text to be processed.
  GoogleCloudDialogflowCxV3beta1TextInput? text;

  GoogleCloudDialogflowCxV3beta1QueryInput();

  GoogleCloudDialogflowCxV3beta1QueryInput.fromJson(core.Map _json) {
    if (_json.containsKey('audio')) {
      audio = GoogleCloudDialogflowCxV3beta1AudioInput.fromJson(
          _json['audio'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('dtmf')) {
      dtmf = GoogleCloudDialogflowCxV3beta1DtmfInput.fromJson(
          _json['dtmf'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('event')) {
      event = GoogleCloudDialogflowCxV3beta1EventInput.fromJson(
          _json['event'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('intent')) {
      intent = GoogleCloudDialogflowCxV3beta1IntentInput.fromJson(
          _json['intent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = GoogleCloudDialogflowCxV3beta1TextInput.fromJson(
          _json['text'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audio != null) 'audio': audio!.toJson(),
        if (dtmf != null) 'dtmf': dtmf!.toJson(),
        if (event != null) 'event': event!.toJson(),
        if (intent != null) 'intent': intent!.toJson(),
        if (languageCode != null) 'languageCode': languageCode!,
        if (text != null) 'text': text!.toJson(),
      };
}

/// Metadata for ReloadDocument operation.
class GoogleCloudDialogflowCxV3beta1ReloadDocumentOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowCxV3beta1GenericKnowledgeOperationMetadata?
      genericMetadata;

  GoogleCloudDialogflowCxV3beta1ReloadDocumentOperationMetadata();

  GoogleCloudDialogflowCxV3beta1ReloadDocumentOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowCxV3beta1GenericKnowledgeOperationMetadata
              .fromJson(_json['genericMetadata']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// Represents a response message that can be returned by a conversational
/// agent.
///
/// Response messages are also used for output audio synthesis. The approach is
/// as follows: * If at least one OutputAudioText response is present, then all
/// OutputAudioText responses are linearly concatenated, and the result is used
/// for output audio synthesis. * If the OutputAudioText responses are a mixture
/// of text and SSML, then the concatenated result is treated as SSML;
/// otherwise, the result is treated as either text or SSML as appropriate. The
/// agent designer should ideally use either text or SSML consistently
/// throughout the bot design. * Otherwise, all Text responses are linearly
/// concatenated, and the result is used for output audio synthesis. This
/// approach allows for more sophisticated user experience scenarios, where the
/// text displayed to the user may differ from what is heard.
class GoogleCloudDialogflowCxV3beta1ResponseMessage {
  /// Indicates that the conversation succeeded.
  GoogleCloudDialogflowCxV3beta1ResponseMessageConversationSuccess?
      conversationSuccess;

  /// A signal that indicates the interaction with the Dialogflow agent has
  /// ended.
  ///
  /// This message is generated by Dialogflow only when the conversation reaches
  /// `END_SESSION` page. It is not supposed to be defined by the user. It's
  /// guaranteed that there is at most one such message in each response.
  ///
  /// Output only.
  GoogleCloudDialogflowCxV3beta1ResponseMessageEndInteraction? endInteraction;

  /// Hands off conversation to a human agent.
  GoogleCloudDialogflowCxV3beta1ResponseMessageLiveAgentHandoff?
      liveAgentHandoff;

  /// An audio response message composed of both the synthesized Dialogflow
  /// agent responses and responses defined via play_audio.
  ///
  /// This message is generated by Dialogflow only and not supposed to be
  /// defined by the user.
  ///
  /// Output only.
  GoogleCloudDialogflowCxV3beta1ResponseMessageMixedAudio? mixedAudio;

  /// A text or ssml response that is preferentially used for TTS output audio
  /// synthesis, as described in the comment on the ResponseMessage message.
  GoogleCloudDialogflowCxV3beta1ResponseMessageOutputAudioText? outputAudioText;

  /// Returns a response containing a custom, platform-specific payload.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? payload;

  /// Signal that the client should play an audio clip hosted at a
  /// client-specific URI.
  ///
  /// Dialogflow uses this to construct mixed_audio. However, Dialogflow itself
  /// does not try to read or process the URI in any way.
  GoogleCloudDialogflowCxV3beta1ResponseMessagePlayAudio? playAudio;

  /// Returns a text response.
  GoogleCloudDialogflowCxV3beta1ResponseMessageText? text;

  GoogleCloudDialogflowCxV3beta1ResponseMessage();

  GoogleCloudDialogflowCxV3beta1ResponseMessage.fromJson(core.Map _json) {
    if (_json.containsKey('conversationSuccess')) {
      conversationSuccess =
          GoogleCloudDialogflowCxV3beta1ResponseMessageConversationSuccess
              .fromJson(_json['conversationSuccess']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('endInteraction')) {
      endInteraction =
          GoogleCloudDialogflowCxV3beta1ResponseMessageEndInteraction.fromJson(
              _json['endInteraction'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('liveAgentHandoff')) {
      liveAgentHandoff =
          GoogleCloudDialogflowCxV3beta1ResponseMessageLiveAgentHandoff
              .fromJson(_json['liveAgentHandoff']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mixedAudio')) {
      mixedAudio =
          GoogleCloudDialogflowCxV3beta1ResponseMessageMixedAudio.fromJson(
              _json['mixedAudio'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('outputAudioText')) {
      outputAudioText =
          GoogleCloudDialogflowCxV3beta1ResponseMessageOutputAudioText.fromJson(
              _json['outputAudioText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('payload')) {
      payload = (_json['payload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('playAudio')) {
      playAudio =
          GoogleCloudDialogflowCxV3beta1ResponseMessagePlayAudio.fromJson(
              _json['playAudio'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = GoogleCloudDialogflowCxV3beta1ResponseMessageText.fromJson(
          _json['text'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conversationSuccess != null)
          'conversationSuccess': conversationSuccess!.toJson(),
        if (endInteraction != null) 'endInteraction': endInteraction!.toJson(),
        if (liveAgentHandoff != null)
          'liveAgentHandoff': liveAgentHandoff!.toJson(),
        if (mixedAudio != null) 'mixedAudio': mixedAudio!.toJson(),
        if (outputAudioText != null)
          'outputAudioText': outputAudioText!.toJson(),
        if (payload != null) 'payload': payload!,
        if (playAudio != null) 'playAudio': playAudio!.toJson(),
        if (text != null) 'text': text!.toJson(),
      };
}

/// Indicates that the conversation succeeded, i.e., the bot handled the issue
/// that the customer talked to it about.
///
/// Dialogflow only uses this to determine which conversations should be counted
/// as successful and doesn't process the metadata in this message in any way.
/// Note that Dialogflow also considers conversations that get to the
/// conversation end page as successful even if they don't return
/// ConversationSuccess. You may set this, for example: * In the
/// entry_fulfillment of a Page if entering the page indicates that the
/// conversation succeeded. * In a webhook response when you determine that you
/// handled the customer issue.
class GoogleCloudDialogflowCxV3beta1ResponseMessageConversationSuccess {
  /// Custom metadata.
  ///
  /// Dialogflow doesn't impose any structure on this.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  GoogleCloudDialogflowCxV3beta1ResponseMessageConversationSuccess();

  GoogleCloudDialogflowCxV3beta1ResponseMessageConversationSuccess.fromJson(
      core.Map _json) {
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (metadata != null) 'metadata': metadata!,
      };
}

/// Indicates that interaction with the Dialogflow agent has ended.
///
/// This message is generated by Dialogflow only and not supposed to be defined
/// by the user.
class GoogleCloudDialogflowCxV3beta1ResponseMessageEndInteraction {
  GoogleCloudDialogflowCxV3beta1ResponseMessageEndInteraction();

  GoogleCloudDialogflowCxV3beta1ResponseMessageEndInteraction.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Indicates that the conversation should be handed off to a live agent.
///
/// Dialogflow only uses this to determine which conversations were handed off
/// to a human agent for measurement purposes. What else to do with this signal
/// is up to you and your handoff procedures. You may set this, for example: *
/// In the entry_fulfillment of a Page if entering the page indicates something
/// went extremely wrong in the conversation. * In a webhook response when you
/// determine that the customer issue can only be handled by a human.
class GoogleCloudDialogflowCxV3beta1ResponseMessageLiveAgentHandoff {
  /// Custom metadata for your handoff procedure.
  ///
  /// Dialogflow doesn't impose any structure on this.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  GoogleCloudDialogflowCxV3beta1ResponseMessageLiveAgentHandoff();

  GoogleCloudDialogflowCxV3beta1ResponseMessageLiveAgentHandoff.fromJson(
      core.Map _json) {
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (metadata != null) 'metadata': metadata!,
      };
}

/// Represents an audio message that is composed of both segments synthesized
/// from the Dialogflow agent prompts and ones hosted externally at the
/// specified URIs.
///
/// The external URIs are specified via play_audio. This message is generated by
/// Dialogflow only and not supposed to be defined by the user.
class GoogleCloudDialogflowCxV3beta1ResponseMessageMixedAudio {
  /// Segments this audio response is composed of.
  core.List<GoogleCloudDialogflowCxV3beta1ResponseMessageMixedAudioSegment>?
      segments;

  GoogleCloudDialogflowCxV3beta1ResponseMessageMixedAudio();

  GoogleCloudDialogflowCxV3beta1ResponseMessageMixedAudio.fromJson(
      core.Map _json) {
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1ResponseMessageMixedAudioSegment>(
              (value) =>
                  GoogleCloudDialogflowCxV3beta1ResponseMessageMixedAudioSegment
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
      };
}

/// Represents one segment of audio.
class GoogleCloudDialogflowCxV3beta1ResponseMessageMixedAudioSegment {
  /// Whether the playback of this segment can be interrupted by the end user's
  /// speech and the client should then start the next Dialogflow request.
  ///
  /// Output only.
  core.bool? allowPlaybackInterruption;

  /// Raw audio synthesized from the Dialogflow agent's response using the
  /// output config specified in the request.
  core.String? audio;
  core.List<core.int> get audioAsBytes => convert.base64.decode(audio!);

  set audioAsBytes(core.List<core.int> _bytes) {
    audio =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Client-specific URI that points to an audio clip accessible to the client.
  ///
  /// Dialogflow does not impose any validation on it.
  core.String? uri;

  GoogleCloudDialogflowCxV3beta1ResponseMessageMixedAudioSegment();

  GoogleCloudDialogflowCxV3beta1ResponseMessageMixedAudioSegment.fromJson(
      core.Map _json) {
    if (_json.containsKey('allowPlaybackInterruption')) {
      allowPlaybackInterruption =
          _json['allowPlaybackInterruption'] as core.bool;
    }
    if (_json.containsKey('audio')) {
      audio = _json['audio'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowPlaybackInterruption != null)
          'allowPlaybackInterruption': allowPlaybackInterruption!,
        if (audio != null) 'audio': audio!,
        if (uri != null) 'uri': uri!,
      };
}

/// A text or ssml response that is preferentially used for TTS output audio
/// synthesis, as described in the comment on the ResponseMessage message.
class GoogleCloudDialogflowCxV3beta1ResponseMessageOutputAudioText {
  /// Whether the playback of this message can be interrupted by the end user's
  /// speech and the client can then starts the next Dialogflow request.
  ///
  /// Output only.
  core.bool? allowPlaybackInterruption;

  /// The SSML text to be synthesized.
  ///
  /// For more information, see \[SSML\](/speech/text-to-speech/docs/ssml).
  core.String? ssml;

  /// The raw text to be synthesized.
  core.String? text;

  GoogleCloudDialogflowCxV3beta1ResponseMessageOutputAudioText();

  GoogleCloudDialogflowCxV3beta1ResponseMessageOutputAudioText.fromJson(
      core.Map _json) {
    if (_json.containsKey('allowPlaybackInterruption')) {
      allowPlaybackInterruption =
          _json['allowPlaybackInterruption'] as core.bool;
    }
    if (_json.containsKey('ssml')) {
      ssml = _json['ssml'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowPlaybackInterruption != null)
          'allowPlaybackInterruption': allowPlaybackInterruption!,
        if (ssml != null) 'ssml': ssml!,
        if (text != null) 'text': text!,
      };
}

/// Specifies an audio clip to be played by the client as part of the response.
class GoogleCloudDialogflowCxV3beta1ResponseMessagePlayAudio {
  /// Whether the playback of this message can be interrupted by the end user's
  /// speech and the client can then starts the next Dialogflow request.
  ///
  /// Output only.
  core.bool? allowPlaybackInterruption;

  /// URI of the audio clip.
  ///
  /// Dialogflow does not impose any validation on this value. It is specific to
  /// the client that reads it.
  ///
  /// Required.
  core.String? audioUri;

  GoogleCloudDialogflowCxV3beta1ResponseMessagePlayAudio();

  GoogleCloudDialogflowCxV3beta1ResponseMessagePlayAudio.fromJson(
      core.Map _json) {
    if (_json.containsKey('allowPlaybackInterruption')) {
      allowPlaybackInterruption =
          _json['allowPlaybackInterruption'] as core.bool;
    }
    if (_json.containsKey('audioUri')) {
      audioUri = _json['audioUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowPlaybackInterruption != null)
          'allowPlaybackInterruption': allowPlaybackInterruption!,
        if (audioUri != null) 'audioUri': audioUri!,
      };
}

/// The text response message.
class GoogleCloudDialogflowCxV3beta1ResponseMessageText {
  /// Whether the playback of this message can be interrupted by the end user's
  /// speech and the client can then starts the next Dialogflow request.
  ///
  /// Output only.
  core.bool? allowPlaybackInterruption;

  /// A collection of text responses.
  ///
  /// Required.
  core.List<core.String>? text;

  GoogleCloudDialogflowCxV3beta1ResponseMessageText();

  GoogleCloudDialogflowCxV3beta1ResponseMessageText.fromJson(core.Map _json) {
    if (_json.containsKey('allowPlaybackInterruption')) {
      allowPlaybackInterruption =
          _json['allowPlaybackInterruption'] as core.bool;
    }
    if (_json.containsKey('text')) {
      text = (_json['text'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowPlaybackInterruption != null)
          'allowPlaybackInterruption': allowPlaybackInterruption!,
        if (text != null) 'text': text!,
      };
}

/// Metadata returned for the TestCases.RunTestCase long running operation.
class GoogleCloudDialogflowCxV3beta1RunTestCaseMetadata {
  GoogleCloudDialogflowCxV3beta1RunTestCaseMetadata();

  GoogleCloudDialogflowCxV3beta1RunTestCaseMetadata.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The response message for TestCases.RunTestCase.
class GoogleCloudDialogflowCxV3beta1RunTestCaseResponse {
  /// The result.
  GoogleCloudDialogflowCxV3beta1TestCaseResult? result;

  GoogleCloudDialogflowCxV3beta1RunTestCaseResponse();

  GoogleCloudDialogflowCxV3beta1RunTestCaseResponse.fromJson(core.Map _json) {
    if (_json.containsKey('result')) {
      result = GoogleCloudDialogflowCxV3beta1TestCaseResult.fromJson(
          _json['result'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (result != null) 'result': result!.toJson(),
      };
}

/// Represents session information communicated to and from the webhook.
class GoogleCloudDialogflowCxV3beta1SessionInfo {
  /// Optional for WebhookRequest.
  ///
  /// Optional for WebhookResponse. All parameters collected from forms and
  /// intents during the session. Parameters can be created, updated, or removed
  /// by the webhook. To remove a parameter from the session, the webhook should
  /// explicitly set the parameter value to null in WebhookResponse. The map is
  /// keyed by parameters' display names.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? parameters;

  /// Always present for WebhookRequest.
  ///
  /// Ignored for WebhookResponse. The unique identifier of the session. This
  /// field can be used by the webhook to identify a session. Format:
  /// `projects//locations//agents//sessions/` or
  /// `projects//locations//agents//environments//sessions/` if environment is
  /// specified.
  core.String? session;

  GoogleCloudDialogflowCxV3beta1SessionInfo();

  GoogleCloudDialogflowCxV3beta1SessionInfo.fromJson(core.Map _json) {
    if (_json.containsKey('parameters')) {
      parameters =
          (_json['parameters'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('session')) {
      session = _json['session'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (parameters != null) 'parameters': parameters!,
        if (session != null) 'session': session!,
      };
}

/// Represents a test case.
class GoogleCloudDialogflowCxV3beta1TestCase {
  /// When the test was created.
  ///
  /// Output only.
  core.String? creationTime;

  /// The human-readable name of the test case, unique within the agent.
  ///
  /// Limit of 200 characters.
  ///
  /// Required.
  core.String? displayName;

  /// The latest test result.
  GoogleCloudDialogflowCxV3beta1TestCaseResult? lastTestResult;

  /// The unique identifier of the test case.
  ///
  /// TestCases.CreateTestCase will populate the name automatically. Otherwise
  /// use format: `projects//locations//agents/ /testCases/`.
  core.String? name;

  /// Additional freeform notes about the test case.
  ///
  /// Limit of 400 characters.
  core.String? notes;

  /// Tags are short descriptions that users may apply to test cases for
  /// organizational and filtering purposes.
  ///
  /// Each tag should start with "#" and has a limit of 30 characters.
  core.List<core.String>? tags;

  /// The conversation turns uttered when the test case was created, in
  /// chronological order.
  ///
  /// These include the canonical set of agent utterances that should occur when
  /// the agent is working properly.
  core.List<GoogleCloudDialogflowCxV3beta1ConversationTurn>?
      testCaseConversationTurns;

  /// Config for the test case.
  GoogleCloudDialogflowCxV3beta1TestConfig? testConfig;

  GoogleCloudDialogflowCxV3beta1TestCase();

  GoogleCloudDialogflowCxV3beta1TestCase.fromJson(core.Map _json) {
    if (_json.containsKey('creationTime')) {
      creationTime = _json['creationTime'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('lastTestResult')) {
      lastTestResult = GoogleCloudDialogflowCxV3beta1TestCaseResult.fromJson(
          _json['lastTestResult'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('notes')) {
      notes = _json['notes'] as core.String;
    }
    if (_json.containsKey('tags')) {
      tags = (_json['tags'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('testCaseConversationTurns')) {
      testCaseConversationTurns =
          (_json['testCaseConversationTurns'] as core.List)
              .map<GoogleCloudDialogflowCxV3beta1ConversationTurn>((value) =>
                  GoogleCloudDialogflowCxV3beta1ConversationTurn.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('testConfig')) {
      testConfig = GoogleCloudDialogflowCxV3beta1TestConfig.fromJson(
          _json['testConfig'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (creationTime != null) 'creationTime': creationTime!,
        if (displayName != null) 'displayName': displayName!,
        if (lastTestResult != null) 'lastTestResult': lastTestResult!.toJson(),
        if (name != null) 'name': name!,
        if (notes != null) 'notes': notes!,
        if (tags != null) 'tags': tags!,
        if (testCaseConversationTurns != null)
          'testCaseConversationTurns': testCaseConversationTurns!
              .map((value) => value.toJson())
              .toList(),
        if (testConfig != null) 'testConfig': testConfig!.toJson(),
      };
}

/// Error info for importing a test.
class GoogleCloudDialogflowCxV3beta1TestCaseError {
  /// The status associated with the test case.
  GoogleRpcStatus? status;

  /// The test case.
  GoogleCloudDialogflowCxV3beta1TestCase? testCase;

  GoogleCloudDialogflowCxV3beta1TestCaseError();

  GoogleCloudDialogflowCxV3beta1TestCaseError.fromJson(core.Map _json) {
    if (_json.containsKey('status')) {
      status = GoogleRpcStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('testCase')) {
      testCase = GoogleCloudDialogflowCxV3beta1TestCase.fromJson(
          _json['testCase'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (status != null) 'status': status!.toJson(),
        if (testCase != null) 'testCase': testCase!.toJson(),
      };
}

/// Represents a result from running a test case in an agent environment.
class GoogleCloudDialogflowCxV3beta1TestCaseResult {
  /// The conversation turns uttered during the test case replay in
  /// chronological order.
  core.List<GoogleCloudDialogflowCxV3beta1ConversationTurn>? conversationTurns;

  /// Environment where the test was run.
  ///
  /// If not set, it indicates the draft environment.
  core.String? environment;

  /// The resource name for the test case result.
  ///
  /// Format: `projects//locations//agents//testCases/ /results/`.
  core.String? name;

  /// Whether the test case passed in the agent environment.
  /// Possible string values are:
  /// - "TEST_RESULT_UNSPECIFIED" : Not specified. Should never be used.
  /// - "PASSED" : The test passed.
  /// - "FAILED" : The test did not pass.
  core.String? testResult;

  /// The time that the test was run.
  core.String? testTime;

  GoogleCloudDialogflowCxV3beta1TestCaseResult();

  GoogleCloudDialogflowCxV3beta1TestCaseResult.fromJson(core.Map _json) {
    if (_json.containsKey('conversationTurns')) {
      conversationTurns = (_json['conversationTurns'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1ConversationTurn>((value) =>
              GoogleCloudDialogflowCxV3beta1ConversationTurn.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('environment')) {
      environment = _json['environment'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('testResult')) {
      testResult = _json['testResult'] as core.String;
    }
    if (_json.containsKey('testTime')) {
      testTime = _json['testTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conversationTurns != null)
          'conversationTurns':
              conversationTurns!.map((value) => value.toJson()).toList(),
        if (environment != null) 'environment': environment!,
        if (name != null) 'name': name!,
        if (testResult != null) 'testResult': testResult!,
        if (testTime != null) 'testTime': testTime!,
      };
}

/// Represents configurations for a test case.
class GoogleCloudDialogflowCxV3beta1TestConfig {
  /// Flow name.
  ///
  /// If not set, default start flow is assumed. Format:
  /// `projects//locations//agents//flows/`.
  core.String? flow;

  /// Session parameters to be compared when calculating differences.
  core.List<core.String>? trackingParameters;

  GoogleCloudDialogflowCxV3beta1TestConfig();

  GoogleCloudDialogflowCxV3beta1TestConfig.fromJson(core.Map _json) {
    if (_json.containsKey('flow')) {
      flow = _json['flow'] as core.String;
    }
    if (_json.containsKey('trackingParameters')) {
      trackingParameters = (_json['trackingParameters'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (flow != null) 'flow': flow!,
        if (trackingParameters != null)
          'trackingParameters': trackingParameters!,
      };
}

/// Error info for running a test.
class GoogleCloudDialogflowCxV3beta1TestError {
  /// The status associated with the test.
  GoogleRpcStatus? status;

  /// The test case resource name.
  core.String? testCase;

  /// The timestamp when the test was completed.
  core.String? testTime;

  GoogleCloudDialogflowCxV3beta1TestError();

  GoogleCloudDialogflowCxV3beta1TestError.fromJson(core.Map _json) {
    if (_json.containsKey('status')) {
      status = GoogleRpcStatus.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('testCase')) {
      testCase = _json['testCase'] as core.String;
    }
    if (_json.containsKey('testTime')) {
      testTime = _json['testTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (status != null) 'status': status!.toJson(),
        if (testCase != null) 'testCase': testCase!,
        if (testTime != null) 'testTime': testTime!,
      };
}

/// The description of differences between original and replayed agent output.
class GoogleCloudDialogflowCxV3beta1TestRunDifference {
  /// A description of the diff, showing the actual output vs expected output.
  core.String? description;

  /// The type of diff.
  /// Possible string values are:
  /// - "DIFF_TYPE_UNSPECIFIED" : Should never be used.
  /// - "INTENT" : The intent.
  /// - "PAGE" : The page.
  /// - "PARAMETERS" : The parameters.
  /// - "UTTERANCE" : The message utterance.
  core.String? type;

  GoogleCloudDialogflowCxV3beta1TestRunDifference();

  GoogleCloudDialogflowCxV3beta1TestRunDifference.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (type != null) 'type': type!,
      };
}

/// Represents the natural language text to be processed.
class GoogleCloudDialogflowCxV3beta1TextInput {
  /// The UTF-8 encoded natural language text to be processed.
  ///
  /// Text length must not exceed 256 characters.
  ///
  /// Required.
  core.String? text;

  GoogleCloudDialogflowCxV3beta1TextInput();

  GoogleCloudDialogflowCxV3beta1TextInput.fromJson(core.Map _json) {
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (text != null) 'text': text!,
      };
}

/// A transition route specifies a intent that can be matched and/or a data
/// condition that can be evaluated during a session.
///
/// When a specified transition is matched, the following actions are taken in
/// order: * If there is a `trigger_fulfillment` associated with the transition,
/// it will be called. * If there is a `target_page` associated with the
/// transition, the session will transition into the specified page. * If there
/// is a `target_flow` associated with the transition, the session will
/// transition into the specified flow.
class GoogleCloudDialogflowCxV3beta1TransitionRoute {
  /// The condition to evaluate against form parameters or session parameters.
  ///
  /// See the
  /// [conditions reference](https://cloud.google.com/dialogflow/cx/docs/reference/condition).
  /// At least one of `intent` or `condition` must be specified. When both
  /// `intent` and `condition` are specified, the transition can only happen
  /// when both are fulfilled.
  core.String? condition;

  /// The unique identifier of an Intent.
  ///
  /// Format: `projects//locations//agents//intents/`. Indicates that the
  /// transition can only happen when the given intent is matched. At least one
  /// of `intent` or `condition` must be specified. When both `intent` and
  /// `condition` are specified, the transition can only happen when both are
  /// fulfilled.
  core.String? intent;

  /// The unique identifier of this transition route.
  ///
  /// Output only.
  core.String? name;

  /// The target flow to transition to.
  ///
  /// Format: `projects//locations//agents//flows/`.
  core.String? targetFlow;

  /// The target page to transition to.
  ///
  /// Format: `projects//locations//agents//flows//pages/`.
  core.String? targetPage;

  /// The fulfillment to call when the condition is satisfied.
  ///
  /// At least one of `trigger_fulfillment` and `target` must be specified. When
  /// both are defined, `trigger_fulfillment` is executed first.
  GoogleCloudDialogflowCxV3beta1Fulfillment? triggerFulfillment;

  GoogleCloudDialogflowCxV3beta1TransitionRoute();

  GoogleCloudDialogflowCxV3beta1TransitionRoute.fromJson(core.Map _json) {
    if (_json.containsKey('condition')) {
      condition = _json['condition'] as core.String;
    }
    if (_json.containsKey('intent')) {
      intent = _json['intent'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('targetFlow')) {
      targetFlow = _json['targetFlow'] as core.String;
    }
    if (_json.containsKey('targetPage')) {
      targetPage = _json['targetPage'] as core.String;
    }
    if (_json.containsKey('triggerFulfillment')) {
      triggerFulfillment = GoogleCloudDialogflowCxV3beta1Fulfillment.fromJson(
          _json['triggerFulfillment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (condition != null) 'condition': condition!,
        if (intent != null) 'intent': intent!,
        if (name != null) 'name': name!,
        if (targetFlow != null) 'targetFlow': targetFlow!,
        if (targetPage != null) 'targetPage': targetPage!,
        if (triggerFulfillment != null)
          'triggerFulfillment': triggerFulfillment!.toJson(),
      };
}

/// Metadata for UpdateDocument operation.
class GoogleCloudDialogflowCxV3beta1UpdateDocumentOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowCxV3beta1GenericKnowledgeOperationMetadata?
      genericMetadata;

  GoogleCloudDialogflowCxV3beta1UpdateDocumentOperationMetadata();

  GoogleCloudDialogflowCxV3beta1UpdateDocumentOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowCxV3beta1GenericKnowledgeOperationMetadata
              .fromJson(_json['genericMetadata']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// The request message for a webhook call.
///
/// The request is sent as a JSON object and the field names will be presented
/// in camel cases.
class GoogleCloudDialogflowCxV3beta1WebhookRequest {
  /// Always present.
  ///
  /// The unique identifier of the DetectIntentResponse that will be returned to
  /// the API caller.
  core.String? detectIntentResponseId;

  /// Always present.
  ///
  /// Information about the fulfillment that triggered this webhook call.
  GoogleCloudDialogflowCxV3beta1WebhookRequestFulfillmentInfo? fulfillmentInfo;

  /// Information about the last matched intent.
  GoogleCloudDialogflowCxV3beta1WebhookRequestIntentInfo? intentInfo;

  /// The language code specified in the original request.
  core.String? languageCode;

  /// The list of rich message responses to present to the user.
  ///
  /// Webhook can choose to append or replace this list in
  /// WebhookResponse.fulfillment_response;
  core.List<GoogleCloudDialogflowCxV3beta1ResponseMessage>? messages;

  /// Information about page status.
  GoogleCloudDialogflowCxV3beta1PageInfo? pageInfo;

  /// Custom data set in QueryParameters.payload.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? payload;

  /// The sentiment analysis result of the current user request.
  ///
  /// The field is filled when sentiment analysis is configured to be enabled
  /// for the request.
  GoogleCloudDialogflowCxV3beta1WebhookRequestSentimentAnalysisResult?
      sentimentAnalysisResult;

  /// Information about session status.
  GoogleCloudDialogflowCxV3beta1SessionInfo? sessionInfo;

  /// If natural language text was provided as input, this field will contain a
  /// copy of the text.
  core.String? text;

  /// If natural language speech audio was provided as input, this field will
  /// contain the transcript for the audio.
  core.String? transcript;

  /// If an event was provided as input, this field will contain the name of the
  /// event.
  core.String? triggerEvent;

  /// If an intent was provided as input, this field will contain a copy of the
  /// intent identifier.
  ///
  /// Format: `projects//locations//agents//intents/`.
  core.String? triggerIntent;

  GoogleCloudDialogflowCxV3beta1WebhookRequest();

  GoogleCloudDialogflowCxV3beta1WebhookRequest.fromJson(core.Map _json) {
    if (_json.containsKey('detectIntentResponseId')) {
      detectIntentResponseId = _json['detectIntentResponseId'] as core.String;
    }
    if (_json.containsKey('fulfillmentInfo')) {
      fulfillmentInfo =
          GoogleCloudDialogflowCxV3beta1WebhookRequestFulfillmentInfo.fromJson(
              _json['fulfillmentInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('intentInfo')) {
      intentInfo =
          GoogleCloudDialogflowCxV3beta1WebhookRequestIntentInfo.fromJson(
              _json['intentInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('messages')) {
      messages = (_json['messages'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1ResponseMessage>((value) =>
              GoogleCloudDialogflowCxV3beta1ResponseMessage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('pageInfo')) {
      pageInfo = GoogleCloudDialogflowCxV3beta1PageInfo.fromJson(
          _json['pageInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('payload')) {
      payload = (_json['payload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('sentimentAnalysisResult')) {
      sentimentAnalysisResult =
          GoogleCloudDialogflowCxV3beta1WebhookRequestSentimentAnalysisResult
              .fromJson(_json['sentimentAnalysisResult']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sessionInfo')) {
      sessionInfo = GoogleCloudDialogflowCxV3beta1SessionInfo.fromJson(
          _json['sessionInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
    if (_json.containsKey('transcript')) {
      transcript = _json['transcript'] as core.String;
    }
    if (_json.containsKey('triggerEvent')) {
      triggerEvent = _json['triggerEvent'] as core.String;
    }
    if (_json.containsKey('triggerIntent')) {
      triggerIntent = _json['triggerIntent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (detectIntentResponseId != null)
          'detectIntentResponseId': detectIntentResponseId!,
        if (fulfillmentInfo != null)
          'fulfillmentInfo': fulfillmentInfo!.toJson(),
        if (intentInfo != null) 'intentInfo': intentInfo!.toJson(),
        if (languageCode != null) 'languageCode': languageCode!,
        if (messages != null)
          'messages': messages!.map((value) => value.toJson()).toList(),
        if (pageInfo != null) 'pageInfo': pageInfo!.toJson(),
        if (payload != null) 'payload': payload!,
        if (sentimentAnalysisResult != null)
          'sentimentAnalysisResult': sentimentAnalysisResult!.toJson(),
        if (sessionInfo != null) 'sessionInfo': sessionInfo!.toJson(),
        if (text != null) 'text': text!,
        if (transcript != null) 'transcript': transcript!,
        if (triggerEvent != null) 'triggerEvent': triggerEvent!,
        if (triggerIntent != null) 'triggerIntent': triggerIntent!,
      };
}

/// Represents fulfillment information communicated to the webhook.
class GoogleCloudDialogflowCxV3beta1WebhookRequestFulfillmentInfo {
  /// Always present.
  ///
  /// The tag used to identify which fulfillment is being called.
  core.String? tag;

  GoogleCloudDialogflowCxV3beta1WebhookRequestFulfillmentInfo();

  GoogleCloudDialogflowCxV3beta1WebhookRequestFulfillmentInfo.fromJson(
      core.Map _json) {
    if (_json.containsKey('tag')) {
      tag = _json['tag'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tag != null) 'tag': tag!,
      };
}

/// Represents intent information communicated to the webhook.
class GoogleCloudDialogflowCxV3beta1WebhookRequestIntentInfo {
  /// The confidence of the matched intent.
  ///
  /// Values range from 0.0 (completely uncertain) to 1.0 (completely certain).
  core.double? confidence;

  /// Always present.
  ///
  /// The display name of the last matched intent.
  core.String? displayName;

  /// Always present.
  ///
  /// The unique identifier of the last matched intent. Format:
  /// `projects//locations//agents//intents/`.
  core.String? lastMatchedIntent;

  /// Parameters identified as a result of intent matching.
  ///
  /// This is a map of the name of the identified parameter to the value of the
  /// parameter identified from the user's utterance. All parameters defined in
  /// the matched intent that are identified will be surfaced here.
  core.Map<core.String,
          GoogleCloudDialogflowCxV3beta1WebhookRequestIntentInfoIntentParameterValue>?
      parameters;

  GoogleCloudDialogflowCxV3beta1WebhookRequestIntentInfo();

  GoogleCloudDialogflowCxV3beta1WebhookRequestIntentInfo.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('lastMatchedIntent')) {
      lastMatchedIntent = _json['lastMatchedIntent'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters =
          (_json['parameters'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          GoogleCloudDialogflowCxV3beta1WebhookRequestIntentInfoIntentParameterValue
              .fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (displayName != null) 'displayName': displayName!,
        if (lastMatchedIntent != null) 'lastMatchedIntent': lastMatchedIntent!,
        if (parameters != null)
          'parameters':
              parameters!.map((key, item) => core.MapEntry(key, item.toJson())),
      };
}

/// Represents a value for an intent parameter.
class GoogleCloudDialogflowCxV3beta1WebhookRequestIntentInfoIntentParameterValue {
  /// Always present.
  ///
  /// Original text value extracted from user utterance.
  core.String? originalValue;

  /// Always present.
  ///
  /// Structured value for the parameter extracted from user utterance.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? resolvedValue;

  GoogleCloudDialogflowCxV3beta1WebhookRequestIntentInfoIntentParameterValue();

  GoogleCloudDialogflowCxV3beta1WebhookRequestIntentInfoIntentParameterValue.fromJson(
      core.Map _json) {
    if (_json.containsKey('originalValue')) {
      originalValue = _json['originalValue'] as core.String;
    }
    if (_json.containsKey('resolvedValue')) {
      resolvedValue = _json['resolvedValue'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (originalValue != null) 'originalValue': originalValue!,
        if (resolvedValue != null) 'resolvedValue': resolvedValue!,
      };
}

/// Represents the result of sentiment analysis.
class GoogleCloudDialogflowCxV3beta1WebhookRequestSentimentAnalysisResult {
  /// A non-negative number in the \[0, +inf) range, which represents the
  /// absolute magnitude of sentiment, regardless of score (positive or
  /// negative).
  core.double? magnitude;

  /// Sentiment score between -1.0 (negative sentiment) and 1.0 (positive
  /// sentiment).
  core.double? score;

  GoogleCloudDialogflowCxV3beta1WebhookRequestSentimentAnalysisResult();

  GoogleCloudDialogflowCxV3beta1WebhookRequestSentimentAnalysisResult.fromJson(
      core.Map _json) {
    if (_json.containsKey('magnitude')) {
      magnitude = (_json['magnitude'] as core.num).toDouble();
    }
    if (_json.containsKey('score')) {
      score = (_json['score'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (magnitude != null) 'magnitude': magnitude!,
        if (score != null) 'score': score!,
      };
}

/// The response message for a webhook call.
class GoogleCloudDialogflowCxV3beta1WebhookResponse {
  /// The fulfillment response to send to the user.
  ///
  /// This field can be omitted by the webhook if it does not intend to send any
  /// response to the user.
  GoogleCloudDialogflowCxV3beta1WebhookResponseFulfillmentResponse?
      fulfillmentResponse;

  /// Information about page status.
  ///
  /// This field can be omitted by the webhook if it does not intend to modify
  /// page status.
  GoogleCloudDialogflowCxV3beta1PageInfo? pageInfo;

  /// Value to append directly to QueryResult.webhook_payloads.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? payload;

  /// Information about session status.
  ///
  /// This field can be omitted by the webhook if it does not intend to modify
  /// session status.
  GoogleCloudDialogflowCxV3beta1SessionInfo? sessionInfo;

  /// The target flow to transition to.
  ///
  /// Format: `projects//locations//agents//flows/`.
  core.String? targetFlow;

  /// The target page to transition to.
  ///
  /// Format: `projects//locations//agents//flows//pages/`.
  core.String? targetPage;

  GoogleCloudDialogflowCxV3beta1WebhookResponse();

  GoogleCloudDialogflowCxV3beta1WebhookResponse.fromJson(core.Map _json) {
    if (_json.containsKey('fulfillmentResponse')) {
      fulfillmentResponse =
          GoogleCloudDialogflowCxV3beta1WebhookResponseFulfillmentResponse
              .fromJson(_json['fulfillmentResponse']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pageInfo')) {
      pageInfo = GoogleCloudDialogflowCxV3beta1PageInfo.fromJson(
          _json['pageInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('payload')) {
      payload = (_json['payload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('sessionInfo')) {
      sessionInfo = GoogleCloudDialogflowCxV3beta1SessionInfo.fromJson(
          _json['sessionInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('targetFlow')) {
      targetFlow = _json['targetFlow'] as core.String;
    }
    if (_json.containsKey('targetPage')) {
      targetPage = _json['targetPage'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fulfillmentResponse != null)
          'fulfillmentResponse': fulfillmentResponse!.toJson(),
        if (pageInfo != null) 'pageInfo': pageInfo!.toJson(),
        if (payload != null) 'payload': payload!,
        if (sessionInfo != null) 'sessionInfo': sessionInfo!.toJson(),
        if (targetFlow != null) 'targetFlow': targetFlow!,
        if (targetPage != null) 'targetPage': targetPage!,
      };
}

/// Represents a fulfillment response to the user.
class GoogleCloudDialogflowCxV3beta1WebhookResponseFulfillmentResponse {
  /// Merge behavior for `messages`.
  /// Possible string values are:
  /// - "MERGE_BEHAVIOR_UNSPECIFIED" : Not specified. `APPEND` will be used.
  /// - "APPEND" : `messages` will be appended to the list of messages waiting
  /// to be sent to the user.
  /// - "REPLACE" : `messages` will replace the list of messages waiting to be
  /// sent to the user.
  core.String? mergeBehavior;

  /// The list of rich message responses to present to the user.
  core.List<GoogleCloudDialogflowCxV3beta1ResponseMessage>? messages;

  GoogleCloudDialogflowCxV3beta1WebhookResponseFulfillmentResponse();

  GoogleCloudDialogflowCxV3beta1WebhookResponseFulfillmentResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('mergeBehavior')) {
      mergeBehavior = _json['mergeBehavior'] as core.String;
    }
    if (_json.containsKey('messages')) {
      messages = (_json['messages'] as core.List)
          .map<GoogleCloudDialogflowCxV3beta1ResponseMessage>((value) =>
              GoogleCloudDialogflowCxV3beta1ResponseMessage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mergeBehavior != null) 'mergeBehavior': mergeBehavior!,
        if (messages != null)
          'messages': messages!.map((value) => value.toJson()).toList(),
      };
}

/// Represents a part of a message possibly annotated with an entity.
///
/// The part can be an entity or purely a part of the message between two
/// entities or message start/end.
class GoogleCloudDialogflowV2AnnotatedMessagePart {
  /// The
  /// [Dialogflow system entity type](https://cloud.google.com/dialogflow/docs/reference/system-entities)
  /// of this message part.
  ///
  /// If this is empty, Dialogflow could not annotate the phrase part with a
  /// system entity.
  core.String? entityType;

  /// The
  /// [Dialogflow system entity formatted value ](https://cloud.google.com/dialogflow/docs/reference/system-entities)
  /// of this message part.
  ///
  /// For example for a system entity of type `@sys.unit-currency`, this may
  /// contain: { "amount": 5, "currency": "USD" }
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? formattedValue;

  /// A part of a message possibly annotated with an entity.
  core.String? text;

  GoogleCloudDialogflowV2AnnotatedMessagePart();

  GoogleCloudDialogflowV2AnnotatedMessagePart.fromJson(core.Map _json) {
    if (_json.containsKey('entityType')) {
      entityType = _json['entityType'] as core.String;
    }
    if (_json.containsKey('formattedValue')) {
      formattedValue = _json['formattedValue'] as core.Object;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entityType != null) 'entityType': entityType!,
        if (formattedValue != null) 'formattedValue': formattedValue!,
        if (text != null) 'text': text!,
      };
}

/// Represents article answer.
class GoogleCloudDialogflowV2ArticleAnswer {
  /// The name of answer record, in the format of
  /// "projects//locations//answerRecords/"
  core.String? answerRecord;

  /// Article match confidence.
  ///
  /// The system's confidence score that this article is a good match for this
  /// conversation, as a value from 0.0 (completely uncertain) to 1.0
  /// (completely certain).
  core.double? confidence;

  /// A map that contains metadata about the answer and the document from which
  /// it originates.
  core.Map<core.String, core.String>? metadata;

  /// Article snippets.
  core.List<core.String>? snippets;

  /// The article title.
  core.String? title;

  /// The article URI.
  core.String? uri;

  GoogleCloudDialogflowV2ArticleAnswer();

  GoogleCloudDialogflowV2ArticleAnswer.fromJson(core.Map _json) {
    if (_json.containsKey('answerRecord')) {
      answerRecord = _json['answerRecord'] as core.String;
    }
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('snippets')) {
      snippets = (_json['snippets'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (answerRecord != null) 'answerRecord': answerRecord!,
        if (confidence != null) 'confidence': confidence!,
        if (metadata != null) 'metadata': metadata!,
        if (snippets != null) 'snippets': snippets!,
        if (title != null) 'title': title!,
        if (uri != null) 'uri': uri!,
      };
}

/// The response message for EntityTypes.BatchUpdateEntityTypes.
class GoogleCloudDialogflowV2BatchUpdateEntityTypesResponse {
  /// The collection of updated or created entity types.
  core.List<GoogleCloudDialogflowV2EntityType>? entityTypes;

  GoogleCloudDialogflowV2BatchUpdateEntityTypesResponse();

  GoogleCloudDialogflowV2BatchUpdateEntityTypesResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('entityTypes')) {
      entityTypes = (_json['entityTypes'] as core.List)
          .map<GoogleCloudDialogflowV2EntityType>((value) =>
              GoogleCloudDialogflowV2EntityType.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entityTypes != null)
          'entityTypes': entityTypes!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for Intents.BatchUpdateIntents.
class GoogleCloudDialogflowV2BatchUpdateIntentsResponse {
  /// The collection of updated or created intents.
  core.List<GoogleCloudDialogflowV2Intent>? intents;

  GoogleCloudDialogflowV2BatchUpdateIntentsResponse();

  GoogleCloudDialogflowV2BatchUpdateIntentsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('intents')) {
      intents = (_json['intents'] as core.List)
          .map<GoogleCloudDialogflowV2Intent>((value) =>
              GoogleCloudDialogflowV2Intent.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (intents != null)
          'intents': intents!.map((value) => value.toJson()).toList(),
      };
}

/// Dialogflow contexts are similar to natural language context.
///
/// If a person says to you "they are orange", you need context in order to
/// understand what "they" is referring to. Similarly, for Dialogflow to handle
/// an end-user expression like that, it needs to be provided with context in
/// order to correctly match an intent. Using contexts, you can control the flow
/// of a conversation. You can configure contexts for an intent by setting input
/// and output contexts, which are identified by string names. When an intent is
/// matched, any configured output contexts for that intent become active. While
/// any contexts are active, Dialogflow is more likely to match intents that are
/// configured with input contexts that correspond to the currently active
/// contexts. For more information about context, see the
/// [Contexts guide](https://cloud.google.com/dialogflow/docs/contexts-overview).
class GoogleCloudDialogflowV2Context {
  /// The number of conversational query requests after which the context
  /// expires.
  ///
  /// The default is `0`. If set to `0`, the context expires immediately.
  /// Contexts expire automatically after 20 minutes if there are no matching
  /// queries.
  ///
  /// Optional.
  core.int? lifespanCount;

  /// The unique identifier of the context.
  ///
  /// Format: `projects//agent/sessions//contexts/`, or
  /// `projects//agent/environments//users//sessions//contexts/`. The `Context
  /// ID` is always converted to lowercase, may only contain characters in
  /// a-zA-Z0-9_-% and may be at most 250 bytes long. If `Environment ID` is not
  /// specified, we assume default 'draft' environment. If `User ID` is not
  /// specified, we assume default '-' user. The following context names are
  /// reserved for internal use by Dialogflow. You should not use these contexts
  /// or create contexts with these names: * `__system_counters__` *
  /// `*_id_dialog_context` * `*_dialog_params_size`
  ///
  /// Required.
  core.String? name;

  /// The collection of parameters associated with this context.
  ///
  /// Depending on your protocol or client library language, this is a map,
  /// associative array, symbol table, dictionary, or JSON object composed of a
  /// collection of (MapKey, MapValue) pairs: - MapKey type: string - MapKey
  /// value: parameter name - MapValue type: - If parameter's entity type is a
  /// composite entity: map - Else: depending on parameter value type, could be
  /// one of string, number, boolean, null, list or map - MapValue value: - If
  /// parameter's entity type is a composite entity: map from composite entity
  /// property names to property values - Else: parameter value
  ///
  /// Optional.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? parameters;

  GoogleCloudDialogflowV2Context();

  GoogleCloudDialogflowV2Context.fromJson(core.Map _json) {
    if (_json.containsKey('lifespanCount')) {
      lifespanCount = _json['lifespanCount'] as core.int;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters =
          (_json['parameters'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lifespanCount != null) 'lifespanCount': lifespanCount!,
        if (name != null) 'name': name!,
        if (parameters != null) 'parameters': parameters!,
      };
}

/// Represents a notification sent to Pub/Sub subscribers for conversation
/// lifecycle events.
class GoogleCloudDialogflowV2ConversationEvent {
  /// The unique identifier of the conversation this notification refers to.
  ///
  /// Format: `projects//conversations/`.
  core.String? conversation;

  /// More detailed information about an error.
  ///
  /// Only set for type UNRECOVERABLE_ERROR_IN_PHONE_CALL.
  GoogleRpcStatus? errorStatus;

  /// Payload of NEW_MESSAGE event.
  GoogleCloudDialogflowV2Message? newMessagePayload;

  /// The type of the event that this notification refers to.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Type not set.
  /// - "CONVERSATION_STARTED" : A new conversation has been opened. This is
  /// fired when a telephone call is answered, or a conversation is created via
  /// the API.
  /// - "CONVERSATION_FINISHED" : An existing conversation has closed. This is
  /// fired when a telephone call is terminated, or a conversation is closed via
  /// the API.
  /// - "HUMAN_INTERVENTION_NEEDED" : An existing conversation has received
  /// notification from Dialogflow that human intervention is required.
  /// - "NEW_MESSAGE" : An existing conversation has received a new message,
  /// either from API or telephony. It is configured in
  /// ConversationProfile.new_message_event_notification_config
  /// - "UNRECOVERABLE_ERROR" : Unrecoverable error during a telephone call. In
  /// general non-recoverable errors only occur if something was misconfigured
  /// in the ConversationProfile corresponding to the call. After a
  /// non-recoverable error, Dialogflow may stop responding. We don't fire this
  /// event: * in an API call because we can directly return the error, or, *
  /// when we can recover from an error.
  core.String? type;

  GoogleCloudDialogflowV2ConversationEvent();

  GoogleCloudDialogflowV2ConversationEvent.fromJson(core.Map _json) {
    if (_json.containsKey('conversation')) {
      conversation = _json['conversation'] as core.String;
    }
    if (_json.containsKey('errorStatus')) {
      errorStatus = GoogleRpcStatus.fromJson(
          _json['errorStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('newMessagePayload')) {
      newMessagePayload = GoogleCloudDialogflowV2Message.fromJson(
          _json['newMessagePayload'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conversation != null) 'conversation': conversation!,
        if (errorStatus != null) 'errorStatus': errorStatus!.toJson(),
        if (newMessagePayload != null)
          'newMessagePayload': newMessagePayload!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// Each intent parameter has a type, called the entity type, which dictates
/// exactly how data from an end-user expression is extracted.
///
/// Dialogflow provides predefined system entities that can match many common
/// types of data. For example, there are system entities for matching dates,
/// times, colors, email addresses, and so on. You can also create your own
/// custom entities for matching custom data. For example, you could define a
/// vegetable entity that can match the types of vegetables available for
/// purchase with a grocery store agent. For more information, see the
/// [Entity guide](https://cloud.google.com/dialogflow/docs/entities-overview).
class GoogleCloudDialogflowV2EntityType {
  /// Indicates whether the entity type can be automatically expanded.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "AUTO_EXPANSION_MODE_UNSPECIFIED" : Auto expansion disabled for the
  /// entity.
  /// - "AUTO_EXPANSION_MODE_DEFAULT" : Allows an agent to recognize values that
  /// have not been explicitly listed in the entity.
  core.String? autoExpansionMode;

  /// The name of the entity type.
  ///
  /// Required.
  core.String? displayName;

  /// Enables fuzzy entity extraction during classification.
  ///
  /// Optional.
  core.bool? enableFuzzyExtraction;

  /// The collection of entity entries associated with the entity type.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2EntityTypeEntity>? entities;

  /// Indicates the kind of entity type.
  ///
  /// Required.
  /// Possible string values are:
  /// - "KIND_UNSPECIFIED" : Not specified. This value should be never used.
  /// - "KIND_MAP" : Map entity types allow mapping of a group of synonyms to a
  /// reference value.
  /// - "KIND_LIST" : List entity types contain a set of entries that do not map
  /// to reference values. However, list entity types can contain references to
  /// other entity types (with or without aliases).
  /// - "KIND_REGEXP" : Regexp entity types allow to specify regular expressions
  /// in entries values.
  core.String? kind;

  /// The unique identifier of the entity type.
  ///
  /// Required for EntityTypes.UpdateEntityType and
  /// EntityTypes.BatchUpdateEntityTypes methods. Format:
  /// `projects//agent/entityTypes/`.
  core.String? name;

  GoogleCloudDialogflowV2EntityType();

  GoogleCloudDialogflowV2EntityType.fromJson(core.Map _json) {
    if (_json.containsKey('autoExpansionMode')) {
      autoExpansionMode = _json['autoExpansionMode'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('enableFuzzyExtraction')) {
      enableFuzzyExtraction = _json['enableFuzzyExtraction'] as core.bool;
    }
    if (_json.containsKey('entities')) {
      entities = (_json['entities'] as core.List)
          .map<GoogleCloudDialogflowV2EntityTypeEntity>((value) =>
              GoogleCloudDialogflowV2EntityTypeEntity.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoExpansionMode != null) 'autoExpansionMode': autoExpansionMode!,
        if (displayName != null) 'displayName': displayName!,
        if (enableFuzzyExtraction != null)
          'enableFuzzyExtraction': enableFuzzyExtraction!,
        if (entities != null)
          'entities': entities!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// An **entity entry** for an associated entity type.
class GoogleCloudDialogflowV2EntityTypeEntity {
  /// A collection of value synonyms.
  ///
  /// For example, if the entity type is *vegetable*, and `value` is
  /// *scallions*, a synonym could be *green onions*. For `KIND_LIST` entity
  /// types: * This collection must contain exactly one synonym equal to
  /// `value`.
  ///
  /// Required.
  core.List<core.String>? synonyms;

  /// The primary value associated with this entity entry.
  ///
  /// For example, if the entity type is *vegetable*, the value could be
  /// *scallions*. For `KIND_MAP` entity types: * A reference value to be used
  /// in place of synonyms. For `KIND_LIST` entity types: * A string that can
  /// contain references to other entity types (with or without aliases).
  ///
  /// Required.
  core.String? value;

  GoogleCloudDialogflowV2EntityTypeEntity();

  GoogleCloudDialogflowV2EntityTypeEntity.fromJson(core.Map _json) {
    if (_json.containsKey('synonyms')) {
      synonyms = (_json['synonyms'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (synonyms != null) 'synonyms': synonyms!,
        if (value != null) 'value': value!,
      };
}

/// Events allow for matching intents by event name instead of the natural
/// language input.
///
/// For instance, input `` can trigger a personalized welcome response. The
/// parameter `name` may be used by the agent in the response: `"Hello
/// #welcome_event.name! What can I do for you today?"`.
class GoogleCloudDialogflowV2EventInput {
  /// The language of this query.
  ///
  /// See
  /// [Language Support](https://cloud.google.com/dialogflow/docs/reference/language)
  /// for a list of the currently supported language codes. Note that queries in
  /// the same session do not necessarily need to specify the same language.
  ///
  /// Required.
  core.String? languageCode;

  /// The unique identifier of the event.
  ///
  /// Required.
  core.String? name;

  /// The collection of parameters associated with the event.
  ///
  /// Depending on your protocol or client library language, this is a map,
  /// associative array, symbol table, dictionary, or JSON object composed of a
  /// collection of (MapKey, MapValue) pairs: - MapKey type: string - MapKey
  /// value: parameter name - MapValue type: - If parameter's entity type is a
  /// composite entity: map - Else: depending on parameter value type, could be
  /// one of string, number, boolean, null, list or map - MapValue value: - If
  /// parameter's entity type is a composite entity: map from composite entity
  /// property names to property values - Else: parameter value
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? parameters;

  GoogleCloudDialogflowV2EventInput();

  GoogleCloudDialogflowV2EventInput.fromJson(core.Map _json) {
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters =
          (_json['parameters'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (languageCode != null) 'languageCode': languageCode!,
        if (name != null) 'name': name!,
        if (parameters != null) 'parameters': parameters!,
      };
}

/// The response message for Agents.ExportAgent.
class GoogleCloudDialogflowV2ExportAgentResponse {
  /// Zip compressed raw byte content for agent.
  core.String? agentContent;
  core.List<core.int> get agentContentAsBytes =>
      convert.base64.decode(agentContent!);

  set agentContentAsBytes(core.List<core.int> _bytes) {
    agentContent =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The URI to a file containing the exported agent.
  ///
  /// This field is populated only if `agent_uri` is specified in
  /// `ExportAgentRequest`.
  core.String? agentUri;

  GoogleCloudDialogflowV2ExportAgentResponse();

  GoogleCloudDialogflowV2ExportAgentResponse.fromJson(core.Map _json) {
    if (_json.containsKey('agentContent')) {
      agentContent = _json['agentContent'] as core.String;
    }
    if (_json.containsKey('agentUri')) {
      agentUri = _json['agentUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (agentContent != null) 'agentContent': agentContent!,
        if (agentUri != null) 'agentUri': agentUri!,
      };
}

/// Represents answer from "frequently asked questions".
class GoogleCloudDialogflowV2FaqAnswer {
  /// The piece of text from the `source` knowledge base document.
  core.String? answer;

  /// The name of answer record, in the format of
  /// "projects//locations//answerRecords/"
  core.String? answerRecord;

  /// The system's confidence score that this Knowledge answer is a good match
  /// for this conversational query, range from 0.0 (completely uncertain) to
  /// 1.0 (completely certain).
  core.double? confidence;

  /// A map that contains metadata about the answer and the document from which
  /// it originates.
  core.Map<core.String, core.String>? metadata;

  /// The corresponding FAQ question.
  core.String? question;

  /// Indicates which Knowledge Document this answer was extracted from.
  ///
  /// Format: `projects//locations//agent/knowledgeBases//documents/`.
  core.String? source;

  GoogleCloudDialogflowV2FaqAnswer();

  GoogleCloudDialogflowV2FaqAnswer.fromJson(core.Map _json) {
    if (_json.containsKey('answer')) {
      answer = _json['answer'] as core.String;
    }
    if (_json.containsKey('answerRecord')) {
      answerRecord = _json['answerRecord'] as core.String;
    }
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('question')) {
      question = _json['question'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (answer != null) 'answer': answer!,
        if (answerRecord != null) 'answerRecord': answerRecord!,
        if (confidence != null) 'confidence': confidence!,
        if (metadata != null) 'metadata': metadata!,
        if (question != null) 'question': question!,
        if (source != null) 'source': source!,
      };
}

/// Represents a notification sent to Cloud Pub/Sub subscribers for human agent
/// assistant events in a specific conversation.
class GoogleCloudDialogflowV2HumanAgentAssistantEvent {
  /// The conversation this notification refers to.
  ///
  /// Format: `projects//conversations/`.
  core.String? conversation;

  /// The participant that the suggestion is compiled for.
  ///
  /// Format: `projects//conversations//participants/`. It will not be set in
  /// legacy workflow.
  core.String? participant;

  /// The suggestion results payload that this notification refers to.
  core.List<GoogleCloudDialogflowV2SuggestionResult>? suggestionResults;

  GoogleCloudDialogflowV2HumanAgentAssistantEvent();

  GoogleCloudDialogflowV2HumanAgentAssistantEvent.fromJson(core.Map _json) {
    if (_json.containsKey('conversation')) {
      conversation = _json['conversation'] as core.String;
    }
    if (_json.containsKey('participant')) {
      participant = _json['participant'] as core.String;
    }
    if (_json.containsKey('suggestionResults')) {
      suggestionResults = (_json['suggestionResults'] as core.List)
          .map<GoogleCloudDialogflowV2SuggestionResult>((value) =>
              GoogleCloudDialogflowV2SuggestionResult.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conversation != null) 'conversation': conversation!,
        if (participant != null) 'participant': participant!,
        if (suggestionResults != null)
          'suggestionResults':
              suggestionResults!.map((value) => value.toJson()).toList(),
      };
}

/// An intent categorizes an end-user's intention for one conversation turn.
///
/// For each agent, you define many intents, where your combined intents can
/// handle a complete conversation. When an end-user writes or says something,
/// referred to as an end-user expression or end-user input, Dialogflow matches
/// the end-user input to the best intent in your agent. Matching an intent is
/// also known as intent classification. For more information, see the
/// [intent guide](https://cloud.google.com/dialogflow/docs/intents-overview).
class GoogleCloudDialogflowV2Intent {
  /// The name of the action associated with the intent.
  ///
  /// Note: The action name must not contain whitespaces.
  ///
  /// Optional.
  core.String? action;

  /// The list of platforms for which the first responses will be copied from
  /// the messages in PLATFORM_UNSPECIFIED (i.e. default platform).
  ///
  /// Optional.
  core.List<core.String>? defaultResponsePlatforms;

  /// The name of this intent.
  ///
  /// Required.
  core.String? displayName;

  /// Indicates that this intent ends an interaction.
  ///
  /// Some integrations (e.g., Actions on Google or Dialogflow phone gateway)
  /// use this information to close interaction with an end user. Default is
  /// false.
  ///
  /// Optional.
  core.bool? endInteraction;

  /// The collection of event names that trigger the intent.
  ///
  /// If the collection of input contexts is not empty, all of the contexts must
  /// be present in the active user session for an event to trigger this intent.
  /// Event names are limited to 150 characters.
  ///
  /// Optional.
  core.List<core.String>? events;

  /// Read-only.
  ///
  /// Information about all followup intents that have this intent as a direct
  /// or indirect parent. We populate this field only in the output.
  core.List<GoogleCloudDialogflowV2IntentFollowupIntentInfo>?
      followupIntentInfo;

  /// The list of context names required for this intent to be triggered.
  ///
  /// Format: `projects//agent/sessions/-/contexts/`.
  ///
  /// Optional.
  core.List<core.String>? inputContextNames;

  /// Indicates whether this is a fallback intent.
  ///
  /// Optional.
  core.bool? isFallback;

  /// Indicates that a live agent should be brought in to handle the interaction
  /// with the user.
  ///
  /// In most cases, when you set this flag to true, you would also want to set
  /// end_interaction to true as well. Default is false.
  ///
  /// Optional.
  core.bool? liveAgentHandoff;

  /// The collection of rich messages corresponding to the `Response` field in
  /// the Dialogflow console.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2IntentMessage>? messages;

  /// Indicates whether Machine Learning is disabled for the intent.
  ///
  /// Note: If `ml_disabled` setting is set to true, then this intent is not
  /// taken into account during inference in `ML ONLY` match mode. Also,
  /// auto-markup in the UI is turned off.
  ///
  /// Optional.
  core.bool? mlDisabled;

  /// The unique identifier of this intent.
  ///
  /// Required for Intents.UpdateIntent and Intents.BatchUpdateIntents methods.
  /// Format: `projects//agent/intents/`.
  ///
  /// Optional.
  core.String? name;

  /// The collection of contexts that are activated when the intent is matched.
  ///
  /// Context messages in this collection should not set the parameters field.
  /// Setting the `lifespan_count` to 0 will reset the context when the intent
  /// is matched. Format: `projects//agent/sessions/-/contexts/`.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2Context>? outputContexts;

  /// The collection of parameters associated with the intent.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2IntentParameter>? parameters;

  /// Read-only after creation.
  ///
  /// The unique identifier of the parent intent in the chain of followup
  /// intents. You can set this field when creating an intent, for example with
  /// CreateIntent or BatchUpdateIntents, in order to make this intent a
  /// followup intent. It identifies the parent followup intent. Format:
  /// `projects//agent/intents/`.
  core.String? parentFollowupIntentName;

  /// The priority of this intent.
  ///
  /// Higher numbers represent higher priorities. - If the supplied value is
  /// unspecified or 0, the service translates the value to 500,000, which
  /// corresponds to the `Normal` priority in the console. - If the supplied
  /// value is negative, the intent is ignored in runtime detect intent
  /// requests.
  ///
  /// Optional.
  core.int? priority;

  /// Indicates whether to delete all contexts in the current session when this
  /// intent is matched.
  ///
  /// Optional.
  core.bool? resetContexts;

  /// Read-only.
  ///
  /// The unique identifier of the root intent in the chain of followup intents.
  /// It identifies the correct followup intents chain for this intent. We
  /// populate this field only in the output. Format:
  /// `projects//agent/intents/`.
  core.String? rootFollowupIntentName;

  /// The collection of examples that the agent is trained on.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2IntentTrainingPhrase>? trainingPhrases;

  /// Indicates whether webhooks are enabled for the intent.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "WEBHOOK_STATE_UNSPECIFIED" : Webhook is disabled in the agent and in
  /// the intent.
  /// - "WEBHOOK_STATE_ENABLED" : Webhook is enabled in the agent and in the
  /// intent.
  /// - "WEBHOOK_STATE_ENABLED_FOR_SLOT_FILLING" : Webhook is enabled in the
  /// agent and in the intent. Also, each slot filling prompt is forwarded to
  /// the webhook.
  core.String? webhookState;

  GoogleCloudDialogflowV2Intent();

  GoogleCloudDialogflowV2Intent.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('defaultResponsePlatforms')) {
      defaultResponsePlatforms =
          (_json['defaultResponsePlatforms'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('endInteraction')) {
      endInteraction = _json['endInteraction'] as core.bool;
    }
    if (_json.containsKey('events')) {
      events = (_json['events'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('followupIntentInfo')) {
      followupIntentInfo = (_json['followupIntentInfo'] as core.List)
          .map<GoogleCloudDialogflowV2IntentFollowupIntentInfo>((value) =>
              GoogleCloudDialogflowV2IntentFollowupIntentInfo.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('inputContextNames')) {
      inputContextNames = (_json['inputContextNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('isFallback')) {
      isFallback = _json['isFallback'] as core.bool;
    }
    if (_json.containsKey('liveAgentHandoff')) {
      liveAgentHandoff = _json['liveAgentHandoff'] as core.bool;
    }
    if (_json.containsKey('messages')) {
      messages = (_json['messages'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessage>((value) =>
              GoogleCloudDialogflowV2IntentMessage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('mlDisabled')) {
      mlDisabled = _json['mlDisabled'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('outputContexts')) {
      outputContexts = (_json['outputContexts'] as core.List)
          .map<GoogleCloudDialogflowV2Context>((value) =>
              GoogleCloudDialogflowV2Context.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<GoogleCloudDialogflowV2IntentParameter>((value) =>
              GoogleCloudDialogflowV2IntentParameter.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('parentFollowupIntentName')) {
      parentFollowupIntentName =
          _json['parentFollowupIntentName'] as core.String;
    }
    if (_json.containsKey('priority')) {
      priority = _json['priority'] as core.int;
    }
    if (_json.containsKey('resetContexts')) {
      resetContexts = _json['resetContexts'] as core.bool;
    }
    if (_json.containsKey('rootFollowupIntentName')) {
      rootFollowupIntentName = _json['rootFollowupIntentName'] as core.String;
    }
    if (_json.containsKey('trainingPhrases')) {
      trainingPhrases = (_json['trainingPhrases'] as core.List)
          .map<GoogleCloudDialogflowV2IntentTrainingPhrase>((value) =>
              GoogleCloudDialogflowV2IntentTrainingPhrase.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('webhookState')) {
      webhookState = _json['webhookState'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (defaultResponsePlatforms != null)
          'defaultResponsePlatforms': defaultResponsePlatforms!,
        if (displayName != null) 'displayName': displayName!,
        if (endInteraction != null) 'endInteraction': endInteraction!,
        if (events != null) 'events': events!,
        if (followupIntentInfo != null)
          'followupIntentInfo':
              followupIntentInfo!.map((value) => value.toJson()).toList(),
        if (inputContextNames != null) 'inputContextNames': inputContextNames!,
        if (isFallback != null) 'isFallback': isFallback!,
        if (liveAgentHandoff != null) 'liveAgentHandoff': liveAgentHandoff!,
        if (messages != null)
          'messages': messages!.map((value) => value.toJson()).toList(),
        if (mlDisabled != null) 'mlDisabled': mlDisabled!,
        if (name != null) 'name': name!,
        if (outputContexts != null)
          'outputContexts':
              outputContexts!.map((value) => value.toJson()).toList(),
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
        if (parentFollowupIntentName != null)
          'parentFollowupIntentName': parentFollowupIntentName!,
        if (priority != null) 'priority': priority!,
        if (resetContexts != null) 'resetContexts': resetContexts!,
        if (rootFollowupIntentName != null)
          'rootFollowupIntentName': rootFollowupIntentName!,
        if (trainingPhrases != null)
          'trainingPhrases':
              trainingPhrases!.map((value) => value.toJson()).toList(),
        if (webhookState != null) 'webhookState': webhookState!,
      };
}

/// Represents a single followup intent in the chain.
class GoogleCloudDialogflowV2IntentFollowupIntentInfo {
  /// The unique identifier of the followup intent.
  ///
  /// Format: `projects//agent/intents/`.
  core.String? followupIntentName;

  /// The unique identifier of the followup intent's parent.
  ///
  /// Format: `projects//agent/intents/`.
  core.String? parentFollowupIntentName;

  GoogleCloudDialogflowV2IntentFollowupIntentInfo();

  GoogleCloudDialogflowV2IntentFollowupIntentInfo.fromJson(core.Map _json) {
    if (_json.containsKey('followupIntentName')) {
      followupIntentName = _json['followupIntentName'] as core.String;
    }
    if (_json.containsKey('parentFollowupIntentName')) {
      parentFollowupIntentName =
          _json['parentFollowupIntentName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (followupIntentName != null)
          'followupIntentName': followupIntentName!,
        if (parentFollowupIntentName != null)
          'parentFollowupIntentName': parentFollowupIntentName!,
      };
}

/// A rich response message.
///
/// Corresponds to the intent `Response` field in the Dialogflow console. For
/// more information, see
/// [Rich response messages](https://cloud.google.com/dialogflow/docs/intents-rich-messages).
class GoogleCloudDialogflowV2IntentMessage {
  /// The basic card response for Actions on Google.
  GoogleCloudDialogflowV2IntentMessageBasicCard? basicCard;

  /// Browse carousel card for Actions on Google.
  GoogleCloudDialogflowV2IntentMessageBrowseCarouselCard? browseCarouselCard;

  /// The card response.
  GoogleCloudDialogflowV2IntentMessageCard? card;

  /// The carousel card response for Actions on Google.
  GoogleCloudDialogflowV2IntentMessageCarouselSelect? carouselSelect;

  /// The image response.
  GoogleCloudDialogflowV2IntentMessageImage? image;

  /// The link out suggestion chip for Actions on Google.
  GoogleCloudDialogflowV2IntentMessageLinkOutSuggestion? linkOutSuggestion;

  /// The list card response for Actions on Google.
  GoogleCloudDialogflowV2IntentMessageListSelect? listSelect;

  /// The media content card for Actions on Google.
  GoogleCloudDialogflowV2IntentMessageMediaContent? mediaContent;

  /// A custom platform-specific response.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? payload;

  /// The platform that this message is intended for.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "PLATFORM_UNSPECIFIED" : Default platform.
  /// - "FACEBOOK" : Facebook.
  /// - "SLACK" : Slack.
  /// - "TELEGRAM" : Telegram.
  /// - "KIK" : Kik.
  /// - "SKYPE" : Skype.
  /// - "LINE" : Line.
  /// - "VIBER" : Viber.
  /// - "ACTIONS_ON_GOOGLE" : Google Assistant See
  /// [Dialogflow webhook format](https://developers.google.com/assistant/actions/build/json/dialogflow-webhook-json)
  /// - "GOOGLE_HANGOUTS" : Google Hangouts.
  core.String? platform;

  /// The quick replies response.
  GoogleCloudDialogflowV2IntentMessageQuickReplies? quickReplies;

  /// The voice and text-only responses for Actions on Google.
  GoogleCloudDialogflowV2IntentMessageSimpleResponses? simpleResponses;

  /// The suggestion chips for Actions on Google.
  GoogleCloudDialogflowV2IntentMessageSuggestions? suggestions;

  /// Table card for Actions on Google.
  GoogleCloudDialogflowV2IntentMessageTableCard? tableCard;

  /// The text response.
  GoogleCloudDialogflowV2IntentMessageText? text;

  GoogleCloudDialogflowV2IntentMessage();

  GoogleCloudDialogflowV2IntentMessage.fromJson(core.Map _json) {
    if (_json.containsKey('basicCard')) {
      basicCard = GoogleCloudDialogflowV2IntentMessageBasicCard.fromJson(
          _json['basicCard'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('browseCarouselCard')) {
      browseCarouselCard =
          GoogleCloudDialogflowV2IntentMessageBrowseCarouselCard.fromJson(
              _json['browseCarouselCard']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('card')) {
      card = GoogleCloudDialogflowV2IntentMessageCard.fromJson(
          _json['card'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('carouselSelect')) {
      carouselSelect =
          GoogleCloudDialogflowV2IntentMessageCarouselSelect.fromJson(
              _json['carouselSelect'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('image')) {
      image = GoogleCloudDialogflowV2IntentMessageImage.fromJson(
          _json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('linkOutSuggestion')) {
      linkOutSuggestion =
          GoogleCloudDialogflowV2IntentMessageLinkOutSuggestion.fromJson(
              _json['linkOutSuggestion']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('listSelect')) {
      listSelect = GoogleCloudDialogflowV2IntentMessageListSelect.fromJson(
          _json['listSelect'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mediaContent')) {
      mediaContent = GoogleCloudDialogflowV2IntentMessageMediaContent.fromJson(
          _json['mediaContent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('payload')) {
      payload = (_json['payload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('platform')) {
      platform = _json['platform'] as core.String;
    }
    if (_json.containsKey('quickReplies')) {
      quickReplies = GoogleCloudDialogflowV2IntentMessageQuickReplies.fromJson(
          _json['quickReplies'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('simpleResponses')) {
      simpleResponses =
          GoogleCloudDialogflowV2IntentMessageSimpleResponses.fromJson(
              _json['simpleResponses'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('suggestions')) {
      suggestions = GoogleCloudDialogflowV2IntentMessageSuggestions.fromJson(
          _json['suggestions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableCard')) {
      tableCard = GoogleCloudDialogflowV2IntentMessageTableCard.fromJson(
          _json['tableCard'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = GoogleCloudDialogflowV2IntentMessageText.fromJson(
          _json['text'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (basicCard != null) 'basicCard': basicCard!.toJson(),
        if (browseCarouselCard != null)
          'browseCarouselCard': browseCarouselCard!.toJson(),
        if (card != null) 'card': card!.toJson(),
        if (carouselSelect != null) 'carouselSelect': carouselSelect!.toJson(),
        if (image != null) 'image': image!.toJson(),
        if (linkOutSuggestion != null)
          'linkOutSuggestion': linkOutSuggestion!.toJson(),
        if (listSelect != null) 'listSelect': listSelect!.toJson(),
        if (mediaContent != null) 'mediaContent': mediaContent!.toJson(),
        if (payload != null) 'payload': payload!,
        if (platform != null) 'platform': platform!,
        if (quickReplies != null) 'quickReplies': quickReplies!.toJson(),
        if (simpleResponses != null)
          'simpleResponses': simpleResponses!.toJson(),
        if (suggestions != null) 'suggestions': suggestions!.toJson(),
        if (tableCard != null) 'tableCard': tableCard!.toJson(),
        if (text != null) 'text': text!.toJson(),
      };
}

/// The basic card message.
///
/// Useful for displaying information.
class GoogleCloudDialogflowV2IntentMessageBasicCard {
  /// The collection of card buttons.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2IntentMessageBasicCardButton>? buttons;

  /// Required, unless image is present.
  ///
  /// The body text of the card.
  core.String? formattedText;

  /// The image for the card.
  ///
  /// Optional.
  GoogleCloudDialogflowV2IntentMessageImage? image;

  /// The subtitle of the card.
  ///
  /// Optional.
  core.String? subtitle;

  /// The title of the card.
  ///
  /// Optional.
  core.String? title;

  GoogleCloudDialogflowV2IntentMessageBasicCard();

  GoogleCloudDialogflowV2IntentMessageBasicCard.fromJson(core.Map _json) {
    if (_json.containsKey('buttons')) {
      buttons = (_json['buttons'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessageBasicCardButton>((value) =>
              GoogleCloudDialogflowV2IntentMessageBasicCardButton.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('formattedText')) {
      formattedText = _json['formattedText'] as core.String;
    }
    if (_json.containsKey('image')) {
      image = GoogleCloudDialogflowV2IntentMessageImage.fromJson(
          _json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subtitle')) {
      subtitle = _json['subtitle'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buttons != null)
          'buttons': buttons!.map((value) => value.toJson()).toList(),
        if (formattedText != null) 'formattedText': formattedText!,
        if (image != null) 'image': image!.toJson(),
        if (subtitle != null) 'subtitle': subtitle!,
        if (title != null) 'title': title!,
      };
}

/// The button object that appears at the bottom of a card.
class GoogleCloudDialogflowV2IntentMessageBasicCardButton {
  /// Action to take when a user taps on the button.
  ///
  /// Required.
  GoogleCloudDialogflowV2IntentMessageBasicCardButtonOpenUriAction?
      openUriAction;

  /// The title of the button.
  ///
  /// Required.
  core.String? title;

  GoogleCloudDialogflowV2IntentMessageBasicCardButton();

  GoogleCloudDialogflowV2IntentMessageBasicCardButton.fromJson(core.Map _json) {
    if (_json.containsKey('openUriAction')) {
      openUriAction =
          GoogleCloudDialogflowV2IntentMessageBasicCardButtonOpenUriAction
              .fromJson(_json['openUriAction']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (openUriAction != null) 'openUriAction': openUriAction!.toJson(),
        if (title != null) 'title': title!,
      };
}

/// Opens the given URI.
class GoogleCloudDialogflowV2IntentMessageBasicCardButtonOpenUriAction {
  /// The HTTP or HTTPS scheme URI.
  ///
  /// Required.
  core.String? uri;

  GoogleCloudDialogflowV2IntentMessageBasicCardButtonOpenUriAction();

  GoogleCloudDialogflowV2IntentMessageBasicCardButtonOpenUriAction.fromJson(
      core.Map _json) {
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (uri != null) 'uri': uri!,
      };
}

/// Browse Carousel Card for Actions on Google.
///
/// https://developers.google.com/actions/assistant/responses#browsing_carousel
class GoogleCloudDialogflowV2IntentMessageBrowseCarouselCard {
  /// Settings for displaying the image.
  ///
  /// Applies to every image in items.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "IMAGE_DISPLAY_OPTIONS_UNSPECIFIED" : Fill the gaps between the image
  /// and the image container with gray bars.
  /// - "GRAY" : Fill the gaps between the image and the image container with
  /// gray bars.
  /// - "WHITE" : Fill the gaps between the image and the image container with
  /// white bars.
  /// - "CROPPED" : Image is scaled such that the image width and height match
  /// or exceed the container dimensions. This may crop the top and bottom of
  /// the image if the scaled image height is greater than the container height,
  /// or crop the left and right of the image if the scaled image width is
  /// greater than the container width. This is similar to "Zoom Mode" on a
  /// widescreen TV when playing a 4:3 video.
  /// - "BLURRED_BACKGROUND" : Pad the gaps between image and image frame with a
  /// blurred copy of the same image.
  core.String? imageDisplayOptions;

  /// List of items in the Browse Carousel Card.
  ///
  /// Minimum of two items, maximum of ten.
  ///
  /// Required.
  core.List<
          GoogleCloudDialogflowV2IntentMessageBrowseCarouselCardBrowseCarouselCardItem>?
      items;

  GoogleCloudDialogflowV2IntentMessageBrowseCarouselCard();

  GoogleCloudDialogflowV2IntentMessageBrowseCarouselCard.fromJson(
      core.Map _json) {
    if (_json.containsKey('imageDisplayOptions')) {
      imageDisplayOptions = _json['imageDisplayOptions'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessageBrowseCarouselCardBrowseCarouselCardItem>(
              (value) =>
                  GoogleCloudDialogflowV2IntentMessageBrowseCarouselCardBrowseCarouselCardItem
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (imageDisplayOptions != null)
          'imageDisplayOptions': imageDisplayOptions!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
      };
}

/// Browsing carousel tile
class GoogleCloudDialogflowV2IntentMessageBrowseCarouselCardBrowseCarouselCardItem {
  /// Description of the carousel item.
  ///
  /// Maximum of four lines of text.
  ///
  /// Optional.
  core.String? description;

  /// Text that appears at the bottom of the Browse Carousel Card.
  ///
  /// Maximum of one line of text.
  ///
  /// Optional.
  core.String? footer;

  /// Hero image for the carousel item.
  ///
  /// Optional.
  GoogleCloudDialogflowV2IntentMessageImage? image;

  /// Action to present to the user.
  ///
  /// Required.
  GoogleCloudDialogflowV2IntentMessageBrowseCarouselCardBrowseCarouselCardItemOpenUrlAction?
      openUriAction;

  /// Title of the carousel item.
  ///
  /// Maximum of two lines of text.
  ///
  /// Required.
  core.String? title;

  GoogleCloudDialogflowV2IntentMessageBrowseCarouselCardBrowseCarouselCardItem();

  GoogleCloudDialogflowV2IntentMessageBrowseCarouselCardBrowseCarouselCardItem.fromJson(
      core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('footer')) {
      footer = _json['footer'] as core.String;
    }
    if (_json.containsKey('image')) {
      image = GoogleCloudDialogflowV2IntentMessageImage.fromJson(
          _json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('openUriAction')) {
      openUriAction =
          GoogleCloudDialogflowV2IntentMessageBrowseCarouselCardBrowseCarouselCardItemOpenUrlAction
              .fromJson(_json['openUriAction']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (footer != null) 'footer': footer!,
        if (image != null) 'image': image!.toJson(),
        if (openUriAction != null) 'openUriAction': openUriAction!.toJson(),
        if (title != null) 'title': title!,
      };
}

/// Actions on Google action to open a given url.
class GoogleCloudDialogflowV2IntentMessageBrowseCarouselCardBrowseCarouselCardItemOpenUrlAction {
  /// URL
  ///
  /// Required.
  core.String? url;

  /// Specifies the type of viewer that is used when opening the URL.
  ///
  /// Defaults to opening via web browser.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "URL_TYPE_HINT_UNSPECIFIED" : Unspecified
  /// - "AMP_ACTION" : Url would be an amp action
  /// - "AMP_CONTENT" : URL that points directly to AMP content, or to a
  /// canonical URL which refers to AMP content via .
  core.String? urlTypeHint;

  GoogleCloudDialogflowV2IntentMessageBrowseCarouselCardBrowseCarouselCardItemOpenUrlAction();

  GoogleCloudDialogflowV2IntentMessageBrowseCarouselCardBrowseCarouselCardItemOpenUrlAction.fromJson(
      core.Map _json) {
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
    if (_json.containsKey('urlTypeHint')) {
      urlTypeHint = _json['urlTypeHint'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (url != null) 'url': url!,
        if (urlTypeHint != null) 'urlTypeHint': urlTypeHint!,
      };
}

/// The card response message.
class GoogleCloudDialogflowV2IntentMessageCard {
  /// The collection of card buttons.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2IntentMessageCardButton>? buttons;

  /// The public URI to an image file for the card.
  ///
  /// Optional.
  core.String? imageUri;

  /// The subtitle of the card.
  ///
  /// Optional.
  core.String? subtitle;

  /// The title of the card.
  ///
  /// Optional.
  core.String? title;

  GoogleCloudDialogflowV2IntentMessageCard();

  GoogleCloudDialogflowV2IntentMessageCard.fromJson(core.Map _json) {
    if (_json.containsKey('buttons')) {
      buttons = (_json['buttons'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessageCardButton>((value) =>
              GoogleCloudDialogflowV2IntentMessageCardButton.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('imageUri')) {
      imageUri = _json['imageUri'] as core.String;
    }
    if (_json.containsKey('subtitle')) {
      subtitle = _json['subtitle'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buttons != null)
          'buttons': buttons!.map((value) => value.toJson()).toList(),
        if (imageUri != null) 'imageUri': imageUri!,
        if (subtitle != null) 'subtitle': subtitle!,
        if (title != null) 'title': title!,
      };
}

/// Contains information about a button.
class GoogleCloudDialogflowV2IntentMessageCardButton {
  /// The text to send back to the Dialogflow API or a URI to open.
  ///
  /// Optional.
  core.String? postback;

  /// The text to show on the button.
  ///
  /// Optional.
  core.String? text;

  GoogleCloudDialogflowV2IntentMessageCardButton();

  GoogleCloudDialogflowV2IntentMessageCardButton.fromJson(core.Map _json) {
    if (_json.containsKey('postback')) {
      postback = _json['postback'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (postback != null) 'postback': postback!,
        if (text != null) 'text': text!,
      };
}

/// The card for presenting a carousel of options to select from.
class GoogleCloudDialogflowV2IntentMessageCarouselSelect {
  /// Carousel items.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowV2IntentMessageCarouselSelectItem>? items;

  GoogleCloudDialogflowV2IntentMessageCarouselSelect();

  GoogleCloudDialogflowV2IntentMessageCarouselSelect.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessageCarouselSelectItem>(
              (value) => GoogleCloudDialogflowV2IntentMessageCarouselSelectItem
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
      };
}

/// An item in the carousel.
class GoogleCloudDialogflowV2IntentMessageCarouselSelectItem {
  /// The body text of the card.
  ///
  /// Optional.
  core.String? description;

  /// The image to display.
  ///
  /// Optional.
  GoogleCloudDialogflowV2IntentMessageImage? image;

  /// Additional info about the option item.
  ///
  /// Required.
  GoogleCloudDialogflowV2IntentMessageSelectItemInfo? info;

  /// Title of the carousel item.
  ///
  /// Required.
  core.String? title;

  GoogleCloudDialogflowV2IntentMessageCarouselSelectItem();

  GoogleCloudDialogflowV2IntentMessageCarouselSelectItem.fromJson(
      core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('image')) {
      image = GoogleCloudDialogflowV2IntentMessageImage.fromJson(
          _json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('info')) {
      info = GoogleCloudDialogflowV2IntentMessageSelectItemInfo.fromJson(
          _json['info'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (image != null) 'image': image!.toJson(),
        if (info != null) 'info': info!.toJson(),
        if (title != null) 'title': title!,
      };
}

/// Column properties for TableCard.
class GoogleCloudDialogflowV2IntentMessageColumnProperties {
  /// Column heading.
  ///
  /// Required.
  core.String? header;

  /// Defines text alignment for all cells in this column.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "HORIZONTAL_ALIGNMENT_UNSPECIFIED" : Text is aligned to the leading edge
  /// of the column.
  /// - "LEADING" : Text is aligned to the leading edge of the column.
  /// - "CENTER" : Text is centered in the column.
  /// - "TRAILING" : Text is aligned to the trailing edge of the column.
  core.String? horizontalAlignment;

  GoogleCloudDialogflowV2IntentMessageColumnProperties();

  GoogleCloudDialogflowV2IntentMessageColumnProperties.fromJson(
      core.Map _json) {
    if (_json.containsKey('header')) {
      header = _json['header'] as core.String;
    }
    if (_json.containsKey('horizontalAlignment')) {
      horizontalAlignment = _json['horizontalAlignment'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (header != null) 'header': header!,
        if (horizontalAlignment != null)
          'horizontalAlignment': horizontalAlignment!,
      };
}

/// The image response message.
class GoogleCloudDialogflowV2IntentMessageImage {
  /// A text description of the image to be used for accessibility, e.g., screen
  /// readers.
  ///
  /// Optional.
  core.String? accessibilityText;

  /// The public URI to an image file.
  ///
  /// Optional.
  core.String? imageUri;

  GoogleCloudDialogflowV2IntentMessageImage();

  GoogleCloudDialogflowV2IntentMessageImage.fromJson(core.Map _json) {
    if (_json.containsKey('accessibilityText')) {
      accessibilityText = _json['accessibilityText'] as core.String;
    }
    if (_json.containsKey('imageUri')) {
      imageUri = _json['imageUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessibilityText != null) 'accessibilityText': accessibilityText!,
        if (imageUri != null) 'imageUri': imageUri!,
      };
}

/// The suggestion chip message that allows the user to jump out to the app or
/// website associated with this agent.
class GoogleCloudDialogflowV2IntentMessageLinkOutSuggestion {
  /// The name of the app or site this chip is linking to.
  ///
  /// Required.
  core.String? destinationName;

  /// The URI of the app or site to open when the user taps the suggestion chip.
  ///
  /// Required.
  core.String? uri;

  GoogleCloudDialogflowV2IntentMessageLinkOutSuggestion();

  GoogleCloudDialogflowV2IntentMessageLinkOutSuggestion.fromJson(
      core.Map _json) {
    if (_json.containsKey('destinationName')) {
      destinationName = _json['destinationName'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationName != null) 'destinationName': destinationName!,
        if (uri != null) 'uri': uri!,
      };
}

/// The card for presenting a list of options to select from.
class GoogleCloudDialogflowV2IntentMessageListSelect {
  /// List items.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowV2IntentMessageListSelectItem>? items;

  /// Subtitle of the list.
  ///
  /// Optional.
  core.String? subtitle;

  /// The overall title of the list.
  ///
  /// Optional.
  core.String? title;

  GoogleCloudDialogflowV2IntentMessageListSelect();

  GoogleCloudDialogflowV2IntentMessageListSelect.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessageListSelectItem>((value) =>
              GoogleCloudDialogflowV2IntentMessageListSelectItem.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('subtitle')) {
      subtitle = _json['subtitle'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (subtitle != null) 'subtitle': subtitle!,
        if (title != null) 'title': title!,
      };
}

/// An item in the list.
class GoogleCloudDialogflowV2IntentMessageListSelectItem {
  /// The main text describing the item.
  ///
  /// Optional.
  core.String? description;

  /// The image to display.
  ///
  /// Optional.
  GoogleCloudDialogflowV2IntentMessageImage? image;

  /// Additional information about this option.
  ///
  /// Required.
  GoogleCloudDialogflowV2IntentMessageSelectItemInfo? info;

  /// The title of the list item.
  ///
  /// Required.
  core.String? title;

  GoogleCloudDialogflowV2IntentMessageListSelectItem();

  GoogleCloudDialogflowV2IntentMessageListSelectItem.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('image')) {
      image = GoogleCloudDialogflowV2IntentMessageImage.fromJson(
          _json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('info')) {
      info = GoogleCloudDialogflowV2IntentMessageSelectItemInfo.fromJson(
          _json['info'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (image != null) 'image': image!.toJson(),
        if (info != null) 'info': info!.toJson(),
        if (title != null) 'title': title!,
      };
}

/// The media content card for Actions on Google.
class GoogleCloudDialogflowV2IntentMessageMediaContent {
  /// List of media objects.
  ///
  /// Required.
  core.List<
          GoogleCloudDialogflowV2IntentMessageMediaContentResponseMediaObject>?
      mediaObjects;

  /// What type of media is the content (ie "audio").
  ///
  /// Optional.
  /// Possible string values are:
  /// - "RESPONSE_MEDIA_TYPE_UNSPECIFIED" : Unspecified.
  /// - "AUDIO" : Response media type is audio.
  core.String? mediaType;

  GoogleCloudDialogflowV2IntentMessageMediaContent();

  GoogleCloudDialogflowV2IntentMessageMediaContent.fromJson(core.Map _json) {
    if (_json.containsKey('mediaObjects')) {
      mediaObjects = (_json['mediaObjects'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessageMediaContentResponseMediaObject>(
              (value) =>
                  GoogleCloudDialogflowV2IntentMessageMediaContentResponseMediaObject
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('mediaType')) {
      mediaType = _json['mediaType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mediaObjects != null)
          'mediaObjects': mediaObjects!.map((value) => value.toJson()).toList(),
        if (mediaType != null) 'mediaType': mediaType!,
      };
}

/// Response media object for media content card.
class GoogleCloudDialogflowV2IntentMessageMediaContentResponseMediaObject {
  /// Url where the media is stored.
  ///
  /// Required.
  core.String? contentUrl;

  /// Description of media card.
  ///
  /// Optional.
  core.String? description;

  /// Icon to display above media content.
  ///
  /// Optional.
  GoogleCloudDialogflowV2IntentMessageImage? icon;

  /// Image to display above media content.
  ///
  /// Optional.
  GoogleCloudDialogflowV2IntentMessageImage? largeImage;

  /// Name of media card.
  ///
  /// Required.
  core.String? name;

  GoogleCloudDialogflowV2IntentMessageMediaContentResponseMediaObject();

  GoogleCloudDialogflowV2IntentMessageMediaContentResponseMediaObject.fromJson(
      core.Map _json) {
    if (_json.containsKey('contentUrl')) {
      contentUrl = _json['contentUrl'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('icon')) {
      icon = GoogleCloudDialogflowV2IntentMessageImage.fromJson(
          _json['icon'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('largeImage')) {
      largeImage = GoogleCloudDialogflowV2IntentMessageImage.fromJson(
          _json['largeImage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentUrl != null) 'contentUrl': contentUrl!,
        if (description != null) 'description': description!,
        if (icon != null) 'icon': icon!.toJson(),
        if (largeImage != null) 'largeImage': largeImage!.toJson(),
        if (name != null) 'name': name!,
      };
}

/// The quick replies response message.
class GoogleCloudDialogflowV2IntentMessageQuickReplies {
  /// The collection of quick replies.
  ///
  /// Optional.
  core.List<core.String>? quickReplies;

  /// The title of the collection of quick replies.
  ///
  /// Optional.
  core.String? title;

  GoogleCloudDialogflowV2IntentMessageQuickReplies();

  GoogleCloudDialogflowV2IntentMessageQuickReplies.fromJson(core.Map _json) {
    if (_json.containsKey('quickReplies')) {
      quickReplies = (_json['quickReplies'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (quickReplies != null) 'quickReplies': quickReplies!,
        if (title != null) 'title': title!,
      };
}

/// Additional info about the select item for when it is triggered in a dialog.
class GoogleCloudDialogflowV2IntentMessageSelectItemInfo {
  /// A unique key that will be sent back to the agent if this response is
  /// given.
  ///
  /// Required.
  core.String? key;

  /// A list of synonyms that can also be used to trigger this item in dialog.
  ///
  /// Optional.
  core.List<core.String>? synonyms;

  GoogleCloudDialogflowV2IntentMessageSelectItemInfo();

  GoogleCloudDialogflowV2IntentMessageSelectItemInfo.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('synonyms')) {
      synonyms = (_json['synonyms'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (synonyms != null) 'synonyms': synonyms!,
      };
}

/// The simple response message containing speech or text.
class GoogleCloudDialogflowV2IntentMessageSimpleResponse {
  /// The text to display.
  ///
  /// Optional.
  core.String? displayText;

  /// One of text_to_speech or ssml must be provided.
  ///
  /// Structured spoken response to the user in the SSML format. Mutually
  /// exclusive with text_to_speech.
  core.String? ssml;

  /// One of text_to_speech or ssml must be provided.
  ///
  /// The plain text of the speech output. Mutually exclusive with ssml.
  core.String? textToSpeech;

  GoogleCloudDialogflowV2IntentMessageSimpleResponse();

  GoogleCloudDialogflowV2IntentMessageSimpleResponse.fromJson(core.Map _json) {
    if (_json.containsKey('displayText')) {
      displayText = _json['displayText'] as core.String;
    }
    if (_json.containsKey('ssml')) {
      ssml = _json['ssml'] as core.String;
    }
    if (_json.containsKey('textToSpeech')) {
      textToSpeech = _json['textToSpeech'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayText != null) 'displayText': displayText!,
        if (ssml != null) 'ssml': ssml!,
        if (textToSpeech != null) 'textToSpeech': textToSpeech!,
      };
}

/// The collection of simple response candidates.
///
/// This message in `QueryResult.fulfillment_messages` and
/// `WebhookResponse.fulfillment_messages` should contain only one
/// `SimpleResponse`.
class GoogleCloudDialogflowV2IntentMessageSimpleResponses {
  /// The list of simple responses.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowV2IntentMessageSimpleResponse>?
      simpleResponses;

  GoogleCloudDialogflowV2IntentMessageSimpleResponses();

  GoogleCloudDialogflowV2IntentMessageSimpleResponses.fromJson(core.Map _json) {
    if (_json.containsKey('simpleResponses')) {
      simpleResponses = (_json['simpleResponses'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessageSimpleResponse>((value) =>
              GoogleCloudDialogflowV2IntentMessageSimpleResponse.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (simpleResponses != null)
          'simpleResponses':
              simpleResponses!.map((value) => value.toJson()).toList(),
      };
}

/// The suggestion chip message that the user can tap to quickly post a reply to
/// the conversation.
class GoogleCloudDialogflowV2IntentMessageSuggestion {
  /// The text shown the in the suggestion chip.
  ///
  /// Required.
  core.String? title;

  GoogleCloudDialogflowV2IntentMessageSuggestion();

  GoogleCloudDialogflowV2IntentMessageSuggestion.fromJson(core.Map _json) {
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (title != null) 'title': title!,
      };
}

/// The collection of suggestions.
class GoogleCloudDialogflowV2IntentMessageSuggestions {
  /// The list of suggested replies.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowV2IntentMessageSuggestion>? suggestions;

  GoogleCloudDialogflowV2IntentMessageSuggestions();

  GoogleCloudDialogflowV2IntentMessageSuggestions.fromJson(core.Map _json) {
    if (_json.containsKey('suggestions')) {
      suggestions = (_json['suggestions'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessageSuggestion>((value) =>
              GoogleCloudDialogflowV2IntentMessageSuggestion.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (suggestions != null)
          'suggestions': suggestions!.map((value) => value.toJson()).toList(),
      };
}

/// Table card for Actions on Google.
class GoogleCloudDialogflowV2IntentMessageTableCard {
  /// List of buttons for the card.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2IntentMessageBasicCardButton>? buttons;

  /// Display properties for the columns in this table.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2IntentMessageColumnProperties>?
      columnProperties;

  /// Image which should be displayed on the card.
  ///
  /// Optional.
  GoogleCloudDialogflowV2IntentMessageImage? image;

  /// Rows in this table of data.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2IntentMessageTableCardRow>? rows;

  /// Subtitle to the title.
  ///
  /// Optional.
  core.String? subtitle;

  /// Title of the card.
  ///
  /// Required.
  core.String? title;

  GoogleCloudDialogflowV2IntentMessageTableCard();

  GoogleCloudDialogflowV2IntentMessageTableCard.fromJson(core.Map _json) {
    if (_json.containsKey('buttons')) {
      buttons = (_json['buttons'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessageBasicCardButton>((value) =>
              GoogleCloudDialogflowV2IntentMessageBasicCardButton.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('columnProperties')) {
      columnProperties = (_json['columnProperties'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessageColumnProperties>((value) =>
              GoogleCloudDialogflowV2IntentMessageColumnProperties.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('image')) {
      image = GoogleCloudDialogflowV2IntentMessageImage.fromJson(
          _json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rows')) {
      rows = (_json['rows'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessageTableCardRow>((value) =>
              GoogleCloudDialogflowV2IntentMessageTableCardRow.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('subtitle')) {
      subtitle = _json['subtitle'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buttons != null)
          'buttons': buttons!.map((value) => value.toJson()).toList(),
        if (columnProperties != null)
          'columnProperties':
              columnProperties!.map((value) => value.toJson()).toList(),
        if (image != null) 'image': image!.toJson(),
        if (rows != null) 'rows': rows!.map((value) => value.toJson()).toList(),
        if (subtitle != null) 'subtitle': subtitle!,
        if (title != null) 'title': title!,
      };
}

/// Cell of TableCardRow.
class GoogleCloudDialogflowV2IntentMessageTableCardCell {
  /// Text in this cell.
  ///
  /// Required.
  core.String? text;

  GoogleCloudDialogflowV2IntentMessageTableCardCell();

  GoogleCloudDialogflowV2IntentMessageTableCardCell.fromJson(core.Map _json) {
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (text != null) 'text': text!,
      };
}

/// Row of TableCard.
class GoogleCloudDialogflowV2IntentMessageTableCardRow {
  /// List of cells that make up this row.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2IntentMessageTableCardCell>? cells;

  /// Whether to add a visual divider after this row.
  ///
  /// Optional.
  core.bool? dividerAfter;

  GoogleCloudDialogflowV2IntentMessageTableCardRow();

  GoogleCloudDialogflowV2IntentMessageTableCardRow.fromJson(core.Map _json) {
    if (_json.containsKey('cells')) {
      cells = (_json['cells'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessageTableCardCell>((value) =>
              GoogleCloudDialogflowV2IntentMessageTableCardCell.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dividerAfter')) {
      dividerAfter = _json['dividerAfter'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cells != null)
          'cells': cells!.map((value) => value.toJson()).toList(),
        if (dividerAfter != null) 'dividerAfter': dividerAfter!,
      };
}

/// The text response message.
class GoogleCloudDialogflowV2IntentMessageText {
  /// The collection of the agent's responses.
  ///
  /// Optional.
  core.List<core.String>? text;

  GoogleCloudDialogflowV2IntentMessageText();

  GoogleCloudDialogflowV2IntentMessageText.fromJson(core.Map _json) {
    if (_json.containsKey('text')) {
      text = (_json['text'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (text != null) 'text': text!,
      };
}

/// Represents intent parameters.
class GoogleCloudDialogflowV2IntentParameter {
  /// The default value to use when the `value` yields an empty result.
  ///
  /// Default values can be extracted from contexts by using the following
  /// syntax: `#context_name.parameter_name`.
  ///
  /// Optional.
  core.String? defaultValue;

  /// The name of the parameter.
  ///
  /// Required.
  core.String? displayName;

  /// The name of the entity type, prefixed with `@`, that describes values of
  /// the parameter.
  ///
  /// If the parameter is required, this must be provided.
  ///
  /// Optional.
  core.String? entityTypeDisplayName;

  /// Indicates whether the parameter represents a list of values.
  ///
  /// Optional.
  core.bool? isList;

  /// Indicates whether the parameter is required.
  ///
  /// That is, whether the intent cannot be completed without collecting the
  /// parameter value.
  ///
  /// Optional.
  core.bool? mandatory;

  /// The unique identifier of this parameter.
  core.String? name;

  /// The collection of prompts that the agent can present to the user in order
  /// to collect a value for the parameter.
  ///
  /// Optional.
  core.List<core.String>? prompts;

  /// The definition of the parameter value.
  ///
  /// It can be: - a constant string, - a parameter value defined as
  /// `$parameter_name`, - an original parameter value defined as
  /// `$parameter_name.original`, - a parameter value from some context defined
  /// as `#context_name.parameter_name`.
  ///
  /// Optional.
  core.String? value;

  GoogleCloudDialogflowV2IntentParameter();

  GoogleCloudDialogflowV2IntentParameter.fromJson(core.Map _json) {
    if (_json.containsKey('defaultValue')) {
      defaultValue = _json['defaultValue'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('entityTypeDisplayName')) {
      entityTypeDisplayName = _json['entityTypeDisplayName'] as core.String;
    }
    if (_json.containsKey('isList')) {
      isList = _json['isList'] as core.bool;
    }
    if (_json.containsKey('mandatory')) {
      mandatory = _json['mandatory'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('prompts')) {
      prompts = (_json['prompts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (defaultValue != null) 'defaultValue': defaultValue!,
        if (displayName != null) 'displayName': displayName!,
        if (entityTypeDisplayName != null)
          'entityTypeDisplayName': entityTypeDisplayName!,
        if (isList != null) 'isList': isList!,
        if (mandatory != null) 'mandatory': mandatory!,
        if (name != null) 'name': name!,
        if (prompts != null) 'prompts': prompts!,
        if (value != null) 'value': value!,
      };
}

/// Represents an example that the agent is trained on.
class GoogleCloudDialogflowV2IntentTrainingPhrase {
  /// The unique identifier of this training phrase.
  ///
  /// Output only.
  core.String? name;

  /// The ordered list of training phrase parts.
  ///
  /// The parts are concatenated in order to form the training phrase. Note: The
  /// API does not automatically annotate training phrases like the Dialogflow
  /// Console does. Note: Do not forget to include whitespace at part
  /// boundaries, so the training phrase is well formatted when the parts are
  /// concatenated. If the training phrase does not need to be annotated with
  /// parameters, you just need a single part with only the Part.text field set.
  /// If you want to annotate the training phrase, you must create multiple
  /// parts, where the fields of each part are populated in one of two ways: -
  /// `Part.text` is set to a part of the phrase that has no parameters. -
  /// `Part.text` is set to a part of the phrase that you want to annotate, and
  /// the `entity_type`, `alias`, and `user_defined` fields are all set.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowV2IntentTrainingPhrasePart>? parts;

  /// Indicates how many times this example was added to the intent.
  ///
  /// Each time a developer adds an existing sample by editing an intent or
  /// training, this counter is increased.
  ///
  /// Optional.
  core.int? timesAddedCount;

  /// The type of the training phrase.
  ///
  /// Required.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Not specified. This value should never be used.
  /// - "EXAMPLE" : Examples do not contain @-prefixed entity type names, but
  /// example parts can be annotated with entity types.
  /// - "TEMPLATE" : Templates are not annotated with entity types, but they can
  /// contain @-prefixed entity type names as substrings. Template mode has been
  /// deprecated. Example mode is the only supported way to create new training
  /// phrases. If you have existing training phrases that you've created in
  /// template mode, those will continue to work.
  core.String? type;

  GoogleCloudDialogflowV2IntentTrainingPhrase();

  GoogleCloudDialogflowV2IntentTrainingPhrase.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parts')) {
      parts = (_json['parts'] as core.List)
          .map<GoogleCloudDialogflowV2IntentTrainingPhrasePart>((value) =>
              GoogleCloudDialogflowV2IntentTrainingPhrasePart.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('timesAddedCount')) {
      timesAddedCount = _json['timesAddedCount'] as core.int;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (parts != null)
          'parts': parts!.map((value) => value.toJson()).toList(),
        if (timesAddedCount != null) 'timesAddedCount': timesAddedCount!,
        if (type != null) 'type': type!,
      };
}

/// Represents a part of a training phrase.
class GoogleCloudDialogflowV2IntentTrainingPhrasePart {
  /// The parameter name for the value extracted from the annotated part of the
  /// example.
  ///
  /// This field is required for annotated parts of the training phrase.
  ///
  /// Optional.
  core.String? alias;

  /// The entity type name prefixed with `@`.
  ///
  /// This field is required for annotated parts of the training phrase.
  ///
  /// Optional.
  core.String? entityType;

  /// The text for this part.
  ///
  /// Required.
  core.String? text;

  /// Indicates whether the text was manually annotated.
  ///
  /// This field is set to true when the Dialogflow Console is used to manually
  /// annotate the part. When creating an annotated part with the API, you must
  /// set this to true.
  ///
  /// Optional.
  core.bool? userDefined;

  GoogleCloudDialogflowV2IntentTrainingPhrasePart();

  GoogleCloudDialogflowV2IntentTrainingPhrasePart.fromJson(core.Map _json) {
    if (_json.containsKey('alias')) {
      alias = _json['alias'] as core.String;
    }
    if (_json.containsKey('entityType')) {
      entityType = _json['entityType'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
    if (_json.containsKey('userDefined')) {
      userDefined = _json['userDefined'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alias != null) 'alias': alias!,
        if (entityType != null) 'entityType': entityType!,
        if (text != null) 'text': text!,
        if (userDefined != null) 'userDefined': userDefined!,
      };
}

/// Metadata in google::longrunning::Operation for Knowledge operations.
class GoogleCloudDialogflowV2KnowledgeOperationMetadata {
  /// The current state of this operation.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : State unspecified.
  /// - "PENDING" : The operation has been created.
  /// - "RUNNING" : The operation is currently running.
  /// - "DONE" : The operation is done, either cancelled or completed.
  core.String? state;

  GoogleCloudDialogflowV2KnowledgeOperationMetadata();

  GoogleCloudDialogflowV2KnowledgeOperationMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (state != null) 'state': state!,
      };
}

/// Represents a message posted into a conversation.
class GoogleCloudDialogflowV2Message {
  /// The message content.
  ///
  /// Required.
  core.String? content;

  /// The time when the message was created.
  ///
  /// Output only.
  core.String? createTime;

  /// The message language.
  ///
  /// This should be a \[BCP-47\](https://www.rfc-editor.org/rfc/bcp/bcp47.txt)
  /// language tag. Example: "en-US".
  ///
  /// Optional.
  core.String? languageCode;

  /// The annotation for the message.
  ///
  /// Output only.
  GoogleCloudDialogflowV2MessageAnnotation? messageAnnotation;

  /// The unique identifier of the message.
  ///
  /// Format: `projects//locations//conversations//messages/`.
  core.String? name;

  /// The participant that sends this message.
  ///
  /// Output only.
  core.String? participant;

  /// The role of the participant.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "ROLE_UNSPECIFIED" : Participant role not set.
  /// - "HUMAN_AGENT" : Participant is a human agent.
  /// - "AUTOMATED_AGENT" : Participant is an automated agent, such as a
  /// Dialogflow agent.
  /// - "END_USER" : Participant is an end user that has called or chatted with
  /// Dialogflow services.
  core.String? participantRole;

  GoogleCloudDialogflowV2Message();

  GoogleCloudDialogflowV2Message.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('messageAnnotation')) {
      messageAnnotation = GoogleCloudDialogflowV2MessageAnnotation.fromJson(
          _json['messageAnnotation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('participant')) {
      participant = _json['participant'] as core.String;
    }
    if (_json.containsKey('participantRole')) {
      participantRole = _json['participantRole'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!,
        if (createTime != null) 'createTime': createTime!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (messageAnnotation != null)
          'messageAnnotation': messageAnnotation!.toJson(),
        if (name != null) 'name': name!,
        if (participant != null) 'participant': participant!,
        if (participantRole != null) 'participantRole': participantRole!,
      };
}

/// Represents the result of annotation for the message.
class GoogleCloudDialogflowV2MessageAnnotation {
  /// Indicates whether the text message contains entities.
  core.bool? containEntities;

  /// The collection of annotated message parts ordered by their position in the
  /// message.
  ///
  /// You can recover the annotated message by concatenating
  /// \[AnnotatedMessagePart.text\].
  core.List<GoogleCloudDialogflowV2AnnotatedMessagePart>? parts;

  GoogleCloudDialogflowV2MessageAnnotation();

  GoogleCloudDialogflowV2MessageAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('containEntities')) {
      containEntities = _json['containEntities'] as core.bool;
    }
    if (_json.containsKey('parts')) {
      parts = (_json['parts'] as core.List)
          .map<GoogleCloudDialogflowV2AnnotatedMessagePart>((value) =>
              GoogleCloudDialogflowV2AnnotatedMessagePart.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (containEntities != null) 'containEntities': containEntities!,
        if (parts != null)
          'parts': parts!.map((value) => value.toJson()).toList(),
      };
}

/// Represents the contents of the original request that was passed to the
/// `[Streaming]DetectIntent` call.
class GoogleCloudDialogflowV2OriginalDetectIntentRequest {
  /// This field is set to the value of the `QueryParameters.payload` field
  /// passed in the request.
  ///
  /// Some integrations that query a Dialogflow agent may provide additional
  /// information in the payload. In particular, for the Dialogflow Phone
  /// Gateway integration, this field has the form: { "telephony": {
  /// "caller_id": "+18558363987" } } Note: The caller ID field (`caller_id`)
  /// will be redacted for Trial Edition agents and populated with the caller ID
  /// in [E.164 format](https://en.wikipedia.org/wiki/E.164) for Essentials
  /// Edition agents.
  ///
  /// Optional.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? payload;

  /// The source of this request, e.g., `google`, `facebook`, `slack`.
  ///
  /// It is set by Dialogflow-owned servers.
  core.String? source;

  /// The version of the protocol used for this request.
  ///
  /// This field is AoG-specific.
  ///
  /// Optional.
  core.String? version;

  GoogleCloudDialogflowV2OriginalDetectIntentRequest();

  GoogleCloudDialogflowV2OriginalDetectIntentRequest.fromJson(core.Map _json) {
    if (_json.containsKey('payload')) {
      payload = (_json['payload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (payload != null) 'payload': payload!,
        if (source != null) 'source': source!,
        if (version != null) 'version': version!,
      };
}

/// Represents the result of conversational query or event processing.
class GoogleCloudDialogflowV2QueryResult {
  /// The action name from the matched intent.
  core.String? action;

  /// This field is set to: - `false` if the matched intent has required
  /// parameters and not all of the required parameter values have been
  /// collected.
  ///
  /// - `true` if all required parameter values have been collected, or if the
  /// matched intent doesn't contain any required parameters.
  core.bool? allRequiredParamsPresent;

  /// Free-form diagnostic information for the associated detect intent request.
  ///
  /// The fields of this data can change without notice, so you should not write
  /// code that depends on its structure. The data may contain: - webhook call
  /// latency - webhook errors
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? diagnosticInfo;

  /// The collection of rich messages to present to the user.
  core.List<GoogleCloudDialogflowV2IntentMessage>? fulfillmentMessages;

  /// The text to be pronounced to the user or shown on the screen.
  ///
  /// Note: This is a legacy field, `fulfillment_messages` should be preferred.
  core.String? fulfillmentText;

  /// The intent that matched the conversational query.
  ///
  /// Some, not all fields are filled in this message, including but not limited
  /// to: `name`, `display_name`, `end_interaction` and `is_fallback`.
  GoogleCloudDialogflowV2Intent? intent;

  /// The intent detection confidence.
  ///
  /// Values range from 0.0 (completely uncertain) to 1.0 (completely certain).
  /// This value is for informational purpose only and is only used to help
  /// match the best intent within the classification threshold. This value may
  /// change for the same end-user expression at any time due to a model
  /// retraining or change in implementation. If there are `multiple
  /// knowledge_answers` messages, this value is set to the greatest
  /// `knowledgeAnswers.match_confidence` value in the list.
  core.double? intentDetectionConfidence;

  /// The language that was triggered during intent detection.
  ///
  /// See
  /// [Language Support](https://cloud.google.com/dialogflow/docs/reference/language)
  /// for a list of the currently supported language codes.
  core.String? languageCode;

  /// The collection of output contexts.
  ///
  /// If applicable, `output_contexts.parameters` contains entries with name
  /// `.original` containing the original parameter values before the query.
  core.List<GoogleCloudDialogflowV2Context>? outputContexts;

  /// The collection of extracted parameters.
  ///
  /// Depending on your protocol or client library language, this is a map,
  /// associative array, symbol table, dictionary, or JSON object composed of a
  /// collection of (MapKey, MapValue) pairs: - MapKey type: string - MapKey
  /// value: parameter name - MapValue type: - If parameter's entity type is a
  /// composite entity: map - Else: depending on parameter value type, could be
  /// one of string, number, boolean, null, list or map - MapValue value: - If
  /// parameter's entity type is a composite entity: map from composite entity
  /// property names to property values - Else: parameter value
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? parameters;

  /// The original conversational query text: - If natural language text was
  /// provided as input, `query_text` contains a copy of the input.
  ///
  /// - If natural language speech audio was provided as input, `query_text`
  /// contains the speech recognition result. If speech recognizer produced
  /// multiple alternatives, a particular one is picked. - If automatic spell
  /// correction is enabled, `query_text` will contain the corrected user input.
  core.String? queryText;

  /// The sentiment analysis result, which depends on the
  /// `sentiment_analysis_request_config` specified in the request.
  GoogleCloudDialogflowV2SentimentAnalysisResult? sentimentAnalysisResult;

  /// The Speech recognition confidence between 0.0 and 1.0.
  ///
  /// A higher number indicates an estimated greater likelihood that the
  /// recognized words are correct. The default of 0.0 is a sentinel value
  /// indicating that confidence was not set. This field is not guaranteed to be
  /// accurate or set. In particular this field isn't set for
  /// StreamingDetectIntent since the streaming endpoint has separate confidence
  /// estimates per portion of the audio in StreamingRecognitionResult.
  core.double? speechRecognitionConfidence;

  /// If the query was fulfilled by a webhook call, this field is set to the
  /// value of the `payload` field returned in the webhook response.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? webhookPayload;

  /// If the query was fulfilled by a webhook call, this field is set to the
  /// value of the `source` field returned in the webhook response.
  core.String? webhookSource;

  GoogleCloudDialogflowV2QueryResult();

  GoogleCloudDialogflowV2QueryResult.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('allRequiredParamsPresent')) {
      allRequiredParamsPresent = _json['allRequiredParamsPresent'] as core.bool;
    }
    if (_json.containsKey('diagnosticInfo')) {
      diagnosticInfo =
          (_json['diagnosticInfo'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('fulfillmentMessages')) {
      fulfillmentMessages = (_json['fulfillmentMessages'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessage>((value) =>
              GoogleCloudDialogflowV2IntentMessage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('fulfillmentText')) {
      fulfillmentText = _json['fulfillmentText'] as core.String;
    }
    if (_json.containsKey('intent')) {
      intent = GoogleCloudDialogflowV2Intent.fromJson(
          _json['intent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('intentDetectionConfidence')) {
      intentDetectionConfidence =
          (_json['intentDetectionConfidence'] as core.num).toDouble();
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('outputContexts')) {
      outputContexts = (_json['outputContexts'] as core.List)
          .map<GoogleCloudDialogflowV2Context>((value) =>
              GoogleCloudDialogflowV2Context.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('parameters')) {
      parameters =
          (_json['parameters'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('queryText')) {
      queryText = _json['queryText'] as core.String;
    }
    if (_json.containsKey('sentimentAnalysisResult')) {
      sentimentAnalysisResult =
          GoogleCloudDialogflowV2SentimentAnalysisResult.fromJson(
              _json['sentimentAnalysisResult']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('speechRecognitionConfidence')) {
      speechRecognitionConfidence =
          (_json['speechRecognitionConfidence'] as core.num).toDouble();
    }
    if (_json.containsKey('webhookPayload')) {
      webhookPayload =
          (_json['webhookPayload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('webhookSource')) {
      webhookSource = _json['webhookSource'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (allRequiredParamsPresent != null)
          'allRequiredParamsPresent': allRequiredParamsPresent!,
        if (diagnosticInfo != null) 'diagnosticInfo': diagnosticInfo!,
        if (fulfillmentMessages != null)
          'fulfillmentMessages':
              fulfillmentMessages!.map((value) => value.toJson()).toList(),
        if (fulfillmentText != null) 'fulfillmentText': fulfillmentText!,
        if (intent != null) 'intent': intent!.toJson(),
        if (intentDetectionConfidence != null)
          'intentDetectionConfidence': intentDetectionConfidence!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (outputContexts != null)
          'outputContexts':
              outputContexts!.map((value) => value.toJson()).toList(),
        if (parameters != null) 'parameters': parameters!,
        if (queryText != null) 'queryText': queryText!,
        if (sentimentAnalysisResult != null)
          'sentimentAnalysisResult': sentimentAnalysisResult!.toJson(),
        if (speechRecognitionConfidence != null)
          'speechRecognitionConfidence': speechRecognitionConfidence!,
        if (webhookPayload != null) 'webhookPayload': webhookPayload!,
        if (webhookSource != null) 'webhookSource': webhookSource!,
      };
}

/// The sentiment, such as positive/negative feeling or association, for a unit
/// of analysis, such as the query text.
class GoogleCloudDialogflowV2Sentiment {
  /// A non-negative number in the \[0, +inf) range, which represents the
  /// absolute magnitude of sentiment, regardless of score (positive or
  /// negative).
  core.double? magnitude;

  /// Sentiment score between -1.0 (negative sentiment) and 1.0 (positive
  /// sentiment).
  core.double? score;

  GoogleCloudDialogflowV2Sentiment();

  GoogleCloudDialogflowV2Sentiment.fromJson(core.Map _json) {
    if (_json.containsKey('magnitude')) {
      magnitude = (_json['magnitude'] as core.num).toDouble();
    }
    if (_json.containsKey('score')) {
      score = (_json['score'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (magnitude != null) 'magnitude': magnitude!,
        if (score != null) 'score': score!,
      };
}

/// The result of sentiment analysis.
///
/// Sentiment analysis inspects user input and identifies the prevailing
/// subjective opinion, especially to determine a user's attitude as positive,
/// negative, or neutral. For Participants.DetectIntent, it needs to be
/// configured in DetectIntentRequest.query_params. For
/// Participants.StreamingDetectIntent, it needs to be configured in
/// StreamingDetectIntentRequest.query_params. And for
/// Participants.AnalyzeContent and Participants.StreamingAnalyzeContent, it
/// needs to be configured in ConversationProfile.human_agent_assistant_config
class GoogleCloudDialogflowV2SentimentAnalysisResult {
  /// The sentiment analysis result for `query_text`.
  GoogleCloudDialogflowV2Sentiment? queryTextSentiment;

  GoogleCloudDialogflowV2SentimentAnalysisResult();

  GoogleCloudDialogflowV2SentimentAnalysisResult.fromJson(core.Map _json) {
    if (_json.containsKey('queryTextSentiment')) {
      queryTextSentiment = GoogleCloudDialogflowV2Sentiment.fromJson(
          _json['queryTextSentiment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (queryTextSentiment != null)
          'queryTextSentiment': queryTextSentiment!.toJson(),
      };
}

/// A session represents a conversation between a Dialogflow agent and an
/// end-user.
///
/// You can create special entities, called session entities, during a session.
/// Session entities can extend or replace custom entity types and only exist
/// during the session that they were created for. All session data, including
/// session entities, is stored by Dialogflow for 20 minutes. For more
/// information, see the
/// [session entity guide](https://cloud.google.com/dialogflow/docs/entities-session).
class GoogleCloudDialogflowV2SessionEntityType {
  /// The collection of entities associated with this session entity type.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowV2EntityTypeEntity>? entities;

  /// Indicates whether the additional data should override or supplement the
  /// custom entity type definition.
  ///
  /// Required.
  /// Possible string values are:
  /// - "ENTITY_OVERRIDE_MODE_UNSPECIFIED" : Not specified. This value should be
  /// never used.
  /// - "ENTITY_OVERRIDE_MODE_OVERRIDE" : The collection of session entities
  /// overrides the collection of entities in the corresponding custom entity
  /// type.
  /// - "ENTITY_OVERRIDE_MODE_SUPPLEMENT" : The collection of session entities
  /// extends the collection of entities in the corresponding custom entity
  /// type. Note: Even in this override mode calls to `ListSessionEntityTypes`,
  /// `GetSessionEntityType`, `CreateSessionEntityType` and
  /// `UpdateSessionEntityType` only return the additional entities added in
  /// this session entity type. If you want to get the supplemented list, please
  /// call EntityTypes.GetEntityType on the custom entity type and merge.
  core.String? entityOverrideMode;

  /// The unique identifier of this session entity type.
  ///
  /// Format: `projects//agent/sessions//entityTypes/`, or
  /// `projects//agent/environments//users//sessions//entityTypes/`. If
  /// `Environment ID` is not specified, we assume default 'draft' environment.
  /// If `User ID` is not specified, we assume default '-' user. `` must be the
  /// display name of an existing entity type in the same agent that will be
  /// overridden or supplemented.
  ///
  /// Required.
  core.String? name;

  GoogleCloudDialogflowV2SessionEntityType();

  GoogleCloudDialogflowV2SessionEntityType.fromJson(core.Map _json) {
    if (_json.containsKey('entities')) {
      entities = (_json['entities'] as core.List)
          .map<GoogleCloudDialogflowV2EntityTypeEntity>((value) =>
              GoogleCloudDialogflowV2EntityTypeEntity.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('entityOverrideMode')) {
      entityOverrideMode = _json['entityOverrideMode'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entities != null)
          'entities': entities!.map((value) => value.toJson()).toList(),
        if (entityOverrideMode != null)
          'entityOverrideMode': entityOverrideMode!,
        if (name != null) 'name': name!,
      };
}

/// The response message for Participants.SuggestArticles.
class GoogleCloudDialogflowV2SuggestArticlesResponse {
  /// Articles ordered by score in descending order.
  core.List<GoogleCloudDialogflowV2ArticleAnswer>? articleAnswers;

  /// Number of messages prior to and including latest_message to compile the
  /// suggestion.
  ///
  /// It may be smaller than the SuggestArticlesRequest.context_size field in
  /// the request if there aren't that many messages in the conversation.
  core.int? contextSize;

  /// The name of the latest conversation message used to compile suggestion
  /// for.
  ///
  /// Format: `projects//locations//conversations//messages/`.
  core.String? latestMessage;

  GoogleCloudDialogflowV2SuggestArticlesResponse();

  GoogleCloudDialogflowV2SuggestArticlesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('articleAnswers')) {
      articleAnswers = (_json['articleAnswers'] as core.List)
          .map<GoogleCloudDialogflowV2ArticleAnswer>((value) =>
              GoogleCloudDialogflowV2ArticleAnswer.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('contextSize')) {
      contextSize = _json['contextSize'] as core.int;
    }
    if (_json.containsKey('latestMessage')) {
      latestMessage = _json['latestMessage'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (articleAnswers != null)
          'articleAnswers':
              articleAnswers!.map((value) => value.toJson()).toList(),
        if (contextSize != null) 'contextSize': contextSize!,
        if (latestMessage != null) 'latestMessage': latestMessage!,
      };
}

/// The request message for Participants.SuggestFaqAnswers.
class GoogleCloudDialogflowV2SuggestFaqAnswersResponse {
  /// Number of messages prior to and including latest_message to compile the
  /// suggestion.
  ///
  /// It may be smaller than the SuggestFaqAnswersRequest.context_size field in
  /// the request if there aren't that many messages in the conversation.
  core.int? contextSize;

  /// Answers extracted from FAQ documents.
  core.List<GoogleCloudDialogflowV2FaqAnswer>? faqAnswers;

  /// The name of the latest conversation message used to compile suggestion
  /// for.
  ///
  /// Format: `projects//locations//conversations//messages/`.
  core.String? latestMessage;

  GoogleCloudDialogflowV2SuggestFaqAnswersResponse();

  GoogleCloudDialogflowV2SuggestFaqAnswersResponse.fromJson(core.Map _json) {
    if (_json.containsKey('contextSize')) {
      contextSize = _json['contextSize'] as core.int;
    }
    if (_json.containsKey('faqAnswers')) {
      faqAnswers = (_json['faqAnswers'] as core.List)
          .map<GoogleCloudDialogflowV2FaqAnswer>((value) =>
              GoogleCloudDialogflowV2FaqAnswer.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('latestMessage')) {
      latestMessage = _json['latestMessage'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contextSize != null) 'contextSize': contextSize!,
        if (faqAnswers != null)
          'faqAnswers': faqAnswers!.map((value) => value.toJson()).toList(),
        if (latestMessage != null) 'latestMessage': latestMessage!,
      };
}

/// One response of different type of suggestion response which is used in the
/// response of Participants.AnalyzeContent and Participants.AnalyzeContent, as
/// well as HumanAgentAssistantEvent.
class GoogleCloudDialogflowV2SuggestionResult {
  /// Error status if the request failed.
  GoogleRpcStatus? error;

  /// SuggestArticlesResponse if request is for ARTICLE_SUGGESTION.
  GoogleCloudDialogflowV2SuggestArticlesResponse? suggestArticlesResponse;

  /// SuggestFaqAnswersResponse if request is for FAQ_ANSWER.
  GoogleCloudDialogflowV2SuggestFaqAnswersResponse? suggestFaqAnswersResponse;

  GoogleCloudDialogflowV2SuggestionResult();

  GoogleCloudDialogflowV2SuggestionResult.fromJson(core.Map _json) {
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('suggestArticlesResponse')) {
      suggestArticlesResponse =
          GoogleCloudDialogflowV2SuggestArticlesResponse.fromJson(
              _json['suggestArticlesResponse']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('suggestFaqAnswersResponse')) {
      suggestFaqAnswersResponse =
          GoogleCloudDialogflowV2SuggestFaqAnswersResponse.fromJson(
              _json['suggestFaqAnswersResponse']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (error != null) 'error': error!.toJson(),
        if (suggestArticlesResponse != null)
          'suggestArticlesResponse': suggestArticlesResponse!.toJson(),
        if (suggestFaqAnswersResponse != null)
          'suggestFaqAnswersResponse': suggestFaqAnswersResponse!.toJson(),
      };
}

/// The request message for a webhook call.
class GoogleCloudDialogflowV2WebhookRequest {
  /// The contents of the original request that was passed to
  /// `[Streaming]DetectIntent` call.
  ///
  /// Optional.
  GoogleCloudDialogflowV2OriginalDetectIntentRequest?
      originalDetectIntentRequest;

  /// The result of the conversational query or event processing.
  ///
  /// Contains the same value as `[Streaming]DetectIntentResponse.query_result`.
  GoogleCloudDialogflowV2QueryResult? queryResult;

  /// The unique identifier of the response.
  ///
  /// Contains the same value as `[Streaming]DetectIntentResponse.response_id`.
  core.String? responseId;

  /// The unique identifier of detectIntent request session.
  ///
  /// Can be used to identify end-user inside webhook implementation. Format:
  /// `projects//agent/sessions/`, or
  /// `projects//agent/environments//users//sessions/`.
  core.String? session;

  GoogleCloudDialogflowV2WebhookRequest();

  GoogleCloudDialogflowV2WebhookRequest.fromJson(core.Map _json) {
    if (_json.containsKey('originalDetectIntentRequest')) {
      originalDetectIntentRequest =
          GoogleCloudDialogflowV2OriginalDetectIntentRequest.fromJson(
              _json['originalDetectIntentRequest']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('queryResult')) {
      queryResult = GoogleCloudDialogflowV2QueryResult.fromJson(
          _json['queryResult'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('responseId')) {
      responseId = _json['responseId'] as core.String;
    }
    if (_json.containsKey('session')) {
      session = _json['session'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (originalDetectIntentRequest != null)
          'originalDetectIntentRequest': originalDetectIntentRequest!.toJson(),
        if (queryResult != null) 'queryResult': queryResult!.toJson(),
        if (responseId != null) 'responseId': responseId!,
        if (session != null) 'session': session!,
      };
}

/// The response message for a webhook call.
///
/// This response is validated by the Dialogflow server. If validation fails, an
/// error will be returned in the QueryResult.diagnostic_info field. Setting
/// JSON fields to an empty value with the wrong type is a common error. To
/// avoid this error: - Use `""` for empty strings - Use `{}` or `null` for
/// empty objects - Use `[]` or `null` for empty arrays For more information,
/// see the
/// [Protocol Buffers Language Guide](https://developers.google.com/protocol-buffers/docs/proto3#json).
class GoogleCloudDialogflowV2WebhookResponse {
  /// Invokes the supplied events.
  ///
  /// When this field is set, Dialogflow ignores the `fulfillment_text`,
  /// `fulfillment_messages`, and `payload` fields.
  ///
  /// Optional.
  GoogleCloudDialogflowV2EventInput? followupEventInput;

  /// The rich response messages intended for the end-user.
  ///
  /// When provided, Dialogflow uses this field to populate
  /// QueryResult.fulfillment_messages sent to the integration or API caller.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2IntentMessage>? fulfillmentMessages;

  /// The text response message intended for the end-user.
  ///
  /// It is recommended to use `fulfillment_messages.text.text[0]` instead. When
  /// provided, Dialogflow uses this field to populate
  /// QueryResult.fulfillment_text sent to the integration or API caller.
  ///
  /// Optional.
  core.String? fulfillmentText;

  /// The collection of output contexts that will overwrite currently active
  /// contexts for the session and reset their lifespans.
  ///
  /// When provided, Dialogflow uses this field to populate
  /// QueryResult.output_contexts sent to the integration or API caller.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2Context>? outputContexts;

  /// This field can be used to pass custom data from your webhook to the
  /// integration or API caller.
  ///
  /// Arbitrary JSON objects are supported. When provided, Dialogflow uses this
  /// field to populate QueryResult.webhook_payload sent to the integration or
  /// API caller. This field is also used by the
  /// [Google Assistant integration](https://cloud.google.com/dialogflow/docs/integrations/aog)
  /// for rich response messages. See the format definition at
  /// [Google Assistant Dialogflow webhook format](https://developers.google.com/assistant/actions/build/json/dialogflow-webhook-json)
  ///
  /// Optional.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? payload;

  /// Additional session entity types to replace or extend developer entity
  /// types with.
  ///
  /// The entity synonyms apply to all languages and persist for the session.
  /// Setting this data from a webhook overwrites the session entity types that
  /// have been set using `detectIntent`, `streamingDetectIntent` or
  /// SessionEntityType management methods.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2SessionEntityType>? sessionEntityTypes;

  /// A custom field used to identify the webhook source.
  ///
  /// Arbitrary strings are supported. When provided, Dialogflow uses this field
  /// to populate QueryResult.webhook_source sent to the integration or API
  /// caller.
  ///
  /// Optional.
  core.String? source;

  GoogleCloudDialogflowV2WebhookResponse();

  GoogleCloudDialogflowV2WebhookResponse.fromJson(core.Map _json) {
    if (_json.containsKey('followupEventInput')) {
      followupEventInput = GoogleCloudDialogflowV2EventInput.fromJson(
          _json['followupEventInput'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fulfillmentMessages')) {
      fulfillmentMessages = (_json['fulfillmentMessages'] as core.List)
          .map<GoogleCloudDialogflowV2IntentMessage>((value) =>
              GoogleCloudDialogflowV2IntentMessage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('fulfillmentText')) {
      fulfillmentText = _json['fulfillmentText'] as core.String;
    }
    if (_json.containsKey('outputContexts')) {
      outputContexts = (_json['outputContexts'] as core.List)
          .map<GoogleCloudDialogflowV2Context>((value) =>
              GoogleCloudDialogflowV2Context.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('payload')) {
      payload = (_json['payload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('sessionEntityTypes')) {
      sessionEntityTypes = (_json['sessionEntityTypes'] as core.List)
          .map<GoogleCloudDialogflowV2SessionEntityType>((value) =>
              GoogleCloudDialogflowV2SessionEntityType.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (followupEventInput != null)
          'followupEventInput': followupEventInput!.toJson(),
        if (fulfillmentMessages != null)
          'fulfillmentMessages':
              fulfillmentMessages!.map((value) => value.toJson()).toList(),
        if (fulfillmentText != null) 'fulfillmentText': fulfillmentText!,
        if (outputContexts != null)
          'outputContexts':
              outputContexts!.map((value) => value.toJson()).toList(),
        if (payload != null) 'payload': payload!,
        if (sessionEntityTypes != null)
          'sessionEntityTypes':
              sessionEntityTypes!.map((value) => value.toJson()).toList(),
        if (source != null) 'source': source!,
      };
}

/// Represents a part of a message possibly annotated with an entity.
///
/// The part can be an entity or purely a part of the message between two
/// entities or message start/end.
class GoogleCloudDialogflowV2beta1AnnotatedMessagePart {
  /// The
  /// [Dialogflow system entity type](https://cloud.google.com/dialogflow/docs/reference/system-entities)
  /// of this message part.
  ///
  /// If this is empty, Dialogflow could not annotate the phrase part with a
  /// system entity.
  ///
  /// Optional.
  core.String? entityType;

  /// The
  /// [Dialogflow system entity formatted value ](https://cloud.google.com/dialogflow/docs/reference/system-entities)
  /// of this message part.
  ///
  /// For example for a system entity of type `@sys.unit-currency`, this may
  /// contain: { "amount": 5, "currency": "USD" }
  ///
  /// Optional.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? formattedValue;

  /// A part of a message possibly annotated with an entity.
  ///
  /// Required.
  core.String? text;

  GoogleCloudDialogflowV2beta1AnnotatedMessagePart();

  GoogleCloudDialogflowV2beta1AnnotatedMessagePart.fromJson(core.Map _json) {
    if (_json.containsKey('entityType')) {
      entityType = _json['entityType'] as core.String;
    }
    if (_json.containsKey('formattedValue')) {
      formattedValue = _json['formattedValue'] as core.Object;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entityType != null) 'entityType': entityType!,
        if (formattedValue != null) 'formattedValue': formattedValue!,
        if (text != null) 'text': text!,
      };
}

/// Represents article answer.
class GoogleCloudDialogflowV2beta1ArticleAnswer {
  /// The name of answer record, in the format of
  /// "projects//locations//answerRecords/"
  core.String? answerRecord;

  /// A map that contains metadata about the answer and the document from which
  /// it originates.
  core.Map<core.String, core.String>? metadata;

  /// Article snippets.
  ///
  /// Output only.
  core.List<core.String>? snippets;

  /// The article title.
  core.String? title;

  /// The article URI.
  core.String? uri;

  GoogleCloudDialogflowV2beta1ArticleAnswer();

  GoogleCloudDialogflowV2beta1ArticleAnswer.fromJson(core.Map _json) {
    if (_json.containsKey('answerRecord')) {
      answerRecord = _json['answerRecord'] as core.String;
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('snippets')) {
      snippets = (_json['snippets'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (answerRecord != null) 'answerRecord': answerRecord!,
        if (metadata != null) 'metadata': metadata!,
        if (snippets != null) 'snippets': snippets!,
        if (title != null) 'title': title!,
        if (uri != null) 'uri': uri!,
      };
}

/// The response message for EntityTypes.BatchUpdateEntityTypes.
class GoogleCloudDialogflowV2beta1BatchUpdateEntityTypesResponse {
  /// The collection of updated or created entity types.
  core.List<GoogleCloudDialogflowV2beta1EntityType>? entityTypes;

  GoogleCloudDialogflowV2beta1BatchUpdateEntityTypesResponse();

  GoogleCloudDialogflowV2beta1BatchUpdateEntityTypesResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('entityTypes')) {
      entityTypes = (_json['entityTypes'] as core.List)
          .map<GoogleCloudDialogflowV2beta1EntityType>((value) =>
              GoogleCloudDialogflowV2beta1EntityType.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entityTypes != null)
          'entityTypes': entityTypes!.map((value) => value.toJson()).toList(),
      };
}

/// The response message for Intents.BatchUpdateIntents.
class GoogleCloudDialogflowV2beta1BatchUpdateIntentsResponse {
  /// The collection of updated or created intents.
  core.List<GoogleCloudDialogflowV2beta1Intent>? intents;

  GoogleCloudDialogflowV2beta1BatchUpdateIntentsResponse();

  GoogleCloudDialogflowV2beta1BatchUpdateIntentsResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('intents')) {
      intents = (_json['intents'] as core.List)
          .map<GoogleCloudDialogflowV2beta1Intent>((value) =>
              GoogleCloudDialogflowV2beta1Intent.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (intents != null)
          'intents': intents!.map((value) => value.toJson()).toList(),
      };
}

/// Dialogflow contexts are similar to natural language context.
///
/// If a person says to you "they are orange", you need context in order to
/// understand what "they" is referring to. Similarly, for Dialogflow to handle
/// an end-user expression like that, it needs to be provided with context in
/// order to correctly match an intent. Using contexts, you can control the flow
/// of a conversation. You can configure contexts for an intent by setting input
/// and output contexts, which are identified by string names. When an intent is
/// matched, any configured output contexts for that intent become active. While
/// any contexts are active, Dialogflow is more likely to match intents that are
/// configured with input contexts that correspond to the currently active
/// contexts. For more information about context, see the
/// [Contexts guide](https://cloud.google.com/dialogflow/docs/contexts-overview).
class GoogleCloudDialogflowV2beta1Context {
  /// The number of conversational query requests after which the context
  /// expires.
  ///
  /// The default is `0`. If set to `0`, the context expires immediately.
  /// Contexts expire automatically after 20 minutes if there are no matching
  /// queries.
  ///
  /// Optional.
  core.int? lifespanCount;

  /// The unique identifier of the context.
  ///
  /// Supported formats: - `projects//agent/sessions//contexts/`, -
  /// `projects//locations//agent/sessions//contexts/`, -
  /// `projects//agent/environments//users//sessions//contexts/`, -
  /// `projects//locations//agent/environments//users//sessions//contexts/`, The
  /// `Context ID` is always converted to lowercase, may only contain characters
  /// in a-zA-Z0-9_-% and may be at most 250 bytes long. If `Environment ID` is
  /// not specified, we assume default 'draft' environment. If `User ID` is not
  /// specified, we assume default '-' user. The following context names are
  /// reserved for internal use by Dialogflow. You should not use these contexts
  /// or create contexts with these names: * `__system_counters__` *
  /// `*_id_dialog_context` * `*_dialog_params_size`
  ///
  /// Required.
  core.String? name;

  /// The collection of parameters associated with this context.
  ///
  /// Depending on your protocol or client library language, this is a map,
  /// associative array, symbol table, dictionary, or JSON object composed of a
  /// collection of (MapKey, MapValue) pairs: - MapKey type: string - MapKey
  /// value: parameter name - MapValue type: - If parameter's entity type is a
  /// composite entity: map - Else: depending on parameter value type, could be
  /// one of string, number, boolean, null, list or map - MapValue value: - If
  /// parameter's entity type is a composite entity: map from composite entity
  /// property names to property values - Else: parameter value
  ///
  /// Optional.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? parameters;

  GoogleCloudDialogflowV2beta1Context();

  GoogleCloudDialogflowV2beta1Context.fromJson(core.Map _json) {
    if (_json.containsKey('lifespanCount')) {
      lifespanCount = _json['lifespanCount'] as core.int;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters =
          (_json['parameters'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (lifespanCount != null) 'lifespanCount': lifespanCount!,
        if (name != null) 'name': name!,
        if (parameters != null) 'parameters': parameters!,
      };
}

/// Represents a notification sent to Pub/Sub subscribers for conversation
/// lifecycle events.
class GoogleCloudDialogflowV2beta1ConversationEvent {
  /// The unique identifier of the conversation this notification refers to.
  ///
  /// Format: `projects//conversations/`.
  ///
  /// Required.
  core.String? conversation;

  /// More detailed information about an error.
  ///
  /// Only set for type UNRECOVERABLE_ERROR_IN_PHONE_CALL.
  ///
  /// Optional.
  GoogleRpcStatus? errorStatus;

  /// Payload of NEW_MESSAGE event.
  GoogleCloudDialogflowV2beta1Message? newMessagePayload;

  /// The type of the event that this notification refers to.
  ///
  /// Required.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Type not set.
  /// - "CONVERSATION_STARTED" : A new conversation has been opened. This is
  /// fired when a telephone call is answered, or a conversation is created via
  /// the API.
  /// - "CONVERSATION_FINISHED" : An existing conversation has closed. This is
  /// fired when a telephone call is terminated, or a conversation is closed via
  /// the API.
  /// - "NEW_MESSAGE" : An existing conversation has received a new message,
  /// either from API or telephony. It is configured in
  /// ConversationProfile.new_message_event_notification_config
  /// - "UNRECOVERABLE_ERROR" : Unrecoverable error during a telephone call. In
  /// general non-recoverable errors only occur if something was misconfigured
  /// in the ConversationProfile corresponding to the call. After a
  /// non-recoverable error, Dialogflow may stop responding. We don't fire this
  /// event: * in an API call because we can directly return the error, or, *
  /// when we can recover from an error.
  core.String? type;

  GoogleCloudDialogflowV2beta1ConversationEvent();

  GoogleCloudDialogflowV2beta1ConversationEvent.fromJson(core.Map _json) {
    if (_json.containsKey('conversation')) {
      conversation = _json['conversation'] as core.String;
    }
    if (_json.containsKey('errorStatus')) {
      errorStatus = GoogleRpcStatus.fromJson(
          _json['errorStatus'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('newMessagePayload')) {
      newMessagePayload = GoogleCloudDialogflowV2beta1Message.fromJson(
          _json['newMessagePayload'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conversation != null) 'conversation': conversation!,
        if (errorStatus != null) 'errorStatus': errorStatus!.toJson(),
        if (newMessagePayload != null)
          'newMessagePayload': newMessagePayload!.toJson(),
        if (type != null) 'type': type!,
      };
}

/// Each intent parameter has a type, called the entity type, which dictates
/// exactly how data from an end-user expression is extracted.
///
/// Dialogflow provides predefined system entities that can match many common
/// types of data. For example, there are system entities for matching dates,
/// times, colors, email addresses, and so on. You can also create your own
/// custom entities for matching custom data. For example, you could define a
/// vegetable entity that can match the types of vegetables available for
/// purchase with a grocery store agent. For more information, see the
/// [Entity guide](https://cloud.google.com/dialogflow/docs/entities-overview).
class GoogleCloudDialogflowV2beta1EntityType {
  /// Indicates whether the entity type can be automatically expanded.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "AUTO_EXPANSION_MODE_UNSPECIFIED" : Auto expansion disabled for the
  /// entity.
  /// - "AUTO_EXPANSION_MODE_DEFAULT" : Allows an agent to recognize values that
  /// have not been explicitly listed in the entity.
  core.String? autoExpansionMode;

  /// The name of the entity type.
  ///
  /// Required.
  core.String? displayName;

  /// Enables fuzzy entity extraction during classification.
  ///
  /// Optional.
  core.bool? enableFuzzyExtraction;

  /// The collection of entity entries associated with the entity type.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1EntityTypeEntity>? entities;

  /// Indicates the kind of entity type.
  ///
  /// Required.
  /// Possible string values are:
  /// - "KIND_UNSPECIFIED" : Not specified. This value should be never used.
  /// - "KIND_MAP" : Map entity types allow mapping of a group of synonyms to a
  /// reference value.
  /// - "KIND_LIST" : List entity types contain a set of entries that do not map
  /// to reference values. However, list entity types can contain references to
  /// other entity types (with or without aliases).
  /// - "KIND_REGEXP" : Regexp entity types allow to specify regular expressions
  /// in entries values.
  core.String? kind;

  /// The unique identifier of the entity type.
  ///
  /// Required for EntityTypes.UpdateEntityType and
  /// EntityTypes.BatchUpdateEntityTypes methods. Supported formats: -
  /// `projects//agent/entityTypes/` - `projects//locations//agent/entityTypes/`
  core.String? name;

  GoogleCloudDialogflowV2beta1EntityType();

  GoogleCloudDialogflowV2beta1EntityType.fromJson(core.Map _json) {
    if (_json.containsKey('autoExpansionMode')) {
      autoExpansionMode = _json['autoExpansionMode'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('enableFuzzyExtraction')) {
      enableFuzzyExtraction = _json['enableFuzzyExtraction'] as core.bool;
    }
    if (_json.containsKey('entities')) {
      entities = (_json['entities'] as core.List)
          .map<GoogleCloudDialogflowV2beta1EntityTypeEntity>((value) =>
              GoogleCloudDialogflowV2beta1EntityTypeEntity.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (autoExpansionMode != null) 'autoExpansionMode': autoExpansionMode!,
        if (displayName != null) 'displayName': displayName!,
        if (enableFuzzyExtraction != null)
          'enableFuzzyExtraction': enableFuzzyExtraction!,
        if (entities != null)
          'entities': entities!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
      };
}

/// An **entity entry** for an associated entity type.
class GoogleCloudDialogflowV2beta1EntityTypeEntity {
  /// A collection of value synonyms.
  ///
  /// For example, if the entity type is *vegetable*, and `value` is
  /// *scallions*, a synonym could be *green onions*. For `KIND_LIST` entity
  /// types: * This collection must contain exactly one synonym equal to
  /// `value`.
  ///
  /// Required.
  core.List<core.String>? synonyms;

  /// The primary value associated with this entity entry.
  ///
  /// For example, if the entity type is *vegetable*, the value could be
  /// *scallions*. For `KIND_MAP` entity types: * A reference value to be used
  /// in place of synonyms. For `KIND_LIST` entity types: * A string that can
  /// contain references to other entity types (with or without aliases).
  ///
  /// Required.
  core.String? value;

  GoogleCloudDialogflowV2beta1EntityTypeEntity();

  GoogleCloudDialogflowV2beta1EntityTypeEntity.fromJson(core.Map _json) {
    if (_json.containsKey('synonyms')) {
      synonyms = (_json['synonyms'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (synonyms != null) 'synonyms': synonyms!,
        if (value != null) 'value': value!,
      };
}

/// Events allow for matching intents by event name instead of the natural
/// language input.
///
/// For instance, input `` can trigger a personalized welcome response. The
/// parameter `name` may be used by the agent in the response: `"Hello
/// #welcome_event.name! What can I do for you today?"`.
class GoogleCloudDialogflowV2beta1EventInput {
  /// The language of this query.
  ///
  /// See
  /// [Language Support](https://cloud.google.com/dialogflow/docs/reference/language)
  /// for a list of the currently supported language codes. Note that queries in
  /// the same session do not necessarily need to specify the same language.
  ///
  /// Required.
  core.String? languageCode;

  /// The unique identifier of the event.
  ///
  /// Required.
  core.String? name;

  /// The collection of parameters associated with the event.
  ///
  /// Depending on your protocol or client library language, this is a map,
  /// associative array, symbol table, dictionary, or JSON object composed of a
  /// collection of (MapKey, MapValue) pairs: - MapKey type: string - MapKey
  /// value: parameter name - MapValue type: - If parameter's entity type is a
  /// composite entity: map - Else: depending on parameter value type, could be
  /// one of string, number, boolean, null, list or map - MapValue value: - If
  /// parameter's entity type is a composite entity: map from composite entity
  /// property names to property values - Else: parameter value
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? parameters;

  GoogleCloudDialogflowV2beta1EventInput();

  GoogleCloudDialogflowV2beta1EventInput.fromJson(core.Map _json) {
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parameters')) {
      parameters =
          (_json['parameters'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (languageCode != null) 'languageCode': languageCode!,
        if (name != null) 'name': name!,
        if (parameters != null) 'parameters': parameters!,
      };
}

/// The response message for Agents.ExportAgent.
class GoogleCloudDialogflowV2beta1ExportAgentResponse {
  /// Zip compressed raw byte content for agent.
  core.String? agentContent;
  core.List<core.int> get agentContentAsBytes =>
      convert.base64.decode(agentContent!);

  set agentContentAsBytes(core.List<core.int> _bytes) {
    agentContent =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The URI to a file containing the exported agent.
  ///
  /// This field is populated only if `agent_uri` is specified in
  /// `ExportAgentRequest`.
  core.String? agentUri;

  GoogleCloudDialogflowV2beta1ExportAgentResponse();

  GoogleCloudDialogflowV2beta1ExportAgentResponse.fromJson(core.Map _json) {
    if (_json.containsKey('agentContent')) {
      agentContent = _json['agentContent'] as core.String;
    }
    if (_json.containsKey('agentUri')) {
      agentUri = _json['agentUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (agentContent != null) 'agentContent': agentContent!,
        if (agentUri != null) 'agentUri': agentUri!,
      };
}

/// Represents answer from "frequently asked questions".
class GoogleCloudDialogflowV2beta1FaqAnswer {
  /// The piece of text from the `source` knowledge base document.
  core.String? answer;

  /// The name of answer record, in the format of
  /// "projects//locations//answerRecords/"
  core.String? answerRecord;

  /// The system's confidence score that this Knowledge answer is a good match
  /// for this conversational query, range from 0.0 (completely uncertain) to
  /// 1.0 (completely certain).
  core.double? confidence;

  /// A map that contains metadata about the answer and the document from which
  /// it originates.
  core.Map<core.String, core.String>? metadata;

  /// The corresponding FAQ question.
  core.String? question;

  /// Indicates which Knowledge Document this answer was extracted from.
  ///
  /// Format: `projects//locations//agent/knowledgeBases//documents/`.
  core.String? source;

  GoogleCloudDialogflowV2beta1FaqAnswer();

  GoogleCloudDialogflowV2beta1FaqAnswer.fromJson(core.Map _json) {
    if (_json.containsKey('answer')) {
      answer = _json['answer'] as core.String;
    }
    if (_json.containsKey('answerRecord')) {
      answerRecord = _json['answerRecord'] as core.String;
    }
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('question')) {
      question = _json['question'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (answer != null) 'answer': answer!,
        if (answerRecord != null) 'answerRecord': answerRecord!,
        if (confidence != null) 'confidence': confidence!,
        if (metadata != null) 'metadata': metadata!,
        if (question != null) 'question': question!,
        if (source != null) 'source': source!,
      };
}

/// Represents a notification sent to Pub/Sub subscribers for agent assistant
/// events in a specific conversation.
///
/// Output only.
class GoogleCloudDialogflowV2beta1HumanAgentAssistantEvent {
  /// The conversation this notification refers to.
  ///
  /// Format: `projects//conversations/`.
  core.String? conversation;

  /// The participant that the suggestion is compiled for.
  ///
  /// And This field is used to call Participants.ListSuggestions API. Format:
  /// `projects//conversations//participants/`. It will not be set in legacy
  /// workflow. HumanAgentAssistantConfig.name for more information.
  core.String? participant;

  /// The suggestion results payload that this notification refers to.
  ///
  /// It will only be set when
  /// HumanAgentAssistantConfig.SuggestionConfig.group_suggestion_responses sets
  /// to true.
  core.List<GoogleCloudDialogflowV2beta1SuggestionResult>? suggestionResults;

  GoogleCloudDialogflowV2beta1HumanAgentAssistantEvent();

  GoogleCloudDialogflowV2beta1HumanAgentAssistantEvent.fromJson(
      core.Map _json) {
    if (_json.containsKey('conversation')) {
      conversation = _json['conversation'] as core.String;
    }
    if (_json.containsKey('participant')) {
      participant = _json['participant'] as core.String;
    }
    if (_json.containsKey('suggestionResults')) {
      suggestionResults = (_json['suggestionResults'] as core.List)
          .map<GoogleCloudDialogflowV2beta1SuggestionResult>((value) =>
              GoogleCloudDialogflowV2beta1SuggestionResult.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (conversation != null) 'conversation': conversation!,
        if (participant != null) 'participant': participant!,
        if (suggestionResults != null)
          'suggestionResults':
              suggestionResults!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for Documents.ImportDocuments.
class GoogleCloudDialogflowV2beta1ImportDocumentsResponse {
  /// Includes details about skipped documents or any other warnings.
  core.List<GoogleRpcStatus>? warnings;

  GoogleCloudDialogflowV2beta1ImportDocumentsResponse();

  GoogleCloudDialogflowV2beta1ImportDocumentsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('warnings')) {
      warnings = (_json['warnings'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (warnings != null)
          'warnings': warnings!.map((value) => value.toJson()).toList(),
      };
}

/// An intent categorizes an end-user's intention for one conversation turn.
///
/// For each agent, you define many intents, where your combined intents can
/// handle a complete conversation. When an end-user writes or says something,
/// referred to as an end-user expression or end-user input, Dialogflow matches
/// the end-user input to the best intent in your agent. Matching an intent is
/// also known as intent classification. For more information, see the
/// [intent guide](https://cloud.google.com/dialogflow/docs/intents-overview).
class GoogleCloudDialogflowV2beta1Intent {
  /// The name of the action associated with the intent.
  ///
  /// Note: The action name must not contain whitespaces.
  ///
  /// Optional.
  core.String? action;

  /// The list of platforms for which the first responses will be copied from
  /// the messages in PLATFORM_UNSPECIFIED (i.e. default platform).
  ///
  /// Optional.
  core.List<core.String>? defaultResponsePlatforms;

  /// The name of this intent.
  ///
  /// Required.
  core.String? displayName;

  /// Indicates that this intent ends an interaction.
  ///
  /// Some integrations (e.g., Actions on Google or Dialogflow phone gateway)
  /// use this information to close interaction with an end user. Default is
  /// false.
  ///
  /// Optional.
  core.bool? endInteraction;

  /// The collection of event names that trigger the intent.
  ///
  /// If the collection of input contexts is not empty, all of the contexts must
  /// be present in the active user session for an event to trigger this intent.
  /// Event names are limited to 150 characters.
  ///
  /// Optional.
  core.List<core.String>? events;

  /// Information about all followup intents that have this intent as a direct
  /// or indirect parent.
  ///
  /// We populate this field only in the output.
  ///
  /// Output only.
  core.List<GoogleCloudDialogflowV2beta1IntentFollowupIntentInfo>?
      followupIntentInfo;

  /// The list of context names required for this intent to be triggered.
  ///
  /// Formats: - `projects//agent/sessions/-/contexts/` -
  /// `projects//locations//agent/sessions/-/contexts/`
  ///
  /// Optional.
  core.List<core.String>? inputContextNames;

  /// Indicates whether this is a fallback intent.
  ///
  /// Optional.
  core.bool? isFallback;

  /// Indicates that a live agent should be brought in to handle the interaction
  /// with the user.
  ///
  /// In most cases, when you set this flag to true, you would also want to set
  /// end_interaction to true as well. Default is false.
  ///
  /// Optional.
  core.bool? liveAgentHandoff;

  /// The collection of rich messages corresponding to the `Response` field in
  /// the Dialogflow console.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1IntentMessage>? messages;

  /// Indicates whether Machine Learning is disabled for the intent.
  ///
  /// Note: If `ml_disabled` setting is set to true, then this intent is not
  /// taken into account during inference in `ML ONLY` match mode. Also,
  /// auto-markup in the UI is turned off.
  ///
  /// Optional.
  core.bool? mlDisabled;

  /// Indicates whether Machine Learning is enabled for the intent.
  ///
  /// Note: If `ml_enabled` setting is set to false, then this intent is not
  /// taken into account during inference in `ML ONLY` match mode. Also,
  /// auto-markup in the UI is turned off. DEPRECATED! Please use `ml_disabled`
  /// field instead. NOTE: If both `ml_enabled` and `ml_disabled` are either not
  /// set or false, then the default value is determined as follows: - Before
  /// April 15th, 2018 the default is: ml_enabled = false / ml_disabled = true.
  /// - After April 15th, 2018 the default is: ml_enabled = true / ml_disabled =
  /// false.
  ///
  /// Optional.
  core.bool? mlEnabled;

  /// The unique identifier of this intent.
  ///
  /// Required for Intents.UpdateIntent and Intents.BatchUpdateIntents methods.
  /// Supported formats: - `projects//agent/intents/` -
  /// `projects//locations//agent/intents/`
  ///
  /// Optional.
  core.String? name;

  /// The collection of contexts that are activated when the intent is matched.
  ///
  /// Context messages in this collection should not set the parameters field.
  /// Setting the `lifespan_count` to 0 will reset the context when the intent
  /// is matched. Format: `projects//agent/sessions/-/contexts/`.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1Context>? outputContexts;

  /// The collection of parameters associated with the intent.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1IntentParameter>? parameters;

  /// The unique identifier of the parent intent in the chain of followup
  /// intents.
  ///
  /// You can set this field when creating an intent, for example with
  /// CreateIntent or BatchUpdateIntents, in order to make this intent a
  /// followup intent. It identifies the parent followup intent. Format:
  /// `projects//agent/intents/`.
  ///
  /// Optional.
  core.String? parentFollowupIntentName;

  /// The priority of this intent.
  ///
  /// Higher numbers represent higher priorities. - If the supplied value is
  /// unspecified or 0, the service translates the value to 500,000, which
  /// corresponds to the `Normal` priority in the console. - If the supplied
  /// value is negative, the intent is ignored in runtime detect intent
  /// requests.
  ///
  /// Optional.
  core.int? priority;

  /// Indicates whether to delete all contexts in the current session when this
  /// intent is matched.
  ///
  /// Optional.
  core.bool? resetContexts;

  /// The unique identifier of the root intent in the chain of followup intents.
  ///
  /// It identifies the correct followup intents chain for this intent. Format:
  /// `projects//agent/intents/`.
  ///
  /// Output only.
  core.String? rootFollowupIntentName;

  /// The collection of examples that the agent is trained on.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1IntentTrainingPhrase>? trainingPhrases;

  /// Indicates whether webhooks are enabled for the intent.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "WEBHOOK_STATE_UNSPECIFIED" : Webhook is disabled in the agent and in
  /// the intent.
  /// - "WEBHOOK_STATE_ENABLED" : Webhook is enabled in the agent and in the
  /// intent.
  /// - "WEBHOOK_STATE_ENABLED_FOR_SLOT_FILLING" : Webhook is enabled in the
  /// agent and in the intent. Also, each slot filling prompt is forwarded to
  /// the webhook.
  core.String? webhookState;

  GoogleCloudDialogflowV2beta1Intent();

  GoogleCloudDialogflowV2beta1Intent.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('defaultResponsePlatforms')) {
      defaultResponsePlatforms =
          (_json['defaultResponsePlatforms'] as core.List)
              .map<core.String>((value) => value as core.String)
              .toList();
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('endInteraction')) {
      endInteraction = _json['endInteraction'] as core.bool;
    }
    if (_json.containsKey('events')) {
      events = (_json['events'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('followupIntentInfo')) {
      followupIntentInfo = (_json['followupIntentInfo'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentFollowupIntentInfo>((value) =>
              GoogleCloudDialogflowV2beta1IntentFollowupIntentInfo.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('inputContextNames')) {
      inputContextNames = (_json['inputContextNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('isFallback')) {
      isFallback = _json['isFallback'] as core.bool;
    }
    if (_json.containsKey('liveAgentHandoff')) {
      liveAgentHandoff = _json['liveAgentHandoff'] as core.bool;
    }
    if (_json.containsKey('messages')) {
      messages = (_json['messages'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessage>((value) =>
              GoogleCloudDialogflowV2beta1IntentMessage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('mlDisabled')) {
      mlDisabled = _json['mlDisabled'] as core.bool;
    }
    if (_json.containsKey('mlEnabled')) {
      mlEnabled = _json['mlEnabled'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('outputContexts')) {
      outputContexts = (_json['outputContexts'] as core.List)
          .map<GoogleCloudDialogflowV2beta1Context>((value) =>
              GoogleCloudDialogflowV2beta1Context.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('parameters')) {
      parameters = (_json['parameters'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentParameter>((value) =>
              GoogleCloudDialogflowV2beta1IntentParameter.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('parentFollowupIntentName')) {
      parentFollowupIntentName =
          _json['parentFollowupIntentName'] as core.String;
    }
    if (_json.containsKey('priority')) {
      priority = _json['priority'] as core.int;
    }
    if (_json.containsKey('resetContexts')) {
      resetContexts = _json['resetContexts'] as core.bool;
    }
    if (_json.containsKey('rootFollowupIntentName')) {
      rootFollowupIntentName = _json['rootFollowupIntentName'] as core.String;
    }
    if (_json.containsKey('trainingPhrases')) {
      trainingPhrases = (_json['trainingPhrases'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentTrainingPhrase>((value) =>
              GoogleCloudDialogflowV2beta1IntentTrainingPhrase.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('webhookState')) {
      webhookState = _json['webhookState'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (defaultResponsePlatforms != null)
          'defaultResponsePlatforms': defaultResponsePlatforms!,
        if (displayName != null) 'displayName': displayName!,
        if (endInteraction != null) 'endInteraction': endInteraction!,
        if (events != null) 'events': events!,
        if (followupIntentInfo != null)
          'followupIntentInfo':
              followupIntentInfo!.map((value) => value.toJson()).toList(),
        if (inputContextNames != null) 'inputContextNames': inputContextNames!,
        if (isFallback != null) 'isFallback': isFallback!,
        if (liveAgentHandoff != null) 'liveAgentHandoff': liveAgentHandoff!,
        if (messages != null)
          'messages': messages!.map((value) => value.toJson()).toList(),
        if (mlDisabled != null) 'mlDisabled': mlDisabled!,
        if (mlEnabled != null) 'mlEnabled': mlEnabled!,
        if (name != null) 'name': name!,
        if (outputContexts != null)
          'outputContexts':
              outputContexts!.map((value) => value.toJson()).toList(),
        if (parameters != null)
          'parameters': parameters!.map((value) => value.toJson()).toList(),
        if (parentFollowupIntentName != null)
          'parentFollowupIntentName': parentFollowupIntentName!,
        if (priority != null) 'priority': priority!,
        if (resetContexts != null) 'resetContexts': resetContexts!,
        if (rootFollowupIntentName != null)
          'rootFollowupIntentName': rootFollowupIntentName!,
        if (trainingPhrases != null)
          'trainingPhrases':
              trainingPhrases!.map((value) => value.toJson()).toList(),
        if (webhookState != null) 'webhookState': webhookState!,
      };
}

/// Represents a single followup intent in the chain.
class GoogleCloudDialogflowV2beta1IntentFollowupIntentInfo {
  /// The unique identifier of the followup intent.
  ///
  /// Format: `projects//agent/intents/`.
  core.String? followupIntentName;

  /// The unique identifier of the followup intent's parent.
  ///
  /// Format: `projects//agent/intents/`.
  core.String? parentFollowupIntentName;

  GoogleCloudDialogflowV2beta1IntentFollowupIntentInfo();

  GoogleCloudDialogflowV2beta1IntentFollowupIntentInfo.fromJson(
      core.Map _json) {
    if (_json.containsKey('followupIntentName')) {
      followupIntentName = _json['followupIntentName'] as core.String;
    }
    if (_json.containsKey('parentFollowupIntentName')) {
      parentFollowupIntentName =
          _json['parentFollowupIntentName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (followupIntentName != null)
          'followupIntentName': followupIntentName!,
        if (parentFollowupIntentName != null)
          'parentFollowupIntentName': parentFollowupIntentName!,
      };
}

/// Corresponds to the `Response` field in the Dialogflow console.
class GoogleCloudDialogflowV2beta1IntentMessage {
  /// Displays a basic card for Actions on Google.
  GoogleCloudDialogflowV2beta1IntentMessageBasicCard? basicCard;

  /// Browse carousel card for Actions on Google.
  GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCard?
      browseCarouselCard;

  /// Displays a card.
  GoogleCloudDialogflowV2beta1IntentMessageCard? card;

  /// Displays a carousel card for Actions on Google.
  GoogleCloudDialogflowV2beta1IntentMessageCarouselSelect? carouselSelect;

  /// Displays an image.
  GoogleCloudDialogflowV2beta1IntentMessageImage? image;

  /// Displays a link out suggestion chip for Actions on Google.
  GoogleCloudDialogflowV2beta1IntentMessageLinkOutSuggestion? linkOutSuggestion;

  /// Displays a list card for Actions on Google.
  GoogleCloudDialogflowV2beta1IntentMessageListSelect? listSelect;

  /// The media content card for Actions on Google.
  GoogleCloudDialogflowV2beta1IntentMessageMediaContent? mediaContent;

  /// A custom platform-specific response.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? payload;

  /// The platform that this message is intended for.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "PLATFORM_UNSPECIFIED" : Not specified.
  /// - "FACEBOOK" : Facebook.
  /// - "SLACK" : Slack.
  /// - "TELEGRAM" : Telegram.
  /// - "KIK" : Kik.
  /// - "SKYPE" : Skype.
  /// - "LINE" : Line.
  /// - "VIBER" : Viber.
  /// - "ACTIONS_ON_GOOGLE" : Google Assistant See
  /// [Dialogflow webhook format](https://developers.google.com/assistant/actions/build/json/dialogflow-webhook-json)
  /// - "TELEPHONY" : Telephony Gateway.
  /// - "GOOGLE_HANGOUTS" : Google Hangouts.
  core.String? platform;

  /// Displays quick replies.
  GoogleCloudDialogflowV2beta1IntentMessageQuickReplies? quickReplies;

  /// Rich Business Messaging (RBM) carousel rich card response.
  GoogleCloudDialogflowV2beta1IntentMessageRbmCarouselCard? rbmCarouselRichCard;

  /// Standalone Rich Business Messaging (RBM) rich card response.
  GoogleCloudDialogflowV2beta1IntentMessageRbmStandaloneCard?
      rbmStandaloneRichCard;

  /// Rich Business Messaging (RBM) text response.
  ///
  /// RBM allows businesses to send enriched and branded versions of SMS. See
  /// https://jibe.google.com/business-messaging.
  GoogleCloudDialogflowV2beta1IntentMessageRbmText? rbmText;

  /// Returns a voice or text-only response for Actions on Google.
  GoogleCloudDialogflowV2beta1IntentMessageSimpleResponses? simpleResponses;

  /// Displays suggestion chips for Actions on Google.
  GoogleCloudDialogflowV2beta1IntentMessageSuggestions? suggestions;

  /// Table card for Actions on Google.
  GoogleCloudDialogflowV2beta1IntentMessageTableCard? tableCard;

  /// Plays audio from a file in Telephony Gateway.
  GoogleCloudDialogflowV2beta1IntentMessageTelephonyPlayAudio?
      telephonyPlayAudio;

  /// Synthesizes speech in Telephony Gateway.
  GoogleCloudDialogflowV2beta1IntentMessageTelephonySynthesizeSpeech?
      telephonySynthesizeSpeech;

  /// Transfers the call in Telephony Gateway.
  GoogleCloudDialogflowV2beta1IntentMessageTelephonyTransferCall?
      telephonyTransferCall;

  /// Returns a text response.
  GoogleCloudDialogflowV2beta1IntentMessageText? text;

  GoogleCloudDialogflowV2beta1IntentMessage();

  GoogleCloudDialogflowV2beta1IntentMessage.fromJson(core.Map _json) {
    if (_json.containsKey('basicCard')) {
      basicCard = GoogleCloudDialogflowV2beta1IntentMessageBasicCard.fromJson(
          _json['basicCard'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('browseCarouselCard')) {
      browseCarouselCard =
          GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCard.fromJson(
              _json['browseCarouselCard']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('card')) {
      card = GoogleCloudDialogflowV2beta1IntentMessageCard.fromJson(
          _json['card'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('carouselSelect')) {
      carouselSelect =
          GoogleCloudDialogflowV2beta1IntentMessageCarouselSelect.fromJson(
              _json['carouselSelect'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('image')) {
      image = GoogleCloudDialogflowV2beta1IntentMessageImage.fromJson(
          _json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('linkOutSuggestion')) {
      linkOutSuggestion =
          GoogleCloudDialogflowV2beta1IntentMessageLinkOutSuggestion.fromJson(
              _json['linkOutSuggestion']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('listSelect')) {
      listSelect = GoogleCloudDialogflowV2beta1IntentMessageListSelect.fromJson(
          _json['listSelect'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mediaContent')) {
      mediaContent =
          GoogleCloudDialogflowV2beta1IntentMessageMediaContent.fromJson(
              _json['mediaContent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('payload')) {
      payload = (_json['payload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('platform')) {
      platform = _json['platform'] as core.String;
    }
    if (_json.containsKey('quickReplies')) {
      quickReplies =
          GoogleCloudDialogflowV2beta1IntentMessageQuickReplies.fromJson(
              _json['quickReplies'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rbmCarouselRichCard')) {
      rbmCarouselRichCard =
          GoogleCloudDialogflowV2beta1IntentMessageRbmCarouselCard.fromJson(
              _json['rbmCarouselRichCard']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rbmStandaloneRichCard')) {
      rbmStandaloneRichCard =
          GoogleCloudDialogflowV2beta1IntentMessageRbmStandaloneCard.fromJson(
              _json['rbmStandaloneRichCard']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rbmText')) {
      rbmText = GoogleCloudDialogflowV2beta1IntentMessageRbmText.fromJson(
          _json['rbmText'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('simpleResponses')) {
      simpleResponses =
          GoogleCloudDialogflowV2beta1IntentMessageSimpleResponses.fromJson(
              _json['simpleResponses'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('suggestions')) {
      suggestions =
          GoogleCloudDialogflowV2beta1IntentMessageSuggestions.fromJson(
              _json['suggestions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tableCard')) {
      tableCard = GoogleCloudDialogflowV2beta1IntentMessageTableCard.fromJson(
          _json['tableCard'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('telephonyPlayAudio')) {
      telephonyPlayAudio =
          GoogleCloudDialogflowV2beta1IntentMessageTelephonyPlayAudio.fromJson(
              _json['telephonyPlayAudio']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('telephonySynthesizeSpeech')) {
      telephonySynthesizeSpeech =
          GoogleCloudDialogflowV2beta1IntentMessageTelephonySynthesizeSpeech
              .fromJson(_json['telephonySynthesizeSpeech']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('telephonyTransferCall')) {
      telephonyTransferCall =
          GoogleCloudDialogflowV2beta1IntentMessageTelephonyTransferCall
              .fromJson(_json['telephonyTransferCall']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = GoogleCloudDialogflowV2beta1IntentMessageText.fromJson(
          _json['text'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (basicCard != null) 'basicCard': basicCard!.toJson(),
        if (browseCarouselCard != null)
          'browseCarouselCard': browseCarouselCard!.toJson(),
        if (card != null) 'card': card!.toJson(),
        if (carouselSelect != null) 'carouselSelect': carouselSelect!.toJson(),
        if (image != null) 'image': image!.toJson(),
        if (linkOutSuggestion != null)
          'linkOutSuggestion': linkOutSuggestion!.toJson(),
        if (listSelect != null) 'listSelect': listSelect!.toJson(),
        if (mediaContent != null) 'mediaContent': mediaContent!.toJson(),
        if (payload != null) 'payload': payload!,
        if (platform != null) 'platform': platform!,
        if (quickReplies != null) 'quickReplies': quickReplies!.toJson(),
        if (rbmCarouselRichCard != null)
          'rbmCarouselRichCard': rbmCarouselRichCard!.toJson(),
        if (rbmStandaloneRichCard != null)
          'rbmStandaloneRichCard': rbmStandaloneRichCard!.toJson(),
        if (rbmText != null) 'rbmText': rbmText!.toJson(),
        if (simpleResponses != null)
          'simpleResponses': simpleResponses!.toJson(),
        if (suggestions != null) 'suggestions': suggestions!.toJson(),
        if (tableCard != null) 'tableCard': tableCard!.toJson(),
        if (telephonyPlayAudio != null)
          'telephonyPlayAudio': telephonyPlayAudio!.toJson(),
        if (telephonySynthesizeSpeech != null)
          'telephonySynthesizeSpeech': telephonySynthesizeSpeech!.toJson(),
        if (telephonyTransferCall != null)
          'telephonyTransferCall': telephonyTransferCall!.toJson(),
        if (text != null) 'text': text!.toJson(),
      };
}

/// The basic card message.
///
/// Useful for displaying information.
class GoogleCloudDialogflowV2beta1IntentMessageBasicCard {
  /// The collection of card buttons.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1IntentMessageBasicCardButton>? buttons;

  /// Required, unless image is present.
  ///
  /// The body text of the card.
  core.String? formattedText;

  /// The image for the card.
  ///
  /// Optional.
  GoogleCloudDialogflowV2beta1IntentMessageImage? image;

  /// The subtitle of the card.
  ///
  /// Optional.
  core.String? subtitle;

  /// The title of the card.
  ///
  /// Optional.
  core.String? title;

  GoogleCloudDialogflowV2beta1IntentMessageBasicCard();

  GoogleCloudDialogflowV2beta1IntentMessageBasicCard.fromJson(core.Map _json) {
    if (_json.containsKey('buttons')) {
      buttons = (_json['buttons'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageBasicCardButton>(
              (value) =>
                  GoogleCloudDialogflowV2beta1IntentMessageBasicCardButton
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('formattedText')) {
      formattedText = _json['formattedText'] as core.String;
    }
    if (_json.containsKey('image')) {
      image = GoogleCloudDialogflowV2beta1IntentMessageImage.fromJson(
          _json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subtitle')) {
      subtitle = _json['subtitle'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buttons != null)
          'buttons': buttons!.map((value) => value.toJson()).toList(),
        if (formattedText != null) 'formattedText': formattedText!,
        if (image != null) 'image': image!.toJson(),
        if (subtitle != null) 'subtitle': subtitle!,
        if (title != null) 'title': title!,
      };
}

/// The button object that appears at the bottom of a card.
class GoogleCloudDialogflowV2beta1IntentMessageBasicCardButton {
  /// Action to take when a user taps on the button.
  ///
  /// Required.
  GoogleCloudDialogflowV2beta1IntentMessageBasicCardButtonOpenUriAction?
      openUriAction;

  /// The title of the button.
  ///
  /// Required.
  core.String? title;

  GoogleCloudDialogflowV2beta1IntentMessageBasicCardButton();

  GoogleCloudDialogflowV2beta1IntentMessageBasicCardButton.fromJson(
      core.Map _json) {
    if (_json.containsKey('openUriAction')) {
      openUriAction =
          GoogleCloudDialogflowV2beta1IntentMessageBasicCardButtonOpenUriAction
              .fromJson(_json['openUriAction']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (openUriAction != null) 'openUriAction': openUriAction!.toJson(),
        if (title != null) 'title': title!,
      };
}

/// Opens the given URI.
class GoogleCloudDialogflowV2beta1IntentMessageBasicCardButtonOpenUriAction {
  /// The HTTP or HTTPS scheme URI.
  ///
  /// Required.
  core.String? uri;

  GoogleCloudDialogflowV2beta1IntentMessageBasicCardButtonOpenUriAction();

  GoogleCloudDialogflowV2beta1IntentMessageBasicCardButtonOpenUriAction.fromJson(
      core.Map _json) {
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (uri != null) 'uri': uri!,
      };
}

/// Browse Carousel Card for Actions on Google.
///
/// https://developers.google.com/actions/assistant/responses#browsing_carousel
class GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCard {
  /// Settings for displaying the image.
  ///
  /// Applies to every image in items.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "IMAGE_DISPLAY_OPTIONS_UNSPECIFIED" : Fill the gaps between the image
  /// and the image container with gray bars.
  /// - "GRAY" : Fill the gaps between the image and the image container with
  /// gray bars.
  /// - "WHITE" : Fill the gaps between the image and the image container with
  /// white bars.
  /// - "CROPPED" : Image is scaled such that the image width and height match
  /// or exceed the container dimensions. This may crop the top and bottom of
  /// the image if the scaled image height is greater than the container height,
  /// or crop the left and right of the image if the scaled image width is
  /// greater than the container width. This is similar to "Zoom Mode" on a
  /// widescreen TV when playing a 4:3 video.
  /// - "BLURRED_BACKGROUND" : Pad the gaps between image and image frame with a
  /// blurred copy of the same image.
  core.String? imageDisplayOptions;

  /// List of items in the Browse Carousel Card.
  ///
  /// Minimum of two items, maximum of ten.
  ///
  /// Required.
  core.List<
          GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCardBrowseCarouselCardItem>?
      items;

  GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCard();

  GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCard.fromJson(
      core.Map _json) {
    if (_json.containsKey('imageDisplayOptions')) {
      imageDisplayOptions = _json['imageDisplayOptions'] as core.String;
    }
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCardBrowseCarouselCardItem>(
              (value) =>
                  GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCardBrowseCarouselCardItem
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (imageDisplayOptions != null)
          'imageDisplayOptions': imageDisplayOptions!,
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
      };
}

/// Browsing carousel tile
class GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCardBrowseCarouselCardItem {
  /// Description of the carousel item.
  ///
  /// Maximum of four lines of text.
  ///
  /// Optional.
  core.String? description;

  /// Text that appears at the bottom of the Browse Carousel Card.
  ///
  /// Maximum of one line of text.
  ///
  /// Optional.
  core.String? footer;

  /// Hero image for the carousel item.
  ///
  /// Optional.
  GoogleCloudDialogflowV2beta1IntentMessageImage? image;

  /// Action to present to the user.
  ///
  /// Required.
  GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCardBrowseCarouselCardItemOpenUrlAction?
      openUriAction;

  /// Title of the carousel item.
  ///
  /// Maximum of two lines of text.
  ///
  /// Required.
  core.String? title;

  GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCardBrowseCarouselCardItem();

  GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCardBrowseCarouselCardItem.fromJson(
      core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('footer')) {
      footer = _json['footer'] as core.String;
    }
    if (_json.containsKey('image')) {
      image = GoogleCloudDialogflowV2beta1IntentMessageImage.fromJson(
          _json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('openUriAction')) {
      openUriAction =
          GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCardBrowseCarouselCardItemOpenUrlAction
              .fromJson(_json['openUriAction']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (footer != null) 'footer': footer!,
        if (image != null) 'image': image!.toJson(),
        if (openUriAction != null) 'openUriAction': openUriAction!.toJson(),
        if (title != null) 'title': title!,
      };
}

/// Actions on Google action to open a given url.
class GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCardBrowseCarouselCardItemOpenUrlAction {
  /// URL
  ///
  /// Required.
  core.String? url;

  /// Specifies the type of viewer that is used when opening the URL.
  ///
  /// Defaults to opening via web browser.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "URL_TYPE_HINT_UNSPECIFIED" : Unspecified
  /// - "AMP_ACTION" : Url would be an amp action
  /// - "AMP_CONTENT" : URL that points directly to AMP content, or to a
  /// canonical URL which refers to AMP content via .
  core.String? urlTypeHint;

  GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCardBrowseCarouselCardItemOpenUrlAction();

  GoogleCloudDialogflowV2beta1IntentMessageBrowseCarouselCardBrowseCarouselCardItemOpenUrlAction.fromJson(
      core.Map _json) {
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
    if (_json.containsKey('urlTypeHint')) {
      urlTypeHint = _json['urlTypeHint'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (url != null) 'url': url!,
        if (urlTypeHint != null) 'urlTypeHint': urlTypeHint!,
      };
}

/// The card response message.
class GoogleCloudDialogflowV2beta1IntentMessageCard {
  /// The collection of card buttons.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1IntentMessageCardButton>? buttons;

  /// The public URI to an image file for the card.
  ///
  /// Optional.
  core.String? imageUri;

  /// The subtitle of the card.
  ///
  /// Optional.
  core.String? subtitle;

  /// The title of the card.
  ///
  /// Optional.
  core.String? title;

  GoogleCloudDialogflowV2beta1IntentMessageCard();

  GoogleCloudDialogflowV2beta1IntentMessageCard.fromJson(core.Map _json) {
    if (_json.containsKey('buttons')) {
      buttons = (_json['buttons'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageCardButton>((value) =>
              GoogleCloudDialogflowV2beta1IntentMessageCardButton.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('imageUri')) {
      imageUri = _json['imageUri'] as core.String;
    }
    if (_json.containsKey('subtitle')) {
      subtitle = _json['subtitle'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buttons != null)
          'buttons': buttons!.map((value) => value.toJson()).toList(),
        if (imageUri != null) 'imageUri': imageUri!,
        if (subtitle != null) 'subtitle': subtitle!,
        if (title != null) 'title': title!,
      };
}

/// Contains information about a button.
///
/// Optional.
class GoogleCloudDialogflowV2beta1IntentMessageCardButton {
  /// The text to send back to the Dialogflow API or a URI to open.
  ///
  /// Optional.
  core.String? postback;

  /// The text to show on the button.
  ///
  /// Optional.
  core.String? text;

  GoogleCloudDialogflowV2beta1IntentMessageCardButton();

  GoogleCloudDialogflowV2beta1IntentMessageCardButton.fromJson(core.Map _json) {
    if (_json.containsKey('postback')) {
      postback = _json['postback'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (postback != null) 'postback': postback!,
        if (text != null) 'text': text!,
      };
}

/// The card for presenting a carousel of options to select from.
class GoogleCloudDialogflowV2beta1IntentMessageCarouselSelect {
  /// Carousel items.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowV2beta1IntentMessageCarouselSelectItem>? items;

  GoogleCloudDialogflowV2beta1IntentMessageCarouselSelect();

  GoogleCloudDialogflowV2beta1IntentMessageCarouselSelect.fromJson(
      core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageCarouselSelectItem>(
              (value) =>
                  GoogleCloudDialogflowV2beta1IntentMessageCarouselSelectItem
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
      };
}

/// An item in the carousel.
class GoogleCloudDialogflowV2beta1IntentMessageCarouselSelectItem {
  /// The body text of the card.
  ///
  /// Optional.
  core.String? description;

  /// The image to display.
  ///
  /// Optional.
  GoogleCloudDialogflowV2beta1IntentMessageImage? image;

  /// Additional info about the option item.
  ///
  /// Required.
  GoogleCloudDialogflowV2beta1IntentMessageSelectItemInfo? info;

  /// Title of the carousel item.
  ///
  /// Required.
  core.String? title;

  GoogleCloudDialogflowV2beta1IntentMessageCarouselSelectItem();

  GoogleCloudDialogflowV2beta1IntentMessageCarouselSelectItem.fromJson(
      core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('image')) {
      image = GoogleCloudDialogflowV2beta1IntentMessageImage.fromJson(
          _json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('info')) {
      info = GoogleCloudDialogflowV2beta1IntentMessageSelectItemInfo.fromJson(
          _json['info'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (image != null) 'image': image!.toJson(),
        if (info != null) 'info': info!.toJson(),
        if (title != null) 'title': title!,
      };
}

/// Column properties for TableCard.
class GoogleCloudDialogflowV2beta1IntentMessageColumnProperties {
  /// Column heading.
  ///
  /// Required.
  core.String? header;

  /// Defines text alignment for all cells in this column.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "HORIZONTAL_ALIGNMENT_UNSPECIFIED" : Text is aligned to the leading edge
  /// of the column.
  /// - "LEADING" : Text is aligned to the leading edge of the column.
  /// - "CENTER" : Text is centered in the column.
  /// - "TRAILING" : Text is aligned to the trailing edge of the column.
  core.String? horizontalAlignment;

  GoogleCloudDialogflowV2beta1IntentMessageColumnProperties();

  GoogleCloudDialogflowV2beta1IntentMessageColumnProperties.fromJson(
      core.Map _json) {
    if (_json.containsKey('header')) {
      header = _json['header'] as core.String;
    }
    if (_json.containsKey('horizontalAlignment')) {
      horizontalAlignment = _json['horizontalAlignment'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (header != null) 'header': header!,
        if (horizontalAlignment != null)
          'horizontalAlignment': horizontalAlignment!,
      };
}

/// The image response message.
class GoogleCloudDialogflowV2beta1IntentMessageImage {
  /// A text description of the image to be used for accessibility, e.g., screen
  /// readers.
  ///
  /// Required if image_uri is set for CarouselSelect.
  core.String? accessibilityText;

  /// The public URI to an image file.
  ///
  /// Optional.
  core.String? imageUri;

  GoogleCloudDialogflowV2beta1IntentMessageImage();

  GoogleCloudDialogflowV2beta1IntentMessageImage.fromJson(core.Map _json) {
    if (_json.containsKey('accessibilityText')) {
      accessibilityText = _json['accessibilityText'] as core.String;
    }
    if (_json.containsKey('imageUri')) {
      imageUri = _json['imageUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessibilityText != null) 'accessibilityText': accessibilityText!,
        if (imageUri != null) 'imageUri': imageUri!,
      };
}

/// The suggestion chip message that allows the user to jump out to the app or
/// website associated with this agent.
class GoogleCloudDialogflowV2beta1IntentMessageLinkOutSuggestion {
  /// The name of the app or site this chip is linking to.
  ///
  /// Required.
  core.String? destinationName;

  /// The URI of the app or site to open when the user taps the suggestion chip.
  ///
  /// Required.
  core.String? uri;

  GoogleCloudDialogflowV2beta1IntentMessageLinkOutSuggestion();

  GoogleCloudDialogflowV2beta1IntentMessageLinkOutSuggestion.fromJson(
      core.Map _json) {
    if (_json.containsKey('destinationName')) {
      destinationName = _json['destinationName'] as core.String;
    }
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (destinationName != null) 'destinationName': destinationName!,
        if (uri != null) 'uri': uri!,
      };
}

/// The card for presenting a list of options to select from.
class GoogleCloudDialogflowV2beta1IntentMessageListSelect {
  /// List items.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowV2beta1IntentMessageListSelectItem>? items;

  /// Subtitle of the list.
  ///
  /// Optional.
  core.String? subtitle;

  /// The overall title of the list.
  ///
  /// Optional.
  core.String? title;

  GoogleCloudDialogflowV2beta1IntentMessageListSelect();

  GoogleCloudDialogflowV2beta1IntentMessageListSelect.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageListSelectItem>(
              (value) => GoogleCloudDialogflowV2beta1IntentMessageListSelectItem
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('subtitle')) {
      subtitle = _json['subtitle'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (subtitle != null) 'subtitle': subtitle!,
        if (title != null) 'title': title!,
      };
}

/// An item in the list.
class GoogleCloudDialogflowV2beta1IntentMessageListSelectItem {
  /// The main text describing the item.
  ///
  /// Optional.
  core.String? description;

  /// The image to display.
  ///
  /// Optional.
  GoogleCloudDialogflowV2beta1IntentMessageImage? image;

  /// Additional information about this option.
  ///
  /// Required.
  GoogleCloudDialogflowV2beta1IntentMessageSelectItemInfo? info;

  /// The title of the list item.
  ///
  /// Required.
  core.String? title;

  GoogleCloudDialogflowV2beta1IntentMessageListSelectItem();

  GoogleCloudDialogflowV2beta1IntentMessageListSelectItem.fromJson(
      core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('image')) {
      image = GoogleCloudDialogflowV2beta1IntentMessageImage.fromJson(
          _json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('info')) {
      info = GoogleCloudDialogflowV2beta1IntentMessageSelectItemInfo.fromJson(
          _json['info'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (image != null) 'image': image!.toJson(),
        if (info != null) 'info': info!.toJson(),
        if (title != null) 'title': title!,
      };
}

/// The media content card for Actions on Google.
class GoogleCloudDialogflowV2beta1IntentMessageMediaContent {
  /// List of media objects.
  ///
  /// Required.
  core.List<
          GoogleCloudDialogflowV2beta1IntentMessageMediaContentResponseMediaObject>?
      mediaObjects;

  /// What type of media is the content (ie "audio").
  ///
  /// Optional.
  /// Possible string values are:
  /// - "RESPONSE_MEDIA_TYPE_UNSPECIFIED" : Unspecified.
  /// - "AUDIO" : Response media type is audio.
  core.String? mediaType;

  GoogleCloudDialogflowV2beta1IntentMessageMediaContent();

  GoogleCloudDialogflowV2beta1IntentMessageMediaContent.fromJson(
      core.Map _json) {
    if (_json.containsKey('mediaObjects')) {
      mediaObjects = (_json['mediaObjects'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageMediaContentResponseMediaObject>(
              (value) =>
                  GoogleCloudDialogflowV2beta1IntentMessageMediaContentResponseMediaObject
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('mediaType')) {
      mediaType = _json['mediaType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mediaObjects != null)
          'mediaObjects': mediaObjects!.map((value) => value.toJson()).toList(),
        if (mediaType != null) 'mediaType': mediaType!,
      };
}

/// Response media object for media content card.
class GoogleCloudDialogflowV2beta1IntentMessageMediaContentResponseMediaObject {
  /// Url where the media is stored.
  ///
  /// Required.
  core.String? contentUrl;

  /// Description of media card.
  ///
  /// Optional.
  core.String? description;

  /// Icon to display above media content.
  ///
  /// Optional.
  GoogleCloudDialogflowV2beta1IntentMessageImage? icon;

  /// Image to display above media content.
  ///
  /// Optional.
  GoogleCloudDialogflowV2beta1IntentMessageImage? largeImage;

  /// Name of media card.
  ///
  /// Required.
  core.String? name;

  GoogleCloudDialogflowV2beta1IntentMessageMediaContentResponseMediaObject();

  GoogleCloudDialogflowV2beta1IntentMessageMediaContentResponseMediaObject.fromJson(
      core.Map _json) {
    if (_json.containsKey('contentUrl')) {
      contentUrl = _json['contentUrl'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('icon')) {
      icon = GoogleCloudDialogflowV2beta1IntentMessageImage.fromJson(
          _json['icon'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('largeImage')) {
      largeImage = GoogleCloudDialogflowV2beta1IntentMessageImage.fromJson(
          _json['largeImage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contentUrl != null) 'contentUrl': contentUrl!,
        if (description != null) 'description': description!,
        if (icon != null) 'icon': icon!.toJson(),
        if (largeImage != null) 'largeImage': largeImage!.toJson(),
        if (name != null) 'name': name!,
      };
}

/// The quick replies response message.
class GoogleCloudDialogflowV2beta1IntentMessageQuickReplies {
  /// The collection of quick replies.
  ///
  /// Optional.
  core.List<core.String>? quickReplies;

  /// The title of the collection of quick replies.
  ///
  /// Optional.
  core.String? title;

  GoogleCloudDialogflowV2beta1IntentMessageQuickReplies();

  GoogleCloudDialogflowV2beta1IntentMessageQuickReplies.fromJson(
      core.Map _json) {
    if (_json.containsKey('quickReplies')) {
      quickReplies = (_json['quickReplies'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (quickReplies != null) 'quickReplies': quickReplies!,
        if (title != null) 'title': title!,
      };
}

/// Rich Business Messaging (RBM) Card content
class GoogleCloudDialogflowV2beta1IntentMessageRbmCardContent {
  /// Description of the card (at most 2000 bytes).
  ///
  /// At least one of the title, description or media must be set.
  ///
  /// Optional.
  core.String? description;

  /// However at least one of the title, description or media must be set.
  ///
  /// Media (image, GIF or a video) to include in the card.
  ///
  /// Optional.
  GoogleCloudDialogflowV2beta1IntentMessageRbmCardContentRbmMedia? media;

  /// List of suggestions to include in the card.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestion>?
      suggestions;

  /// Title of the card (at most 200 bytes).
  ///
  /// At least one of the title, description or media must be set.
  ///
  /// Optional.
  core.String? title;

  GoogleCloudDialogflowV2beta1IntentMessageRbmCardContent();

  GoogleCloudDialogflowV2beta1IntentMessageRbmCardContent.fromJson(
      core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('media')) {
      media = GoogleCloudDialogflowV2beta1IntentMessageRbmCardContentRbmMedia
          .fromJson(_json['media'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('suggestions')) {
      suggestions = (_json['suggestions'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestion>(
              (value) => GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestion
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (media != null) 'media': media!.toJson(),
        if (suggestions != null)
          'suggestions': suggestions!.map((value) => value.toJson()).toList(),
        if (title != null) 'title': title!,
      };
}

/// Rich Business Messaging (RBM) Media displayed in Cards The following
/// media-types are currently supported: Image Types * image/jpeg * image/jpg' *
/// image/gif * image/png Video Types * video/h263 * video/m4v * video/mp4 *
/// video/mpeg * video/mpeg4 * video/webm
class GoogleCloudDialogflowV2beta1IntentMessageRbmCardContentRbmMedia {
  /// Publicly reachable URI of the file.
  ///
  /// The RBM platform determines the MIME type of the file from the
  /// content-type field in the HTTP headers when the platform fetches the file.
  /// The content-type field must be present and accurate in the HTTP response
  /// from the URL.
  ///
  /// Required.
  core.String? fileUri;

  /// Required for cards with vertical orientation.
  ///
  /// The height of the media within a rich card with a vertical layout. For a
  /// standalone card with horizontal layout, height is not customizable, and
  /// this field is ignored.
  /// Possible string values are:
  /// - "HEIGHT_UNSPECIFIED" : Not specified.
  /// - "SHORT" : 112 DP.
  /// - "MEDIUM" : 168 DP.
  /// - "TALL" : 264 DP. Not available for rich card carousels when the card
  /// width is set to small.
  core.String? height;

  /// Publicly reachable URI of the thumbnail.If you don't provide a thumbnail
  /// URI, the RBM platform displays a blank placeholder thumbnail until the
  /// user's device downloads the file.
  ///
  /// Depending on the user's setting, the file may not download automatically
  /// and may require the user to tap a download button.
  ///
  /// Optional.
  core.String? thumbnailUri;

  GoogleCloudDialogflowV2beta1IntentMessageRbmCardContentRbmMedia();

  GoogleCloudDialogflowV2beta1IntentMessageRbmCardContentRbmMedia.fromJson(
      core.Map _json) {
    if (_json.containsKey('fileUri')) {
      fileUri = _json['fileUri'] as core.String;
    }
    if (_json.containsKey('height')) {
      height = _json['height'] as core.String;
    }
    if (_json.containsKey('thumbnailUri')) {
      thumbnailUri = _json['thumbnailUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fileUri != null) 'fileUri': fileUri!,
        if (height != null) 'height': height!,
        if (thumbnailUri != null) 'thumbnailUri': thumbnailUri!,
      };
}

/// Carousel Rich Business Messaging (RBM) rich card.
///
/// Rich cards allow you to respond to users with more vivid content, e.g. with
/// media and suggestions. If you want to show a single card with more control
/// over the layout, please use RbmStandaloneCard instead.
class GoogleCloudDialogflowV2beta1IntentMessageRbmCarouselCard {
  /// The cards in the carousel.
  ///
  /// A carousel must have at least 2 cards and at most 10.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowV2beta1IntentMessageRbmCardContent>?
      cardContents;

  /// The width of the cards in the carousel.
  ///
  /// Required.
  /// Possible string values are:
  /// - "CARD_WIDTH_UNSPECIFIED" : Not specified.
  /// - "SMALL" : 120 DP. Note that tall media cannot be used.
  /// - "MEDIUM" : 232 DP.
  core.String? cardWidth;

  GoogleCloudDialogflowV2beta1IntentMessageRbmCarouselCard();

  GoogleCloudDialogflowV2beta1IntentMessageRbmCarouselCard.fromJson(
      core.Map _json) {
    if (_json.containsKey('cardContents')) {
      cardContents = (_json['cardContents'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageRbmCardContent>(
              (value) => GoogleCloudDialogflowV2beta1IntentMessageRbmCardContent
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('cardWidth')) {
      cardWidth = _json['cardWidth'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cardContents != null)
          'cardContents': cardContents!.map((value) => value.toJson()).toList(),
        if (cardWidth != null) 'cardWidth': cardWidth!,
      };
}

/// Standalone Rich Business Messaging (RBM) rich card.
///
/// Rich cards allow you to respond to users with more vivid content, e.g. with
/// media and suggestions. You can group multiple rich cards into one using
/// RbmCarouselCard but carousel cards will give you less control over the card
/// layout.
class GoogleCloudDialogflowV2beta1IntentMessageRbmStandaloneCard {
  /// Card content.
  ///
  /// Required.
  GoogleCloudDialogflowV2beta1IntentMessageRbmCardContent? cardContent;

  /// Orientation of the card.
  ///
  /// Required.
  /// Possible string values are:
  /// - "CARD_ORIENTATION_UNSPECIFIED" : Not specified.
  /// - "HORIZONTAL" : Horizontal layout.
  /// - "VERTICAL" : Vertical layout.
  core.String? cardOrientation;

  /// Required if orientation is horizontal.
  ///
  /// Image preview alignment for standalone cards with horizontal layout.
  /// Possible string values are:
  /// - "THUMBNAIL_IMAGE_ALIGNMENT_UNSPECIFIED" : Not specified.
  /// - "LEFT" : Thumbnail preview is left-aligned.
  /// - "RIGHT" : Thumbnail preview is right-aligned.
  core.String? thumbnailImageAlignment;

  GoogleCloudDialogflowV2beta1IntentMessageRbmStandaloneCard();

  GoogleCloudDialogflowV2beta1IntentMessageRbmStandaloneCard.fromJson(
      core.Map _json) {
    if (_json.containsKey('cardContent')) {
      cardContent =
          GoogleCloudDialogflowV2beta1IntentMessageRbmCardContent.fromJson(
              _json['cardContent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('cardOrientation')) {
      cardOrientation = _json['cardOrientation'] as core.String;
    }
    if (_json.containsKey('thumbnailImageAlignment')) {
      thumbnailImageAlignment = _json['thumbnailImageAlignment'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cardContent != null) 'cardContent': cardContent!.toJson(),
        if (cardOrientation != null) 'cardOrientation': cardOrientation!,
        if (thumbnailImageAlignment != null)
          'thumbnailImageAlignment': thumbnailImageAlignment!,
      };
}

/// Rich Business Messaging (RBM) suggested client-side action that the user can
/// choose from the card.
class GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedAction {
  /// Suggested client side action: Dial a phone number
  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionDial?
      dial;

  /// Suggested client side action: Open a URI on device
  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionOpenUri?
      openUrl;

  /// Opaque payload that the Dialogflow receives in a user event when the user
  /// taps the suggested action.
  ///
  /// This data will be also forwarded to webhook to allow performing custom
  /// business logic.
  core.String? postbackData;

  /// Suggested client side action: Share user location
  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionShareLocation?
      shareLocation;

  /// Text to display alongside the action.
  core.String? text;

  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedAction();

  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedAction.fromJson(
      core.Map _json) {
    if (_json.containsKey('dial')) {
      dial =
          GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionDial
              .fromJson(_json['dial'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('openUrl')) {
      openUrl =
          GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionOpenUri
              .fromJson(
                  _json['openUrl'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('postbackData')) {
      postbackData = _json['postbackData'] as core.String;
    }
    if (_json.containsKey('shareLocation')) {
      shareLocation =
          GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionShareLocation
              .fromJson(_json['shareLocation']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dial != null) 'dial': dial!.toJson(),
        if (openUrl != null) 'openUrl': openUrl!.toJson(),
        if (postbackData != null) 'postbackData': postbackData!,
        if (shareLocation != null) 'shareLocation': shareLocation!.toJson(),
        if (text != null) 'text': text!,
      };
}

/// Opens the user's default dialer app with the specified phone number but does
/// not dial automatically.
class GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionDial {
  /// The phone number to fill in the default dialer app.
  ///
  /// This field should be in [E.164](https://en.wikipedia.org/wiki/E.164)
  /// format. An example of a correctly formatted phone number: +15556767888.
  ///
  /// Required.
  core.String? phoneNumber;

  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionDial();

  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionDial.fromJson(
      core.Map _json) {
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
      };
}

/// Opens the user's default web browser app to the specified uri If the user
/// has an app installed that is registered as the default handler for the URL,
/// then this app will be opened instead, and its icon will be used in the
/// suggested action UI.
class GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionOpenUri {
  /// The uri to open on the user device
  ///
  /// Required.
  core.String? uri;

  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionOpenUri();

  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionOpenUri.fromJson(
      core.Map _json) {
    if (_json.containsKey('uri')) {
      uri = _json['uri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (uri != null) 'uri': uri!,
      };
}

/// Opens the device's location chooser so the user can pick a location to send
/// back to the agent.
class GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionShareLocation {
  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionShareLocation();

  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedActionRbmSuggestedActionShareLocation.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Rich Business Messaging (RBM) suggested reply that the user can click
/// instead of typing in their own response.
class GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedReply {
  /// Opaque payload that the Dialogflow receives in a user event when the user
  /// taps the suggested reply.
  ///
  /// This data will be also forwarded to webhook to allow performing custom
  /// business logic.
  core.String? postbackData;

  /// Suggested reply text.
  core.String? text;

  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedReply();

  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedReply.fromJson(
      core.Map _json) {
    if (_json.containsKey('postbackData')) {
      postbackData = _json['postbackData'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (postbackData != null) 'postbackData': postbackData!,
        if (text != null) 'text': text!,
      };
}

/// Rich Business Messaging (RBM) suggestion.
///
/// Suggestions allow user to easily select/click a predefined response or
/// perform an action (like opening a web uri).
class GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestion {
  /// Predefined client side actions that user can choose
  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedAction? action;

  /// Predefined replies for user to select instead of typing
  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedReply? reply;

  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestion();

  GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestion.fromJson(
      core.Map _json) {
    if (_json.containsKey('action')) {
      action =
          GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedAction.fromJson(
              _json['action'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('reply')) {
      reply =
          GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestedReply.fromJson(
              _json['reply'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!.toJson(),
        if (reply != null) 'reply': reply!.toJson(),
      };
}

/// Rich Business Messaging (RBM) text response with suggestions.
class GoogleCloudDialogflowV2beta1IntentMessageRbmText {
  /// One or more suggestions to show to the user.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestion>?
      rbmSuggestion;

  /// Text sent and displayed to the user.
  ///
  /// Required.
  core.String? text;

  GoogleCloudDialogflowV2beta1IntentMessageRbmText();

  GoogleCloudDialogflowV2beta1IntentMessageRbmText.fromJson(core.Map _json) {
    if (_json.containsKey('rbmSuggestion')) {
      rbmSuggestion = (_json['rbmSuggestion'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestion>(
              (value) => GoogleCloudDialogflowV2beta1IntentMessageRbmSuggestion
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rbmSuggestion != null)
          'rbmSuggestion':
              rbmSuggestion!.map((value) => value.toJson()).toList(),
        if (text != null) 'text': text!,
      };
}

/// Additional info about the select item for when it is triggered in a dialog.
class GoogleCloudDialogflowV2beta1IntentMessageSelectItemInfo {
  /// A unique key that will be sent back to the agent if this response is
  /// given.
  ///
  /// Required.
  core.String? key;

  /// A list of synonyms that can also be used to trigger this item in dialog.
  ///
  /// Optional.
  core.List<core.String>? synonyms;

  GoogleCloudDialogflowV2beta1IntentMessageSelectItemInfo();

  GoogleCloudDialogflowV2beta1IntentMessageSelectItemInfo.fromJson(
      core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('synonyms')) {
      synonyms = (_json['synonyms'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (synonyms != null) 'synonyms': synonyms!,
      };
}

/// The simple response message containing speech or text.
class GoogleCloudDialogflowV2beta1IntentMessageSimpleResponse {
  /// The text to display.
  ///
  /// Optional.
  core.String? displayText;

  /// One of text_to_speech or ssml must be provided.
  ///
  /// Structured spoken response to the user in the SSML format. Mutually
  /// exclusive with text_to_speech.
  core.String? ssml;

  /// One of text_to_speech or ssml must be provided.
  ///
  /// The plain text of the speech output. Mutually exclusive with ssml.
  core.String? textToSpeech;

  GoogleCloudDialogflowV2beta1IntentMessageSimpleResponse();

  GoogleCloudDialogflowV2beta1IntentMessageSimpleResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('displayText')) {
      displayText = _json['displayText'] as core.String;
    }
    if (_json.containsKey('ssml')) {
      ssml = _json['ssml'] as core.String;
    }
    if (_json.containsKey('textToSpeech')) {
      textToSpeech = _json['textToSpeech'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (displayText != null) 'displayText': displayText!,
        if (ssml != null) 'ssml': ssml!,
        if (textToSpeech != null) 'textToSpeech': textToSpeech!,
      };
}

/// The collection of simple response candidates.
///
/// This message in `QueryResult.fulfillment_messages` and
/// `WebhookResponse.fulfillment_messages` should contain only one
/// `SimpleResponse`.
class GoogleCloudDialogflowV2beta1IntentMessageSimpleResponses {
  /// The list of simple responses.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowV2beta1IntentMessageSimpleResponse>?
      simpleResponses;

  GoogleCloudDialogflowV2beta1IntentMessageSimpleResponses();

  GoogleCloudDialogflowV2beta1IntentMessageSimpleResponses.fromJson(
      core.Map _json) {
    if (_json.containsKey('simpleResponses')) {
      simpleResponses = (_json['simpleResponses'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageSimpleResponse>(
              (value) => GoogleCloudDialogflowV2beta1IntentMessageSimpleResponse
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (simpleResponses != null)
          'simpleResponses':
              simpleResponses!.map((value) => value.toJson()).toList(),
      };
}

/// The suggestion chip message that the user can tap to quickly post a reply to
/// the conversation.
class GoogleCloudDialogflowV2beta1IntentMessageSuggestion {
  /// The text shown the in the suggestion chip.
  ///
  /// Required.
  core.String? title;

  GoogleCloudDialogflowV2beta1IntentMessageSuggestion();

  GoogleCloudDialogflowV2beta1IntentMessageSuggestion.fromJson(core.Map _json) {
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (title != null) 'title': title!,
      };
}

/// The collection of suggestions.
class GoogleCloudDialogflowV2beta1IntentMessageSuggestions {
  /// The list of suggested replies.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowV2beta1IntentMessageSuggestion>? suggestions;

  GoogleCloudDialogflowV2beta1IntentMessageSuggestions();

  GoogleCloudDialogflowV2beta1IntentMessageSuggestions.fromJson(
      core.Map _json) {
    if (_json.containsKey('suggestions')) {
      suggestions = (_json['suggestions'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageSuggestion>((value) =>
              GoogleCloudDialogflowV2beta1IntentMessageSuggestion.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (suggestions != null)
          'suggestions': suggestions!.map((value) => value.toJson()).toList(),
      };
}

/// Table card for Actions on Google.
class GoogleCloudDialogflowV2beta1IntentMessageTableCard {
  /// List of buttons for the card.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1IntentMessageBasicCardButton>? buttons;

  /// Display properties for the columns in this table.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1IntentMessageColumnProperties>?
      columnProperties;

  /// Image which should be displayed on the card.
  ///
  /// Optional.
  GoogleCloudDialogflowV2beta1IntentMessageImage? image;

  /// Rows in this table of data.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1IntentMessageTableCardRow>? rows;

  /// Subtitle to the title.
  ///
  /// Optional.
  core.String? subtitle;

  /// Title of the card.
  ///
  /// Required.
  core.String? title;

  GoogleCloudDialogflowV2beta1IntentMessageTableCard();

  GoogleCloudDialogflowV2beta1IntentMessageTableCard.fromJson(core.Map _json) {
    if (_json.containsKey('buttons')) {
      buttons = (_json['buttons'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageBasicCardButton>(
              (value) =>
                  GoogleCloudDialogflowV2beta1IntentMessageBasicCardButton
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('columnProperties')) {
      columnProperties = (_json['columnProperties'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageColumnProperties>(
              (value) =>
                  GoogleCloudDialogflowV2beta1IntentMessageColumnProperties
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('image')) {
      image = GoogleCloudDialogflowV2beta1IntentMessageImage.fromJson(
          _json['image'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rows')) {
      rows = (_json['rows'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageTableCardRow>((value) =>
              GoogleCloudDialogflowV2beta1IntentMessageTableCardRow.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('subtitle')) {
      subtitle = _json['subtitle'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buttons != null)
          'buttons': buttons!.map((value) => value.toJson()).toList(),
        if (columnProperties != null)
          'columnProperties':
              columnProperties!.map((value) => value.toJson()).toList(),
        if (image != null) 'image': image!.toJson(),
        if (rows != null) 'rows': rows!.map((value) => value.toJson()).toList(),
        if (subtitle != null) 'subtitle': subtitle!,
        if (title != null) 'title': title!,
      };
}

/// Cell of TableCardRow.
class GoogleCloudDialogflowV2beta1IntentMessageTableCardCell {
  /// Text in this cell.
  ///
  /// Required.
  core.String? text;

  GoogleCloudDialogflowV2beta1IntentMessageTableCardCell();

  GoogleCloudDialogflowV2beta1IntentMessageTableCardCell.fromJson(
      core.Map _json) {
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (text != null) 'text': text!,
      };
}

/// Row of TableCard.
class GoogleCloudDialogflowV2beta1IntentMessageTableCardRow {
  /// List of cells that make up this row.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1IntentMessageTableCardCell>? cells;

  /// Whether to add a visual divider after this row.
  ///
  /// Optional.
  core.bool? dividerAfter;

  GoogleCloudDialogflowV2beta1IntentMessageTableCardRow();

  GoogleCloudDialogflowV2beta1IntentMessageTableCardRow.fromJson(
      core.Map _json) {
    if (_json.containsKey('cells')) {
      cells = (_json['cells'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessageTableCardCell>(
              (value) => GoogleCloudDialogflowV2beta1IntentMessageTableCardCell
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('dividerAfter')) {
      dividerAfter = _json['dividerAfter'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cells != null)
          'cells': cells!.map((value) => value.toJson()).toList(),
        if (dividerAfter != null) 'dividerAfter': dividerAfter!,
      };
}

/// Plays audio from a file in Telephony Gateway.
class GoogleCloudDialogflowV2beta1IntentMessageTelephonyPlayAudio {
  /// URI to a Google Cloud Storage object containing the audio to play, e.g.,
  /// "gs://bucket/object".
  ///
  /// The object must contain a single channel (mono) of linear PCM audio (2
  /// bytes / sample) at 8kHz. This object must be readable by the
  /// `service-@gcp-sa-dialogflow.iam.gserviceaccount.com` service account where
  /// is the number of the Telephony Gateway project (usually the same as the
  /// Dialogflow agent project). If the Google Cloud Storage bucket is in the
  /// Telephony Gateway project, this permission is added by default when
  /// enabling the Dialogflow V2 API. For audio from other sources, consider
  /// using the `TelephonySynthesizeSpeech` message with SSML.
  ///
  /// Required.
  core.String? audioUri;

  GoogleCloudDialogflowV2beta1IntentMessageTelephonyPlayAudio();

  GoogleCloudDialogflowV2beta1IntentMessageTelephonyPlayAudio.fromJson(
      core.Map _json) {
    if (_json.containsKey('audioUri')) {
      audioUri = _json['audioUri'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audioUri != null) 'audioUri': audioUri!,
      };
}

/// Synthesizes speech and plays back the synthesized audio to the caller in
/// Telephony Gateway.
///
/// Telephony Gateway takes the synthesizer settings from
/// `DetectIntentResponse.output_audio_config` which can either be set at
/// request-level or can come from the agent-level synthesizer config.
class GoogleCloudDialogflowV2beta1IntentMessageTelephonySynthesizeSpeech {
  /// The SSML to be synthesized.
  ///
  /// For more information, see
  /// [SSML](https://developers.google.com/actions/reference/ssml).
  core.String? ssml;

  /// The raw text to be synthesized.
  core.String? text;

  GoogleCloudDialogflowV2beta1IntentMessageTelephonySynthesizeSpeech();

  GoogleCloudDialogflowV2beta1IntentMessageTelephonySynthesizeSpeech.fromJson(
      core.Map _json) {
    if (_json.containsKey('ssml')) {
      ssml = _json['ssml'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ssml != null) 'ssml': ssml!,
        if (text != null) 'text': text!,
      };
}

/// Transfers the call in Telephony Gateway.
class GoogleCloudDialogflowV2beta1IntentMessageTelephonyTransferCall {
  /// The phone number to transfer the call to in
  /// [E.164 format](https://en.wikipedia.org/wiki/E.164).
  ///
  /// We currently only allow transferring to US numbers (+1xxxyyyzzzz).
  ///
  /// Required.
  core.String? phoneNumber;

  GoogleCloudDialogflowV2beta1IntentMessageTelephonyTransferCall();

  GoogleCloudDialogflowV2beta1IntentMessageTelephonyTransferCall.fromJson(
      core.Map _json) {
    if (_json.containsKey('phoneNumber')) {
      phoneNumber = _json['phoneNumber'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (phoneNumber != null) 'phoneNumber': phoneNumber!,
      };
}

/// The text response message.
class GoogleCloudDialogflowV2beta1IntentMessageText {
  /// The collection of the agent's responses.
  ///
  /// Optional.
  core.List<core.String>? text;

  GoogleCloudDialogflowV2beta1IntentMessageText();

  GoogleCloudDialogflowV2beta1IntentMessageText.fromJson(core.Map _json) {
    if (_json.containsKey('text')) {
      text = (_json['text'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (text != null) 'text': text!,
      };
}

/// Represents intent parameters.
class GoogleCloudDialogflowV2beta1IntentParameter {
  /// The default value to use when the `value` yields an empty result.
  ///
  /// Default values can be extracted from contexts by using the following
  /// syntax: `#context_name.parameter_name`.
  ///
  /// Optional.
  core.String? defaultValue;

  /// The name of the parameter.
  ///
  /// Required.
  core.String? displayName;

  /// The name of the entity type, prefixed with `@`, that describes values of
  /// the parameter.
  ///
  /// If the parameter is required, this must be provided.
  ///
  /// Optional.
  core.String? entityTypeDisplayName;

  /// Indicates whether the parameter represents a list of values.
  ///
  /// Optional.
  core.bool? isList;

  /// Indicates whether the parameter is required.
  ///
  /// That is, whether the intent cannot be completed without collecting the
  /// parameter value.
  ///
  /// Optional.
  core.bool? mandatory;

  /// The unique identifier of this parameter.
  core.String? name;

  /// The collection of prompts that the agent can present to the user in order
  /// to collect a value for the parameter.
  ///
  /// Optional.
  core.List<core.String>? prompts;

  /// The definition of the parameter value.
  ///
  /// It can be: - a constant string, - a parameter value defined as
  /// `$parameter_name`, - an original parameter value defined as
  /// `$parameter_name.original`, - a parameter value from some context defined
  /// as `#context_name.parameter_name`.
  ///
  /// Optional.
  core.String? value;

  GoogleCloudDialogflowV2beta1IntentParameter();

  GoogleCloudDialogflowV2beta1IntentParameter.fromJson(core.Map _json) {
    if (_json.containsKey('defaultValue')) {
      defaultValue = _json['defaultValue'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('entityTypeDisplayName')) {
      entityTypeDisplayName = _json['entityTypeDisplayName'] as core.String;
    }
    if (_json.containsKey('isList')) {
      isList = _json['isList'] as core.bool;
    }
    if (_json.containsKey('mandatory')) {
      mandatory = _json['mandatory'] as core.bool;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('prompts')) {
      prompts = (_json['prompts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (defaultValue != null) 'defaultValue': defaultValue!,
        if (displayName != null) 'displayName': displayName!,
        if (entityTypeDisplayName != null)
          'entityTypeDisplayName': entityTypeDisplayName!,
        if (isList != null) 'isList': isList!,
        if (mandatory != null) 'mandatory': mandatory!,
        if (name != null) 'name': name!,
        if (prompts != null) 'prompts': prompts!,
        if (value != null) 'value': value!,
      };
}

/// Represents an example that the agent is trained on.
class GoogleCloudDialogflowV2beta1IntentTrainingPhrase {
  /// The unique identifier of this training phrase.
  ///
  /// Output only.
  core.String? name;

  /// The ordered list of training phrase parts.
  ///
  /// The parts are concatenated in order to form the training phrase. Note: The
  /// API does not automatically annotate training phrases like the Dialogflow
  /// Console does. Note: Do not forget to include whitespace at part
  /// boundaries, so the training phrase is well formatted when the parts are
  /// concatenated. If the training phrase does not need to be annotated with
  /// parameters, you just need a single part with only the Part.text field set.
  /// If you want to annotate the training phrase, you must create multiple
  /// parts, where the fields of each part are populated in one of two ways: -
  /// `Part.text` is set to a part of the phrase that has no parameters. -
  /// `Part.text` is set to a part of the phrase that you want to annotate, and
  /// the `entity_type`, `alias`, and `user_defined` fields are all set.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowV2beta1IntentTrainingPhrasePart>? parts;

  /// Indicates how many times this example was added to the intent.
  ///
  /// Each time a developer adds an existing sample by editing an intent or
  /// training, this counter is increased.
  ///
  /// Optional.
  core.int? timesAddedCount;

  /// The type of the training phrase.
  ///
  /// Required.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Not specified. This value should never be used.
  /// - "EXAMPLE" : Examples do not contain @-prefixed entity type names, but
  /// example parts can be annotated with entity types.
  /// - "TEMPLATE" : Templates are not annotated with entity types, but they can
  /// contain @-prefixed entity type names as substrings. Template mode has been
  /// deprecated. Example mode is the only supported way to create new training
  /// phrases. If you have existing training phrases that you've created in
  /// template mode, those will continue to work.
  core.String? type;

  GoogleCloudDialogflowV2beta1IntentTrainingPhrase();

  GoogleCloudDialogflowV2beta1IntentTrainingPhrase.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parts')) {
      parts = (_json['parts'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentTrainingPhrasePart>((value) =>
              GoogleCloudDialogflowV2beta1IntentTrainingPhrasePart.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('timesAddedCount')) {
      timesAddedCount = _json['timesAddedCount'] as core.int;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (parts != null)
          'parts': parts!.map((value) => value.toJson()).toList(),
        if (timesAddedCount != null) 'timesAddedCount': timesAddedCount!,
        if (type != null) 'type': type!,
      };
}

/// Represents a part of a training phrase.
class GoogleCloudDialogflowV2beta1IntentTrainingPhrasePart {
  /// The parameter name for the value extracted from the annotated part of the
  /// example.
  ///
  /// This field is required for annotated parts of the training phrase.
  ///
  /// Optional.
  core.String? alias;

  /// The entity type name prefixed with `@`.
  ///
  /// This field is required for annotated parts of the training phrase.
  ///
  /// Optional.
  core.String? entityType;

  /// The text for this part.
  ///
  /// Required.
  core.String? text;

  /// Indicates whether the text was manually annotated.
  ///
  /// This field is set to true when the Dialogflow Console is used to manually
  /// annotate the part. When creating an annotated part with the API, you must
  /// set this to true.
  ///
  /// Optional.
  core.bool? userDefined;

  GoogleCloudDialogflowV2beta1IntentTrainingPhrasePart();

  GoogleCloudDialogflowV2beta1IntentTrainingPhrasePart.fromJson(
      core.Map _json) {
    if (_json.containsKey('alias')) {
      alias = _json['alias'] as core.String;
    }
    if (_json.containsKey('entityType')) {
      entityType = _json['entityType'] as core.String;
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
    if (_json.containsKey('userDefined')) {
      userDefined = _json['userDefined'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alias != null) 'alias': alias!,
        if (entityType != null) 'entityType': entityType!,
        if (text != null) 'text': text!,
        if (userDefined != null) 'userDefined': userDefined!,
      };
}

/// Represents the result of querying a Knowledge base.
class GoogleCloudDialogflowV2beta1KnowledgeAnswers {
  /// A list of answers from Knowledge Connector.
  core.List<GoogleCloudDialogflowV2beta1KnowledgeAnswersAnswer>? answers;

  GoogleCloudDialogflowV2beta1KnowledgeAnswers();

  GoogleCloudDialogflowV2beta1KnowledgeAnswers.fromJson(core.Map _json) {
    if (_json.containsKey('answers')) {
      answers = (_json['answers'] as core.List)
          .map<GoogleCloudDialogflowV2beta1KnowledgeAnswersAnswer>((value) =>
              GoogleCloudDialogflowV2beta1KnowledgeAnswersAnswer.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (answers != null)
          'answers': answers!.map((value) => value.toJson()).toList(),
      };
}

/// An answer from Knowledge Connector.
class GoogleCloudDialogflowV2beta1KnowledgeAnswersAnswer {
  /// The piece of text from the `source` knowledge base document that answers
  /// this conversational query.
  core.String? answer;

  /// The corresponding FAQ question if the answer was extracted from a FAQ
  /// Document, empty otherwise.
  core.String? faqQuestion;

  /// The system's confidence score that this Knowledge answer is a good match
  /// for this conversational query.
  ///
  /// The range is from 0.0 (completely uncertain) to 1.0 (completely certain).
  /// Note: The confidence score is likely to vary somewhat (possibly even for
  /// identical requests), as the underlying model is under constant
  /// improvement. It may be deprecated in the future. We recommend using
  /// `match_confidence_level` which should be generally more stable.
  core.double? matchConfidence;

  /// The system's confidence level that this knowledge answer is a good match
  /// for this conversational query.
  ///
  /// NOTE: The confidence level for a given `` pair may change without notice,
  /// as it depends on models that are constantly being improved. However, it
  /// will change less frequently than the confidence score below, and should be
  /// preferred for referencing the quality of an answer.
  /// Possible string values are:
  /// - "MATCH_CONFIDENCE_LEVEL_UNSPECIFIED" : Not specified.
  /// - "LOW" : Indicates that the confidence is low.
  /// - "MEDIUM" : Indicates our confidence is medium.
  /// - "HIGH" : Indicates our confidence is high.
  core.String? matchConfidenceLevel;

  /// Indicates which Knowledge Document this answer was extracted from.
  ///
  /// Format: `projects//knowledgeBases//documents/`.
  core.String? source;

  GoogleCloudDialogflowV2beta1KnowledgeAnswersAnswer();

  GoogleCloudDialogflowV2beta1KnowledgeAnswersAnswer.fromJson(core.Map _json) {
    if (_json.containsKey('answer')) {
      answer = _json['answer'] as core.String;
    }
    if (_json.containsKey('faqQuestion')) {
      faqQuestion = _json['faqQuestion'] as core.String;
    }
    if (_json.containsKey('matchConfidence')) {
      matchConfidence = (_json['matchConfidence'] as core.num).toDouble();
    }
    if (_json.containsKey('matchConfidenceLevel')) {
      matchConfidenceLevel = _json['matchConfidenceLevel'] as core.String;
    }
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (answer != null) 'answer': answer!,
        if (faqQuestion != null) 'faqQuestion': faqQuestion!,
        if (matchConfidence != null) 'matchConfidence': matchConfidence!,
        if (matchConfidenceLevel != null)
          'matchConfidenceLevel': matchConfidenceLevel!,
        if (source != null) 'source': source!,
      };
}

/// Metadata in google::longrunning::Operation for Knowledge operations.
class GoogleCloudDialogflowV2beta1KnowledgeOperationMetadata {
  /// The current state of this operation.
  ///
  /// Required. Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : State unspecified.
  /// - "PENDING" : The operation has been created.
  /// - "RUNNING" : The operation is currently running.
  /// - "DONE" : The operation is done, either cancelled or completed.
  core.String? state;

  GoogleCloudDialogflowV2beta1KnowledgeOperationMetadata();

  GoogleCloudDialogflowV2beta1KnowledgeOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (state != null) 'state': state!,
      };
}

/// Represents a message posted into a conversation.
class GoogleCloudDialogflowV2beta1Message {
  /// The message content.
  ///
  /// Required.
  core.String? content;

  /// The time when the message was created in Contact Center AI.
  ///
  /// Output only.
  core.String? createTime;

  /// The message language.
  ///
  /// This should be a \[BCP-47\](https://www.rfc-editor.org/rfc/bcp/bcp47.txt)
  /// language tag. Example: "en-US".
  ///
  /// Optional.
  core.String? languageCode;

  /// The annotation for the message.
  ///
  /// Output only.
  GoogleCloudDialogflowV2beta1MessageAnnotation? messageAnnotation;

  /// The unique identifier of the message.
  ///
  /// Format: `projects//locations//conversations//messages/`.
  ///
  /// Optional.
  core.String? name;

  /// The participant that sends this message.
  ///
  /// Output only.
  core.String? participant;

  /// The role of the participant.
  ///
  /// Output only.
  /// Possible string values are:
  /// - "ROLE_UNSPECIFIED" : Participant role not set.
  /// - "HUMAN_AGENT" : Participant is a human agent.
  /// - "AUTOMATED_AGENT" : Participant is an automated agent, such as a
  /// Dialogflow agent.
  /// - "END_USER" : Participant is an end user that has called or chatted with
  /// Dialogflow services.
  core.String? participantRole;

  /// The time when the message was sent.
  ///
  /// Optional.
  core.String? sendTime;

  /// The sentiment analysis result for the message.
  ///
  /// Output only.
  GoogleCloudDialogflowV2beta1SentimentAnalysisResult? sentimentAnalysis;

  GoogleCloudDialogflowV2beta1Message();

  GoogleCloudDialogflowV2beta1Message.fromJson(core.Map _json) {
    if (_json.containsKey('content')) {
      content = _json['content'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('messageAnnotation')) {
      messageAnnotation =
          GoogleCloudDialogflowV2beta1MessageAnnotation.fromJson(
              _json['messageAnnotation']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('participant')) {
      participant = _json['participant'] as core.String;
    }
    if (_json.containsKey('participantRole')) {
      participantRole = _json['participantRole'] as core.String;
    }
    if (_json.containsKey('sendTime')) {
      sendTime = _json['sendTime'] as core.String;
    }
    if (_json.containsKey('sentimentAnalysis')) {
      sentimentAnalysis =
          GoogleCloudDialogflowV2beta1SentimentAnalysisResult.fromJson(
              _json['sentimentAnalysis']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (content != null) 'content': content!,
        if (createTime != null) 'createTime': createTime!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (messageAnnotation != null)
          'messageAnnotation': messageAnnotation!.toJson(),
        if (name != null) 'name': name!,
        if (participant != null) 'participant': participant!,
        if (participantRole != null) 'participantRole': participantRole!,
        if (sendTime != null) 'sendTime': sendTime!,
        if (sentimentAnalysis != null)
          'sentimentAnalysis': sentimentAnalysis!.toJson(),
      };
}

/// Represents the result of annotation for the message.
class GoogleCloudDialogflowV2beta1MessageAnnotation {
  /// Indicates whether the text message contains entities.
  ///
  /// Required.
  core.bool? containEntities;

  /// The collection of annotated message parts ordered by their position in the
  /// message.
  ///
  /// You can recover the annotated message by concatenating
  /// \[AnnotatedMessagePart.text\].
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1AnnotatedMessagePart>? parts;

  GoogleCloudDialogflowV2beta1MessageAnnotation();

  GoogleCloudDialogflowV2beta1MessageAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('containEntities')) {
      containEntities = _json['containEntities'] as core.bool;
    }
    if (_json.containsKey('parts')) {
      parts = (_json['parts'] as core.List)
          .map<GoogleCloudDialogflowV2beta1AnnotatedMessagePart>((value) =>
              GoogleCloudDialogflowV2beta1AnnotatedMessagePart.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (containEntities != null) 'containEntities': containEntities!,
        if (parts != null)
          'parts': parts!.map((value) => value.toJson()).toList(),
      };
}

/// Represents the contents of the original request that was passed to the
/// `[Streaming]DetectIntent` call.
class GoogleCloudDialogflowV2beta1OriginalDetectIntentRequest {
  /// This field is set to the value of the `QueryParameters.payload` field
  /// passed in the request.
  ///
  /// Some integrations that query a Dialogflow agent may provide additional
  /// information in the payload. In particular, for the Dialogflow Phone
  /// Gateway integration, this field has the form: { "telephony": {
  /// "caller_id": "+18558363987" } } Note: The caller ID field (`caller_id`)
  /// will be redacted for Trial Edition agents and populated with the caller ID
  /// in [E.164 format](https://en.wikipedia.org/wiki/E.164) for Essentials
  /// Edition agents.
  ///
  /// Optional.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? payload;

  /// The source of this request, e.g., `google`, `facebook`, `slack`.
  ///
  /// It is set by Dialogflow-owned servers.
  core.String? source;

  /// The version of the protocol used for this request.
  ///
  /// This field is AoG-specific.
  ///
  /// Optional.
  core.String? version;

  GoogleCloudDialogflowV2beta1OriginalDetectIntentRequest();

  GoogleCloudDialogflowV2beta1OriginalDetectIntentRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('payload')) {
      payload = (_json['payload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (payload != null) 'payload': payload!,
        if (source != null) 'source': source!,
        if (version != null) 'version': version!,
      };
}

/// Represents the result of conversational query or event processing.
class GoogleCloudDialogflowV2beta1QueryResult {
  /// The action name from the matched intent.
  core.String? action;

  /// This field is set to: - `false` if the matched intent has required
  /// parameters and not all of the required parameter values have been
  /// collected.
  ///
  /// - `true` if all required parameter values have been collected, or if the
  /// matched intent doesn't contain any required parameters.
  core.bool? allRequiredParamsPresent;

  /// Free-form diagnostic information for the associated detect intent request.
  ///
  /// The fields of this data can change without notice, so you should not write
  /// code that depends on its structure. The data may contain: - webhook call
  /// latency - webhook errors
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? diagnosticInfo;

  /// The collection of rich messages to present to the user.
  core.List<GoogleCloudDialogflowV2beta1IntentMessage>? fulfillmentMessages;

  /// The text to be pronounced to the user or shown on the screen.
  ///
  /// Note: This is a legacy field, `fulfillment_messages` should be preferred.
  core.String? fulfillmentText;

  /// The intent that matched the conversational query.
  ///
  /// Some, not all fields are filled in this message, including but not limited
  /// to: `name`, `display_name`, `end_interaction` and `is_fallback`.
  GoogleCloudDialogflowV2beta1Intent? intent;

  /// The intent detection confidence.
  ///
  /// Values range from 0.0 (completely uncertain) to 1.0 (completely certain).
  /// This value is for informational purpose only and is only used to help
  /// match the best intent within the classification threshold. This value may
  /// change for the same end-user expression at any time due to a model
  /// retraining or change in implementation. If there are `multiple
  /// knowledge_answers` messages, this value is set to the greatest
  /// `knowledgeAnswers.match_confidence` value in the list.
  core.double? intentDetectionConfidence;

  /// The result from Knowledge Connector (if any), ordered by decreasing
  /// `KnowledgeAnswers.match_confidence`.
  GoogleCloudDialogflowV2beta1KnowledgeAnswers? knowledgeAnswers;

  /// The language that was triggered during intent detection.
  ///
  /// See
  /// [Language Support](https://cloud.google.com/dialogflow/docs/reference/language)
  /// for a list of the currently supported language codes.
  core.String? languageCode;

  /// The collection of output contexts.
  ///
  /// If applicable, `output_contexts.parameters` contains entries with name
  /// `.original` containing the original parameter values before the query.
  core.List<GoogleCloudDialogflowV2beta1Context>? outputContexts;

  /// The collection of extracted parameters.
  ///
  /// Depending on your protocol or client library language, this is a map,
  /// associative array, symbol table, dictionary, or JSON object composed of a
  /// collection of (MapKey, MapValue) pairs: - MapKey type: string - MapKey
  /// value: parameter name - MapValue type: - If parameter's entity type is a
  /// composite entity: map - Else: depending on parameter value type, could be
  /// one of string, number, boolean, null, list or map - MapValue value: - If
  /// parameter's entity type is a composite entity: map from composite entity
  /// property names to property values - Else: parameter value
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? parameters;

  /// The original conversational query text: - If natural language text was
  /// provided as input, `query_text` contains a copy of the input.
  ///
  /// - If natural language speech audio was provided as input, `query_text`
  /// contains the speech recognition result. If speech recognizer produced
  /// multiple alternatives, a particular one is picked. - If automatic spell
  /// correction is enabled, `query_text` will contain the corrected user input.
  core.String? queryText;

  /// The sentiment analysis result, which depends on the
  /// `sentiment_analysis_request_config` specified in the request.
  GoogleCloudDialogflowV2beta1SentimentAnalysisResult? sentimentAnalysisResult;

  /// The Speech recognition confidence between 0.0 and 1.0.
  ///
  /// A higher number indicates an estimated greater likelihood that the
  /// recognized words are correct. The default of 0.0 is a sentinel value
  /// indicating that confidence was not set. This field is not guaranteed to be
  /// accurate or set. In particular this field isn't set for
  /// StreamingDetectIntent since the streaming endpoint has separate confidence
  /// estimates per portion of the audio in StreamingRecognitionResult.
  core.double? speechRecognitionConfidence;

  /// If the query was fulfilled by a webhook call, this field is set to the
  /// value of the `payload` field returned in the webhook response.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? webhookPayload;

  /// If the query was fulfilled by a webhook call, this field is set to the
  /// value of the `source` field returned in the webhook response.
  core.String? webhookSource;

  GoogleCloudDialogflowV2beta1QueryResult();

  GoogleCloudDialogflowV2beta1QueryResult.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('allRequiredParamsPresent')) {
      allRequiredParamsPresent = _json['allRequiredParamsPresent'] as core.bool;
    }
    if (_json.containsKey('diagnosticInfo')) {
      diagnosticInfo =
          (_json['diagnosticInfo'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('fulfillmentMessages')) {
      fulfillmentMessages = (_json['fulfillmentMessages'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessage>((value) =>
              GoogleCloudDialogflowV2beta1IntentMessage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('fulfillmentText')) {
      fulfillmentText = _json['fulfillmentText'] as core.String;
    }
    if (_json.containsKey('intent')) {
      intent = GoogleCloudDialogflowV2beta1Intent.fromJson(
          _json['intent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('intentDetectionConfidence')) {
      intentDetectionConfidence =
          (_json['intentDetectionConfidence'] as core.num).toDouble();
    }
    if (_json.containsKey('knowledgeAnswers')) {
      knowledgeAnswers = GoogleCloudDialogflowV2beta1KnowledgeAnswers.fromJson(
          _json['knowledgeAnswers'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('outputContexts')) {
      outputContexts = (_json['outputContexts'] as core.List)
          .map<GoogleCloudDialogflowV2beta1Context>((value) =>
              GoogleCloudDialogflowV2beta1Context.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('parameters')) {
      parameters =
          (_json['parameters'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('queryText')) {
      queryText = _json['queryText'] as core.String;
    }
    if (_json.containsKey('sentimentAnalysisResult')) {
      sentimentAnalysisResult =
          GoogleCloudDialogflowV2beta1SentimentAnalysisResult.fromJson(
              _json['sentimentAnalysisResult']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('speechRecognitionConfidence')) {
      speechRecognitionConfidence =
          (_json['speechRecognitionConfidence'] as core.num).toDouble();
    }
    if (_json.containsKey('webhookPayload')) {
      webhookPayload =
          (_json['webhookPayload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('webhookSource')) {
      webhookSource = _json['webhookSource'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (allRequiredParamsPresent != null)
          'allRequiredParamsPresent': allRequiredParamsPresent!,
        if (diagnosticInfo != null) 'diagnosticInfo': diagnosticInfo!,
        if (fulfillmentMessages != null)
          'fulfillmentMessages':
              fulfillmentMessages!.map((value) => value.toJson()).toList(),
        if (fulfillmentText != null) 'fulfillmentText': fulfillmentText!,
        if (intent != null) 'intent': intent!.toJson(),
        if (intentDetectionConfidence != null)
          'intentDetectionConfidence': intentDetectionConfidence!,
        if (knowledgeAnswers != null)
          'knowledgeAnswers': knowledgeAnswers!.toJson(),
        if (languageCode != null) 'languageCode': languageCode!,
        if (outputContexts != null)
          'outputContexts':
              outputContexts!.map((value) => value.toJson()).toList(),
        if (parameters != null) 'parameters': parameters!,
        if (queryText != null) 'queryText': queryText!,
        if (sentimentAnalysisResult != null)
          'sentimentAnalysisResult': sentimentAnalysisResult!.toJson(),
        if (speechRecognitionConfidence != null)
          'speechRecognitionConfidence': speechRecognitionConfidence!,
        if (webhookPayload != null) 'webhookPayload': webhookPayload!,
        if (webhookSource != null) 'webhookSource': webhookSource!,
      };
}

/// The sentiment, such as positive/negative feeling or association, for a unit
/// of analysis, such as the query text.
class GoogleCloudDialogflowV2beta1Sentiment {
  /// A non-negative number in the \[0, +inf) range, which represents the
  /// absolute magnitude of sentiment, regardless of score (positive or
  /// negative).
  core.double? magnitude;

  /// Sentiment score between -1.0 (negative sentiment) and 1.0 (positive
  /// sentiment).
  core.double? score;

  GoogleCloudDialogflowV2beta1Sentiment();

  GoogleCloudDialogflowV2beta1Sentiment.fromJson(core.Map _json) {
    if (_json.containsKey('magnitude')) {
      magnitude = (_json['magnitude'] as core.num).toDouble();
    }
    if (_json.containsKey('score')) {
      score = (_json['score'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (magnitude != null) 'magnitude': magnitude!,
        if (score != null) 'score': score!,
      };
}

/// The result of sentiment analysis.
///
/// Sentiment analysis inspects user input and identifies the prevailing
/// subjective opinion, especially to determine a user's attitude as positive,
/// negative, or neutral. For Participants.DetectIntent, it needs to be
/// configured in DetectIntentRequest.query_params. For
/// Participants.StreamingDetectIntent, it needs to be configured in
/// StreamingDetectIntentRequest.query_params. And for
/// Participants.AnalyzeContent and Participants.StreamingAnalyzeContent, it
/// needs to be configured in ConversationProfile.human_agent_assistant_config
class GoogleCloudDialogflowV2beta1SentimentAnalysisResult {
  /// The sentiment analysis result for `query_text`.
  GoogleCloudDialogflowV2beta1Sentiment? queryTextSentiment;

  GoogleCloudDialogflowV2beta1SentimentAnalysisResult();

  GoogleCloudDialogflowV2beta1SentimentAnalysisResult.fromJson(core.Map _json) {
    if (_json.containsKey('queryTextSentiment')) {
      queryTextSentiment = GoogleCloudDialogflowV2beta1Sentiment.fromJson(
          _json['queryTextSentiment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (queryTextSentiment != null)
          'queryTextSentiment': queryTextSentiment!.toJson(),
      };
}

/// A session represents a conversation between a Dialogflow agent and an
/// end-user.
///
/// You can create special entities, called session entities, during a session.
/// Session entities can extend or replace custom entity types and only exist
/// during the session that they were created for. All session data, including
/// session entities, is stored by Dialogflow for 20 minutes. For more
/// information, see the
/// [session entity guide](https://cloud.google.com/dialogflow/docs/entities-session).
class GoogleCloudDialogflowV2beta1SessionEntityType {
  /// The collection of entities associated with this session entity type.
  ///
  /// Required.
  core.List<GoogleCloudDialogflowV2beta1EntityTypeEntity>? entities;

  /// Indicates whether the additional data should override or supplement the
  /// custom entity type definition.
  ///
  /// Required.
  /// Possible string values are:
  /// - "ENTITY_OVERRIDE_MODE_UNSPECIFIED" : Not specified. This value should be
  /// never used.
  /// - "ENTITY_OVERRIDE_MODE_OVERRIDE" : The collection of session entities
  /// overrides the collection of entities in the corresponding custom entity
  /// type.
  /// - "ENTITY_OVERRIDE_MODE_SUPPLEMENT" : The collection of session entities
  /// extends the collection of entities in the corresponding custom entity
  /// type. Note: Even in this override mode calls to `ListSessionEntityTypes`,
  /// `GetSessionEntityType`, `CreateSessionEntityType` and
  /// `UpdateSessionEntityType` only return the additional entities added in
  /// this session entity type. If you want to get the supplemented list, please
  /// call EntityTypes.GetEntityType on the custom entity type and merge.
  core.String? entityOverrideMode;

  /// The unique identifier of this session entity type.
  ///
  /// Supported formats: - `projects//agent/sessions//entityTypes/` -
  /// `projects//locations//agent/sessions//entityTypes/` -
  /// `projects//agent/environments//users//sessions//entityTypes/` -
  /// `projects//locations//agent/environments/ /users//sessions//entityTypes/`
  /// If `Location ID` is not specified we assume default 'us' location. If
  /// `Environment ID` is not specified, we assume default 'draft' environment.
  /// If `User ID` is not specified, we assume default '-' user. `` must be the
  /// display name of an existing entity type in the same agent that will be
  /// overridden or supplemented.
  ///
  /// Required.
  core.String? name;

  GoogleCloudDialogflowV2beta1SessionEntityType();

  GoogleCloudDialogflowV2beta1SessionEntityType.fromJson(core.Map _json) {
    if (_json.containsKey('entities')) {
      entities = (_json['entities'] as core.List)
          .map<GoogleCloudDialogflowV2beta1EntityTypeEntity>((value) =>
              GoogleCloudDialogflowV2beta1EntityTypeEntity.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('entityOverrideMode')) {
      entityOverrideMode = _json['entityOverrideMode'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entities != null)
          'entities': entities!.map((value) => value.toJson()).toList(),
        if (entityOverrideMode != null)
          'entityOverrideMode': entityOverrideMode!,
        if (name != null) 'name': name!,
      };
}

/// Represents a smart reply answer.
class GoogleCloudDialogflowV2beta1SmartReplyAnswer {
  /// The name of answer record, in the format of
  /// "projects//locations//answerRecords/"
  core.String? answerRecord;

  /// Smart reply confidence.
  ///
  /// The system's confidence score that this reply is a good match for this
  /// conversation, as a value from 0.0 (completely uncertain) to 1.0
  /// (completely certain).
  core.double? confidence;

  /// The content of the reply.
  core.String? reply;

  GoogleCloudDialogflowV2beta1SmartReplyAnswer();

  GoogleCloudDialogflowV2beta1SmartReplyAnswer.fromJson(core.Map _json) {
    if (_json.containsKey('answerRecord')) {
      answerRecord = _json['answerRecord'] as core.String;
    }
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('reply')) {
      reply = _json['reply'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (answerRecord != null) 'answerRecord': answerRecord!,
        if (confidence != null) 'confidence': confidence!,
        if (reply != null) 'reply': reply!,
      };
}

/// The response message for Participants.SuggestArticles.
class GoogleCloudDialogflowV2beta1SuggestArticlesResponse {
  /// Articles ordered by score in descending order.
  ///
  /// Output only.
  core.List<GoogleCloudDialogflowV2beta1ArticleAnswer>? articleAnswers;

  /// Number of messages prior to and including latest_message to compile the
  /// suggestion.
  ///
  /// It may be smaller than the SuggestArticlesResponse.context_size field in
  /// the request if there aren't that many messages in the conversation.
  core.int? contextSize;

  /// The name of the latest conversation message used to compile suggestion
  /// for.
  ///
  /// Format: `projects//locations//conversations//messages/`.
  core.String? latestMessage;

  GoogleCloudDialogflowV2beta1SuggestArticlesResponse();

  GoogleCloudDialogflowV2beta1SuggestArticlesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('articleAnswers')) {
      articleAnswers = (_json['articleAnswers'] as core.List)
          .map<GoogleCloudDialogflowV2beta1ArticleAnswer>((value) =>
              GoogleCloudDialogflowV2beta1ArticleAnswer.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('contextSize')) {
      contextSize = _json['contextSize'] as core.int;
    }
    if (_json.containsKey('latestMessage')) {
      latestMessage = _json['latestMessage'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (articleAnswers != null)
          'articleAnswers':
              articleAnswers!.map((value) => value.toJson()).toList(),
        if (contextSize != null) 'contextSize': contextSize!,
        if (latestMessage != null) 'latestMessage': latestMessage!,
      };
}

/// The request message for Participants.SuggestFaqAnswers.
class GoogleCloudDialogflowV2beta1SuggestFaqAnswersResponse {
  /// Number of messages prior to and including latest_message to compile the
  /// suggestion.
  ///
  /// It may be smaller than the SuggestFaqAnswersRequest.context_size field in
  /// the request if there aren't that many messages in the conversation.
  core.int? contextSize;

  /// Answers extracted from FAQ documents.
  ///
  /// Output only.
  core.List<GoogleCloudDialogflowV2beta1FaqAnswer>? faqAnswers;

  /// The name of the latest conversation message used to compile suggestion
  /// for.
  ///
  /// Format: `projects//locations//conversations//messages/`.
  core.String? latestMessage;

  GoogleCloudDialogflowV2beta1SuggestFaqAnswersResponse();

  GoogleCloudDialogflowV2beta1SuggestFaqAnswersResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('contextSize')) {
      contextSize = _json['contextSize'] as core.int;
    }
    if (_json.containsKey('faqAnswers')) {
      faqAnswers = (_json['faqAnswers'] as core.List)
          .map<GoogleCloudDialogflowV2beta1FaqAnswer>((value) =>
              GoogleCloudDialogflowV2beta1FaqAnswer.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('latestMessage')) {
      latestMessage = _json['latestMessage'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contextSize != null) 'contextSize': contextSize!,
        if (faqAnswers != null)
          'faqAnswers': faqAnswers!.map((value) => value.toJson()).toList(),
        if (latestMessage != null) 'latestMessage': latestMessage!,
      };
}

/// The response message for Participants.SuggestSmartReplies.
class GoogleCloudDialogflowV2beta1SuggestSmartRepliesResponse {
  /// Number of messages prior to and including latest_message to compile the
  /// suggestion.
  ///
  /// It may be smaller than the SuggestSmartRepliesRequest.context_size field
  /// in the request if there aren't that many messages in the conversation.
  core.int? contextSize;

  /// The name of the latest conversation message used to compile suggestion
  /// for.
  ///
  /// Format: `projects//locations//conversations//messages/`.
  core.String? latestMessage;

  /// Multiple reply options provided by smart reply service.
  ///
  /// The order is based on the rank of the model prediction. The maximum number
  /// of the returned replies is set in SmartReplyConfig.
  ///
  /// Output only.
  core.List<GoogleCloudDialogflowV2beta1SmartReplyAnswer>? smartReplyAnswers;

  GoogleCloudDialogflowV2beta1SuggestSmartRepliesResponse();

  GoogleCloudDialogflowV2beta1SuggestSmartRepliesResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('contextSize')) {
      contextSize = _json['contextSize'] as core.int;
    }
    if (_json.containsKey('latestMessage')) {
      latestMessage = _json['latestMessage'] as core.String;
    }
    if (_json.containsKey('smartReplyAnswers')) {
      smartReplyAnswers = (_json['smartReplyAnswers'] as core.List)
          .map<GoogleCloudDialogflowV2beta1SmartReplyAnswer>((value) =>
              GoogleCloudDialogflowV2beta1SmartReplyAnswer.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contextSize != null) 'contextSize': contextSize!,
        if (latestMessage != null) 'latestMessage': latestMessage!,
        if (smartReplyAnswers != null)
          'smartReplyAnswers':
              smartReplyAnswers!.map((value) => value.toJson()).toList(),
      };
}

/// One response of different type of suggestion response which is used in the
/// response of Participants.AnalyzeContent and Participants.AnalyzeContent, as
/// well as HumanAgentAssistantEvent.
class GoogleCloudDialogflowV2beta1SuggestionResult {
  /// Error status if the request failed.
  GoogleRpcStatus? error;

  /// SuggestArticlesResponse if request is for ARTICLE_SUGGESTION.
  GoogleCloudDialogflowV2beta1SuggestArticlesResponse? suggestArticlesResponse;

  /// SuggestFaqAnswersResponse if request is for FAQ_ANSWER.
  GoogleCloudDialogflowV2beta1SuggestFaqAnswersResponse?
      suggestFaqAnswersResponse;

  /// SuggestSmartRepliesResponse if request is for SMART_REPLY.
  GoogleCloudDialogflowV2beta1SuggestSmartRepliesResponse?
      suggestSmartRepliesResponse;

  GoogleCloudDialogflowV2beta1SuggestionResult();

  GoogleCloudDialogflowV2beta1SuggestionResult.fromJson(core.Map _json) {
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('suggestArticlesResponse')) {
      suggestArticlesResponse =
          GoogleCloudDialogflowV2beta1SuggestArticlesResponse.fromJson(
              _json['suggestArticlesResponse']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('suggestFaqAnswersResponse')) {
      suggestFaqAnswersResponse =
          GoogleCloudDialogflowV2beta1SuggestFaqAnswersResponse.fromJson(
              _json['suggestFaqAnswersResponse']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('suggestSmartRepliesResponse')) {
      suggestSmartRepliesResponse =
          GoogleCloudDialogflowV2beta1SuggestSmartRepliesResponse.fromJson(
              _json['suggestSmartRepliesResponse']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (error != null) 'error': error!.toJson(),
        if (suggestArticlesResponse != null)
          'suggestArticlesResponse': suggestArticlesResponse!.toJson(),
        if (suggestFaqAnswersResponse != null)
          'suggestFaqAnswersResponse': suggestFaqAnswersResponse!.toJson(),
        if (suggestSmartRepliesResponse != null)
          'suggestSmartRepliesResponse': suggestSmartRepliesResponse!.toJson(),
      };
}

/// The request message for a webhook call.
class GoogleCloudDialogflowV2beta1WebhookRequest {
  /// Alternative query results from KnowledgeService.
  core.List<GoogleCloudDialogflowV2beta1QueryResult>? alternativeQueryResults;

  /// The contents of the original request that was passed to
  /// `[Streaming]DetectIntent` call.
  ///
  /// Optional.
  GoogleCloudDialogflowV2beta1OriginalDetectIntentRequest?
      originalDetectIntentRequest;

  /// The result of the conversational query or event processing.
  ///
  /// Contains the same value as `[Streaming]DetectIntentResponse.query_result`.
  GoogleCloudDialogflowV2beta1QueryResult? queryResult;

  /// The unique identifier of the response.
  ///
  /// Contains the same value as `[Streaming]DetectIntentResponse.response_id`.
  core.String? responseId;

  /// The unique identifier of detectIntent request session.
  ///
  /// Can be used to identify end-user inside webhook implementation. Supported
  /// formats: - \`projects//agent/sessions/, -
  /// \`projects//locations//agent/sessions/\`, -
  /// \`projects//agent/environments//users//sessions/\`, -
  /// \`projects//locations//agent/environments//users//sessions/\`,
  core.String? session;

  GoogleCloudDialogflowV2beta1WebhookRequest();

  GoogleCloudDialogflowV2beta1WebhookRequest.fromJson(core.Map _json) {
    if (_json.containsKey('alternativeQueryResults')) {
      alternativeQueryResults = (_json['alternativeQueryResults'] as core.List)
          .map<GoogleCloudDialogflowV2beta1QueryResult>((value) =>
              GoogleCloudDialogflowV2beta1QueryResult.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('originalDetectIntentRequest')) {
      originalDetectIntentRequest =
          GoogleCloudDialogflowV2beta1OriginalDetectIntentRequest.fromJson(
              _json['originalDetectIntentRequest']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('queryResult')) {
      queryResult = GoogleCloudDialogflowV2beta1QueryResult.fromJson(
          _json['queryResult'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('responseId')) {
      responseId = _json['responseId'] as core.String;
    }
    if (_json.containsKey('session')) {
      session = _json['session'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alternativeQueryResults != null)
          'alternativeQueryResults':
              alternativeQueryResults!.map((value) => value.toJson()).toList(),
        if (originalDetectIntentRequest != null)
          'originalDetectIntentRequest': originalDetectIntentRequest!.toJson(),
        if (queryResult != null) 'queryResult': queryResult!.toJson(),
        if (responseId != null) 'responseId': responseId!,
        if (session != null) 'session': session!,
      };
}

/// The response message for a webhook call.
///
/// This response is validated by the Dialogflow server. If validation fails, an
/// error will be returned in the QueryResult.diagnostic_info field. Setting
/// JSON fields to an empty value with the wrong type is a common error. To
/// avoid this error: - Use `""` for empty strings - Use `{}` or `null` for
/// empty objects - Use `[]` or `null` for empty arrays For more information,
/// see the
/// [Protocol Buffers Language Guide](https://developers.google.com/protocol-buffers/docs/proto3#json).
class GoogleCloudDialogflowV2beta1WebhookResponse {
  /// Indicates that this intent ends an interaction.
  ///
  /// Some integrations (e.g., Actions on Google or Dialogflow phone gateway)
  /// use this information to close interaction with an end user. Default is
  /// false.
  ///
  /// Optional.
  core.bool? endInteraction;

  /// Invokes the supplied events.
  ///
  /// When this field is set, Dialogflow ignores the `fulfillment_text`,
  /// `fulfillment_messages`, and `payload` fields.
  ///
  /// Optional.
  GoogleCloudDialogflowV2beta1EventInput? followupEventInput;

  /// The rich response messages intended for the end-user.
  ///
  /// When provided, Dialogflow uses this field to populate
  /// QueryResult.fulfillment_messages sent to the integration or API caller.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1IntentMessage>? fulfillmentMessages;

  /// The text response message intended for the end-user.
  ///
  /// It is recommended to use `fulfillment_messages.text.text[0]` instead. When
  /// provided, Dialogflow uses this field to populate
  /// QueryResult.fulfillment_text sent to the integration or API caller.
  ///
  /// Optional.
  core.String? fulfillmentText;

  /// Indicates that a live agent should be brought in to handle the interaction
  /// with the user.
  ///
  /// In most cases, when you set this flag to true, you would also want to set
  /// end_interaction to true as well. Default is false.
  core.bool? liveAgentHandoff;

  /// The collection of output contexts that will overwrite currently active
  /// contexts for the session and reset their lifespans.
  ///
  /// When provided, Dialogflow uses this field to populate
  /// QueryResult.output_contexts sent to the integration or API caller.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1Context>? outputContexts;

  /// This field can be used to pass custom data from your webhook to the
  /// integration or API caller.
  ///
  /// Arbitrary JSON objects are supported. When provided, Dialogflow uses this
  /// field to populate QueryResult.webhook_payload sent to the integration or
  /// API caller. This field is also used by the
  /// [Google Assistant integration](https://cloud.google.com/dialogflow/docs/integrations/aog)
  /// for rich response messages. See the format definition at
  /// [Google Assistant Dialogflow webhook format](https://developers.google.com/assistant/actions/build/json/dialogflow-webhook-json)
  ///
  /// Optional.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? payload;

  /// Additional session entity types to replace or extend developer entity
  /// types with.
  ///
  /// The entity synonyms apply to all languages and persist for the session.
  /// Setting this data from a webhook overwrites the session entity types that
  /// have been set using `detectIntent`, `streamingDetectIntent` or
  /// SessionEntityType management methods.
  ///
  /// Optional.
  core.List<GoogleCloudDialogflowV2beta1SessionEntityType>? sessionEntityTypes;

  /// A custom field used to identify the webhook source.
  ///
  /// Arbitrary strings are supported. When provided, Dialogflow uses this field
  /// to populate QueryResult.webhook_source sent to the integration or API
  /// caller.
  ///
  /// Optional.
  core.String? source;

  GoogleCloudDialogflowV2beta1WebhookResponse();

  GoogleCloudDialogflowV2beta1WebhookResponse.fromJson(core.Map _json) {
    if (_json.containsKey('endInteraction')) {
      endInteraction = _json['endInteraction'] as core.bool;
    }
    if (_json.containsKey('followupEventInput')) {
      followupEventInput = GoogleCloudDialogflowV2beta1EventInput.fromJson(
          _json['followupEventInput'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fulfillmentMessages')) {
      fulfillmentMessages = (_json['fulfillmentMessages'] as core.List)
          .map<GoogleCloudDialogflowV2beta1IntentMessage>((value) =>
              GoogleCloudDialogflowV2beta1IntentMessage.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('fulfillmentText')) {
      fulfillmentText = _json['fulfillmentText'] as core.String;
    }
    if (_json.containsKey('liveAgentHandoff')) {
      liveAgentHandoff = _json['liveAgentHandoff'] as core.bool;
    }
    if (_json.containsKey('outputContexts')) {
      outputContexts = (_json['outputContexts'] as core.List)
          .map<GoogleCloudDialogflowV2beta1Context>((value) =>
              GoogleCloudDialogflowV2beta1Context.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('payload')) {
      payload = (_json['payload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('sessionEntityTypes')) {
      sessionEntityTypes = (_json['sessionEntityTypes'] as core.List)
          .map<GoogleCloudDialogflowV2beta1SessionEntityType>((value) =>
              GoogleCloudDialogflowV2beta1SessionEntityType.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('source')) {
      source = _json['source'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endInteraction != null) 'endInteraction': endInteraction!,
        if (followupEventInput != null)
          'followupEventInput': followupEventInput!.toJson(),
        if (fulfillmentMessages != null)
          'fulfillmentMessages':
              fulfillmentMessages!.map((value) => value.toJson()).toList(),
        if (fulfillmentText != null) 'fulfillmentText': fulfillmentText!,
        if (liveAgentHandoff != null) 'liveAgentHandoff': liveAgentHandoff!,
        if (outputContexts != null)
          'outputContexts':
              outputContexts!.map((value) => value.toJson()).toList(),
        if (payload != null) 'payload': payload!,
        if (sessionEntityTypes != null)
          'sessionEntityTypes':
              sessionEntityTypes!.map((value) => value.toJson()).toList(),
        if (source != null) 'source': source!,
      };
}

/// Metadata for CreateDocument operation.
class GoogleCloudDialogflowV3alpha1CreateDocumentOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowV3alpha1GenericKnowledgeOperationMetadata?
      genericMetadata;

  GoogleCloudDialogflowV3alpha1CreateDocumentOperationMetadata();

  GoogleCloudDialogflowV3alpha1CreateDocumentOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowV3alpha1GenericKnowledgeOperationMetadata
              .fromJson(_json['genericMetadata']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// Metadata for DeleteDocument operation.
class GoogleCloudDialogflowV3alpha1DeleteDocumentOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowV3alpha1GenericKnowledgeOperationMetadata?
      genericMetadata;

  GoogleCloudDialogflowV3alpha1DeleteDocumentOperationMetadata();

  GoogleCloudDialogflowV3alpha1DeleteDocumentOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowV3alpha1GenericKnowledgeOperationMetadata
              .fromJson(_json['genericMetadata']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// Metadata in google::longrunning::Operation for Knowledge operations.
class GoogleCloudDialogflowV3alpha1GenericKnowledgeOperationMetadata {
  /// The current state of this operation.
  ///
  /// Required. Output only.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : State unspecified.
  /// - "PENDING" : The operation has been created.
  /// - "RUNNING" : The operation is currently running.
  /// - "DONE" : The operation is done, either cancelled or completed.
  core.String? state;

  GoogleCloudDialogflowV3alpha1GenericKnowledgeOperationMetadata();

  GoogleCloudDialogflowV3alpha1GenericKnowledgeOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (state != null) 'state': state!,
      };
}

/// Metadata for ImportDocuments operation.
class GoogleCloudDialogflowV3alpha1ImportDocumentsOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowV3alpha1GenericKnowledgeOperationMetadata?
      genericMetadata;

  GoogleCloudDialogflowV3alpha1ImportDocumentsOperationMetadata();

  GoogleCloudDialogflowV3alpha1ImportDocumentsOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowV3alpha1GenericKnowledgeOperationMetadata
              .fromJson(_json['genericMetadata']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// Response message for Documents.ImportDocuments.
class GoogleCloudDialogflowV3alpha1ImportDocumentsResponse {
  /// Includes details about skipped documents or any other warnings.
  core.List<GoogleRpcStatus>? warnings;

  GoogleCloudDialogflowV3alpha1ImportDocumentsResponse();

  GoogleCloudDialogflowV3alpha1ImportDocumentsResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('warnings')) {
      warnings = (_json['warnings'] as core.List)
          .map<GoogleRpcStatus>((value) => GoogleRpcStatus.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (warnings != null)
          'warnings': warnings!.map((value) => value.toJson()).toList(),
      };
}

/// Metadata for ReloadDocument operation.
class GoogleCloudDialogflowV3alpha1ReloadDocumentOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowV3alpha1GenericKnowledgeOperationMetadata?
      genericMetadata;

  GoogleCloudDialogflowV3alpha1ReloadDocumentOperationMetadata();

  GoogleCloudDialogflowV3alpha1ReloadDocumentOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowV3alpha1GenericKnowledgeOperationMetadata
              .fromJson(_json['genericMetadata']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// Metadata for UpdateDocument operation.
class GoogleCloudDialogflowV3alpha1UpdateDocumentOperationMetadata {
  /// The generic information of the operation.
  GoogleCloudDialogflowV3alpha1GenericKnowledgeOperationMetadata?
      genericMetadata;

  GoogleCloudDialogflowV3alpha1UpdateDocumentOperationMetadata();

  GoogleCloudDialogflowV3alpha1UpdateDocumentOperationMetadata.fromJson(
      core.Map _json) {
    if (_json.containsKey('genericMetadata')) {
      genericMetadata =
          GoogleCloudDialogflowV3alpha1GenericKnowledgeOperationMetadata
              .fromJson(_json['genericMetadata']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (genericMetadata != null)
          'genericMetadata': genericMetadata!.toJson(),
      };
}

/// The response message for Operations.ListOperations.
class GoogleLongrunningListOperationsResponse {
  /// The standard List next-page token.
  core.String? nextPageToken;

  /// A list of operations that matches the specified filter in the request.
  core.List<GoogleLongrunningOperation>? operations;

  GoogleLongrunningListOperationsResponse();

  GoogleLongrunningListOperationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<GoogleLongrunningOperation>((value) =>
              GoogleLongrunningOperation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
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
class GoogleLongrunningOperation {
  /// If the value is `false`, it means the operation is still in progress.
  ///
  /// If `true`, the operation is completed, and either `error` or `response` is
  /// available.
  core.bool? done;

  /// The error result of the operation in case of failure or cancellation.
  GoogleRpcStatus? error;

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

  GoogleLongrunningOperation();

  GoogleLongrunningOperation.fromJson(core.Map _json) {
    if (_json.containsKey('done')) {
      done = _json['done'] as core.bool;
    }
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
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

/// A generic empty message that you can re-use to avoid defining duplicated
/// empty messages in your APIs.
///
/// A typical example is to use it as the request or the response type of an API
/// method. For instance: service Foo { rpc Bar(google.protobuf.Empty) returns
/// (google.protobuf.Empty); } The JSON representation for `Empty` is empty JSON
/// object `{}`.
class GoogleProtobufEmpty {
  GoogleProtobufEmpty();

  GoogleProtobufEmpty.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs.
///
/// It is used by [gRPC](https://github.com/grpc). Each `Status` message
/// contains three pieces of data: error code, error message, and error details.
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
class GoogleRpcStatus {
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

  GoogleRpcStatus();

  GoogleRpcStatus.fromJson(core.Map _json) {
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

/// An object that represents a latitude/longitude pair.
///
/// This is expressed as a pair of doubles to represent degrees latitude and
/// degrees longitude. Unless specified otherwise, this object must conform to
/// the WGS84 standard. Values must be within normalized ranges.
class GoogleTypeLatLng {
  /// The latitude in degrees.
  ///
  /// It must be in the range \[-90.0, +90.0\].
  core.double? latitude;

  /// The longitude in degrees.
  ///
  /// It must be in the range \[-180.0, +180.0\].
  core.double? longitude;

  GoogleTypeLatLng();

  GoogleTypeLatLng.fromJson(core.Map _json) {
    if (_json.containsKey('latitude')) {
      latitude = (_json['latitude'] as core.num).toDouble();
    }
    if (_json.containsKey('longitude')) {
      longitude = (_json['longitude'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (latitude != null) 'latitude': latitude!,
        if (longitude != null) 'longitude': longitude!,
      };
}
