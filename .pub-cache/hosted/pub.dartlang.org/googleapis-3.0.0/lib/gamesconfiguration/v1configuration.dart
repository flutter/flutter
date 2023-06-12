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

/// Google Play Game Services Publishing API - v1configuration
///
/// The Google Play Game Services Publishing API allows developers to configure
/// their games in Game Services.
///
/// For more information, see <https://developers.google.com/games/>
///
/// Create an instance of [GamesConfigurationApi] to access these resources:
///
/// - [AchievementConfigurationsResource]
/// - [ImageConfigurationsResource]
/// - [LeaderboardConfigurationsResource]
library gamesConfiguration.v1configuration;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show
        ApiRequestError,
        DetailedApiRequestError,
        Media,
        UploadOptions,
        ResumableUploadOptions,
        DownloadOptions,
        PartialDownloadOptions,
        ByteRange;

/// The Google Play Game Services Publishing API allows developers to configure
/// their games in Game Services.
class GamesConfigurationApi {
  /// View and manage your Google Play Developer account
  static const androidpublisherScope =
      'https://www.googleapis.com/auth/androidpublisher';

  final commons.ApiRequester _requester;

  AchievementConfigurationsResource get achievementConfigurations =>
      AchievementConfigurationsResource(_requester);
  ImageConfigurationsResource get imageConfigurations =>
      ImageConfigurationsResource(_requester);
  LeaderboardConfigurationsResource get leaderboardConfigurations =>
      LeaderboardConfigurationsResource(_requester);

  GamesConfigurationApi(http.Client client,
      {core.String rootUrl = 'https://gamesconfiguration.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class AchievementConfigurationsResource {
  final commons.ApiRequester _requester;

  AchievementConfigurationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Delete the achievement configuration with the given ID.
  ///
  /// Request parameters:
  ///
  /// [achievementId] - The ID of the achievement used by this method.
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
    core.String achievementId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1configuration/achievements/' +
        commons.escapeVariable('$achievementId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves the metadata of the achievement configuration with the given ID.
  ///
  /// Request parameters:
  ///
  /// [achievementId] - The ID of the achievement used by this method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AchievementConfiguration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AchievementConfiguration> get(
    core.String achievementId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1configuration/achievements/' +
        commons.escapeVariable('$achievementId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AchievementConfiguration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Insert a new achievement configuration in this application.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [applicationId] - The application ID from the Google Play developer
  /// console.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AchievementConfiguration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AchievementConfiguration> insert(
    AchievementConfiguration request,
    core.String applicationId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1configuration/applications/' +
        commons.escapeVariable('$applicationId') +
        '/achievements';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AchievementConfiguration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns a list of the achievement configurations in this application.
  ///
  /// Request parameters:
  ///
  /// [applicationId] - The application ID from the Google Play developer
  /// console.
  ///
  /// [maxResults] - The maximum number of resource configurations to return in
  /// the response, used for paging. For any response, the actual number of
  /// resources returned may be less than the specified `maxResults`.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AchievementConfigurationListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AchievementConfigurationListResponse> list(
    core.String applicationId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1configuration/applications/' +
        commons.escapeVariable('$applicationId') +
        '/achievements';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return AchievementConfigurationListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update the metadata of the achievement configuration with the given ID.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [achievementId] - The ID of the achievement used by this method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AchievementConfiguration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AchievementConfiguration> update(
    AchievementConfiguration request,
    core.String achievementId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1configuration/achievements/' +
        commons.escapeVariable('$achievementId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return AchievementConfiguration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ImageConfigurationsResource {
  final commons.ApiRequester _requester;

  ImageConfigurationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Uploads an image for a resource with the given ID and image type.
  ///
  /// Request parameters:
  ///
  /// [resourceId] - The ID of the resource used by this method.
  ///
  /// [imageType] - Selects which image in a resource for this method.
  /// Possible string values are:
  /// - "IMAGE_TYPE_UNSPECIFIED" : Default value. This value is unused.
  /// - "ACHIEVEMENT_ICON" : The icon image for an achievement resource.
  /// - "LEADERBOARD_ICON" : The icon image for a leaderboard resource.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// [uploadMedia] - The media to upload.
  ///
  /// Completes with a [ImageConfiguration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ImageConfiguration> upload(
    core.String resourceId,
    core.String imageType, {
    core.String? $fields,
    commons.Media? uploadMedia,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    core.String _url;
    if (uploadMedia == null) {
      _url = 'games/v1configuration/images/' +
          commons.escapeVariable('$resourceId') +
          '/imageType/' +
          commons.escapeVariable('$imageType');
    } else {
      _url = '/upload/games/v1configuration/images/' +
          commons.escapeVariable('$resourceId') +
          '/imageType/' +
          commons.escapeVariable('$imageType');
    }

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
      uploadMedia: uploadMedia,
      uploadOptions: commons.UploadOptions.defaultOptions,
    );
    return ImageConfiguration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class LeaderboardConfigurationsResource {
  final commons.ApiRequester _requester;

  LeaderboardConfigurationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Delete the leaderboard configuration with the given ID.
  ///
  /// Request parameters:
  ///
  /// [leaderboardId] - The ID of the leaderboard.
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
    core.String leaderboardId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1configuration/leaderboards/' +
        commons.escapeVariable('$leaderboardId');

    await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
      downloadOptions: null,
    );
  }

  /// Retrieves the metadata of the leaderboard configuration with the given ID.
  ///
  /// Request parameters:
  ///
  /// [leaderboardId] - The ID of the leaderboard.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LeaderboardConfiguration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LeaderboardConfiguration> get(
    core.String leaderboardId, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1configuration/leaderboards/' +
        commons.escapeVariable('$leaderboardId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LeaderboardConfiguration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Insert a new leaderboard configuration in this application.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [applicationId] - The application ID from the Google Play developer
  /// console.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LeaderboardConfiguration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LeaderboardConfiguration> insert(
    LeaderboardConfiguration request,
    core.String applicationId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1configuration/applications/' +
        commons.escapeVariable('$applicationId') +
        '/leaderboards';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return LeaderboardConfiguration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns a list of the leaderboard configurations in this application.
  ///
  /// Request parameters:
  ///
  /// [applicationId] - The application ID from the Google Play developer
  /// console.
  ///
  /// [maxResults] - The maximum number of resource configurations to return in
  /// the response, used for paging. For any response, the actual number of
  /// resources returned may be less than the specified `maxResults`.
  ///
  /// [pageToken] - The token returned by the previous request.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LeaderboardConfigurationListResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LeaderboardConfigurationListResponse> list(
    core.String applicationId, {
    core.int? maxResults,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (maxResults != null) 'maxResults': ['${maxResults}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1configuration/applications/' +
        commons.escapeVariable('$applicationId') +
        '/leaderboards';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return LeaderboardConfigurationListResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Update the metadata of the leaderboard configuration with the given ID.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [leaderboardId] - The ID of the leaderboard.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [LeaderboardConfiguration].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<LeaderboardConfiguration> update(
    LeaderboardConfiguration request,
    core.String leaderboardId, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'games/v1configuration/leaderboards/' +
        commons.escapeVariable('$leaderboardId');

    final _response = await _requester.request(
      _url,
      'PUT',
      body: _body,
      queryParams: _queryParams,
    );
    return LeaderboardConfiguration.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// An achievement configuration resource.
class AchievementConfiguration {
  /// The type of the achievement.
  /// Possible string values are:
  /// - "ACHIEVEMENT_TYPE_UNSPECIFIED" : Default value. This value is unused.
  /// - "STANDARD" : Achievement is either locked or unlocked.
  /// - "INCREMENTAL" : Achievement is incremental.
  core.String? achievementType;

  /// The draft data of the achievement.
  AchievementConfigurationDetail? draft;

  /// The ID of the achievement.
  core.String? id;

  /// The initial state of the achievement.
  /// Possible string values are:
  /// - "INITIAL_STATE_UNSPECIFIED" : Default value. This value is unused.
  /// - "HIDDEN" : Achievement is hidden.
  /// - "REVEALED" : Achievement is revealed.
  core.String? initialState;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string
  /// `gamesConfiguration#achievementConfiguration`.
  core.String? kind;

  /// The read-only published data of the achievement.
  AchievementConfigurationDetail? published;

  /// Steps to unlock.
  ///
  /// Only applicable to incremental achievements.
  core.int? stepsToUnlock;

  /// The token for this resource.
  core.String? token;

  AchievementConfiguration();

  AchievementConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('achievementType')) {
      achievementType = _json['achievementType'] as core.String;
    }
    if (_json.containsKey('draft')) {
      draft = AchievementConfigurationDetail.fromJson(
          _json['draft'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('initialState')) {
      initialState = _json['initialState'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('published')) {
      published = AchievementConfigurationDetail.fromJson(
          _json['published'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('stepsToUnlock')) {
      stepsToUnlock = _json['stepsToUnlock'] as core.int;
    }
    if (_json.containsKey('token')) {
      token = _json['token'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (achievementType != null) 'achievementType': achievementType!,
        if (draft != null) 'draft': draft!.toJson(),
        if (id != null) 'id': id!,
        if (initialState != null) 'initialState': initialState!,
        if (kind != null) 'kind': kind!,
        if (published != null) 'published': published!.toJson(),
        if (stepsToUnlock != null) 'stepsToUnlock': stepsToUnlock!,
        if (token != null) 'token': token!,
      };
}

/// An achievement configuration detail.
class AchievementConfigurationDetail {
  /// Localized strings for the achievement description.
  LocalizedStringBundle? description;

  /// The icon url of this achievement.
  ///
  /// Writes to this field are ignored.
  core.String? iconUrl;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string
  /// `gamesConfiguration#achievementConfigurationDetail`.
  core.String? kind;

  /// Localized strings for the achievement name.
  LocalizedStringBundle? name;

  /// Point value for the achievement.
  core.int? pointValue;

  /// The sort rank of this achievement.
  ///
  /// Writes to this field are ignored.
  core.int? sortRank;

  AchievementConfigurationDetail();

  AchievementConfigurationDetail.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = LocalizedStringBundle.fromJson(
          _json['description'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('iconUrl')) {
      iconUrl = _json['iconUrl'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = LocalizedStringBundle.fromJson(
          _json['name'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pointValue')) {
      pointValue = _json['pointValue'] as core.int;
    }
    if (_json.containsKey('sortRank')) {
      sortRank = _json['sortRank'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!.toJson(),
        if (iconUrl != null) 'iconUrl': iconUrl!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!.toJson(),
        if (pointValue != null) 'pointValue': pointValue!,
        if (sortRank != null) 'sortRank': sortRank!,
      };
}

/// A ListConfigurations response.
class AchievementConfigurationListResponse {
  /// The achievement configurations.
  core.List<AchievementConfiguration>? items;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string
  /// `gamesConfiguration#achievementConfigurationListResponse`.
  core.String? kind;

  /// The pagination token for the next page of results.
  core.String? nextPageToken;

  AchievementConfigurationListResponse();

  AchievementConfigurationListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<AchievementConfiguration>((value) =>
              AchievementConfiguration.fromJson(
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

/// A number affix resource.
class GamesNumberAffixConfiguration {
  /// When the language requires special treatment of "small" numbers (as with
  /// 2, 3, and 4 in Czech; or numbers ending 2, 3, or 4 but not 12, 13, or 14
  /// in Polish).
  LocalizedStringBundle? few;

  /// When the language requires special treatment of "large" numbers (as with
  /// numbers ending 11-99 in Maltese).
  LocalizedStringBundle? many;

  /// When the language requires special treatment of numbers like one (as with
  /// the number 1 in English and most other languages; in Russian, any number
  /// ending in 1 but not ending in 11 is in this class).
  LocalizedStringBundle? one;

  /// When the language does not require special treatment of the given quantity
  /// (as with all numbers in Chinese, or 42 in English).
  LocalizedStringBundle? other;

  /// When the language requires special treatment of numbers like two (as with
  /// 2 in Welsh, or 102 in Slovenian).
  LocalizedStringBundle? two;

  /// When the language requires special treatment of the number 0 (as in
  /// Arabic).
  LocalizedStringBundle? zero;

  GamesNumberAffixConfiguration();

  GamesNumberAffixConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('few')) {
      few = LocalizedStringBundle.fromJson(
          _json['few'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('many')) {
      many = LocalizedStringBundle.fromJson(
          _json['many'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('one')) {
      one = LocalizedStringBundle.fromJson(
          _json['one'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('other')) {
      other = LocalizedStringBundle.fromJson(
          _json['other'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('two')) {
      two = LocalizedStringBundle.fromJson(
          _json['two'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('zero')) {
      zero = LocalizedStringBundle.fromJson(
          _json['zero'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (few != null) 'few': few!.toJson(),
        if (many != null) 'many': many!.toJson(),
        if (one != null) 'one': one!.toJson(),
        if (other != null) 'other': other!.toJson(),
        if (two != null) 'two': two!.toJson(),
        if (zero != null) 'zero': zero!.toJson(),
      };
}

/// A number format resource.
class GamesNumberFormatConfiguration {
  /// The curreny code string.
  ///
  /// Only used for CURRENCY format type.
  core.String? currencyCode;

  /// The number of decimal places for number.
  ///
  /// Only used for NUMERIC format type.
  core.int? numDecimalPlaces;

  /// The formatting for the number.
  /// Possible string values are:
  /// - "NUMBER_FORMAT_TYPE_UNSPECIFIED" : Default value. This value is unused.
  /// - "NUMERIC" : Numbers are formatted to have no digits or fixed number of
  /// digits after the decimal point according to locale. An optional custom
  /// unit can be added.
  /// - "TIME_DURATION" : Numbers are formatted to hours, minutes and seconds.
  /// - "CURRENCY" : Numbers are formatted to currency according to locale.
  core.String? numberFormatType;

  /// An optional suffix for the NUMERIC format type.
  ///
  /// These strings follow the same plural rules as all Android string
  /// resources.
  GamesNumberAffixConfiguration? suffix;

  GamesNumberFormatConfiguration();

  GamesNumberFormatConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('numDecimalPlaces')) {
      numDecimalPlaces = _json['numDecimalPlaces'] as core.int;
    }
    if (_json.containsKey('numberFormatType')) {
      numberFormatType = _json['numberFormatType'] as core.String;
    }
    if (_json.containsKey('suffix')) {
      suffix = GamesNumberAffixConfiguration.fromJson(
          _json['suffix'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (numDecimalPlaces != null) 'numDecimalPlaces': numDecimalPlaces!,
        if (numberFormatType != null) 'numberFormatType': numberFormatType!,
        if (suffix != null) 'suffix': suffix!.toJson(),
      };
}

/// An image configuration resource.
class ImageConfiguration {
  /// The image type for the image.
  /// Possible string values are:
  /// - "IMAGE_TYPE_UNSPECIFIED" : Default value. This value is unused.
  /// - "ACHIEVEMENT_ICON" : The icon image for an achievement resource.
  /// - "LEADERBOARD_ICON" : The icon image for a leaderboard resource.
  core.String? imageType;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `gamesConfiguration#imageConfiguration`.
  core.String? kind;

  /// The resource ID of resource which the image belongs to.
  core.String? resourceId;

  /// The url for this image.
  core.String? url;

  ImageConfiguration();

  ImageConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('imageType')) {
      imageType = _json['imageType'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('resourceId')) {
      resourceId = _json['resourceId'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (imageType != null) 'imageType': imageType!,
        if (kind != null) 'kind': kind!,
        if (resourceId != null) 'resourceId': resourceId!,
        if (url != null) 'url': url!,
      };
}

/// An leaderboard configuration resource.
class LeaderboardConfiguration {
  /// The draft data of the leaderboard.
  LeaderboardConfigurationDetail? draft;

  /// The ID of the leaderboard.
  core.String? id;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string
  /// `gamesConfiguration#leaderboardConfiguration`.
  core.String? kind;

  /// The read-only published data of the leaderboard.
  LeaderboardConfigurationDetail? published;

  /// Maximum score that can be posted to this leaderboard.
  core.String? scoreMax;

  /// Minimum score that can be posted to this leaderboard.
  core.String? scoreMin;

  ///
  /// Possible string values are:
  /// - "SCORE_ORDER_UNSPECIFIED" : Default value. This value is unused.
  /// - "LARGER_IS_BETTER" : Larger scores posted are ranked higher.
  /// - "SMALLER_IS_BETTER" : Smaller scores posted are ranked higher.
  core.String? scoreOrder;

  /// The token for this resource.
  core.String? token;

  LeaderboardConfiguration();

  LeaderboardConfiguration.fromJson(core.Map _json) {
    if (_json.containsKey('draft')) {
      draft = LeaderboardConfigurationDetail.fromJson(
          _json['draft'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('published')) {
      published = LeaderboardConfigurationDetail.fromJson(
          _json['published'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('scoreMax')) {
      scoreMax = _json['scoreMax'] as core.String;
    }
    if (_json.containsKey('scoreMin')) {
      scoreMin = _json['scoreMin'] as core.String;
    }
    if (_json.containsKey('scoreOrder')) {
      scoreOrder = _json['scoreOrder'] as core.String;
    }
    if (_json.containsKey('token')) {
      token = _json['token'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (draft != null) 'draft': draft!.toJson(),
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (published != null) 'published': published!.toJson(),
        if (scoreMax != null) 'scoreMax': scoreMax!,
        if (scoreMin != null) 'scoreMin': scoreMin!,
        if (scoreOrder != null) 'scoreOrder': scoreOrder!,
        if (token != null) 'token': token!,
      };
}

/// A leaderboard configuration detail.
class LeaderboardConfigurationDetail {
  /// The icon url of this leaderboard.
  ///
  /// Writes to this field are ignored.
  core.String? iconUrl;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string
  /// `gamesConfiguration#leaderboardConfigurationDetail`.
  core.String? kind;

  /// Localized strings for the leaderboard name.
  LocalizedStringBundle? name;

  /// The score formatting for the leaderboard.
  GamesNumberFormatConfiguration? scoreFormat;

  /// The sort rank of this leaderboard.
  ///
  /// Writes to this field are ignored.
  core.int? sortRank;

  LeaderboardConfigurationDetail();

  LeaderboardConfigurationDetail.fromJson(core.Map _json) {
    if (_json.containsKey('iconUrl')) {
      iconUrl = _json['iconUrl'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = LocalizedStringBundle.fromJson(
          _json['name'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('scoreFormat')) {
      scoreFormat = GamesNumberFormatConfiguration.fromJson(
          _json['scoreFormat'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sortRank')) {
      sortRank = _json['sortRank'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (iconUrl != null) 'iconUrl': iconUrl!,
        if (kind != null) 'kind': kind!,
        if (name != null) 'name': name!.toJson(),
        if (scoreFormat != null) 'scoreFormat': scoreFormat!.toJson(),
        if (sortRank != null) 'sortRank': sortRank!,
      };
}

/// A ListConfigurations response.
class LeaderboardConfigurationListResponse {
  /// The leaderboard configurations.
  core.List<LeaderboardConfiguration>? items;

  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string
  /// `gamesConfiguration#leaderboardConfigurationListResponse`.
  core.String? kind;

  /// The pagination token for the next page of results.
  core.String? nextPageToken;

  LeaderboardConfigurationListResponse();

  LeaderboardConfigurationListResponse.fromJson(core.Map _json) {
    if (_json.containsKey('items')) {
      items = (_json['items'] as core.List)
          .map<LeaderboardConfiguration>((value) =>
              LeaderboardConfiguration.fromJson(
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

/// A localized string resource.
class LocalizedString {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string `gamesConfiguration#localizedString`.
  core.String? kind;

  /// The locale string.
  core.String? locale;

  /// The string value.
  core.String? value;

  LocalizedString();

  LocalizedString.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('locale')) {
      locale = _json['locale'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (locale != null) 'locale': locale!,
        if (value != null) 'value': value!,
      };
}

/// A localized string bundle resource.
class LocalizedStringBundle {
  /// Uniquely identifies the type of this resource.
  ///
  /// Value is always the fixed string
  /// `gamesConfiguration#localizedStringBundle`.
  core.String? kind;

  /// The locale strings.
  core.List<LocalizedString>? translations;

  LocalizedStringBundle();

  LocalizedStringBundle.fromJson(core.Map _json) {
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('translations')) {
      translations = (_json['translations'] as core.List)
          .map<LocalizedString>((value) => LocalizedString.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (kind != null) 'kind': kind!,
        if (translations != null)
          'translations': translations!.map((value) => value.toJson()).toList(),
      };
}
