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

/// Playable Locations API - v3
///
/// For more information, see
/// <https://developers.google.com/maps/contact-sales/>
///
/// Create an instance of [PlayableLocationsApi] to access these resources:
///
/// - [V3Resource]
library playablelocations.v3;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

class PlayableLocationsApi {
  final commons.ApiRequester _requester;

  V3Resource get v3 => V3Resource(_requester);

  PlayableLocationsApi(http.Client client,
      {core.String rootUrl = 'https://playablelocations.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class V3Resource {
  final commons.ApiRequester _requester;

  V3Resource(commons.ApiRequester client) : _requester = client;

  /// Logs new events when playable locations are displayed, and when they are
  /// interacted with.
  ///
  /// Impressions are not partially saved; either all impressions are saved and
  /// this request succeeds, or no impressions are saved, and this request
  /// fails.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleMapsPlayablelocationsV3LogImpressionsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleMapsPlayablelocationsV3LogImpressionsResponse>
      logImpressions(
    GoogleMapsPlayablelocationsV3LogImpressionsRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v3:logImpressions';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleMapsPlayablelocationsV3LogImpressionsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Logs bad playable location reports submitted by players.
  ///
  /// Reports are not partially saved; either all reports are saved and this
  /// request succeeds, or no reports are saved, and this request fails.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleMapsPlayablelocationsV3LogPlayerReportsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleMapsPlayablelocationsV3LogPlayerReportsResponse>
      logPlayerReports(
    GoogleMapsPlayablelocationsV3LogPlayerReportsRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v3:logPlayerReports';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleMapsPlayablelocationsV3LogPlayerReportsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns a set of playable locations that lie within a specified area, that
  /// satisfy optional filter criteria.
  ///
  /// Note: Identical `SamplePlayableLocations` requests can return different
  /// results as the state of the world changes over time.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse>
      samplePlayableLocations(
    GoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v3:samplePlayableLocations';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse
        .fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// Encapsulates impression event details.
class GoogleMapsPlayablelocationsV3Impression {
  /// An arbitrary, developer-defined type identifier for each type of game
  /// object used in your game.
  ///
  /// Since players interact with differ types of game objects in different
  /// ways, this field allows you to segregate impression data by type for
  /// analysis. You should assign a unique `game_object_type` ID to represent a
  /// distinct type of game object in your game. For example, 1=monster
  /// location, 2=powerup location.
  core.int? gameObjectType;

  /// The type of impression event.
  ///
  /// Required.
  /// Possible string values are:
  /// - "IMPRESSION_TYPE_UNSPECIFIED" : Unspecified type. Do not use.
  /// - "PRESENTED" : The playable location was presented to a player.
  /// - "INTERACTED" : A player interacted with the playable location.
  core.String? impressionType;

  /// The name of the playable location.
  ///
  /// Required.
  core.String? locationName;

  GoogleMapsPlayablelocationsV3Impression();

  GoogleMapsPlayablelocationsV3Impression.fromJson(core.Map _json) {
    if (_json.containsKey('gameObjectType')) {
      gameObjectType = _json['gameObjectType'] as core.int;
    }
    if (_json.containsKey('impressionType')) {
      impressionType = _json['impressionType'] as core.String;
    }
    if (_json.containsKey('locationName')) {
      locationName = _json['locationName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (gameObjectType != null) 'gameObjectType': gameObjectType!,
        if (impressionType != null) 'impressionType': impressionType!,
        if (locationName != null) 'locationName': locationName!,
      };
}

/// A request for logging impressions.
class GoogleMapsPlayablelocationsV3LogImpressionsRequest {
  /// Information about the client device.
  ///
  /// For example, device model and operating system.
  ///
  /// Required.
  GoogleMapsUnityClientInfo? clientInfo;

  /// Impression event details.
  ///
  /// The maximum number of impression reports that you can log at once is 50.
  ///
  /// Required.
  core.List<GoogleMapsPlayablelocationsV3Impression>? impressions;

  /// A string that uniquely identifies the log impressions request.
  ///
  /// This allows you to detect duplicate requests. We recommend that you use
  /// UUIDs for this value. The value must not exceed 50 characters. You should
  /// reuse the `request_id` only when retrying a request in case of failure. In
  /// this case, the request must be identical to the one that failed.
  ///
  /// Required.
  core.String? requestId;

  GoogleMapsPlayablelocationsV3LogImpressionsRequest();

  GoogleMapsPlayablelocationsV3LogImpressionsRequest.fromJson(core.Map _json) {
    if (_json.containsKey('clientInfo')) {
      clientInfo = GoogleMapsUnityClientInfo.fromJson(
          _json['clientInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('impressions')) {
      impressions = (_json['impressions'] as core.List)
          .map<GoogleMapsPlayablelocationsV3Impression>((value) =>
              GoogleMapsPlayablelocationsV3Impression.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clientInfo != null) 'clientInfo': clientInfo!.toJson(),
        if (impressions != null)
          'impressions': impressions!.map((value) => value.toJson()).toList(),
        if (requestId != null) 'requestId': requestId!,
      };
}

/// A response for the LogImpressions method.
///
/// This method returns no data upon success.
class GoogleMapsPlayablelocationsV3LogImpressionsResponse {
  GoogleMapsPlayablelocationsV3LogImpressionsResponse();

  GoogleMapsPlayablelocationsV3LogImpressionsResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A request for logging your player's bad location reports.
class GoogleMapsPlayablelocationsV3LogPlayerReportsRequest {
  /// Information about the client device (for example, device model and
  /// operating system).
  ///
  /// Required.
  GoogleMapsUnityClientInfo? clientInfo;

  /// Player reports.
  ///
  /// The maximum number of player reports that you can log at once is 50.
  ///
  /// Required.
  core.List<GoogleMapsPlayablelocationsV3PlayerReport>? playerReports;

  /// A string that uniquely identifies the log player reports request.
  ///
  /// This allows you to detect duplicate requests. We recommend that you use
  /// UUIDs for this value. The value must not exceed 50 characters. You should
  /// reuse the `request_id` only when retrying a request in the case of a
  /// failure. In that case, the request must be identical to the one that
  /// failed.
  ///
  /// Required.
  core.String? requestId;

  GoogleMapsPlayablelocationsV3LogPlayerReportsRequest();

  GoogleMapsPlayablelocationsV3LogPlayerReportsRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('clientInfo')) {
      clientInfo = GoogleMapsUnityClientInfo.fromJson(
          _json['clientInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('playerReports')) {
      playerReports = (_json['playerReports'] as core.List)
          .map<GoogleMapsPlayablelocationsV3PlayerReport>((value) =>
              GoogleMapsPlayablelocationsV3PlayerReport.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('requestId')) {
      requestId = _json['requestId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clientInfo != null) 'clientInfo': clientInfo!.toJson(),
        if (playerReports != null)
          'playerReports':
              playerReports!.map((value) => value.toJson()).toList(),
        if (requestId != null) 'requestId': requestId!,
      };
}

/// A response for the LogPlayerReports method.
///
/// This method returns no data upon success.
class GoogleMapsPlayablelocationsV3LogPlayerReportsResponse {
  GoogleMapsPlayablelocationsV3LogPlayerReportsResponse();

  GoogleMapsPlayablelocationsV3LogPlayerReportsResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A report submitted by a player about a playable location that is considered
/// inappropriate for use in the game.
class GoogleMapsPlayablelocationsV3PlayerReport {
  /// Language code (in BCP-47 format) indicating the language of the freeform
  /// description provided in `reason_details`.
  ///
  /// Examples are "en", "en-US" or "ja-Latn". For more information, see
  /// http://www.unicode.org/reports/tr35/#Unicode_locale_identifier.
  core.String? languageCode;

  /// The name of the playable location.
  ///
  /// Required.
  core.String? locationName;

  /// A free-form description detailing why the playable location is considered
  /// bad.
  ///
  /// Required.
  core.String? reasonDetails;

  /// One or more reasons why this playable location is considered bad.
  ///
  /// Required.
  core.List<core.String>? reasons;

  GoogleMapsPlayablelocationsV3PlayerReport();

  GoogleMapsPlayablelocationsV3PlayerReport.fromJson(core.Map _json) {
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('locationName')) {
      locationName = _json['locationName'] as core.String;
    }
    if (_json.containsKey('reasonDetails')) {
      reasonDetails = _json['reasonDetails'] as core.String;
    }
    if (_json.containsKey('reasons')) {
      reasons = (_json['reasons'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (languageCode != null) 'languageCode': languageCode!,
        if (locationName != null) 'locationName': locationName!,
        if (reasonDetails != null) 'reasonDetails': reasonDetails!,
        if (reasons != null) 'reasons': reasons!,
      };
}

/// Specifies the area to search for playable locations.
class GoogleMapsPlayablelocationsV3SampleAreaFilter {
  /// The S2 cell ID of the area you want.
  ///
  /// This must be between cell level 11 and 14 (inclusive). S2 cells are 64-bit
  /// integers that identify areas on the Earth. They are hierarchical, and can
  /// therefore be used for spatial indexing. The S2 geometry library is
  /// available in a number of languages: *
  /// \[C++\](https://github.com/google/s2geometry) *
  /// [Java](https://github.com/google/s2-geometry-library-java) *
  /// [Go](https://github.com/golang/geo) *
  /// [Python](https://github.com/google/s2geometry/tree/master/src/python)
  ///
  /// Required.
  core.String? s2CellId;

  GoogleMapsPlayablelocationsV3SampleAreaFilter();

  GoogleMapsPlayablelocationsV3SampleAreaFilter.fromJson(core.Map _json) {
    if (_json.containsKey('s2CellId')) {
      s2CellId = _json['s2CellId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (s2CellId != null) 's2CellId': s2CellId!,
      };
}

/// Encapsulates a filter criterion for searching for a set of playable
/// locations.
class GoogleMapsPlayablelocationsV3SampleCriterion {
  /// Specifies which `PlayableLocation` fields are returned.
  ///
  /// `name` (which is used for logging impressions), `center_point` and
  /// `place_id` (or `plus_code`) are always returned. The following fields are
  /// omitted unless you specify them here: * snapped_point * types Note: The
  /// more fields you include, the more expensive in terms of data and
  /// associated latency your query will be.
  core.String? fieldsToReturn;

  /// Specifies filtering options, and specifies what will be included in the
  /// result set.
  GoogleMapsPlayablelocationsV3SampleFilter? filter;

  /// An arbitrary, developer-defined identifier of the type of game object that
  /// the playable location is used for.
  ///
  /// This field allows you to specify criteria per game object type when
  /// searching for playable locations. You should assign a unique
  /// `game_object_type` ID across all `request_criteria` to represent a
  /// distinct type of game object. For example, 1=monster location, 2=powerup
  /// location. The response contains a map.
  ///
  /// Required.
  core.int? gameObjectType;

  GoogleMapsPlayablelocationsV3SampleCriterion();

  GoogleMapsPlayablelocationsV3SampleCriterion.fromJson(core.Map _json) {
    if (_json.containsKey('fieldsToReturn')) {
      fieldsToReturn = _json['fieldsToReturn'] as core.String;
    }
    if (_json.containsKey('filter')) {
      filter = GoogleMapsPlayablelocationsV3SampleFilter.fromJson(
          _json['filter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('gameObjectType')) {
      gameObjectType = _json['gameObjectType'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (fieldsToReturn != null) 'fieldsToReturn': fieldsToReturn!,
        if (filter != null) 'filter': filter!.toJson(),
        if (gameObjectType != null) 'gameObjectType': gameObjectType!,
      };
}

/// Specifies the filters to use when searching for playable locations.
class GoogleMapsPlayablelocationsV3SampleFilter {
  /// Restricts the set of playable locations to just the
  /// \[types\](/maps/documentation/gaming/tt/types) that you want.
  core.List<core.String>? includedTypes;

  /// Specifies the maximum number of playable locations to return.
  ///
  /// This value must not be greater than 1000. The default value is 100. Only
  /// the top-ranking playable locations are returned.
  core.int? maxLocationCount;

  /// A set of options that control the spacing between playable locations.
  ///
  /// By default the minimum distance between locations is 200m.
  GoogleMapsPlayablelocationsV3SampleSpacingOptions? spacing;

  GoogleMapsPlayablelocationsV3SampleFilter();

  GoogleMapsPlayablelocationsV3SampleFilter.fromJson(core.Map _json) {
    if (_json.containsKey('includedTypes')) {
      includedTypes = (_json['includedTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('maxLocationCount')) {
      maxLocationCount = _json['maxLocationCount'] as core.int;
    }
    if (_json.containsKey('spacing')) {
      spacing = GoogleMapsPlayablelocationsV3SampleSpacingOptions.fromJson(
          _json['spacing'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (includedTypes != null) 'includedTypes': includedTypes!,
        if (maxLocationCount != null) 'maxLocationCount': maxLocationCount!,
        if (spacing != null) 'spacing': spacing!.toJson(),
      };
}

/// A geographical point suitable for placing game objects in location-based
/// games.
class GoogleMapsPlayablelocationsV3SamplePlayableLocation {
  /// The latitude and longitude associated with the center of the playable
  /// location.
  ///
  /// By default, the set of playable locations returned from
  /// SamplePlayableLocations use center-point coordinates.
  ///
  /// Required.
  GoogleTypeLatLng? centerPoint;

  /// The name of this playable location.
  ///
  /// Required.
  core.String? name;

  /// A [place ID](https://developers.google.com/places/place-id)
  core.String? placeId;

  /// A [plus code](http://openlocationcode.com)
  core.String? plusCode;

  /// The playable location's coordinates, snapped to the sidewalk of the
  /// nearest road, if a nearby road exists.
  GoogleTypeLatLng? snappedPoint;

  /// A collection of \[Playable Location
  /// Types\](/maps/documentation/gaming/tt/types) for this playable location.
  ///
  /// The first type in the collection is the primary type. Type information
  /// might not be available for all playable locations.
  core.List<core.String>? types;

  GoogleMapsPlayablelocationsV3SamplePlayableLocation();

  GoogleMapsPlayablelocationsV3SamplePlayableLocation.fromJson(core.Map _json) {
    if (_json.containsKey('centerPoint')) {
      centerPoint = GoogleTypeLatLng.fromJson(
          _json['centerPoint'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('placeId')) {
      placeId = _json['placeId'] as core.String;
    }
    if (_json.containsKey('plusCode')) {
      plusCode = _json['plusCode'] as core.String;
    }
    if (_json.containsKey('snappedPoint')) {
      snappedPoint = GoogleTypeLatLng.fromJson(
          _json['snappedPoint'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('types')) {
      types = (_json['types'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (centerPoint != null) 'centerPoint': centerPoint!.toJson(),
        if (name != null) 'name': name!,
        if (placeId != null) 'placeId': placeId!,
        if (plusCode != null) 'plusCode': plusCode!,
        if (snappedPoint != null) 'snappedPoint': snappedPoint!.toJson(),
        if (types != null) 'types': types!,
      };
}

/// A list of PlayableLocation objects that satisfies a single Criterion.
class GoogleMapsPlayablelocationsV3SamplePlayableLocationList {
  /// A list of playable locations for this game object type.
  core.List<GoogleMapsPlayablelocationsV3SamplePlayableLocation>? locations;

  GoogleMapsPlayablelocationsV3SamplePlayableLocationList();

  GoogleMapsPlayablelocationsV3SamplePlayableLocationList.fromJson(
      core.Map _json) {
    if (_json.containsKey('locations')) {
      locations = (_json['locations'] as core.List)
          .map<GoogleMapsPlayablelocationsV3SamplePlayableLocation>((value) =>
              GoogleMapsPlayablelocationsV3SamplePlayableLocation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (locations != null)
          'locations': locations!.map((value) => value.toJson()).toList(),
      };
}

/// Life of a query: - When a game starts in a new location, your game server
/// issues a SamplePlayableLocations request.
///
/// The request specifies the S2 cell, and contains one or more "criteria" for
/// filtering: - Criterion 0: i locations for long-lived bases, or level 0
/// monsters, or... - Criterion 1: j locations for short-lived bases, or level 1
/// monsters, ... - Criterion 2: k locations for random objects. - etc (up to 5
/// criterion may be specified). `PlayableLocationList` will then contain
/// mutually exclusive lists of `PlayableLocation` objects that satisfy each of
/// the criteria. Think of it as a collection of real-world locations that you
/// can then associate with your game state. Note: These points are impermanent
/// in nature. E.g, parks can close, and places can be removed. The response
/// specifies how long you can expect the playable locations to last. Once they
/// expire, you should query the `samplePlayableLocations` API again to get a
/// fresh view of the real world.
class GoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest {
  /// Specifies the area to search within for playable locations.
  ///
  /// Required.
  GoogleMapsPlayablelocationsV3SampleAreaFilter? areaFilter;

  /// Specifies one or more (up to 5) criteria for filtering the returned
  /// playable locations.
  ///
  /// Required.
  core.List<GoogleMapsPlayablelocationsV3SampleCriterion>? criteria;

  GoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest();

  GoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('areaFilter')) {
      areaFilter = GoogleMapsPlayablelocationsV3SampleAreaFilter.fromJson(
          _json['areaFilter'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('criteria')) {
      criteria = (_json['criteria'] as core.List)
          .map<GoogleMapsPlayablelocationsV3SampleCriterion>((value) =>
              GoogleMapsPlayablelocationsV3SampleCriterion.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (areaFilter != null) 'areaFilter': areaFilter!.toJson(),
        if (criteria != null)
          'criteria': criteria!.map((value) => value.toJson()).toList(),
      };
}

///  Response for the SamplePlayableLocations method.
class GoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse {
  /// Each PlayableLocation object corresponds to a game_object_type specified
  /// in the request.
  core.Map<core.String,
          GoogleMapsPlayablelocationsV3SamplePlayableLocationList>?
      locationsPerGameObjectType;

  /// Specifies the "time-to-live" for the set of playable locations.
  ///
  /// You can use this value to determine how long to cache the set of playable
  /// locations. After this length of time, your back-end game server should
  /// issue a new SamplePlayableLocations request to get a fresh set of playable
  /// locations (because for example, they might have been removed, a park might
  /// have closed for the day, a business might have closed permanently).
  ///
  /// Required.
  core.String? ttl;

  GoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse();

  GoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('locationsPerGameObjectType')) {
      locationsPerGameObjectType = (_json['locationsPerGameObjectType']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          GoogleMapsPlayablelocationsV3SamplePlayableLocationList.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('ttl')) {
      ttl = _json['ttl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (locationsPerGameObjectType != null)
          'locationsPerGameObjectType': locationsPerGameObjectType!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (ttl != null) 'ttl': ttl!,
      };
}

/// A set of options that specifies the separation between playable locations.
class GoogleMapsPlayablelocationsV3SampleSpacingOptions {
  /// The minimum spacing between any two playable locations, measured in
  /// meters.
  ///
  /// The minimum value is 30. The maximum value is 1000. Inputs will be rounded
  /// up to the next 10 meter interval. The default value is 200m. Set this
  /// field to remove tight clusters of playable locations. Note: The spacing is
  /// a greedy algorithm. It optimizes for selecting the highest ranking
  /// locations first, not to maximize the number of locations selected.
  /// Consider the following scenario: * Rank: A: 2, B: 1, C: 3. * Distance:
  /// A--200m--B--200m--C If spacing=250, it will pick the highest ranked
  /// location \[B\], not \[A, C\]. Note: Spacing works within the game object
  /// type itself, as well as the previous ones. Suppose three game object
  /// types, each with the following spacing: * X: 400m, Y: undefined, Z: 200m.
  /// 1. Add locations for X, within 400m of each other. 2. Add locations for Y,
  /// without any spacing. 3. Finally, add locations for Z within 200m of each
  /// other as well X and Y. The distance diagram between those locations end up
  /// as: * From->To. * X->X: 400m * Y->X, Y->Y: unspecified. * Z->X, Z->Y,
  /// Z->Z: 200m.
  ///
  /// Required.
  core.double? minSpacingMeters;

  /// Specifies whether the minimum spacing constraint applies to the
  /// center-point or to the snapped point of playable locations.
  ///
  /// The default value is `CENTER_POINT`. If a snapped point is not available
  /// for a playable location, its center-point is used instead. Set this to the
  /// point type used in your game.
  /// Possible string values are:
  /// - "POINT_TYPE_UNSPECIFIED" : Unspecified point type. Do not use this
  /// value.
  /// - "CENTER_POINT" : The geographic coordinates correspond to the center of
  /// the location.
  /// - "SNAPPED_POINT" : The geographic coordinates correspond to the location
  /// snapped to the sidewalk of the nearest road (when a nearby road exists).
  core.String? pointType;

  GoogleMapsPlayablelocationsV3SampleSpacingOptions();

  GoogleMapsPlayablelocationsV3SampleSpacingOptions.fromJson(core.Map _json) {
    if (_json.containsKey('minSpacingMeters')) {
      minSpacingMeters = (_json['minSpacingMeters'] as core.num).toDouble();
    }
    if (_json.containsKey('pointType')) {
      pointType = _json['pointType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (minSpacingMeters != null) 'minSpacingMeters': minSpacingMeters!,
        if (pointType != null) 'pointType': pointType!,
      };
}

/// Client information.
class GoogleMapsUnityClientInfo {
  /// API client name and version.
  ///
  /// For example, the SDK calling the API. The exact format is up to the
  /// client.
  core.String? apiClient;

  /// Application ID, such as the package name on Android and the bundle
  /// identifier on iOS platforms.
  core.String? applicationId;

  /// Application version number, such as "1.2.3".
  ///
  /// The exact format is application-dependent.
  core.String? applicationVersion;

  /// Device model as reported by the device.
  ///
  /// The exact format is platform-dependent.
  core.String? deviceModel;

  /// Language code (in BCP-47 format) indicating the UI language of the client.
  ///
  /// Examples are "en", "en-US" or "ja-Latn". For more information, see
  /// http://www.unicode.org/reports/tr35/#Unicode_locale_identifier.
  core.String? languageCode;

  /// Operating system name and version as reported by the OS.
  ///
  /// For example, "Mac OS X 10.10.4". The exact format is platform-dependent.
  core.String? operatingSystem;

  /// Build number/version of the operating system.
  ///
  /// e.g., the contents of android.os.Build.ID in Android, or the contents of
  /// sysctl "kern.osversion" in iOS.
  core.String? operatingSystemBuild;

  /// Platform where the application is running.
  /// Possible string values are:
  /// - "PLATFORM_UNSPECIFIED" : Unspecified or unknown OS.
  /// - "EDITOR" : Development environment.
  /// - "MAC_OS" : macOS.
  /// - "WINDOWS" : Windows.
  /// - "LINUX" : Linux
  /// - "ANDROID" : Android
  /// - "IOS" : iOS
  /// - "WEB_GL" : WebGL.
  core.String? platform;

  GoogleMapsUnityClientInfo();

  GoogleMapsUnityClientInfo.fromJson(core.Map _json) {
    if (_json.containsKey('apiClient')) {
      apiClient = _json['apiClient'] as core.String;
    }
    if (_json.containsKey('applicationId')) {
      applicationId = _json['applicationId'] as core.String;
    }
    if (_json.containsKey('applicationVersion')) {
      applicationVersion = _json['applicationVersion'] as core.String;
    }
    if (_json.containsKey('deviceModel')) {
      deviceModel = _json['deviceModel'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('operatingSystem')) {
      operatingSystem = _json['operatingSystem'] as core.String;
    }
    if (_json.containsKey('operatingSystemBuild')) {
      operatingSystemBuild = _json['operatingSystemBuild'] as core.String;
    }
    if (_json.containsKey('platform')) {
      platform = _json['platform'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiClient != null) 'apiClient': apiClient!,
        if (applicationId != null) 'applicationId': applicationId!,
        if (applicationVersion != null)
          'applicationVersion': applicationVersion!,
        if (deviceModel != null) 'deviceModel': deviceModel!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (operatingSystem != null) 'operatingSystem': operatingSystem!,
        if (operatingSystemBuild != null)
          'operatingSystemBuild': operatingSystemBuild!,
        if (platform != null) 'platform': platform!,
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
