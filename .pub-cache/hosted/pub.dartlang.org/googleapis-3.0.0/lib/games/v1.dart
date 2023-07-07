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

/// Google Play Game Services - v1
///
/// The Google Play games service allows developers to enhance games with social
/// leaderboards, achievements, game state, sign-in with Google, and more.
///
/// For more information, see <https://developers.google.com/games/>
///
/// Create an instance of [GamesApi] to access these resources:
///
/// - [AchievementDefinitionsResource]
/// - [AchievementsResource]
/// - [ApplicationsResource]
/// - [EventsResource]
/// - [LeaderboardsResource]
/// - [MetagameResource]
/// - [PlayersResource]
/// - [RevisionsResource]
/// - [ScoresResource]
/// - [SnapshotsResource]
/// - [StatsResource]
library games.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// The Google Play games service allows developers to enhance games with social
/// leaderboards, achievements, game state, sign-in with Google, and more.
class GamesApi {
  /// See, create, and delete its own configuration data in your Google Drive
  static const driveAppdataScope =
      'https://www.googleapis.com/auth/drive.appdata';

  /// Create, edit, and delete your Google Play Games activity
  static const gamesScope = 'https://www.googleapis.com/auth/games';

  final commons.ApiRequester _requester;

  AchievementDefinitionsResource get achievementDefinitions =>
      AchievementDefinitionsResource(_requester);
  AchievementsResource get achievements => AchievementsResource(_requester);
  ApplicationsResource get applications => ApplicationsResource(_requester);
  EventsResource get events => EventsResource(_requester);
  LeaderboardsResource get leaderboards => LeaderboardsResource(_requester);
  MetagameResource get metagame => MetagameResource(_requester);
  PlayersResource get players => PlayersResource(_requester);
  RevisionsResource get revisions => RevisionsResource(_requester);
  ScoresResource get scores => ScoresResource(_requester);
  SnapshotsResource get snapshots => SnapshotsResource(_requester);
  StatsResource get stats => StatsResource(_requester);

  GamesApi(http.Client client,
      {core.String rootUrl = 'https://games.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AchievementDefinitionsResource {
  final commons.ApiRequester _requester;

  AchievementDefinitionsResource(commons.ApiRequester client)
      : _requester = client;

  /// Lists all the achievement definitions for your application.
  ///
  /// Request parameters:
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [maxResults] - The maximum number of achievement resources to return in
  /// the response, used for paging. For any response, the actual number of
  /// achievement resources returned may be less than the specified
  /// `maxResults`.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AchievementDefinitionsListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AchievementDefinitionsListResponse> list({
    core.String? language,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'games/v1/achievements';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AchievementDefinitionsListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AchievementsResource {
  final commons.ApiRequester _requester;

  AchievementsResource(commons.ApiRequester client) : _requester = client;

  /// Increments the steps of the achievement with the given ID for the
  /// currently authenticated player.
  ///
  /// Request parameters:
  ///
  /// [achievementId] - The ID of the achievement used by this method.
  ///
  /// [stepsToIncrement] - The number of steps to increment.
  ///
  /// [requestId] - A randomly generated numeric ID for each request specified
  /// by the caller. This number is used at the server to ensure that the
  /// request is handled correctly across retries.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AchievementIncrementResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AchievementIncrementResponse> increment(
    core.String achievementId,
    core.int stepsToIncrement, {
    core.String? requestId,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'stepsToIncrement': ['${stepsToIncrement}'],
      if (requestId != null) 'requestId': [requestId],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1/achievements/' +
        commons.escapeVariable('$achievementId') +
        '/increment';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return AchievementIncrementResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the progress for all your application's achievements for the
  /// currently authenticated player.
  ///
  /// Request parameters:
  ///
  /// [playerId] - A player ID. A value of `me` may be used in place of the
  /// authenticated player's ID.
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [maxResults] - The maximum number of achievement resources to return in
  /// the response, used for paging. For any response, the actual number of
  /// achievement resources returned may be less than the specified
  /// `maxResults`.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [state] - Tells the server to return only achievements with the specified
  /// state. If this parameter isn't specified, all achievements are returned.
  /// Possible string values are:
  /// - "ALL" : List all achievements. This is the default.
  /// - "HIDDEN" : List only hidden achievements.
  /// - "REVEALED" : List only revealed achievements.
  /// - "UNLOCKED" : List only unlocked achievements.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlayerAchievementListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlayerAchievementListResponse> list(
    core.String playerId, {
    core.String? language,
    core.int? maxResults,
    core.String? pageToken,
    core.String? state,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (state != null) 'state': [state],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1/players/' +
        commons.escapeVariable('$playerId') +
        '/achievements';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PlayerAchievementListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the state of the achievement with the given ID to `REVEALED` for the
  /// currently authenticated player.
  ///
  /// Request parameters:
  ///
  /// [achievementId] - The ID of the achievement used by this method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AchievementRevealResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AchievementRevealResponse> reveal(
    core.String achievementId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1/achievements/' +
        commons.escapeVariable('$achievementId') +
        '/reveal';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return AchievementRevealResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Sets the steps for the currently authenticated player towards unlocking an
  /// achievement.
  ///
  /// If the steps parameter is less than the current number of steps that the
  /// player already gained for the achievement, the achievement is not
  /// modified.
  ///
  /// Request parameters:
  ///
  /// [achievementId] - The ID of the achievement used by this method.
  ///
  /// [steps] - The minimum value to set the steps to.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AchievementSetStepsAtLeastResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AchievementSetStepsAtLeastResponse> setStepsAtLeast(
    core.String achievementId,
    core.int steps, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'steps': ['${steps}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1/achievements/' +
        commons.escapeVariable('$achievementId') +
        '/setStepsAtLeast';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return AchievementSetStepsAtLeastResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Unlocks this achievement for the currently authenticated player.
  ///
  /// Request parameters:
  ///
  /// [achievementId] - The ID of the achievement used by this method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AchievementUnlockResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AchievementUnlockResponse> unlock(
    core.String achievementId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1/achievements/' +
        commons.escapeVariable('$achievementId') +
        '/unlock';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return AchievementUnlockResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates multiple achievements for the currently authenticated player.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AchievementUpdateMultipleResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AchievementUpdateMultipleResponse> updateMultiple(
    AchievementUpdateMultipleRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'games/v1/achievements/updateMultiple';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AchievementUpdateMultipleResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ApplicationsResource {
  final commons.ApiRequester _requester;

  ApplicationsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves the metadata of the application with the given ID.
  ///
  /// If the requested application is not available for the specified
  /// `platformType`, the returned response will not include any instance data.
  ///
  /// Request parameters:
  ///
  /// [applicationId] - The application ID from the Google Play developer
  /// console.
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [platformType] - Restrict application details returned to the specific
  /// platform.
  /// Possible string values are:
  /// - "PLATFORM_TYPE_UNSPECIFIED" : Default value, don't use.
  /// - "ANDROID" : Retrieve applications that can be played on Android.
  /// - "IOS" : Retrieve applications that can be played on iOS.
  /// - "WEB_APP" : Retrieve applications that can be played on desktop web.
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
    core.String? language,
    core.String? platformType,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if (platformType != null) 'platformType': [platformType],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'games/v1/applications/' + commons.escapeVariable('$applicationId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Application.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns a URL for the requested end point type.
  ///
  /// Request parameters:
  ///
  /// [applicationId] - The application ID from the Google Play developer
  /// console.
  ///
  /// [endPointType] - Type of endpoint being requested.
  /// Possible string values are:
  /// - "END_POINT_TYPE_UNSPECIFIED" : Default value. This value is unused.
  /// - "PROFILE_CREATION" : Request a URL to create a new profile.
  /// - "PROFILE_SETTINGS" : Request a URL for the Settings view.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EndPoint].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EndPoint> getEndPoint({
    core.String? applicationId,
    core.String? endPointType,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (applicationId != null) 'applicationId': [applicationId],
      if (endPointType != null) 'endPointType': [endPointType],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'games/v1/applications/getEndPoint';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return EndPoint.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Indicate that the currently authenticated user is playing your
  /// application.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<void> played({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'games/v1/applications/played';

    await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Verifies the auth token provided with this request is for the application
  /// with the specified ID, and returns the ID of the player it was granted
  /// for.
  ///
  /// Request parameters:
  ///
  /// [applicationId] - The application ID from the Google Play developer
  /// console.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ApplicationVerifyResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ApplicationVerifyResponse> verify(
    core.String applicationId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1/applications/' +
        commons.escapeVariable('$applicationId') +
        '/verify';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ApplicationVerifyResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class EventsResource {
  final commons.ApiRequester _requester;

  EventsResource(commons.ApiRequester client) : _requester = client;

  /// Returns a list showing the current progress on events in this application
  /// for the currently authenticated user.
  ///
  /// Request parameters:
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [maxResults] - The maximum number of events to return in the response,
  /// used for paging. For any response, the actual number of events to return
  /// may be less than the specified maxResults.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlayerEventListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlayerEventListResponse> listByPlayer({
    core.String? language,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'games/v1/events';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PlayerEventListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns a list of the event definitions in this application.
  ///
  /// Request parameters:
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [maxResults] - The maximum number of event definitions to return in the
  /// response, used for paging. For any response, the actual number of event
  /// definitions to return may be less than the specified `maxResults`.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EventDefinitionListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EventDefinitionListResponse> listDefinitions({
    core.String? language,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'games/v1/eventDefinitions';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return EventDefinitionListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Records a batch of changes to the number of times events have occurred for
  /// the currently authenticated user of this application.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [EventUpdateResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<EventUpdateResponse> record(
    EventRecordRequest request, {
    core.String? language,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'games/v1/events';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return EventUpdateResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class LeaderboardsResource {
  final commons.ApiRequester _requester;

  LeaderboardsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves the metadata of the leaderboard with the given ID.
  ///
  /// Request parameters:
  ///
  /// [leaderboardId] - The ID of the leaderboard.
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Leaderboard].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Leaderboard> get(
    core.String leaderboardId, {
    core.String? language,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'games/v1/leaderboards/' + commons.escapeVariable('$leaderboardId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Leaderboard.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists all the leaderboard metadata for your application.
  ///
  /// Request parameters:
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [maxResults] - The maximum number of leaderboards to return in the
  /// response. For any response, the actual number of leaderboards returned may
  /// be less than the specified `maxResults`.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LeaderboardListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LeaderboardListResponse> list({
    core.String? language,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'games/v1/leaderboards';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LeaderboardListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MetagameResource {
  final commons.ApiRequester _requester;

  MetagameResource(commons.ApiRequester client) : _requester = client;

  /// Return the metagame configuration data for the calling application.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [MetagameConfig].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<MetagameConfig> getMetagameConfig({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'games/v1/metagameConfig';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return MetagameConfig.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// List play data aggregated per category for the player corresponding to
  /// `playerId`.
  ///
  /// Request parameters:
  ///
  /// [playerId] - A player ID. A value of `me` may be used in place of the
  /// authenticated player's ID.
  ///
  /// [collection] - The collection of categories for which data will be
  /// returned.
  /// Possible string values are:
  /// - "COLLECTION_UNSPECIFIED" : Default value. This value is unused.
  /// - "ALL" : Retrieve data for all categories. This is the default.
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [maxResults] - The maximum number of category resources to return in the
  /// response, used for paging. For any response, the actual number of category
  /// resources returned may be less than the specified `maxResults`.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CategoryListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CategoryListResponse> listCategoriesByPlayer(
    core.String playerId,
    core.String collection, {
    core.String? language,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1/players/' +
        commons.escapeVariable('$playerId') +
        '/categories/' +
        commons.escapeVariable('$collection');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return CategoryListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class PlayersResource {
  final commons.ApiRequester _requester;

  PlayersResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves the Player resource with the given ID.
  ///
  /// To retrieve the player for the currently authenticated user, set
  /// `playerId` to `me`.
  ///
  /// Request parameters:
  ///
  /// [playerId] - A player ID. A value of `me` may be used in place of the
  /// authenticated player's ID.
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Player].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Player> get(
    core.String playerId, {
    core.String? language,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1/players/' + commons.escapeVariable('$playerId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Player.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Get the collection of players for the currently authenticated user.
  ///
  /// Request parameters:
  ///
  /// [collection] - Collection of players being retrieved
  /// Possible string values are:
  /// - "CONNECTED" : Retrieve a list of players that are also playing this game
  /// in reverse chronological order.
  /// - "VISIBLE" : Retrieve a list of players in the user's social graph that
  /// are visible to this game.
  /// - "FRIENDS_ALL" : Retrieve a list of players who are friends of the user
  /// in alphabetical order.
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [maxResults] - The maximum number of player resources to return in the
  /// response, used for paging. For any response, the actual number of player
  /// resources returned may be less than the specified `maxResults`.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlayerListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlayerListResponse> list(
    core.String collection, {
    core.String? language,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'games/v1/players/me/players/' + commons.escapeVariable('$collection');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PlayerListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class RevisionsResource {
  final commons.ApiRequester _requester;

  RevisionsResource(commons.ApiRequester client) : _requester = client;

  /// Checks whether the games client is out of date.
  ///
  /// Request parameters:
  ///
  /// [clientRevision] - The revision of the client SDK used by your
  /// application. Format: `[PLATFORM_TYPE]:[VERSION_NUMBER]`. Possible values
  /// of `PLATFORM_TYPE` are: * `ANDROID` - Client is running the Android SDK. *
  /// `IOS` - Client is running the iOS SDK. * `WEB_APP` - Client is running as
  /// a Web App.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [RevisionCheckResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<RevisionCheckResponse> check(
    core.String clientRevision, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'clientRevision': [clientRevision],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'games/v1/revisions/check';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return RevisionCheckResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ScoresResource {
  final commons.ApiRequester _requester;

  ScoresResource(commons.ApiRequester client) : _requester = client;

  /// Get high scores, and optionally ranks, in leaderboards for the currently
  /// authenticated player.
  ///
  /// For a specific time span, \`leaderboardId\` can be set to \`ALL\` to
  /// retrieve data for all leaderboards in a given time span. \`NOTE: You
  /// cannot ask for 'ALL' leaderboards and 'ALL' timeSpans in the same request;
  /// only one parameter may be set to 'ALL'.
  ///
  /// Request parameters:
  ///
  /// [playerId] - A player ID. A value of `me` may be used in place of the
  /// authenticated player's ID.
  ///
  /// [leaderboardId] - The ID of the leaderboard. Can be set to 'ALL' to
  /// retrieve data for all leaderboards for this application.
  ///
  /// [timeSpan] - The time span for the scores and ranks you're requesting.
  /// Possible string values are:
  /// - "SCORE_TIME_SPAN_UNSPECIFIED" : Default value. This value is unused.
  /// - "ALL" : Get the high scores for all time spans. If this is used,
  /// maxResults values will be ignored.
  /// - "ALL_TIME" : Get the all time high score.
  /// - "WEEKLY" : List the top scores for the current day.
  /// - "DAILY" : List the top scores for the current week.
  ///
  /// [includeRankType] - The types of ranks to return. If the parameter is
  /// omitted, no ranks will be returned.
  /// Possible string values are:
  /// - "INCLUDE_RANK_TYPE_UNSPECIFIED" : Default value. Should be unused.
  /// - "ALL" : Retrieve all supported ranks. In HTTP, this parameter value can
  /// also be specified as `ALL`.
  /// - "PUBLIC" : Retrieve public ranks, if the player is sharing their
  /// gameplay activity publicly.
  /// - "SOCIAL" : (Obsolete) Retrieve the social rank.
  /// - "FRIENDS" : Retrieve the rank on the friends collection.
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [maxResults] - The maximum number of leaderboard scores to return in the
  /// response. For any response, the actual number of leaderboard scores
  /// returned may be less than the specified `maxResults`.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlayerLeaderboardScoreListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlayerLeaderboardScoreListResponse> get(
    core.String playerId,
    core.String leaderboardId,
    core.String timeSpan, {
    core.String? includeRankType,
    core.String? language,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeRankType != null) 'includeRankType': [includeRankType],
      if (language != null) 'language': [language],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1/players/' +
        commons.escapeVariable('$playerId') +
        '/leaderboards/' +
        commons.escapeVariable('$leaderboardId') +
        '/scores/' +
        commons.escapeVariable('$timeSpan');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PlayerLeaderboardScoreListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the scores in a leaderboard, starting from the top.
  ///
  /// Request parameters:
  ///
  /// [leaderboardId] - The ID of the leaderboard.
  ///
  /// [collection] - The collection of scores you're requesting.
  /// Possible string values are:
  /// - "SCORE_COLLECTION_UNSPECIFIED" : Default value. This value is unused.
  /// - "PUBLIC" : List all scores in the public leaderboard.
  /// - "SOCIAL" : (Obsolete) Legacy G+ social scores.
  /// - "FRIENDS" : List only scores of friends.
  ///
  /// [timeSpan] - The time span for the scores and ranks you're requesting.
  /// Possible string values are:
  /// - "SCORE_TIME_SPAN_UNSPECIFIED" : Default value. This value is unused.
  /// - "ALL_TIME" : The score is an all-time score.
  /// - "WEEKLY" : The score is a weekly score.
  /// - "DAILY" : The score is a daily score.
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [maxResults] - The maximum number of leaderboard scores to return in the
  /// response. For any response, the actual number of leaderboard scores
  /// returned may be less than the specified `maxResults`.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LeaderboardScores].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LeaderboardScores> list(
    core.String leaderboardId,
    core.String collection,
    core.String timeSpan, {
    core.String? language,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'timeSpan': [timeSpan],
      if (language != null) 'language': [language],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1/leaderboards/' +
        commons.escapeVariable('$leaderboardId') +
        '/scores/' +
        commons.escapeVariable('$collection');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LeaderboardScores.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists the scores in a leaderboard around (and including) a player's score.
  ///
  /// Request parameters:
  ///
  /// [leaderboardId] - The ID of the leaderboard.
  ///
  /// [collection] - The collection of scores you're requesting.
  /// Possible string values are:
  /// - "SCORE_COLLECTION_UNSPECIFIED" : Default value. This value is unused.
  /// - "PUBLIC" : List all scores in the public leaderboard.
  /// - "SOCIAL" : (Obsolete) Legacy G+ social scores.
  /// - "FRIENDS" : List only scores of friends.
  ///
  /// [timeSpan] - The time span for the scores and ranks you're requesting.
  /// Possible string values are:
  /// - "SCORE_TIME_SPAN_UNSPECIFIED" : Default value. This value is unused.
  /// - "ALL_TIME" : The score is an all-time score.
  /// - "WEEKLY" : The score is a weekly score.
  /// - "DAILY" : The score is a daily score.
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [maxResults] - The maximum number of leaderboard scores to return in the
  /// response. For any response, the actual number of leaderboard scores
  /// returned may be less than the specified `maxResults`.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [resultsAbove] - The preferred number of scores to return above the
  /// player's score. More scores may be returned if the player is at the bottom
  /// of the leaderboard; fewer may be returned if the player is at the top.
  /// Must be less than or equal to maxResults.
  ///
  /// [returnTopIfAbsent] - True if the top scores should be returned when the
  /// player is not in the leaderboard. Defaults to true.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LeaderboardScores].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LeaderboardScores> listWindow(
    core.String leaderboardId,
    core.String collection,
    core.String timeSpan, {
    core.String? language,
    core.int? maxResults,
    core.String? pageToken,
    core.int? resultsAbove,
    core.bool? returnTopIfAbsent,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'timeSpan': [timeSpan],
      if (language != null) 'language': [language],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (resultsAbove != null) 'resultsAbove': ['${resultsAbove}'],
      if (returnTopIfAbsent != null)
        'returnTopIfAbsent': ['${returnTopIfAbsent}'],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1/leaderboards/' +
        commons.escapeVariable('$leaderboardId') +
        '/window/' +
        commons.escapeVariable('$collection');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LeaderboardScores.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Submits a score to the specified leaderboard.
  ///
  /// Request parameters:
  ///
  /// [leaderboardId] - The ID of the leaderboard.
  ///
  /// [score] - The score you're submitting. The submitted score is ignored if
  /// it is worse than a previously submitted score, where worse depends on the
  /// leaderboard sort order. The meaning of the score value depends on the
  /// leaderboard format type. For fixed-point, the score represents the raw
  /// value. For time, the score represents elapsed time in milliseconds. For
  /// currency, the score represents a value in micro units.
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [scoreTag] - Additional information about the score you're submitting.
  /// Values must contain no more than 64 URI-safe characters as defined by
  /// section 2.3 of RFC 3986.
  /// Value must have pattern `\[a-zA-Z0-9-._~\]{0,64}`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlayerScoreResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlayerScoreResponse> submit(
    core.String leaderboardId,
    core.String score, {
    core.String? language,
    core.String? scoreTag,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'score': [score],
      if (language != null) 'language': [language],
      if (scoreTag != null) 'scoreTag': [scoreTag],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1/leaderboards/' +
        commons.escapeVariable('$leaderboardId') +
        '/scores';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return PlayerScoreResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Submits multiple scores to leaderboards.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PlayerScoreListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PlayerScoreListResponse> submitMultiple(
    PlayerScoreSubmissionList request, {
    core.String? language,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'games/v1/leaderboards/scores';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return PlayerScoreListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class SnapshotsResource {
  final commons.ApiRequester _requester;

  SnapshotsResource(commons.ApiRequester client) : _requester = client;

  /// Retrieves the metadata for a given snapshot ID.
  ///
  /// Request parameters:
  ///
  /// [snapshotId] - The ID of the snapshot.
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Snapshot].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Snapshot> get(
    core.String snapshotId, {
    core.String? language,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1/snapshots/' + commons.escapeVariable('$snapshotId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Snapshot.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Retrieves a list of snapshots created by your application for the player
  /// corresponding to the player ID.
  ///
  /// Request parameters:
  ///
  /// [playerId] - A player ID. A value of `me` may be used in place of the
  /// authenticated player's ID.
  ///
  /// [language] - The preferred language to use for strings returned by this
  /// method.
  ///
  /// [maxResults] - The maximum number of snapshot resources to return in the
  /// response, used for paging. For any response, the actual number of snapshot
  /// resources returned may be less than the specified `maxResults`.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SnapshotListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SnapshotListResponse> list(
    core.String playerId, {
    core.String? language,
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (language != null) 'language': [language],
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1/players/' +
        commons.escapeVariable('$playerId') +
        '/snapshots';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return SnapshotListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class StatsResource {
  final commons.ApiRequester _requester;

  StatsResource(commons.ApiRequester client) : _requester = client;

  /// Returns engagement and spend statistics in this application for the
  /// currently authenticated user.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [StatsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<StatsResponse> get({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'games/v1/stats';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return StatsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// An achievement definition object.
class AchievementDefinition {
  /// The type of the achievement.
  /// Possible string values are:
  /// - "ACHIEVEMENT_TYPE_UNSPECIFIED" : Safe default, don't use.
  /// - "STANDARD" : Achievement is either locked or unlocked.
  /// - "INCREMENTAL" : Achievement is incremental.
  core.String? achievementType;

  /// The description of the achievement.
  core.String? description;

  /// Experience points which will be earned when unlocking this achievement.
  core.String? experiencePoints;

  /// The total steps for an incremental achievement as a string.
  core.String? formattedTotalSteps;

  /// The ID of the achievement.
  core.String? id;

  /// The initial state of the achievement.
  /// Possible string values are:
  /// - "INITIAL_ACHIEVEMENT_STATE_UNSPECIFIED" : Safe default, don't use.
  /// - "HIDDEN" : Achievement is hidden.
  /// - "REVEALED" : Achievement is revealed.
  /// - "UNLOCKED" : Achievement is unlocked.
  core.String? initialState;

  /// Indicates whether the revealed icon image being returned is a default
  /// image, or is provided by the game.
  core.bool? isRevealedIconUrlDefault;

  /// Indicates whether the unlocked icon image being returned is a default
  /// image, or is game-provided.
  core.bool? isUnlockedIconUrlDefault;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#achievementDefinition`.
  core.String? kind;

  /// The name of the achievement.
  core.String? name;

  /// The image URL for the revealed achievement icon.
  core.String? revealedIconUrl;

  /// The total steps for an incremental achievement.
  core.int? totalSteps;

  /// The image URL for the unlocked achievement icon.
  core.String? unlockedIconUrl;

  AchievementDefinition();

  AchievementDefinition.fromJson(core.Map _json) {
    if (_json.containsKey('achievementType')) {
      achievementType = _json['achievementType'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('experiencePoints')) {
      experiencePoints = _json['experiencePoints'] as core.String;
    }
    if (_json.containsKey('formattedTotalSteps')) {
      formattedTotalSteps = _json['formattedTotalSteps'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('initialState')) {
      initialState = _json['initialState'] as core.String;
    }
    if (_json.containsKey('isRevealedIconUrlDefault')) {
      isRevealedIconUrlDefault = _json['isRevealedIconUrlDefault'] as core.bool;
    }
    if (_json.containsKey('isUnlockedIconUrlDefault')) {
      isUnlockedIconUrlDefault = _json['isUnlockedIconUrlDefault'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('revealedIconUrl')) {
      revealedIconUrl = _json['revealedIconUrl'] as core.String;
    }
    if (_json.containsKey('totalSteps')) {
      totalSteps = _json['totalSteps'] as core.int;
    }
    if (_json.containsKey('unlockedIconUrl')) {
      unlockedIconUrl = _json['unlockedIconUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (achievementType != null) 'achievementType': achievementType!,
        if (description != null) 'description': description!,
        if (experiencePoints != null) 'experiencePoints': experiencePoints!,
        if (formattedTotalSteps != null)
          'formattedTotalSteps': formattedTotalSteps!,
        if (id != null) 'id': id!,
        if (initialState != null) 'initialState': initialState!,
        if (isRevealedIconUrlDefault != null)
          'isRevealedIconUrlDefault': isRevealedIconUrlDefault!,
        if (isUnlockedIconUrlDefault != null)
          'isUnlockedIconUrlDefault': isUnlockedIconUrlDefault!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (revealedIconUrl != null) 'revealedIconUrl': revealedIconUrl!,
        if (totalSteps != null) 'totalSteps': totalSteps!,
        if (unlockedIconUrl != null) 'unlockedIconUrl': unlockedIconUrl!,
      };
}

/// A list of achievement definition objects.
class AchievementDefinitionsListResponse {
  /// The achievement definitions.
  core.List<AchievementDefinition>? items;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string
  /// `games#achievementDefinitionsListResponse`.
  core.String? kind;

  /// Token corresponding to the next page of results.
  core.String? nextPageToken;

  AchievementDefinitionsListResponse();

  AchievementDefinitionsListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<AchievementDefinition>((value) => AchievementDefinition.fromJson(
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
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// An achievement increment response
class AchievementIncrementResponse {
  /// The current steps recorded for this incremental achievement.
  core.int? currentSteps;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#achievementIncrementResponse`.
  core.String? kind;

  /// Whether the current steps for the achievement has reached the number of
  /// steps required to unlock.
  core.bool? newlyUnlocked;

  AchievementIncrementResponse();

  AchievementIncrementResponse.fromJson(core.Map _json) {
    if (_json.containsKey('currentSteps')) {
      currentSteps = _json['currentSteps'] as core.int;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('newlyUnlocked')) {
      newlyUnlocked = _json['newlyUnlocked'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentSteps != null) 'currentSteps': currentSteps!,
        if (kind != null) 'kind': kind!,
        if (newlyUnlocked != null) 'newlyUnlocked': newlyUnlocked!,
      };
}

/// An achievement reveal response
class AchievementRevealResponse {
  /// The current state of the achievement for which a reveal was attempted.
  ///
  /// This might be `UNLOCKED` if the achievement was already unlocked.
  /// Possible string values are:
  /// - "REVEAL_ACHIEVEMENT_STATE_UNSPECIFIED" : Safe default, don't use.
  /// - "REVEALED" : Achievement is revealed.
  /// - "UNLOCKED" : Achievement is unlocked.
  core.String? currentState;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#achievementRevealResponse`.
  core.String? kind;

  AchievementRevealResponse();

  AchievementRevealResponse.fromJson(core.Map _json) {
    if (_json.containsKey('currentState')) {
      currentState = _json['currentState'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentState != null) 'currentState': currentState!,
        if (kind != null) 'kind': kind!,
      };
}

/// An achievement set steps at least response.
class AchievementSetStepsAtLeastResponse {
  /// The current steps recorded for this incremental achievement.
  core.int? currentSteps;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string
  /// `games#achievementSetStepsAtLeastResponse`.
  core.String? kind;

  /// Whether the current steps for the achievement has reached the number of
  /// steps required to unlock.
  core.bool? newlyUnlocked;

  AchievementSetStepsAtLeastResponse();

  AchievementSetStepsAtLeastResponse.fromJson(core.Map _json) {
    if (_json.containsKey('currentSteps')) {
      currentSteps = _json['currentSteps'] as core.int;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('newlyUnlocked')) {
      newlyUnlocked = _json['newlyUnlocked'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentSteps != null) 'currentSteps': currentSteps!,
        if (kind != null) 'kind': kind!,
        if (newlyUnlocked != null) 'newlyUnlocked': newlyUnlocked!,
      };
}

/// An achievement unlock response
class AchievementUnlockResponse {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#achievementUnlockResponse`.
  core.String? kind;

  /// Whether this achievement was newly unlocked (that is, whether the unlock
  /// request for the achievement was the first for the player).
  core.bool? newlyUnlocked;

  AchievementUnlockResponse();

  AchievementUnlockResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('newlyUnlocked')) {
      newlyUnlocked = _json['newlyUnlocked'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (newlyUnlocked != null) 'newlyUnlocked': newlyUnlocked!,
      };
}

/// A list of achievement update requests.
class AchievementUpdateMultipleRequest {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#achievementUpdateMultipleRequest`.
  core.String? kind;

  /// The individual achievement update requests.
  core.List<AchievementUpdateRequest>? updates;

  AchievementUpdateMultipleRequest();

  AchievementUpdateMultipleRequest.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('updates')) {
      updates = (_json['updates'] as core.List)
          .map<AchievementUpdateRequest>((value) =>
              AchievementUpdateRequest.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (updates != null)
          'updates': updates!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for UpdateMultipleAchievements rpc.
class AchievementUpdateMultipleResponse {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string
  /// `games#achievementUpdateMultipleResponse`.
  core.String? kind;

  /// The updated state of the achievements.
  core.List<AchievementUpdateResponse>? updatedAchievements;

  AchievementUpdateMultipleResponse();

  AchievementUpdateMultipleResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('updatedAchievements')) {
      updatedAchievements = (_json['updatedAchievements'] as core.List)
          .map<AchievementUpdateResponse>((value) =>
              AchievementUpdateResponse.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (updatedAchievements != null)
          'updatedAchievements':
              updatedAchievements!.map((value) => value.toJson()).toList(),
      };
}

/// A request to update an achievement.
class AchievementUpdateRequest {
  /// The achievement this update is being applied to.
  core.String? achievementId;

  /// The payload if an update of type `INCREMENT` was requested for the
  /// achievement.
  GamesAchievementIncrement? incrementPayload;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#achievementUpdateRequest`.
  core.String? kind;

  /// The payload if an update of type `SET_STEPS_AT_LEAST` was requested for
  /// the achievement.
  GamesAchievementSetStepsAtLeast? setStepsAtLeastPayload;

  /// The type of update being applied.
  /// Possible string values are:
  /// - "ACHIEVEMENT_UPDATE_TYPE_UNSPECIFIED" : Safe default, don't use.
  /// - "REVEAL" : Achievement is revealed.
  /// - "UNLOCK" : Achievement is unlocked.
  /// - "INCREMENT" : Achievement is incremented.
  /// - "SET_STEPS_AT_LEAST" : Achievement progress is set to at least the
  /// passed value.
  core.String? updateType;

  AchievementUpdateRequest();

  AchievementUpdateRequest.fromJson(core.Map _json) {
    if (_json.containsKey('achievementId')) {
      achievementId = _json['achievementId'] as core.String;
    }
    if (_json.containsKey('incrementPayload')) {
      incrementPayload = GamesAchievementIncrement.fromJson(
          _json['incrementPayload'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('setStepsAtLeastPayload')) {
      setStepsAtLeastPayload = GamesAchievementSetStepsAtLeast.fromJson(
          _json['setStepsAtLeastPayload']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updateType')) {
      updateType = _json['updateType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (achievementId != null) 'achievementId': achievementId!,
        if (incrementPayload != null)
          'incrementPayload': incrementPayload!.toJson(),
        if (kind != null) 'kind': kind!,
        if (setStepsAtLeastPayload != null)
          'setStepsAtLeastPayload': setStepsAtLeastPayload!.toJson(),
        if (updateType != null) 'updateType': updateType!,
      };
}

/// An updated achievement.
class AchievementUpdateResponse {
  /// The achievement this update is was applied to.
  core.String? achievementId;

  /// The current state of the achievement.
  /// Possible string values are:
  /// - "UPDATED_ACHIEVEMENT_STATE_UNSPECIFIED" : Safe default, don't use.
  /// - "HIDDEN" : Achievement is hidden.
  /// - "REVEALED" : Achievement is revealed.
  /// - "UNLOCKED" : Achievement is unlocked.
  core.String? currentState;

  /// The current steps recorded for this achievement if it is incremental.
  core.int? currentSteps;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#achievementUpdateResponse`.
  core.String? kind;

  /// Whether this achievement was newly unlocked (that is, whether the unlock
  /// request for the achievement was the first for the player).
  core.bool? newlyUnlocked;

  /// Whether the requested updates actually affected the achievement.
  core.bool? updateOccurred;

  AchievementUpdateResponse();

  AchievementUpdateResponse.fromJson(core.Map _json) {
    if (_json.containsKey('achievementId')) {
      achievementId = _json['achievementId'] as core.String;
    }
    if (_json.containsKey('currentState')) {
      currentState = _json['currentState'] as core.String;
    }
    if (_json.containsKey('currentSteps')) {
      currentSteps = _json['currentSteps'] as core.int;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('newlyUnlocked')) {
      newlyUnlocked = _json['newlyUnlocked'] as core.bool;
    }
    if (_json.containsKey('updateOccurred')) {
      updateOccurred = _json['updateOccurred'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (achievementId != null) 'achievementId': achievementId!,
        if (currentState != null) 'currentState': currentState!,
        if (currentSteps != null) 'currentSteps': currentSteps!,
        if (kind != null) 'kind': kind!,
        if (newlyUnlocked != null) 'newlyUnlocked': newlyUnlocked!,
        if (updateOccurred != null) 'updateOccurred': updateOccurred!,
      };
}

/// The Application resource.
class Application {
  /// The number of achievements visible to the currently authenticated player.
  core.int? achievementCount;

  /// The assets of the application.
  core.List<ImageAsset>? assets;

  /// The author of the application.
  core.String? author;

  /// The category of the application.
  ApplicationCategory? category;

  /// The description of the application.
  core.String? description;

  /// A list of features that have been enabled for the application.
  core.List<core.String>? enabledFeatures;

  /// The ID of the application.
  core.String? id;

  /// The instances of the application.
  core.List<Instance>? instances;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#application`.
  core.String? kind;

  /// The last updated timestamp of the application.
  core.String? lastUpdatedTimestamp;

  /// The number of leaderboards visible to the currently authenticated player.
  core.int? leaderboardCount;

  /// The name of the application.
  core.String? name;

  /// A hint to the client UI for what color to use as an app-themed color.
  ///
  /// The color is given as an RGB triplet (e.g. "E0E0E0").
  core.String? themeColor;

  Application();

  Application.fromJson(core.Map _json) {
    if (_json.containsKey('achievement_count')) {
      achievementCount = _json['achievement_count'] as core.int;
    }
    if (_json.containsKey('assets')) {
      assets = (_json['assets'] as core.List)
          .map<ImageAsset>((value) =>
              ImageAsset.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('author')) {
      author = _json['author'] as core.String;
    }
    if (_json.containsKey('category')) {
      category = ApplicationCategory.fromJson(
          _json['category'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('enabledFeatures')) {
      enabledFeatures = (_json['enabledFeatures'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('instances')) {
      instances = (_json['instances'] as core.List)
          .map<Instance>((value) =>
              Instance.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastUpdatedTimestamp')) {
      lastUpdatedTimestamp = _json['lastUpdatedTimestamp'] as core.String;
    }
    if (_json.containsKey('leaderboard_count')) {
      leaderboardCount = _json['leaderboard_count'] as core.int;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('themeColor')) {
      themeColor = _json['themeColor'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (achievementCount != null) 'achievement_count': achievementCount!,
        if (assets != null)
          'assets': assets!.map((value) => value.toJson()).toList(),
        if (author != null) 'author': author!,
        if (category != null) 'category': category!.toJson(),
        if (description != null) 'description': description!,
        if (enabledFeatures != null) 'enabledFeatures': enabledFeatures!,
        if (id != null) 'id': id!,
        if (instances != null)
          'instances': instances!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (lastUpdatedTimestamp != null)
          'lastUpdatedTimestamp': lastUpdatedTimestamp!,
        if (leaderboardCount != null) 'leaderboard_count': leaderboardCount!,
        if (name != null) 'name': name!,
        if (themeColor != null) 'themeColor': themeColor!,
      };
}

/// An application category object.
class ApplicationCategory {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#applicationCategory`.
  core.String? kind;

  /// The primary category.
  core.String? primary;

  /// The secondary category.
  core.String? secondary;

  ApplicationCategory();

  ApplicationCategory.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('primary')) {
      primary = _json['primary'] as core.String;
    }
    if (_json.containsKey('secondary')) {
      secondary = _json['secondary'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (primary != null) 'primary': primary!,
        if (secondary != null) 'secondary': secondary!,
      };
}

/// A third party application verification response resource.
class ApplicationVerifyResponse {
  /// An alternate ID that was once used for the player that was issued the auth
  /// token used in this request.
  ///
  /// (This field is not normally populated.)
  core.String? alternatePlayerId;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#applicationVerifyResponse`.
  core.String? kind;

  /// The ID of the player that was issued the auth token used in this request.
  core.String? playerId;

  ApplicationVerifyResponse();

  ApplicationVerifyResponse.fromJson(core.Map _json) {
    if (_json.containsKey('alternate_player_id')) {
      alternatePlayerId = _json['alternate_player_id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('player_id')) {
      playerId = _json['player_id'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alternatePlayerId != null)
          'alternate_player_id': alternatePlayerId!,
        if (kind != null) 'kind': kind!,
        if (playerId != null) 'player_id': playerId!,
      };
}

/// Data related to individual game categories.
class Category {
  /// The category name.
  core.String? category;

  /// Experience points earned in this category.
  core.String? experiencePoints;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#category`.
  core.String? kind;

  Category();

  Category.fromJson(core.Map _json) {
    if (_json.containsKey('category')) {
      category = _json['category'] as core.String;
    }
    if (_json.containsKey('experiencePoints')) {
      experiencePoints = _json['experiencePoints'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (category != null) 'category': category!,
        if (experiencePoints != null) 'experiencePoints': experiencePoints!,
        if (kind != null) 'kind': kind!,
      };
}

/// A third party list metagame categories response.
class CategoryListResponse {
  /// The list of categories with usage data.
  core.List<Category>? items;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#categoryListResponse`.
  core.String? kind;

  /// Token corresponding to the next page of results.
  core.String? nextPageToken;

  CategoryListResponse();

  CategoryListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Category>((value) =>
              Category.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Container for a URL end point of the requested type.
class EndPoint {
  /// A URL suitable for loading in a web browser for the requested endpoint.
  core.String? url;

  EndPoint();

  EndPoint.fromJson(core.Map _json) {
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (url != null) 'url': url!,
      };
}

/// A batch update failure resource.
class EventBatchRecordFailure {
  /// The cause for the update failure.
  /// Possible string values are:
  /// - "EVENT_FAILURE_CAUSE_UNSPECIFIED" : Default value. Should not be used.
  /// - "TOO_LARGE" : A batch request was issued with more events than are
  /// allowed in a single batch.
  /// - "TIME_PERIOD_EXPIRED" : A batch was sent with data too far in the past
  /// to record.
  /// - "TIME_PERIOD_SHORT" : A batch was sent with a time range that was too
  /// short.
  /// - "TIME_PERIOD_LONG" : A batch was sent with a time range that was too
  /// long.
  /// - "ALREADY_UPDATED" : An attempt was made to record a batch of data which
  /// was already seen.
  /// - "RECORD_RATE_HIGH" : An attempt was made to record data faster than the
  /// server will apply updates.
  core.String? failureCause;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#eventBatchRecordFailure`.
  core.String? kind;

  /// The time range which was rejected; empty for a request-wide failure.
  EventPeriodRange? range;

  EventBatchRecordFailure();

  EventBatchRecordFailure.fromJson(core.Map _json) {
    if (_json.containsKey('failureCause')) {
      failureCause = _json['failureCause'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('range')) {
      range = EventPeriodRange.fromJson(
          _json['range'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (failureCause != null) 'failureCause': failureCause!,
        if (kind != null) 'kind': kind!,
        if (range != null) 'range': range!.toJson(),
      };
}

/// An event child relationship resource.
class EventChild {
  /// The ID of the child event.
  core.String? childId;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#eventChild`.
  core.String? kind;

  EventChild();

  EventChild.fromJson(core.Map _json) {
    if (_json.containsKey('childId')) {
      childId = _json['childId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (childId != null) 'childId': childId!,
        if (kind != null) 'kind': kind!,
      };
}

/// An event definition resource.
class EventDefinition {
  /// A list of events that are a child of this event.
  core.List<EventChild>? childEvents;

  /// Description of what this event represents.
  core.String? description;

  /// The name to display for the event.
  core.String? displayName;

  /// The ID of the event.
  core.String? id;

  /// The base URL for the image that represents the event.
  core.String? imageUrl;

  /// Indicates whether the icon image being returned is a default image, or is
  /// game-provided.
  core.bool? isDefaultImageUrl;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#eventDefinition`.
  core.String? kind;

  /// The visibility of event being tracked in this definition.
  /// Possible string values are:
  /// - "EVENT_VISIBILITY_UNSPECIFIED" : Default value. Should not be used.
  /// - "REVEALED" : This event should be visible to all users.
  /// - "HIDDEN" : This event should only be shown to users that have recorded
  /// this event at least once.
  core.String? visibility;

  EventDefinition();

  EventDefinition.fromJson(core.Map _json) {
    if (_json.containsKey('childEvents')) {
      childEvents = (_json['childEvents'] as core.List)
          .map<EventChild>((value) =>
              EventChild.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('imageUrl')) {
      imageUrl = _json['imageUrl'] as core.String;
    }
    if (_json.containsKey('isDefaultImageUrl')) {
      isDefaultImageUrl = _json['isDefaultImageUrl'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('visibility')) {
      visibility = _json['visibility'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (childEvents != null)
          'childEvents': childEvents!.map((value) => value.toJson()).toList(),
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (id != null) 'id': id!,
        if (imageUrl != null) 'imageUrl': imageUrl!,
        if (isDefaultImageUrl != null) 'isDefaultImageUrl': isDefaultImageUrl!,
        if (kind != null) 'kind': kind!,
        if (visibility != null) 'visibility': visibility!,
      };
}

/// A ListDefinitions response.
class EventDefinitionListResponse {
  /// The event definitions.
  core.List<EventDefinition>? items;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#eventDefinitionListResponse`.
  core.String? kind;

  /// The pagination token for the next page of results.
  core.String? nextPageToken;

  EventDefinitionListResponse();

  EventDefinitionListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<EventDefinition>((value) => EventDefinition.fromJson(
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
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// An event period time range.
class EventPeriodRange {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#eventPeriodRange`.
  core.String? kind;

  /// The time when this update period ends, in millis, since 1970 UTC (Unix
  /// Epoch).
  core.String? periodEndMillis;

  /// The time when this update period begins, in millis, since 1970 UTC (Unix
  /// Epoch).
  core.String? periodStartMillis;

  EventPeriodRange();

  EventPeriodRange.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('periodEndMillis')) {
      periodEndMillis = _json['periodEndMillis'] as core.String;
    }
    if (_json.containsKey('periodStartMillis')) {
      periodStartMillis = _json['periodStartMillis'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (periodEndMillis != null) 'periodEndMillis': periodEndMillis!,
        if (periodStartMillis != null) 'periodStartMillis': periodStartMillis!,
      };
}

/// An event period update resource.
class EventPeriodUpdate {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#eventPeriodUpdate`.
  core.String? kind;

  /// The time period being covered by this update.
  EventPeriodRange? timePeriod;

  /// The updates being made for this time period.
  core.List<EventUpdateRequest>? updates;

  EventPeriodUpdate();

  EventPeriodUpdate.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('timePeriod')) {
      timePeriod = EventPeriodRange.fromJson(
          _json['timePeriod'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('updates')) {
      updates = (_json['updates'] as core.List)
          .map<EventUpdateRequest>((value) => EventUpdateRequest.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (timePeriod != null) 'timePeriod': timePeriod!.toJson(),
        if (updates != null)
          'updates': updates!.map((value) => value.toJson()).toList(),
      };
}

/// An event update failure resource.
class EventRecordFailure {
  /// The ID of the event that was not updated.
  core.String? eventId;

  /// The cause for the update failure.
  /// Possible string values are:
  /// - "EVENT_UPDATE_FAILURE_CAUSE_UNSPECIFIED" : Default value. Should not
  /// use.
  /// - "NOT_FOUND" : An attempt was made to set an event that was not defined.
  /// - "INVALID_UPDATE_VALUE" : An attempt was made to increment an event by a
  /// non-positive value.
  core.String? failureCause;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#eventRecordFailure`.
  core.String? kind;

  EventRecordFailure();

  EventRecordFailure.fromJson(core.Map _json) {
    if (_json.containsKey('eventId')) {
      eventId = _json['eventId'] as core.String;
    }
    if (_json.containsKey('failureCause')) {
      failureCause = _json['failureCause'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (eventId != null) 'eventId': eventId!,
        if (failureCause != null) 'failureCause': failureCause!,
        if (kind != null) 'kind': kind!,
      };
}

/// An event period update resource.
class EventRecordRequest {
  /// The current time when this update was sent, in milliseconds, since 1970
  /// UTC (Unix Epoch).
  core.String? currentTimeMillis;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#eventRecordRequest`.
  core.String? kind;

  /// The request ID used to identify this attempt to record events.
  core.String? requestId;

  /// A list of the time period updates being made in this request.
  core.List<EventPeriodUpdate>? timePeriods;

  EventRecordRequest();

  EventRecordRequest.fromJson(core.Map _json) {
    if (_json.containsKey('currentTimeMillis')) {
      currentTimeMillis = _json['currentTimeMillis'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
    if (_json.containsKey('timePeriods')) {
      timePeriods = (_json['timePeriods'] as core.List)
          .map<EventPeriodUpdate>((value) => EventPeriodUpdate.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentTimeMillis != null) 'currentTimeMillis': currentTimeMillis!,
        if (kind != null) 'kind': kind!,
        if (requestId != null) 'requestId': requestId!,
        if (timePeriods != null)
          'timePeriods': timePeriods!.map((value) => value.toJson()).toList(),
      };
}

/// An event period update resource.
class EventUpdateRequest {
  /// The ID of the event being modified in this update.
  core.String? definitionId;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#eventUpdateRequest`.
  core.String? kind;

  /// The number of times this event occurred in this time period.
  core.String? updateCount;

  EventUpdateRequest();

  EventUpdateRequest.fromJson(core.Map _json) {
    if (_json.containsKey('definitionId')) {
      definitionId = _json['definitionId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('updateCount')) {
      updateCount = _json['updateCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (definitionId != null) 'definitionId': definitionId!,
        if (kind != null) 'kind': kind!,
        if (updateCount != null) 'updateCount': updateCount!,
      };
}

/// An event period update resource.
class EventUpdateResponse {
  /// Any batch-wide failures which occurred applying updates.
  core.List<EventBatchRecordFailure>? batchFailures;

  /// Any failures updating a particular event.
  core.List<EventRecordFailure>? eventFailures;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#eventUpdateResponse`.
  core.String? kind;

  /// The current status of any updated events
  core.List<PlayerEvent>? playerEvents;

  EventUpdateResponse();

  EventUpdateResponse.fromJson(core.Map _json) {
    if (_json.containsKey('batchFailures')) {
      batchFailures = (_json['batchFailures'] as core.List)
          .map<EventBatchRecordFailure>((value) =>
              EventBatchRecordFailure.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('eventFailures')) {
      eventFailures = (_json['eventFailures'] as core.List)
          .map<EventRecordFailure>((value) => EventRecordFailure.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('playerEvents')) {
      playerEvents = (_json['playerEvents'] as core.List)
          .map<PlayerEvent>((value) => PlayerEvent.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (batchFailures != null)
          'batchFailures':
              batchFailures!.map((value) => value.toJson()).toList(),
        if (eventFailures != null)
          'eventFailures':
              eventFailures!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (playerEvents != null)
          'playerEvents': playerEvents!.map((value) => value.toJson()).toList(),
      };
}

/// The payload to request to increment an achievement.
class GamesAchievementIncrement {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#GamesAchievementIncrement`.
  core.String? kind;

  /// The requestId associated with an increment to an achievement.
  core.String? requestId;

  /// The number of steps to be incremented.
  core.int? steps;

  GamesAchievementIncrement();

  GamesAchievementIncrement.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
    if (_json.containsKey('steps')) {
      steps = _json['steps'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (requestId != null) 'requestId': requestId!,
        if (steps != null) 'steps': steps!,
      };
}

/// The payload to request to increment an achievement.
class GamesAchievementSetStepsAtLeast {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#GamesAchievementSetStepsAtLeast`.
  core.String? kind;

  /// The minimum number of steps for the achievement to be set to.
  core.int? steps;

  GamesAchievementSetStepsAtLeast();

  GamesAchievementSetStepsAtLeast.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('steps')) {
      steps = _json['steps'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (steps != null) 'steps': steps!,
      };
}

/// An image asset object.
class ImageAsset {
  /// The height of the asset.
  core.int? height;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#imageAsset`.
  core.String? kind;

  /// The name of the asset.
  core.String? name;

  /// The URL of the asset.
  core.String? url;

  /// The width of the asset.
  core.int? width;

  ImageAsset();

  ImageAsset.fromJson(core.Map _json) {
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (height != null) 'height': height!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (url != null) 'url': url!,
        if (width != null) 'width': width!,
      };
}

/// The Instance resource.
class Instance {
  /// URI which shows where a user can acquire this instance.
  core.String? acquisitionUri;

  /// Platform dependent details for Android.
  InstanceAndroidDetails? androidInstance;

  /// Platform dependent details for iOS.
  InstanceIosDetails? iosInstance;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#instance`.
  core.String? kind;

  /// Localized display name.
  core.String? name;

  /// The platform type.
  /// Possible string values are:
  /// - "PLATFORM_TYPE_UNSPECIFIED" : Default value. Should be unused.
  /// - "ANDROID" : Instance is for Android.
  /// - "IOS" : Instance is for iOS.
  /// - "WEB_APP" : Instance is for Web App.
  core.String? platformType;

  /// Flag to show if this game instance supports realtime play.
  core.bool? realtimePlay;

  /// Flag to show if this game instance supports turn based play.
  core.bool? turnBasedPlay;

  /// Platform dependent details for Web.
  InstanceWebDetails? webInstance;

  Instance();

  Instance.fromJson(core.Map _json) {
    if (_json.containsKey('acquisitionUri')) {
      acquisitionUri = _json['acquisitionUri'] as core.String;
    }
    if (_json.containsKey('androidInstance')) {
      androidInstance = InstanceAndroidDetails.fromJson(
          _json['androidInstance'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('iosInstance')) {
      iosInstance = InstanceIosDetails.fromJson(
          _json['iosInstance'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('platformType')) {
      platformType = _json['platformType'] as core.String;
    }
    if (_json.containsKey('realtimePlay')) {
      realtimePlay = _json['realtimePlay'] as core.bool;
    }
    if (_json.containsKey('turnBasedPlay')) {
      turnBasedPlay = _json['turnBasedPlay'] as core.bool;
    }
    if (_json.containsKey('webInstance')) {
      webInstance = InstanceWebDetails.fromJson(
          _json['webInstance'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (acquisitionUri != null) 'acquisitionUri': acquisitionUri!,
        if (androidInstance != null)
          'androidInstance': androidInstance!.toJson(),
        if (iosInstance != null) 'iosInstance': iosInstance!.toJson(),
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (platformType != null) 'platformType': platformType!,
        if (realtimePlay != null) 'realtimePlay': realtimePlay!,
        if (turnBasedPlay != null) 'turnBasedPlay': turnBasedPlay!,
        if (webInstance != null) 'webInstance': webInstance!.toJson(),
      };
}

/// The Android instance details resource.
class InstanceAndroidDetails {
  /// Flag indicating whether the anti-piracy check is enabled.
  core.bool? enablePiracyCheck;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#instanceAndroidDetails`.
  core.String? kind;

  /// Android package name which maps to Google Play URL.
  core.String? packageName;

  /// Indicates that this instance is the default for new installations.
  core.bool? preferred;

  InstanceAndroidDetails();

  InstanceAndroidDetails.fromJson(core.Map _json) {
    if (_json.containsKey('enablePiracyCheck')) {
      enablePiracyCheck = _json['enablePiracyCheck'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('packageName')) {
      packageName = _json['packageName'] as core.String;
    }
    if (_json.containsKey('preferred')) {
      preferred = _json['preferred'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enablePiracyCheck != null) 'enablePiracyCheck': enablePiracyCheck!,
        if (kind != null) 'kind': kind!,
        if (packageName != null) 'packageName': packageName!,
        if (preferred != null) 'preferred': preferred!,
      };
}

/// The iOS details resource.
class InstanceIosDetails {
  /// Bundle identifier.
  core.String? bundleIdentifier;

  /// iTunes App ID.
  core.String? itunesAppId;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#instanceIosDetails`.
  core.String? kind;

  /// Indicates that this instance is the default for new installations on iPad
  /// devices.
  core.bool? preferredForIpad;

  /// Indicates that this instance is the default for new installations on
  /// iPhone devices.
  core.bool? preferredForIphone;

  /// Flag to indicate if this instance supports iPad.
  core.bool? supportIpad;

  /// Flag to indicate if this instance supports iPhone.
  core.bool? supportIphone;

  InstanceIosDetails();

  InstanceIosDetails.fromJson(core.Map _json) {
    if (_json.containsKey('bundleIdentifier')) {
      bundleIdentifier = _json['bundleIdentifier'] as core.String;
    }
    if (_json.containsKey('itunesAppId')) {
      itunesAppId = _json['itunesAppId'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('preferredForIpad')) {
      preferredForIpad = _json['preferredForIpad'] as core.bool;
    }
    if (_json.containsKey('preferredForIphone')) {
      preferredForIphone = _json['preferredForIphone'] as core.bool;
    }
    if (_json.containsKey('supportIpad')) {
      supportIpad = _json['supportIpad'] as core.bool;
    }
    if (_json.containsKey('supportIphone')) {
      supportIphone = _json['supportIphone'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bundleIdentifier != null) 'bundleIdentifier': bundleIdentifier!,
        if (itunesAppId != null) 'itunesAppId': itunesAppId!,
        if (kind != null) 'kind': kind!,
        if (preferredForIpad != null) 'preferredForIpad': preferredForIpad!,
        if (preferredForIphone != null)
          'preferredForIphone': preferredForIphone!,
        if (supportIpad != null) 'supportIpad': supportIpad!,
        if (supportIphone != null) 'supportIphone': supportIphone!,
      };
}

/// The Web details resource.
class InstanceWebDetails {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#instanceWebDetails`.
  core.String? kind;

  /// Launch URL for the game.
  core.String? launchUrl;

  /// Indicates that this instance is the default for new installations.
  core.bool? preferred;

  InstanceWebDetails();

  InstanceWebDetails.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('launchUrl')) {
      launchUrl = _json['launchUrl'] as core.String;
    }
    if (_json.containsKey('preferred')) {
      preferred = _json['preferred'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (launchUrl != null) 'launchUrl': launchUrl!,
        if (preferred != null) 'preferred': preferred!,
      };
}

/// The Leaderboard resource.
class Leaderboard {
  /// The icon for the leaderboard.
  core.String? iconUrl;

  /// The leaderboard ID.
  core.String? id;

  /// Indicates whether the icon image being returned is a default image, or is
  /// game-provided.
  core.bool? isIconUrlDefault;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#leaderboard`.
  core.String? kind;

  /// The name of the leaderboard.
  core.String? name;

  /// How scores are ordered.
  /// Possible string values are:
  /// - "SCORE_ORDER_UNSPECIFIED" : Default value. This value is unused.
  /// - "LARGER_IS_BETTER" : Larger values are better; scores are sorted in
  /// descending order
  /// - "SMALLER_IS_BETTER" : Smaller values are better; scores are sorted in
  /// ascending order
  core.String? order;

  Leaderboard();

  Leaderboard.fromJson(core.Map _json) {
    if (_json.containsKey('iconUrl')) {
      iconUrl = _json['iconUrl'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('isIconUrlDefault')) {
      isIconUrlDefault = _json['isIconUrlDefault'] as core.bool;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('order')) {
      order = _json['order'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (iconUrl != null) 'iconUrl': iconUrl!,
        if (id != null) 'id': id!,
        if (isIconUrlDefault != null) 'isIconUrlDefault': isIconUrlDefault!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!,
        if (order != null) 'order': order!,
      };
}

/// The Leaderboard Entry resource.
class LeaderboardEntry {
  /// The localized string for the numerical value of this score.
  core.String? formattedScore;

  /// The localized string for the rank of this score for this leaderboard.
  core.String? formattedScoreRank;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#leaderboardEntry`.
  core.String? kind;

  /// The player who holds this score.
  Player? player;

  /// The rank of this score for this leaderboard.
  core.String? scoreRank;

  /// Additional information about the score.
  ///
  /// Values must contain no more than 64 URI-safe characters as defined by
  /// section 2.3 of RFC 3986.
  core.String? scoreTag;

  /// The numerical value of this score.
  core.String? scoreValue;

  /// The time span of this high score.
  /// Possible string values are:
  /// - "SCORE_TIME_SPAN_UNSPECIFIED" : Default value. This value is unused.
  /// - "ALL_TIME" : The score is an all-time score.
  /// - "WEEKLY" : The score is a weekly score.
  /// - "DAILY" : The score is a daily score.
  core.String? timeSpan;

  /// The timestamp at which this score was recorded, in milliseconds since the
  /// epoch in UTC.
  core.String? writeTimestampMillis;

  LeaderboardEntry();

  LeaderboardEntry.fromJson(core.Map _json) {
    if (_json.containsKey('formattedScore')) {
      formattedScore = _json['formattedScore'] as core.String;
    }
    if (_json.containsKey('formattedScoreRank')) {
      formattedScoreRank = _json['formattedScoreRank'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('player')) {
      player = Player.fromJson(
          _json['player'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('scoreRank')) {
      scoreRank = _json['scoreRank'] as core.String;
    }
    if (_json.containsKey('scoreTag')) {
      scoreTag = _json['scoreTag'] as core.String;
    }
    if (_json.containsKey('scoreValue')) {
      scoreValue = _json['scoreValue'] as core.String;
    }
    if (_json.containsKey('timeSpan')) {
      timeSpan = _json['timeSpan'] as core.String;
    }
    if (_json.containsKey('writeTimestampMillis')) {
      writeTimestampMillis = _json['writeTimestampMillis'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (formattedScore != null) 'formattedScore': formattedScore!,
        if (formattedScoreRank != null)
          'formattedScoreRank': formattedScoreRank!,
        if (kind != null) 'kind': kind!,
        if (player != null) 'player': player!.toJson(),
        if (scoreRank != null) 'scoreRank': scoreRank!,
        if (scoreTag != null) 'scoreTag': scoreTag!,
        if (scoreValue != null) 'scoreValue': scoreValue!,
        if (timeSpan != null) 'timeSpan': timeSpan!,
        if (writeTimestampMillis != null)
          'writeTimestampMillis': writeTimestampMillis!,
      };
}

/// A list of leaderboard objects.
class LeaderboardListResponse {
  /// The leaderboards.
  core.List<Leaderboard>? items;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#leaderboardListResponse`.
  core.String? kind;

  /// Token corresponding to the next page of results.
  core.String? nextPageToken;

  LeaderboardListResponse();

  LeaderboardListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Leaderboard>((value) => Leaderboard.fromJson(
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
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A score rank in a leaderboard.
class LeaderboardScoreRank {
  /// The number of scores in the leaderboard as a string.
  core.String? formattedNumScores;

  /// The rank in the leaderboard as a string.
  core.String? formattedRank;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#leaderboardScoreRank`.
  core.String? kind;

  /// The number of scores in the leaderboard.
  core.String? numScores;

  /// The rank in the leaderboard.
  core.String? rank;

  LeaderboardScoreRank();

  LeaderboardScoreRank.fromJson(core.Map _json) {
    if (_json.containsKey('formattedNumScores')) {
      formattedNumScores = _json['formattedNumScores'] as core.String;
    }
    if (_json.containsKey('formattedRank')) {
      formattedRank = _json['formattedRank'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('numScores')) {
      numScores = _json['numScores'] as core.String;
    }
    if (_json.containsKey('rank')) {
      rank = _json['rank'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (formattedNumScores != null)
          'formattedNumScores': formattedNumScores!,
        if (formattedRank != null) 'formattedRank': formattedRank!,
        if (kind != null) 'kind': kind!,
        if (numScores != null) 'numScores': numScores!,
        if (rank != null) 'rank': rank!,
      };
}

/// A ListScores response.
class LeaderboardScores {
  /// The scores in the leaderboard.
  core.List<LeaderboardEntry>? items;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#leaderboardScores`.
  core.String? kind;

  /// The pagination token for the next page of results.
  core.String? nextPageToken;

  /// The total number of scores in the leaderboard.
  core.String? numScores;

  /// The score of the requesting player on the leaderboard.
  ///
  /// The player's score may appear both here and in the list of scores above.
  /// If you are viewing a public leaderboard and the player is not sharing
  /// their gameplay information publicly, the `scoreRank`and
  /// `formattedScoreRank` values will not be present.
  LeaderboardEntry? playerScore;

  /// The pagination token for the previous page of results.
  core.String? prevPageToken;

  LeaderboardScores();

  LeaderboardScores.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<LeaderboardEntry>((value) => LeaderboardEntry.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('numScores')) {
      numScores = _json['numScores'] as core.String;
    }
    if (_json.containsKey('playerScore')) {
      playerScore = LeaderboardEntry.fromJson(
          _json['playerScore'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('prevPageToken')) {
      prevPageToken = _json['prevPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (numScores != null) 'numScores': numScores!,
        if (playerScore != null) 'playerScore': playerScore!.toJson(),
        if (prevPageToken != null) 'prevPageToken': prevPageToken!,
      };
}

/// The metagame config resource
class MetagameConfig {
  /// Current version of the metagame configuration data.
  ///
  /// When this data is updated, the version number will be increased by one.
  core.int? currentVersion;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#metagameConfig`.
  core.String? kind;

  /// The list of player levels.
  core.List<PlayerLevel>? playerLevels;

  MetagameConfig();

  MetagameConfig.fromJson(core.Map _json) {
    if (_json.containsKey('currentVersion')) {
      currentVersion = _json['currentVersion'] as core.int;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('playerLevels')) {
      playerLevels = (_json['playerLevels'] as core.List)
          .map<PlayerLevel>((value) => PlayerLevel.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentVersion != null) 'currentVersion': currentVersion!,
        if (kind != null) 'kind': kind!,
        if (playerLevels != null)
          'playerLevels': playerLevels!.map((value) => value.toJson()).toList(),
      };
}

/// A representation of the individual components of the name.
class PlayerName {
  /// The family name of this player.
  ///
  /// In some places, this is known as the last name.
  core.String? familyName;

  /// The given name of this player.
  ///
  /// In some places, this is known as the first name.
  core.String? givenName;

  PlayerName();

  PlayerName.fromJson(core.Map _json) {
    if (_json.containsKey('familyName')) {
      familyName = _json['familyName'] as core.String;
    }
    if (_json.containsKey('givenName')) {
      givenName = _json['givenName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (familyName != null) 'familyName': familyName!,
        if (givenName != null) 'givenName': givenName!,
      };
}

/// A Player resource.
class Player {
  /// The base URL for the image that represents the player.
  core.String? avatarImageUrl;

  /// The url to the landscape mode player banner image.
  core.String? bannerUrlLandscape;

  /// The url to the portrait mode player banner image.
  core.String? bannerUrlPortrait;

  /// The name to display for the player.
  core.String? displayName;

  /// An object to represent Play Game experience information for the player.
  PlayerExperienceInfo? experienceInfo;

  /// The friend status of the given player, relative to the requester.
  ///
  /// This is unset if the player is not sharing their friends list with the
  /// game.
  /// Possible string values are:
  /// - "FRIEND_STATUS_UNSPECIFIED" : Default value. This value is unused.
  /// - "NO_RELATIONSHIP" : There is no relationship between the players.
  /// - "FRIEND" : The player and requester are friends.
  core.String? friendStatus;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#player`
  core.String? kind;

  /// A representation of the individual components of the name.
  PlayerName? name;

  /// The player ID that was used for this player the first time they signed
  /// into the game in question.
  ///
  /// This is only populated for calls to player.get for the requesting player,
  /// only if the player ID has subsequently changed, and only to clients that
  /// support remapping player IDs.
  core.String? originalPlayerId;

  /// The ID of the player.
  core.String? playerId;

  /// The player's profile settings.
  ///
  /// Controls whether or not the player's profile is visible to other players.
  ProfileSettings? profileSettings;

  /// The player's title rewarded for their game activities.
  core.String? title;

  Player();

  Player.fromJson(core.Map _json) {
    if (_json.containsKey('avatarImageUrl')) {
      avatarImageUrl = _json['avatarImageUrl'] as core.String;
    }
    if (_json.containsKey('bannerUrlLandscape')) {
      bannerUrlLandscape = _json['bannerUrlLandscape'] as core.String;
    }
    if (_json.containsKey('bannerUrlPortrait')) {
      bannerUrlPortrait = _json['bannerUrlPortrait'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('experienceInfo')) {
      experienceInfo = PlayerExperienceInfo.fromJson(
          _json['experienceInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('friendStatus')) {
      friendStatus = _json['friendStatus'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = PlayerName.fromJson(
          _json['name'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('originalPlayerId')) {
      originalPlayerId = _json['originalPlayerId'] as core.String;
    }
    if (_json.containsKey('playerId')) {
      playerId = _json['playerId'] as core.String;
    }
    if (_json.containsKey('profileSettings')) {
      profileSettings = ProfileSettings.fromJson(
          _json['profileSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (avatarImageUrl != null) 'avatarImageUrl': avatarImageUrl!,
        if (bannerUrlLandscape != null)
          'bannerUrlLandscape': bannerUrlLandscape!,
        if (bannerUrlPortrait != null) 'bannerUrlPortrait': bannerUrlPortrait!,
        if (displayName != null) 'displayName': displayName!,
        if (experienceInfo != null) 'experienceInfo': experienceInfo!.toJson(),
        if (friendStatus != null) 'friendStatus': friendStatus!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!.toJson(),
        if (originalPlayerId != null) 'originalPlayerId': originalPlayerId!,
        if (playerId != null) 'playerId': playerId!,
        if (profileSettings != null)
          'profileSettings': profileSettings!.toJson(),
        if (title != null) 'title': title!,
      };
}

/// An achievement object.
class PlayerAchievement {
  /// The state of the achievement.
  /// Possible string values are:
  /// - "STATE_UNSPECIFIED" : Default value. This value is unused.
  /// - "HIDDEN" : Achievement is hidden.
  /// - "REVEALED" : Achievement is revealed.
  /// - "UNLOCKED" : Achievement is unlocked.
  core.String? achievementState;

  /// The current steps for an incremental achievement.
  core.int? currentSteps;

  /// Experience points earned for the achievement.
  ///
  /// This field is absent for achievements that have not yet been unlocked and
  /// 0 for achievements that have been unlocked by testers but that are
  /// unpublished.
  core.String? experiencePoints;

  /// The current steps for an incremental achievement as a string.
  core.String? formattedCurrentStepsString;

  /// The ID of the achievement.
  core.String? id;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#playerAchievement`.
  core.String? kind;

  /// The timestamp of the last modification to this achievement's state.
  core.String? lastUpdatedTimestamp;

  PlayerAchievement();

  PlayerAchievement.fromJson(core.Map _json) {
    if (_json.containsKey('achievementState')) {
      achievementState = _json['achievementState'] as core.String;
    }
    if (_json.containsKey('currentSteps')) {
      currentSteps = _json['currentSteps'] as core.int;
    }
    if (_json.containsKey('experiencePoints')) {
      experiencePoints = _json['experiencePoints'] as core.String;
    }
    if (_json.containsKey('formattedCurrentStepsString')) {
      formattedCurrentStepsString =
          _json['formattedCurrentStepsString'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastUpdatedTimestamp')) {
      lastUpdatedTimestamp = _json['lastUpdatedTimestamp'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (achievementState != null) 'achievementState': achievementState!,
        if (currentSteps != null) 'currentSteps': currentSteps!,
        if (experiencePoints != null) 'experiencePoints': experiencePoints!,
        if (formattedCurrentStepsString != null)
          'formattedCurrentStepsString': formattedCurrentStepsString!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (lastUpdatedTimestamp != null)
          'lastUpdatedTimestamp': lastUpdatedTimestamp!,
      };
}

/// A list of achievement objects.
class PlayerAchievementListResponse {
  /// The achievements.
  core.List<PlayerAchievement>? items;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#playerAchievementListResponse`.
  core.String? kind;

  /// Token corresponding to the next page of results.
  core.String? nextPageToken;

  PlayerAchievementListResponse();

  PlayerAchievementListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<PlayerAchievement>((value) => PlayerAchievement.fromJson(
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
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// An event status resource.
class PlayerEvent {
  /// The ID of the event definition.
  core.String? definitionId;

  /// The current number of times this event has occurred, as a string.
  ///
  /// The formatting of this string depends on the configuration of your event
  /// in the Play Games Developer Console.
  core.String? formattedNumEvents;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#playerEvent`.
  core.String? kind;

  /// The current number of times this event has occurred.
  core.String? numEvents;

  /// The ID of the player.
  core.String? playerId;

  PlayerEvent();

  PlayerEvent.fromJson(core.Map _json) {
    if (_json.containsKey('definitionId')) {
      definitionId = _json['definitionId'] as core.String;
    }
    if (_json.containsKey('formattedNumEvents')) {
      formattedNumEvents = _json['formattedNumEvents'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('numEvents')) {
      numEvents = _json['numEvents'] as core.String;
    }
    if (_json.containsKey('playerId')) {
      playerId = _json['playerId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (definitionId != null) 'definitionId': definitionId!,
        if (formattedNumEvents != null)
          'formattedNumEvents': formattedNumEvents!,
        if (kind != null) 'kind': kind!,
        if (numEvents != null) 'numEvents': numEvents!,
        if (playerId != null) 'playerId': playerId!,
      };
}

/// A ListByPlayer response.
class PlayerEventListResponse {
  /// The player events.
  core.List<PlayerEvent>? items;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#playerEventListResponse`.
  core.String? kind;

  /// The pagination token for the next page of results.
  core.String? nextPageToken;

  PlayerEventListResponse();

  PlayerEventListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<PlayerEvent>((value) => PlayerEvent.fromJson(
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
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// 1P/3P metadata about the player's experience.
class PlayerExperienceInfo {
  /// The current number of experience points for the player.
  core.String? currentExperiencePoints;

  /// The current level of the player.
  PlayerLevel? currentLevel;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#playerExperienceInfo`.
  core.String? kind;

  /// The timestamp when the player was leveled up, in millis since Unix epoch
  /// UTC.
  core.String? lastLevelUpTimestampMillis;

  /// The next level of the player.
  ///
  /// If the current level is the maximum level, this should be same as the
  /// current level.
  PlayerLevel? nextLevel;

  PlayerExperienceInfo();

  PlayerExperienceInfo.fromJson(core.Map _json) {
    if (_json.containsKey('currentExperiencePoints')) {
      currentExperiencePoints = _json['currentExperiencePoints'] as core.String;
    }
    if (_json.containsKey('currentLevel')) {
      currentLevel = PlayerLevel.fromJson(
          _json['currentLevel'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastLevelUpTimestampMillis')) {
      lastLevelUpTimestampMillis =
          _json['lastLevelUpTimestampMillis'] as core.String;
    }
    if (_json.containsKey('nextLevel')) {
      nextLevel = PlayerLevel.fromJson(
          _json['nextLevel'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentExperiencePoints != null)
          'currentExperiencePoints': currentExperiencePoints!,
        if (currentLevel != null) 'currentLevel': currentLevel!.toJson(),
        if (kind != null) 'kind': kind!,
        if (lastLevelUpTimestampMillis != null)
          'lastLevelUpTimestampMillis': lastLevelUpTimestampMillis!,
        if (nextLevel != null) 'nextLevel': nextLevel!.toJson(),
      };
}

/// A player leaderboard score object.
class PlayerLeaderboardScore {
  /// The rank of the score in the friends collection for this leaderboard.
  LeaderboardScoreRank? friendsRank;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#playerLeaderboardScore`.
  core.String? kind;

  /// The ID of the leaderboard this score is in.
  core.String? leaderboardId;

  /// The public rank of the score in this leaderboard.
  ///
  /// This object will not be present if the user is not sharing their scores
  /// publicly.
  LeaderboardScoreRank? publicRank;

  /// The formatted value of this score.
  core.String? scoreString;

  /// Additional information about the score.
  ///
  /// Values must contain no more than 64 URI-safe characters as defined by
  /// section 2.3 of RFC 3986.
  core.String? scoreTag;

  /// The numerical value of this score.
  core.String? scoreValue;

  /// The social rank of the score in this leaderboard.
  LeaderboardScoreRank? socialRank;

  /// The time span of this score.
  /// Possible string values are:
  /// - "SCORE_TIME_SPAN_UNSPECIFIED" : Default value. This value is unused.
  /// - "ALL_TIME" : The score is an all-time score.
  /// - "WEEKLY" : The score is a weekly score.
  /// - "DAILY" : The score is a daily score.
  core.String? timeSpan;

  /// The timestamp at which this score was recorded, in milliseconds since the
  /// epoch in UTC.
  core.String? writeTimestamp;

  PlayerLeaderboardScore();

  PlayerLeaderboardScore.fromJson(core.Map _json) {
    if (_json.containsKey('friendsRank')) {
      friendsRank = LeaderboardScoreRank.fromJson(
          _json['friendsRank'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('leaderboard_id')) {
      leaderboardId = _json['leaderboard_id'] as core.String;
    }
    if (_json.containsKey('publicRank')) {
      publicRank = LeaderboardScoreRank.fromJson(
          _json['publicRank'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('scoreString')) {
      scoreString = _json['scoreString'] as core.String;
    }
    if (_json.containsKey('scoreTag')) {
      scoreTag = _json['scoreTag'] as core.String;
    }
    if (_json.containsKey('scoreValue')) {
      scoreValue = _json['scoreValue'] as core.String;
    }
    if (_json.containsKey('socialRank')) {
      socialRank = LeaderboardScoreRank.fromJson(
          _json['socialRank'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeSpan')) {
      timeSpan = _json['timeSpan'] as core.String;
    }
    if (_json.containsKey('writeTimestamp')) {
      writeTimestamp = _json['writeTimestamp'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (friendsRank != null) 'friendsRank': friendsRank!.toJson(),
        if (kind != null) 'kind': kind!,
        if (leaderboardId != null) 'leaderboard_id': leaderboardId!,
        if (publicRank != null) 'publicRank': publicRank!.toJson(),
        if (scoreString != null) 'scoreString': scoreString!,
        if (scoreTag != null) 'scoreTag': scoreTag!,
        if (scoreValue != null) 'scoreValue': scoreValue!,
        if (socialRank != null) 'socialRank': socialRank!.toJson(),
        if (timeSpan != null) 'timeSpan': timeSpan!,
        if (writeTimestamp != null) 'writeTimestamp': writeTimestamp!,
      };
}

/// A list of player leaderboard scores.
class PlayerLeaderboardScoreListResponse {
  /// The leaderboard scores.
  core.List<PlayerLeaderboardScore>? items;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string
  /// `games#playerLeaderboardScoreListResponse`.
  core.String? kind;

  /// The pagination token for the next page of results.
  core.String? nextPageToken;

  /// The Player resources for the owner of this score.
  Player? player;

  PlayerLeaderboardScoreListResponse();

  PlayerLeaderboardScoreListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<PlayerLeaderboardScore>((value) =>
              PlayerLeaderboardScore.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('player')) {
      player = Player.fromJson(
          _json['player'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (player != null) 'player': player!.toJson(),
      };
}

/// 1P/3P metadata about a user's level.
class PlayerLevel {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#playerLevel`.
  core.String? kind;

  /// The level for the user.
  core.int? level;

  /// The maximum experience points for this level.
  core.String? maxExperiencePoints;

  /// The minimum experience points for this level.
  core.String? minExperiencePoints;

  PlayerLevel();

  PlayerLevel.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('level')) {
      level = _json['level'] as core.int;
    }
    if (_json.containsKey('maxExperiencePoints')) {
      maxExperiencePoints = _json['maxExperiencePoints'] as core.String;
    }
    if (_json.containsKey('minExperiencePoints')) {
      minExperiencePoints = _json['minExperiencePoints'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (level != null) 'level': level!,
        if (maxExperiencePoints != null)
          'maxExperiencePoints': maxExperiencePoints!,
        if (minExperiencePoints != null)
          'minExperiencePoints': minExperiencePoints!,
      };
}

/// A third party player list response.
class PlayerListResponse {
  /// The players.
  core.List<Player>? items;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#playerListResponse`.
  core.String? kind;

  /// Token corresponding to the next page of results.
  core.String? nextPageToken;

  PlayerListResponse();

  PlayerListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Player>((value) =>
              Player.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A player score.
class PlayerScore {
  /// The formatted score for this player score.
  core.String? formattedScore;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#playerScore`.
  core.String? kind;

  /// The numerical value for this player score.
  core.String? score;

  /// Additional information about this score.
  ///
  /// Values will contain no more than 64 URI-safe characters as defined by
  /// section 2.3 of RFC 3986.
  core.String? scoreTag;

  /// The time span for this player score.
  /// Possible string values are:
  /// - "SCORE_TIME_SPAN_UNSPECIFIED" : Default value. This value is unused.
  /// - "ALL_TIME" : The score is an all-time score.
  /// - "WEEKLY" : The score is a weekly score.
  /// - "DAILY" : The score is a daily score.
  core.String? timeSpan;

  PlayerScore();

  PlayerScore.fromJson(core.Map _json) {
    if (_json.containsKey('formattedScore')) {
      formattedScore = _json['formattedScore'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('score')) {
      score = _json['score'] as core.String;
    }
    if (_json.containsKey('scoreTag')) {
      scoreTag = _json['scoreTag'] as core.String;
    }
    if (_json.containsKey('timeSpan')) {
      timeSpan = _json['timeSpan'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (formattedScore != null) 'formattedScore': formattedScore!,
        if (kind != null) 'kind': kind!,
        if (score != null) 'score': score!,
        if (scoreTag != null) 'scoreTag': scoreTag!,
        if (timeSpan != null) 'timeSpan': timeSpan!,
      };
}

/// A list of score submission statuses.
class PlayerScoreListResponse {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#playerScoreListResponse`.
  core.String? kind;

  /// The score submissions statuses.
  core.List<PlayerScoreResponse>? submittedScores;

  PlayerScoreListResponse();

  PlayerScoreListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('submittedScores')) {
      submittedScores = (_json['submittedScores'] as core.List)
          .map<PlayerScoreResponse>((value) => PlayerScoreResponse.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (submittedScores != null)
          'submittedScores':
              submittedScores!.map((value) => value.toJson()).toList(),
      };
}

/// A list of leaderboard entry resources.
class PlayerScoreResponse {
  /// The time spans where the submitted score is better than the existing score
  /// for that time span.
  core.List<core.String>? beatenScoreTimeSpans;

  /// The formatted value of the submitted score.
  core.String? formattedScore;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#playerScoreResponse`.
  core.String? kind;

  /// The leaderboard ID that this score was submitted to.
  core.String? leaderboardId;

  /// Additional information about this score.
  ///
  /// Values will contain no more than 64 URI-safe characters as defined by
  /// section 2.3 of RFC 3986.
  core.String? scoreTag;

  /// The scores in time spans that have not been beaten.
  ///
  /// As an example, the submitted score may be better than the player's `DAILY`
  /// score, but not better than the player's scores for the `WEEKLY` or
  /// `ALL_TIME` time spans.
  core.List<PlayerScore>? unbeatenScores;

  PlayerScoreResponse();

  PlayerScoreResponse.fromJson(core.Map _json) {
    if (_json.containsKey('beatenScoreTimeSpans')) {
      beatenScoreTimeSpans = (_json['beatenScoreTimeSpans'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('formattedScore')) {
      formattedScore = _json['formattedScore'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('leaderboardId')) {
      leaderboardId = _json['leaderboardId'] as core.String;
    }
    if (_json.containsKey('scoreTag')) {
      scoreTag = _json['scoreTag'] as core.String;
    }
    if (_json.containsKey('unbeatenScores')) {
      unbeatenScores = (_json['unbeatenScores'] as core.List)
          .map<PlayerScore>((value) => PlayerScore.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (beatenScoreTimeSpans != null)
          'beatenScoreTimeSpans': beatenScoreTimeSpans!,
        if (formattedScore != null) 'formattedScore': formattedScore!,
        if (kind != null) 'kind': kind!,
        if (leaderboardId != null) 'leaderboardId': leaderboardId!,
        if (scoreTag != null) 'scoreTag': scoreTag!,
        if (unbeatenScores != null)
          'unbeatenScores':
              unbeatenScores!.map((value) => value.toJson()).toList(),
      };
}

/// A list of score submission requests.
class PlayerScoreSubmissionList {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#playerScoreSubmissionList`.
  core.String? kind;

  /// The score submissions.
  core.List<ScoreSubmission>? scores;

  PlayerScoreSubmissionList();

  PlayerScoreSubmissionList.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('scores')) {
      scores = (_json['scores'] as core.List)
          .map<ScoreSubmission>((value) => ScoreSubmission.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (scores != null)
          'scores': scores!.map((value) => value.toJson()).toList(),
      };
}

/// Profile settings
class ProfileSettings {
  ///
  /// Possible string values are:
  /// - "FRIENDS_LIST_VISIBILITY_UNSPECIFIED" : Unused.
  /// - "VISIBLE" : The friends list is currently visible to the game.
  /// - "REQUEST_REQUIRED" : The developer does not have access to the friends
  /// list, but can call the Android API to show a consent dialog.
  /// - "UNAVAILABLE" : The friends list is currently unavailable for this user,
  /// and it is not possible to request access at this time, either because the
  /// user has permanently declined or the friends feature is not available to
  /// them. In this state, any attempts to request access to the friends list
  /// will be unsuccessful.
  core.String? friendsListVisibility;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#profileSettings`.
  core.String? kind;

  /// Whether the player's profile is visible to the currently signed in player.
  core.bool? profileVisible;

  ProfileSettings();

  ProfileSettings.fromJson(core.Map _json) {
    if (_json.containsKey('friendsListVisibility')) {
      friendsListVisibility = _json['friendsListVisibility'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('profileVisible')) {
      profileVisible = _json['profileVisible'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (friendsListVisibility != null)
          'friendsListVisibility': friendsListVisibility!,
        if (kind != null) 'kind': kind!,
        if (profileVisible != null) 'profileVisible': profileVisible!,
      };
}

/// A third party checking a revision response.
class RevisionCheckResponse {
  /// The version of the API this client revision should use when calling API
  /// methods.
  core.String? apiVersion;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#revisionCheckResponse`.
  core.String? kind;

  /// The result of the revision check.
  /// Possible string values are:
  /// - "REVISION_STATUS_UNSPECIFIED" : Default value. This value is unused.
  /// - "OK" : The revision being used is current.
  /// - "DEPRECATED" : There is currently a newer version available, but the
  /// revision being used still works.
  /// - "INVALID" : The revision being used is not supported in any released
  /// version.
  core.String? revisionStatus;

  RevisionCheckResponse();

  RevisionCheckResponse.fromJson(core.Map _json) {
    if (_json.containsKey('apiVersion')) {
      apiVersion = _json['apiVersion'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('revisionStatus')) {
      revisionStatus = _json['revisionStatus'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiVersion != null) 'apiVersion': apiVersion!,
        if (kind != null) 'kind': kind!,
        if (revisionStatus != null) 'revisionStatus': revisionStatus!,
      };
}

/// A request to submit a score to leaderboards.
class ScoreSubmission {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#scoreSubmission`.
  core.String? kind;

  /// The leaderboard this score is being submitted to.
  core.String? leaderboardId;

  /// The new score being submitted.
  core.String? score;

  /// Additional information about this score.
  ///
  /// Values will contain no more than 64 URI-safe characters as defined by
  /// section 2.3 of RFC 3986.
  core.String? scoreTag;

  /// Signature Values will contain URI-safe characters as defined by section
  /// 2.3 of RFC 3986.
  core.String? signature;

  ScoreSubmission();

  ScoreSubmission.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('leaderboardId')) {
      leaderboardId = _json['leaderboardId'] as core.String;
    }
    if (_json.containsKey('score')) {
      score = _json['score'] as core.String;
    }
    if (_json.containsKey('scoreTag')) {
      scoreTag = _json['scoreTag'] as core.String;
    }
    if (_json.containsKey('signature')) {
      signature = _json['signature'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (leaderboardId != null) 'leaderboardId': leaderboardId!,
        if (score != null) 'score': score!,
        if (scoreTag != null) 'scoreTag': scoreTag!,
        if (signature != null) 'signature': signature!,
      };
}

/// An snapshot object.
class Snapshot {
  /// The cover image of this snapshot.
  ///
  /// May be absent if there is no image.
  SnapshotImage? coverImage;

  /// The description of this snapshot.
  core.String? description;

  /// The ID of the file underlying this snapshot in the Drive API.
  ///
  /// Only present if the snapshot is a view on a Drive file and the file is
  /// owned by the caller.
  core.String? driveId;

  /// The duration associated with this snapshot, in millis.
  core.String? durationMillis;

  /// The ID of the snapshot.
  core.String? id;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#snapshot`.
  core.String? kind;

  /// The timestamp (in millis since Unix epoch) of the last modification to
  /// this snapshot.
  core.String? lastModifiedMillis;

  /// The progress value (64-bit integer set by developer) associated with this
  /// snapshot.
  core.String? progressValue;

  /// The title of this snapshot.
  core.String? title;

  /// The type of this snapshot.
  /// Possible string values are:
  /// - "SNAPSHOT_TYPE_UNSPECIFIED" : Default value. This value is unused.
  /// - "SAVE_GAME" : A snapshot representing a save game.
  core.String? type;

  /// The unique name provided when the snapshot was created.
  core.String? uniqueName;

  Snapshot();

  Snapshot.fromJson(core.Map _json) {
    if (_json.containsKey('coverImage')) {
      coverImage = SnapshotImage.fromJson(
          _json['coverImage'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('driveId')) {
      driveId = _json['driveId'] as core.String;
    }
    if (_json.containsKey('durationMillis')) {
      durationMillis = _json['durationMillis'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lastModifiedMillis')) {
      lastModifiedMillis = _json['lastModifiedMillis'] as core.String;
    }
    if (_json.containsKey('progressValue')) {
      progressValue = _json['progressValue'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('uniqueName')) {
      uniqueName = _json['uniqueName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (coverImage != null) 'coverImage': coverImage!.toJson(),
        if (description != null) 'description': description!,
        if (driveId != null) 'driveId': driveId!,
        if (durationMillis != null) 'durationMillis': durationMillis!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (lastModifiedMillis != null)
          'lastModifiedMillis': lastModifiedMillis!,
        if (progressValue != null) 'progressValue': progressValue!,
        if (title != null) 'title': title!,
        if (type != null) 'type': type!,
        if (uniqueName != null) 'uniqueName': uniqueName!,
      };
}

/// An image of a snapshot.
class SnapshotImage {
  /// The height of the image.
  core.int? height;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#snapshotImage`.
  core.String? kind;

  /// The MIME type of the image.
  core.String? mimeType;

  /// The URL of the image.
  ///
  /// This URL may be invalidated at any time and should not be cached.
  core.String? url;

  /// The width of the image.
  core.int? width;

  SnapshotImage();

  SnapshotImage.fromJson(core.Map _json) {
    if (_json.containsKey('height')) {
      height = _json['height'] as core.int;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('mime_type')) {
      mimeType = _json['mime_type'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
    if (_json.containsKey('width')) {
      width = _json['width'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (height != null) 'height': height!,
        if (kind != null) 'kind': kind!,
        if (mimeType != null) 'mime_type': mimeType!,
        if (url != null) 'url': url!,
        if (width != null) 'width': width!,
      };
}

/// A third party list snapshots response.
class SnapshotListResponse {
  /// The snapshots.
  core.List<Snapshot>? items;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#snapshotListResponse`.
  core.String? kind;

  /// Token corresponding to the next page of results.
  ///
  /// If there are no more results, the token is omitted.
  core.String? nextPageToken;

  SnapshotListResponse();

  SnapshotListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<Snapshot>((value) =>
              Snapshot.fromJson(value as core.Map<core.String, core.dynamic>))
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
        if (items != null)
          'items': items!.map((value) => value.toJson()).toList(),
        if (kind != null) 'kind': kind!,
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// A third party stats resource.
class StatsResponse {
  /// Average session length in minutes of the player.
  ///
  /// E.g., 1, 30, 60, ... . Not populated if there is not enough information.
  core.double? avgSessionLengthMinutes;

  /// The probability of the player not returning to play the game in the next
  /// day.
  ///
  /// E.g., 0, 0.1, 0.5, ..., 1.0. Not populated if there is not enough
  /// information.
  core.double? churnProbability;

  /// Number of days since the player last played this game.
  ///
  /// E.g., 0, 1, 5, 10, ... . Not populated if there is not enough information.
  core.int? daysSinceLastPlayed;

  /// The probability of the player going to spend beyond a threshold amount of
  /// money.
  ///
  /// E.g., 0, 0.25, 0.50, 0.75. Not populated if there is not enough
  /// information.
  core.double? highSpenderProbability;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `games#statsResponse`.
  core.String? kind;

  /// Number of in-app purchases made by the player in this game.
  ///
  /// E.g., 0, 1, 5, 10, ... . Not populated if there is not enough information.
  core.int? numPurchases;

  /// The approximate number of sessions of the player within the last 28 days,
  /// where a session begins when the player is connected to Play Games Services
  /// and ends when they are disconnected.
  ///
  /// E.g., 0, 1, 5, 10, ... . Not populated if there is not enough information.
  core.int? numSessions;

  /// The approximation of the sessions percentile of the player within the last
  /// 30 days, where a session begins when the player is connected to Play Games
  /// Services and ends when they are disconnected.
  ///
  /// E.g., 0, 0.25, 0.5, 0.75. Not populated if there is not enough
  /// information.
  core.double? numSessionsPercentile;

  /// The approximate spend percentile of the player in this game.
  ///
  /// E.g., 0, 0.25, 0.5, 0.75. Not populated if there is not enough
  /// information.
  core.double? spendPercentile;

  /// The probability of the player going to spend the game in the next seven
  /// days.
  ///
  /// E.g., 0, 0.25, 0.50, 0.75. Not populated if there is not enough
  /// information.
  core.double? spendProbability;

  /// The predicted amount of money that the player going to spend in the next
  /// 28 days.
  ///
  /// E.g., 1, 30, 60, ... . Not populated if there is not enough information.
  core.double? totalSpendNext28Days;

  StatsResponse();

  StatsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('avg_session_length_minutes')) {
      avgSessionLengthMinutes =
          (_json['avg_session_length_minutes'] as core.num).toDouble();
    }
    if (_json.containsKey('churn_probability')) {
      churnProbability = (_json['churn_probability'] as core.num).toDouble();
    }
    if (_json.containsKey('days_since_last_played')) {
      daysSinceLastPlayed = _json['days_since_last_played'] as core.int;
    }
    if (_json.containsKey('high_spender_probability')) {
      highSpenderProbability =
          (_json['high_spender_probability'] as core.num).toDouble();
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('num_purchases')) {
      numPurchases = _json['num_purchases'] as core.int;
    }
    if (_json.containsKey('num_sessions')) {
      numSessions = _json['num_sessions'] as core.int;
    }
    if (_json.containsKey('num_sessions_percentile')) {
      numSessionsPercentile =
          (_json['num_sessions_percentile'] as core.num).toDouble();
    }
    if (_json.containsKey('spend_percentile')) {
      spendPercentile = (_json['spend_percentile'] as core.num).toDouble();
    }
    if (_json.containsKey('spend_probability')) {
      spendProbability = (_json['spend_probability'] as core.num).toDouble();
    }
    if (_json.containsKey('total_spend_next_28_days')) {
      totalSpendNext28Days =
          (_json['total_spend_next_28_days'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (avgSessionLengthMinutes != null)
          'avg_session_length_minutes': avgSessionLengthMinutes!,
        if (churnProbability != null) 'churn_probability': churnProbability!,
        if (daysSinceLastPlayed != null)
          'days_since_last_played': daysSinceLastPlayed!,
        if (highSpenderProbability != null)
          'high_spender_probability': highSpenderProbability!,
        if (kind != null) 'kind': kind!,
        if (numPurchases != null) 'num_purchases': numPurchases!,
        if (numSessions != null) 'num_sessions': numSessions!,
        if (numSessionsPercentile != null)
          'num_sessions_percentile': numSessionsPercentile!,
        if (spendPercentile != null) 'spend_percentile': spendPercentile!,
        if (spendProbability != null) 'spend_probability': spendProbability!,
        if (totalSpendNext28Days != null)
          'total_spend_next_28_days': totalSpendNext28Days!,
      };
}
