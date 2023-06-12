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

/// My Business Lodging API - v1
///
/// The My Business Lodging API enables managing lodging business information on
/// Google.
///
/// For more information, see <https://developers.google.com/my-business/>
///
/// Create an instance of [MyBusinessLodgingApi] to access these resources:
///
/// - [LocationsResource]
///   - [LocationsLodgingResource]
library mybusinesslodging.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// The My Business Lodging API enables managing lodging business information on
/// Google.
class MyBusinessLodgingApi {
  final commons.ApiRequester _requester;

  LocationsResource get locations => LocationsResource(_requester);

  MyBusinessLodgingApi(http.Client client,
      {core.String rootUrl = 'https://mybusinesslodging.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class LocationsResource {
  final commons.ApiRequester _requester;

  LocationsLodgingResource get lodging => LocationsLodgingResource(_requester);

  LocationsResource(commons.ApiRequester client) : _requester = client;

  /// Returns the Lodging of a specific location.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Google identifier for this location in the form:
  /// `locations/{location_id}/lodging`
  /// Value must have pattern `^locations/\[^/\]+/lodging$`.
  ///
  /// [readMask] - Required. The specific fields to return. Use "*" to include
  /// all fields. Repeated field items cannot be individually specified.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Lodging].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Lodging> getLodging(
    core.String name, {
    core.String? readMask,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (readMask != null) 'readMask': [readMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Lodging.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the Lodging of a specific location.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Google identifier for this location in the form:
  /// `locations/{location_id}/lodging`
  /// Value must have pattern `^locations/\[^/\]+/lodging$`.
  ///
  /// [updateMask] - Required. The specific fields to update. Use "*" to update
  /// all fields, which may include unsetting empty fields in the request.
  /// Repeated field items cannot be individually updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Lodging].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Lodging> updateLodging(
    Lodging request,
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
    return Lodging.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class LocationsLodgingResource {
  final commons.ApiRequester _requester;

  LocationsLodgingResource(commons.ApiRequester client) : _requester = client;

  /// Returns the Google updated Lodging of a specific location.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. Google identifier for this location in the form:
  /// `accounts/{account_id}/locations/{location_id}/lodging`
  /// Value must have pattern `^locations/\[^/\]+/lodging$`.
  ///
  /// [readMask] - Required. The specific fields to return. Use "*" to include
  /// all fields. Repeated field items cannot be individually specified.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GetGoogleUpdatedLodgingResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GetGoogleUpdatedLodgingResponse> getGoogleUpdated(
    core.String name, {
    core.String? readMask,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (readMask != null) 'readMask': [readMask],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':getGoogleUpdated';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GetGoogleUpdatedLodgingResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Physical adaptations made to the property in consideration of varying levels
/// of human physical ability.
class Accessibility {
  /// Mobility accessible.
  ///
  /// Throughout the property there are physical adaptations to ease the stay of
  /// a person in a wheelchair, such as auto-opening doors, wide elevators, wide
  /// bathrooms or ramps.
  core.bool? mobilityAccessible;

  /// Mobility accessible elevator.
  ///
  /// A lift that transports people from one level to another and is built to
  /// accommodate a wheelchair-using passenger owing to the width of its doors
  /// and placement of call buttons.
  core.bool? mobilityAccessibleElevator;

  /// Mobility accessible elevator exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? mobilityAccessibleElevatorException;

  /// Mobility accessible exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? mobilityAccessibleException;

  /// Mobility accessible parking.
  ///
  /// The presence of a marked, designated area of prescribed size in which only
  /// registered, labeled vehicles transporting a person with physical
  /// challenges may park.
  core.bool? mobilityAccessibleParking;

  /// Mobility accessible parking exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? mobilityAccessibleParkingException;

  /// Mobility accessible pool.
  ///
  /// A swimming pool equipped with a mechanical chair that can be lowered and
  /// raised for the purpose of moving physically challenged guests into and out
  /// of the pool. May be powered by electricity or water. Also known as pool
  /// lift.
  core.bool? mobilityAccessiblePool;

  /// Mobility accessible pool exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? mobilityAccessiblePoolException;

  Accessibility();

  Accessibility.fromJson(core.Map _json) {
    if (_json.containsKey('mobilityAccessible')) {
      mobilityAccessible = _json['mobilityAccessible'] as core.bool;
    }
    if (_json.containsKey('mobilityAccessibleElevator')) {
      mobilityAccessibleElevator =
          _json['mobilityAccessibleElevator'] as core.bool;
    }
    if (_json.containsKey('mobilityAccessibleElevatorException')) {
      mobilityAccessibleElevatorException =
          _json['mobilityAccessibleElevatorException'] as core.String;
    }
    if (_json.containsKey('mobilityAccessibleException')) {
      mobilityAccessibleException =
          _json['mobilityAccessibleException'] as core.String;
    }
    if (_json.containsKey('mobilityAccessibleParking')) {
      mobilityAccessibleParking =
          _json['mobilityAccessibleParking'] as core.bool;
    }
    if (_json.containsKey('mobilityAccessibleParkingException')) {
      mobilityAccessibleParkingException =
          _json['mobilityAccessibleParkingException'] as core.String;
    }
    if (_json.containsKey('mobilityAccessiblePool')) {
      mobilityAccessiblePool = _json['mobilityAccessiblePool'] as core.bool;
    }
    if (_json.containsKey('mobilityAccessiblePoolException')) {
      mobilityAccessiblePoolException =
          _json['mobilityAccessiblePoolException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (mobilityAccessible != null)
          'mobilityAccessible': mobilityAccessible!,
        if (mobilityAccessibleElevator != null)
          'mobilityAccessibleElevator': mobilityAccessibleElevator!,
        if (mobilityAccessibleElevatorException != null)
          'mobilityAccessibleElevatorException':
              mobilityAccessibleElevatorException!,
        if (mobilityAccessibleException != null)
          'mobilityAccessibleException': mobilityAccessibleException!,
        if (mobilityAccessibleParking != null)
          'mobilityAccessibleParking': mobilityAccessibleParking!,
        if (mobilityAccessibleParkingException != null)
          'mobilityAccessibleParkingException':
              mobilityAccessibleParkingException!,
        if (mobilityAccessiblePool != null)
          'mobilityAccessiblePool': mobilityAccessiblePool!,
        if (mobilityAccessiblePoolException != null)
          'mobilityAccessiblePoolException': mobilityAccessiblePoolException!,
      };
}

/// Amenities and features related to leisure and play.
class Activities {
  /// Beach access.
  ///
  /// The hotel property is in close proximity to a beach and offers a way to
  /// get to that beach. This can include a route to the beach such as stairs
  /// down if hotel is on a bluff, or a short trail. Not the same as beachfront
  /// (with beach access, the hotel's proximity is close to but not right on the
  /// beach).
  core.bool? beachAccess;

  /// Beach access exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? beachAccessException;

  /// Breach front.
  ///
  /// The hotel property is physically located on the beach alongside an ocean,
  /// sea, gulf, or bay. It is not on a lake, river, stream, or pond. The hotel
  /// is not separated from the beach by a public road allowing vehicular,
  /// pedestrian, or bicycle traffic.
  core.bool? beachFront;

  /// Beach front exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? beachFrontException;

  /// Bicycle rental.
  ///
  /// The hotel owns bicycles that it permits guests to borrow and use. Can be
  /// free or for a fee.
  core.bool? bicycleRental;

  /// Bicycle rental exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? bicycleRentalException;

  /// Boutique stores.
  ///
  /// There are stores selling clothing, jewelry, art and decor either on hotel
  /// premises or very close by. Does not refer to the hotel gift shop or
  /// convenience store.
  core.bool? boutiqueStores;

  /// Boutique stores exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? boutiqueStoresException;

  /// Casino.
  ///
  /// A space designated for gambling and gaming featuring croupier-run table
  /// and card games, as well as electronic slot machines. May be on hotel
  /// premises or located nearby.
  core.bool? casino;

  /// Casino exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? casinoException;

  /// Free bicycle rental.
  ///
  /// The hotel owns bicycles that it permits guests to borrow and use for free.
  core.bool? freeBicycleRental;

  /// Free bicycle rental exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? freeBicycleRentalException;

  /// Free watercraft rental.
  ///
  /// The hotel owns watercraft that it permits guests to borrow and use for
  /// free.
  core.bool? freeWatercraftRental;

  /// Free Watercraft rental exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? freeWatercraftRentalException;

  /// Game room.
  ///
  /// There is a room at the hotel containing electronic machines for play such
  /// as pinball, prize machines, driving simulators, and other items commonly
  /// found at a family fun center or arcade. May also include non-electronic
  /// games like pool, foosball, darts, and more. May or may not be designed for
  /// children. Also known as arcade, fun room, or family fun center.
  core.bool? gameRoom;

  /// Game room exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? gameRoomException;

  /// Golf.
  ///
  /// There is a golf course on hotel grounds or there is a nearby,
  /// independently run golf course that allows use by hotel guests. Can be free
  /// or for a fee.
  core.bool? golf;

  /// Golf exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? golfException;

  /// Horseback riding.
  ///
  /// The hotel has a horse barn onsite or an affiliation with a nearby barn to
  /// allow for guests to sit astride a horse and direct it to walk, trot,
  /// cantor, gallop and/or jump. Can be in a riding ring, on designated paths,
  /// or in the wilderness. May or may not involve instruction.
  core.bool? horsebackRiding;

  /// Horseback riding exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? horsebackRidingException;

  /// Nightclub.
  ///
  /// There is a room at the hotel with a bar, a dance floor, and seating where
  /// designated staffers play dance music. There may also be a designated area
  /// for the performance of live music, singing and comedy acts.
  core.bool? nightclub;

  /// Nightclub exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? nightclubException;

  /// Private beach.
  ///
  /// The beach which is in close proximity to the hotel is open only to guests.
  core.bool? privateBeach;

  /// Private beach exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? privateBeachException;

  /// Scuba.
  ///
  /// The provision for guests to dive under naturally occurring water fitted
  /// with a self-contained underwater breathing apparatus (SCUBA) for the
  /// purpose of exploring underwater life. Apparatus consists of a tank
  /// providing oxygen to the diver through a mask. Requires certification of
  /// the diver and supervision. The hotel may have the activity at its own
  /// waterfront or have an affiliation with a nearby facility. Required
  /// equipment is most often supplied to guests. Can be free or for a fee. Not
  /// snorkeling. Not done in a swimming pool.
  core.bool? scuba;

  /// Scuba exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? scubaException;

  /// Snorkeling.
  ///
  /// The provision for guests to participate in a recreational water activity
  /// in which swimmers wear a diving mask, a simple, shaped breathing tube and
  /// flippers/swim fins for the purpose of exploring below the surface of an
  /// ocean, gulf or lake. Does not usually require user certification or
  /// professional supervision. Equipment may or may not be available for rent
  /// or purchase. Not scuba diving.
  core.bool? snorkeling;

  /// Snorkeling exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? snorkelingException;

  /// Tennis.
  ///
  /// The hotel has the requisite court(s) on site or has an affiliation with a
  /// nearby facility for the purpose of providing guests with the opportunity
  /// to play a two-sided court-based game in which players use a stringed
  /// racquet to hit a ball across a net to the side of the opposing player. The
  /// court can be indoors or outdoors. Instructors, racquets and balls may or
  /// may not be provided.
  core.bool? tennis;

  /// Tennis exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? tennisException;

  /// Water skiing.
  ///
  /// The provision of giving guests the opportunity to be pulled across
  /// naturally occurring water while standing on skis and holding a tow rope
  /// attached to a motorboat. Can occur on hotel premises or at a nearby
  /// waterfront. Most often performed in a lake or ocean.
  core.bool? waterSkiing;

  /// Water skiing exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? waterSkiingException;

  /// Watercraft rental.
  ///
  /// The hotel owns water vessels that it permits guests to borrow and use. Can
  /// be free or for a fee. Watercraft may include boats, pedal boats, rowboats,
  /// sailboats, powerboats, canoes, kayaks, or personal watercraft (such as a
  /// Jet Ski).
  core.bool? watercraftRental;

  /// Watercraft rental exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? watercraftRentalException;

  Activities();

  Activities.fromJson(core.Map _json) {
    if (_json.containsKey('beachAccess')) {
      beachAccess = _json['beachAccess'] as core.bool;
    }
    if (_json.containsKey('beachAccessException')) {
      beachAccessException = _json['beachAccessException'] as core.String;
    }
    if (_json.containsKey('beachFront')) {
      beachFront = _json['beachFront'] as core.bool;
    }
    if (_json.containsKey('beachFrontException')) {
      beachFrontException = _json['beachFrontException'] as core.String;
    }
    if (_json.containsKey('bicycleRental')) {
      bicycleRental = _json['bicycleRental'] as core.bool;
    }
    if (_json.containsKey('bicycleRentalException')) {
      bicycleRentalException = _json['bicycleRentalException'] as core.String;
    }
    if (_json.containsKey('boutiqueStores')) {
      boutiqueStores = _json['boutiqueStores'] as core.bool;
    }
    if (_json.containsKey('boutiqueStoresException')) {
      boutiqueStoresException = _json['boutiqueStoresException'] as core.String;
    }
    if (_json.containsKey('casino')) {
      casino = _json['casino'] as core.bool;
    }
    if (_json.containsKey('casinoException')) {
      casinoException = _json['casinoException'] as core.String;
    }
    if (_json.containsKey('freeBicycleRental')) {
      freeBicycleRental = _json['freeBicycleRental'] as core.bool;
    }
    if (_json.containsKey('freeBicycleRentalException')) {
      freeBicycleRentalException =
          _json['freeBicycleRentalException'] as core.String;
    }
    if (_json.containsKey('freeWatercraftRental')) {
      freeWatercraftRental = _json['freeWatercraftRental'] as core.bool;
    }
    if (_json.containsKey('freeWatercraftRentalException')) {
      freeWatercraftRentalException =
          _json['freeWatercraftRentalException'] as core.String;
    }
    if (_json.containsKey('gameRoom')) {
      gameRoom = _json['gameRoom'] as core.bool;
    }
    if (_json.containsKey('gameRoomException')) {
      gameRoomException = _json['gameRoomException'] as core.String;
    }
    if (_json.containsKey('golf')) {
      golf = _json['golf'] as core.bool;
    }
    if (_json.containsKey('golfException')) {
      golfException = _json['golfException'] as core.String;
    }
    if (_json.containsKey('horsebackRiding')) {
      horsebackRiding = _json['horsebackRiding'] as core.bool;
    }
    if (_json.containsKey('horsebackRidingException')) {
      horsebackRidingException =
          _json['horsebackRidingException'] as core.String;
    }
    if (_json.containsKey('nightclub')) {
      nightclub = _json['nightclub'] as core.bool;
    }
    if (_json.containsKey('nightclubException')) {
      nightclubException = _json['nightclubException'] as core.String;
    }
    if (_json.containsKey('privateBeach')) {
      privateBeach = _json['privateBeach'] as core.bool;
    }
    if (_json.containsKey('privateBeachException')) {
      privateBeachException = _json['privateBeachException'] as core.String;
    }
    if (_json.containsKey('scuba')) {
      scuba = _json['scuba'] as core.bool;
    }
    if (_json.containsKey('scubaException')) {
      scubaException = _json['scubaException'] as core.String;
    }
    if (_json.containsKey('snorkeling')) {
      snorkeling = _json['snorkeling'] as core.bool;
    }
    if (_json.containsKey('snorkelingException')) {
      snorkelingException = _json['snorkelingException'] as core.String;
    }
    if (_json.containsKey('tennis')) {
      tennis = _json['tennis'] as core.bool;
    }
    if (_json.containsKey('tennisException')) {
      tennisException = _json['tennisException'] as core.String;
    }
    if (_json.containsKey('waterSkiing')) {
      waterSkiing = _json['waterSkiing'] as core.bool;
    }
    if (_json.containsKey('waterSkiingException')) {
      waterSkiingException = _json['waterSkiingException'] as core.String;
    }
    if (_json.containsKey('watercraftRental')) {
      watercraftRental = _json['watercraftRental'] as core.bool;
    }
    if (_json.containsKey('watercraftRentalException')) {
      watercraftRentalException =
          _json['watercraftRentalException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (beachAccess != null) 'beachAccess': beachAccess!,
        if (beachAccessException != null)
          'beachAccessException': beachAccessException!,
        if (beachFront != null) 'beachFront': beachFront!,
        if (beachFrontException != null)
          'beachFrontException': beachFrontException!,
        if (bicycleRental != null) 'bicycleRental': bicycleRental!,
        if (bicycleRentalException != null)
          'bicycleRentalException': bicycleRentalException!,
        if (boutiqueStores != null) 'boutiqueStores': boutiqueStores!,
        if (boutiqueStoresException != null)
          'boutiqueStoresException': boutiqueStoresException!,
        if (casino != null) 'casino': casino!,
        if (casinoException != null) 'casinoException': casinoException!,
        if (freeBicycleRental != null) 'freeBicycleRental': freeBicycleRental!,
        if (freeBicycleRentalException != null)
          'freeBicycleRentalException': freeBicycleRentalException!,
        if (freeWatercraftRental != null)
          'freeWatercraftRental': freeWatercraftRental!,
        if (freeWatercraftRentalException != null)
          'freeWatercraftRentalException': freeWatercraftRentalException!,
        if (gameRoom != null) 'gameRoom': gameRoom!,
        if (gameRoomException != null) 'gameRoomException': gameRoomException!,
        if (golf != null) 'golf': golf!,
        if (golfException != null) 'golfException': golfException!,
        if (horsebackRiding != null) 'horsebackRiding': horsebackRiding!,
        if (horsebackRidingException != null)
          'horsebackRidingException': horsebackRidingException!,
        if (nightclub != null) 'nightclub': nightclub!,
        if (nightclubException != null)
          'nightclubException': nightclubException!,
        if (privateBeach != null) 'privateBeach': privateBeach!,
        if (privateBeachException != null)
          'privateBeachException': privateBeachException!,
        if (scuba != null) 'scuba': scuba!,
        if (scubaException != null) 'scubaException': scubaException!,
        if (snorkeling != null) 'snorkeling': snorkeling!,
        if (snorkelingException != null)
          'snorkelingException': snorkelingException!,
        if (tennis != null) 'tennis': tennis!,
        if (tennisException != null) 'tennisException': tennisException!,
        if (waterSkiing != null) 'waterSkiing': waterSkiing!,
        if (waterSkiingException != null)
          'waterSkiingException': waterSkiingException!,
        if (watercraftRental != null) 'watercraftRental': watercraftRental!,
        if (watercraftRentalException != null)
          'watercraftRentalException': watercraftRentalException!,
      };
}

/// Features of the property of specific interest to the business traveler.
class Business {
  /// Business center.
  ///
  /// A designated room at the hotel with one or more desks and equipped with
  /// guest-use computers, printers, fax machines and/or photocopiers. May or
  /// may not be open 24/7. May or may not require a key to access. Not a
  /// meeting room or conference room.
  core.bool? businessCenter;

  /// Business center exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? businessCenterException;

  /// Meeting rooms.
  ///
  /// Rooms at the hotel designated for business-related gatherings. Rooms are
  /// usually equipped with tables or desks, office chairs and audio/visual
  /// facilities to allow for presentations and conference calls. Also known as
  /// conference rooms.
  core.bool? meetingRooms;

  /// Meeting rooms count.
  ///
  /// The number of meeting rooms at the property.
  core.int? meetingRoomsCount;

  /// Meeting rooms count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? meetingRoomsCountException;

  /// Meeting rooms exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? meetingRoomsException;

  Business();

  Business.fromJson(core.Map _json) {
    if (_json.containsKey('businessCenter')) {
      businessCenter = _json['businessCenter'] as core.bool;
    }
    if (_json.containsKey('businessCenterException')) {
      businessCenterException = _json['businessCenterException'] as core.String;
    }
    if (_json.containsKey('meetingRooms')) {
      meetingRooms = _json['meetingRooms'] as core.bool;
    }
    if (_json.containsKey('meetingRoomsCount')) {
      meetingRoomsCount = _json['meetingRoomsCount'] as core.int;
    }
    if (_json.containsKey('meetingRoomsCountException')) {
      meetingRoomsCountException =
          _json['meetingRoomsCountException'] as core.String;
    }
    if (_json.containsKey('meetingRoomsException')) {
      meetingRoomsException = _json['meetingRoomsException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (businessCenter != null) 'businessCenter': businessCenter!,
        if (businessCenterException != null)
          'businessCenterException': businessCenterException!,
        if (meetingRooms != null) 'meetingRooms': meetingRooms!,
        if (meetingRoomsCount != null) 'meetingRoomsCount': meetingRoomsCount!,
        if (meetingRoomsCountException != null)
          'meetingRoomsCountException': meetingRoomsCountException!,
        if (meetingRoomsException != null)
          'meetingRoomsException': meetingRoomsException!,
      };
}

/// The ways in which the property provides guests with the ability to access
/// the internet.
class Connectivity {
  /// Free wifi.
  ///
  /// The hotel offers guests wifi for free.
  core.bool? freeWifi;

  /// Free wifi exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? freeWifiException;

  /// Public area wifi available.
  ///
  /// Guests have the ability to wirelessly connect to the internet in the areas
  /// of the hotel accessible to anyone. Can be free or for a fee.
  core.bool? publicAreaWifiAvailable;

  /// Public area wifi available exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? publicAreaWifiAvailableException;

  /// Public internet terminal.
  ///
  /// An area of the hotel supplied with computers and designated for the
  /// purpose of providing guests with the ability to access the internet.
  core.bool? publicInternetTerminal;

  /// Public internet terminal exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? publicInternetTerminalException;

  /// Wifi available.
  ///
  /// The hotel provides the ability for guests to wirelessly connect to the
  /// internet. Can be in the public areas of the hotel and/or in the guest
  /// rooms. Can be free or for a fee.
  core.bool? wifiAvailable;

  /// Wifi available exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? wifiAvailableException;

  Connectivity();

  Connectivity.fromJson(core.Map _json) {
    if (_json.containsKey('freeWifi')) {
      freeWifi = _json['freeWifi'] as core.bool;
    }
    if (_json.containsKey('freeWifiException')) {
      freeWifiException = _json['freeWifiException'] as core.String;
    }
    if (_json.containsKey('publicAreaWifiAvailable')) {
      publicAreaWifiAvailable = _json['publicAreaWifiAvailable'] as core.bool;
    }
    if (_json.containsKey('publicAreaWifiAvailableException')) {
      publicAreaWifiAvailableException =
          _json['publicAreaWifiAvailableException'] as core.String;
    }
    if (_json.containsKey('publicInternetTerminal')) {
      publicInternetTerminal = _json['publicInternetTerminal'] as core.bool;
    }
    if (_json.containsKey('publicInternetTerminalException')) {
      publicInternetTerminalException =
          _json['publicInternetTerminalException'] as core.String;
    }
    if (_json.containsKey('wifiAvailable')) {
      wifiAvailable = _json['wifiAvailable'] as core.bool;
    }
    if (_json.containsKey('wifiAvailableException')) {
      wifiAvailableException = _json['wifiAvailableException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (freeWifi != null) 'freeWifi': freeWifi!,
        if (freeWifiException != null) 'freeWifiException': freeWifiException!,
        if (publicAreaWifiAvailable != null)
          'publicAreaWifiAvailable': publicAreaWifiAvailable!,
        if (publicAreaWifiAvailableException != null)
          'publicAreaWifiAvailableException': publicAreaWifiAvailableException!,
        if (publicInternetTerminal != null)
          'publicInternetTerminal': publicInternetTerminal!,
        if (publicInternetTerminalException != null)
          'publicInternetTerminalException': publicInternetTerminalException!,
        if (wifiAvailable != null) 'wifiAvailable': wifiAvailable!,
        if (wifiAvailableException != null)
          'wifiAvailableException': wifiAvailableException!,
      };
}

/// Enhanced cleaning measures implemented by the hotel during COVID-19.
class EnhancedCleaning {
  /// Commercial-grade disinfectant used to clean the property.
  core.bool? commercialGradeDisinfectantCleaning;

  /// Commercial grade disinfectant cleaning exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? commercialGradeDisinfectantCleaningException;

  /// Enhanced cleaning of common areas.
  core.bool? commonAreasEnhancedCleaning;

  /// Common areas enhanced cleaning exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? commonAreasEnhancedCleaningException;

  /// Employees trained in COVID-19 cleaning procedures.
  core.bool? employeesTrainedCleaningProcedures;

  /// Employees trained cleaning procedures exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? employeesTrainedCleaningProceduresException;

  /// Employees trained in thorough hand-washing.
  core.bool? employeesTrainedThoroughHandWashing;

  /// Employees trained thorough hand washing exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? employeesTrainedThoroughHandWashingException;

  /// Employees wear masks, face shields, and/or gloves.
  core.bool? employeesWearProtectiveEquipment;

  /// Employees wear protective equipment exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? employeesWearProtectiveEquipmentException;

  /// Enhanced cleaning of guest rooms.
  core.bool? guestRoomsEnhancedCleaning;

  /// Guest rooms enhanced cleaning exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? guestRoomsEnhancedCleaningException;

  EnhancedCleaning();

  EnhancedCleaning.fromJson(core.Map _json) {
    if (_json.containsKey('commercialGradeDisinfectantCleaning')) {
      commercialGradeDisinfectantCleaning =
          _json['commercialGradeDisinfectantCleaning'] as core.bool;
    }
    if (_json.containsKey('commercialGradeDisinfectantCleaningException')) {
      commercialGradeDisinfectantCleaningException =
          _json['commercialGradeDisinfectantCleaningException'] as core.String;
    }
    if (_json.containsKey('commonAreasEnhancedCleaning')) {
      commonAreasEnhancedCleaning =
          _json['commonAreasEnhancedCleaning'] as core.bool;
    }
    if (_json.containsKey('commonAreasEnhancedCleaningException')) {
      commonAreasEnhancedCleaningException =
          _json['commonAreasEnhancedCleaningException'] as core.String;
    }
    if (_json.containsKey('employeesTrainedCleaningProcedures')) {
      employeesTrainedCleaningProcedures =
          _json['employeesTrainedCleaningProcedures'] as core.bool;
    }
    if (_json.containsKey('employeesTrainedCleaningProceduresException')) {
      employeesTrainedCleaningProceduresException =
          _json['employeesTrainedCleaningProceduresException'] as core.String;
    }
    if (_json.containsKey('employeesTrainedThoroughHandWashing')) {
      employeesTrainedThoroughHandWashing =
          _json['employeesTrainedThoroughHandWashing'] as core.bool;
    }
    if (_json.containsKey('employeesTrainedThoroughHandWashingException')) {
      employeesTrainedThoroughHandWashingException =
          _json['employeesTrainedThoroughHandWashingException'] as core.String;
    }
    if (_json.containsKey('employeesWearProtectiveEquipment')) {
      employeesWearProtectiveEquipment =
          _json['employeesWearProtectiveEquipment'] as core.bool;
    }
    if (_json.containsKey('employeesWearProtectiveEquipmentException')) {
      employeesWearProtectiveEquipmentException =
          _json['employeesWearProtectiveEquipmentException'] as core.String;
    }
    if (_json.containsKey('guestRoomsEnhancedCleaning')) {
      guestRoomsEnhancedCleaning =
          _json['guestRoomsEnhancedCleaning'] as core.bool;
    }
    if (_json.containsKey('guestRoomsEnhancedCleaningException')) {
      guestRoomsEnhancedCleaningException =
          _json['guestRoomsEnhancedCleaningException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (commercialGradeDisinfectantCleaning != null)
          'commercialGradeDisinfectantCleaning':
              commercialGradeDisinfectantCleaning!,
        if (commercialGradeDisinfectantCleaningException != null)
          'commercialGradeDisinfectantCleaningException':
              commercialGradeDisinfectantCleaningException!,
        if (commonAreasEnhancedCleaning != null)
          'commonAreasEnhancedCleaning': commonAreasEnhancedCleaning!,
        if (commonAreasEnhancedCleaningException != null)
          'commonAreasEnhancedCleaningException':
              commonAreasEnhancedCleaningException!,
        if (employeesTrainedCleaningProcedures != null)
          'employeesTrainedCleaningProcedures':
              employeesTrainedCleaningProcedures!,
        if (employeesTrainedCleaningProceduresException != null)
          'employeesTrainedCleaningProceduresException':
              employeesTrainedCleaningProceduresException!,
        if (employeesTrainedThoroughHandWashing != null)
          'employeesTrainedThoroughHandWashing':
              employeesTrainedThoroughHandWashing!,
        if (employeesTrainedThoroughHandWashingException != null)
          'employeesTrainedThoroughHandWashingException':
              employeesTrainedThoroughHandWashingException!,
        if (employeesWearProtectiveEquipment != null)
          'employeesWearProtectiveEquipment': employeesWearProtectiveEquipment!,
        if (employeesWearProtectiveEquipmentException != null)
          'employeesWearProtectiveEquipmentException':
              employeesWearProtectiveEquipmentException!,
        if (guestRoomsEnhancedCleaning != null)
          'guestRoomsEnhancedCleaning': guestRoomsEnhancedCleaning!,
        if (guestRoomsEnhancedCleaningException != null)
          'guestRoomsEnhancedCleaningException':
              guestRoomsEnhancedCleaningException!,
      };
}

/// Services and amenities for families and young guests.
class Families {
  /// Babysitting.
  ///
  /// Child care that is offered by hotel staffers or coordinated by hotel
  /// staffers with local child care professionals. Can be free or for a fee.
  core.bool? babysitting;

  /// Babysitting exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? babysittingException;

  /// Kids activities.
  ///
  /// Recreational options such as sports, films, crafts and games designed for
  /// the enjoyment of children and offered at the hotel. May or may not be
  /// supervised. May or may not be at a designated time or place. Cab be free
  /// or for a fee.
  core.bool? kidsActivities;

  /// Kids activities exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? kidsActivitiesException;

  /// Kids club.
  ///
  /// An organized program of group activities held at the hotel and designed
  /// for the enjoyment of children. Facilitated by hotel staff (or staff
  /// procured by the hotel) in an area(s) designated for the purpose of
  /// entertaining children without their parents. May include games, outings,
  /// water sports, team sports, arts and crafts, and films. Usually has set
  /// hours. Can be free or for a fee. Also known as Kids Camp or Kids program.
  core.bool? kidsClub;

  /// Kids club exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? kidsClubException;

  Families();

  Families.fromJson(core.Map _json) {
    if (_json.containsKey('babysitting')) {
      babysitting = _json['babysitting'] as core.bool;
    }
    if (_json.containsKey('babysittingException')) {
      babysittingException = _json['babysittingException'] as core.String;
    }
    if (_json.containsKey('kidsActivities')) {
      kidsActivities = _json['kidsActivities'] as core.bool;
    }
    if (_json.containsKey('kidsActivitiesException')) {
      kidsActivitiesException = _json['kidsActivitiesException'] as core.String;
    }
    if (_json.containsKey('kidsClub')) {
      kidsClub = _json['kidsClub'] as core.bool;
    }
    if (_json.containsKey('kidsClubException')) {
      kidsClubException = _json['kidsClubException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (babysitting != null) 'babysitting': babysitting!,
        if (babysittingException != null)
          'babysittingException': babysittingException!,
        if (kidsActivities != null) 'kidsActivities': kidsActivities!,
        if (kidsActivitiesException != null)
          'kidsActivitiesException': kidsActivitiesException!,
        if (kidsClub != null) 'kidsClub': kidsClub!,
        if (kidsClubException != null) 'kidsClubException': kidsClubException!,
      };
}

/// Meals, snacks, and beverages available at the property.
class FoodAndDrink {
  /// Bar.
  ///
  /// A designated room, lounge or area of an on-site restaurant with seating at
  /// a counter behind which a hotel staffer takes the guest's order and
  /// provides the requested alcoholic drink. Can be indoors or outdoors. Also
  /// known as Pub.
  core.bool? bar;

  /// Bar exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? barException;

  /// Breakfast available.
  ///
  /// The morning meal is offered to all guests. Can be free or for a fee.
  core.bool? breakfastAvailable;

  /// Breakfast available exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? breakfastAvailableException;

  /// Breakfast buffet.
  ///
  /// Breakfast meal service where guests serve themselves from a variety of
  /// dishes/foods that are put out on a table.
  core.bool? breakfastBuffet;

  /// Breakfast buffet exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? breakfastBuffetException;

  /// Buffet.
  ///
  /// A type of meal where guests serve themselves from a variety of
  /// dishes/foods that are put out on a table. Includes lunch and/or dinner
  /// meals. A breakfast-only buffet is not sufficient.
  core.bool? buffet;

  /// Buffet exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? buffetException;

  /// Dinner buffet.
  ///
  /// Dinner meal service where guests serve themselves from a variety of
  /// dishes/foods that are put out on a table.
  core.bool? dinnerBuffet;

  /// Dinner buffet exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? dinnerBuffetException;

  /// Free breakfast.
  ///
  /// Breakfast is offered for free to all guests. Does not apply if limited to
  /// certain room packages.
  core.bool? freeBreakfast;

  /// Free breakfast exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? freeBreakfastException;

  /// Restaurant.
  ///
  /// A business onsite at the hotel that is open to the public as well as
  /// guests, and offers meals and beverages to consume at tables or counters.
  /// May or may not include table service. Also known as cafe, buffet, eatery.
  /// A "breakfast room" where the hotel serves breakfast only to guests (not
  /// the general public) does not count as a restaurant.
  core.bool? restaurant;

  /// Restaurant exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? restaurantException;

  /// Restaurants count.
  ///
  /// The number of restaurants at the hotel.
  core.int? restaurantsCount;

  /// Restaurants count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? restaurantsCountException;

  /// Room service.
  ///
  /// A hotel staffer delivers meals prepared onsite to a guest's room as per
  /// their request. May or may not be available during specific hours. Services
  /// should be available to all guests (not based on rate/room booked/reward
  /// program, etc).
  core.bool? roomService;

  /// Room service exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? roomServiceException;

  /// Table service.
  ///
  /// A restaurant in which a staff member is assigned to a guest's table to
  /// take their order, deliver and clear away food, and deliver the bill, if
  /// applicable. Also known as sit-down restaurant.
  core.bool? tableService;

  /// Table service exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? tableServiceException;

  /// 24hr room service.
  ///
  /// Room service is available 24 hours a day.
  core.bool? twentyFourHourRoomService;

  /// 24hr room service exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? twentyFourHourRoomServiceException;

  /// Vending machine.
  ///
  /// A glass-fronted mechanized cabinet displaying and dispensing snacks and
  /// beverages for purchase by coins, paper money and/or credit cards.
  core.bool? vendingMachine;

  /// Vending machine exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? vendingMachineException;

  FoodAndDrink();

  FoodAndDrink.fromJson(core.Map _json) {
    if (_json.containsKey('bar')) {
      bar = _json['bar'] as core.bool;
    }
    if (_json.containsKey('barException')) {
      barException = _json['barException'] as core.String;
    }
    if (_json.containsKey('breakfastAvailable')) {
      breakfastAvailable = _json['breakfastAvailable'] as core.bool;
    }
    if (_json.containsKey('breakfastAvailableException')) {
      breakfastAvailableException =
          _json['breakfastAvailableException'] as core.String;
    }
    if (_json.containsKey('breakfastBuffet')) {
      breakfastBuffet = _json['breakfastBuffet'] as core.bool;
    }
    if (_json.containsKey('breakfastBuffetException')) {
      breakfastBuffetException =
          _json['breakfastBuffetException'] as core.String;
    }
    if (_json.containsKey('buffet')) {
      buffet = _json['buffet'] as core.bool;
    }
    if (_json.containsKey('buffetException')) {
      buffetException = _json['buffetException'] as core.String;
    }
    if (_json.containsKey('dinnerBuffet')) {
      dinnerBuffet = _json['dinnerBuffet'] as core.bool;
    }
    if (_json.containsKey('dinnerBuffetException')) {
      dinnerBuffetException = _json['dinnerBuffetException'] as core.String;
    }
    if (_json.containsKey('freeBreakfast')) {
      freeBreakfast = _json['freeBreakfast'] as core.bool;
    }
    if (_json.containsKey('freeBreakfastException')) {
      freeBreakfastException = _json['freeBreakfastException'] as core.String;
    }
    if (_json.containsKey('restaurant')) {
      restaurant = _json['restaurant'] as core.bool;
    }
    if (_json.containsKey('restaurantException')) {
      restaurantException = _json['restaurantException'] as core.String;
    }
    if (_json.containsKey('restaurantsCount')) {
      restaurantsCount = _json['restaurantsCount'] as core.int;
    }
    if (_json.containsKey('restaurantsCountException')) {
      restaurantsCountException =
          _json['restaurantsCountException'] as core.String;
    }
    if (_json.containsKey('roomService')) {
      roomService = _json['roomService'] as core.bool;
    }
    if (_json.containsKey('roomServiceException')) {
      roomServiceException = _json['roomServiceException'] as core.String;
    }
    if (_json.containsKey('tableService')) {
      tableService = _json['tableService'] as core.bool;
    }
    if (_json.containsKey('tableServiceException')) {
      tableServiceException = _json['tableServiceException'] as core.String;
    }
    if (_json.containsKey('twentyFourHourRoomService')) {
      twentyFourHourRoomService =
          _json['twentyFourHourRoomService'] as core.bool;
    }
    if (_json.containsKey('twentyFourHourRoomServiceException')) {
      twentyFourHourRoomServiceException =
          _json['twentyFourHourRoomServiceException'] as core.String;
    }
    if (_json.containsKey('vendingMachine')) {
      vendingMachine = _json['vendingMachine'] as core.bool;
    }
    if (_json.containsKey('vendingMachineException')) {
      vendingMachineException = _json['vendingMachineException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bar != null) 'bar': bar!,
        if (barException != null) 'barException': barException!,
        if (breakfastAvailable != null)
          'breakfastAvailable': breakfastAvailable!,
        if (breakfastAvailableException != null)
          'breakfastAvailableException': breakfastAvailableException!,
        if (breakfastBuffet != null) 'breakfastBuffet': breakfastBuffet!,
        if (breakfastBuffetException != null)
          'breakfastBuffetException': breakfastBuffetException!,
        if (buffet != null) 'buffet': buffet!,
        if (buffetException != null) 'buffetException': buffetException!,
        if (dinnerBuffet != null) 'dinnerBuffet': dinnerBuffet!,
        if (dinnerBuffetException != null)
          'dinnerBuffetException': dinnerBuffetException!,
        if (freeBreakfast != null) 'freeBreakfast': freeBreakfast!,
        if (freeBreakfastException != null)
          'freeBreakfastException': freeBreakfastException!,
        if (restaurant != null) 'restaurant': restaurant!,
        if (restaurantException != null)
          'restaurantException': restaurantException!,
        if (restaurantsCount != null) 'restaurantsCount': restaurantsCount!,
        if (restaurantsCountException != null)
          'restaurantsCountException': restaurantsCountException!,
        if (roomService != null) 'roomService': roomService!,
        if (roomServiceException != null)
          'roomServiceException': roomServiceException!,
        if (tableService != null) 'tableService': tableService!,
        if (tableServiceException != null)
          'tableServiceException': tableServiceException!,
        if (twentyFourHourRoomService != null)
          'twentyFourHourRoomService': twentyFourHourRoomService!,
        if (twentyFourHourRoomServiceException != null)
          'twentyFourHourRoomServiceException':
              twentyFourHourRoomServiceException!,
        if (vendingMachine != null) 'vendingMachine': vendingMachine!,
        if (vendingMachineException != null)
          'vendingMachineException': vendingMachineException!,
      };
}

/// Response message for LodgingService.GetGoogleUpdatedLodging
class GetGoogleUpdatedLodgingResponse {
  /// The fields in the Lodging that have been updated by Google.
  ///
  /// Repeated field items are not individually specified.
  ///
  /// Required.
  core.String? diffMask;

  /// The Google updated Lodging.
  ///
  /// Required.
  Lodging? lodging;

  GetGoogleUpdatedLodgingResponse();

  GetGoogleUpdatedLodgingResponse.fromJson(core.Map _json) {
    if (_json.containsKey('diffMask')) {
      diffMask = _json['diffMask'] as core.String;
    }
    if (_json.containsKey('lodging')) {
      lodging = Lodging.fromJson(
          _json['lodging'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (diffMask != null) 'diffMask': diffMask!,
        if (lodging != null) 'lodging': lodging!.toJson(),
      };
}

/// Features and available amenities in the guest unit.
class GuestUnitFeatures {
  /// Bungalow or villa.
  ///
  /// An independent structure that is part of a hotel or resort that is rented
  /// to one party for a vacation stay. The hotel or resort may be completely
  /// comprised of bungalows or villas, or they may be one of several guestroom
  /// options. Guests in the bungalows or villas most often have the same, if
  /// not more, amenities and services offered to guests in other guestroom
  /// types.
  core.bool? bungalowOrVilla;

  /// Bungalow or villa exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? bungalowOrVillaException;

  /// Connecting unit available.
  ///
  /// A guestroom type that features access to an adjacent guestroom for the
  /// purpose of booking both rooms. Most often used by families who need more
  /// than one room to accommodate the number of people in their group.
  core.bool? connectingUnitAvailable;

  /// Connecting unit available exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? connectingUnitAvailableException;

  /// Executive floor.
  ///
  /// A floor of the hotel where the guestrooms are only bookable by members of
  /// the hotel's frequent guest membership program. Benefits of this room class
  /// include access to a designated lounge which may or may not feature free
  /// breakfast, cocktails or other perks specific to members of the program.
  core.bool? executiveFloor;

  /// Executive floor exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? executiveFloorException;

  /// Max adult occupants count.
  ///
  /// The total number of adult guests allowed to stay overnight in the
  /// guestroom.
  core.int? maxAdultOccupantsCount;

  /// Max adult occupants count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? maxAdultOccupantsCountException;

  /// Max child occupants count.
  ///
  /// The total number of children allowed to stay overnight in the room.
  core.int? maxChildOccupantsCount;

  /// Max child occupants count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? maxChildOccupantsCountException;

  /// Max occupants count.
  ///
  /// The total number of guests allowed to stay overnight in the guestroom.
  core.int? maxOccupantsCount;

  /// Max occupants count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? maxOccupantsCountException;

  /// Private home.
  ///
  /// A privately owned home (house, townhouse, apartment, cabin, bungalow etc)
  /// that may or not serve as the owner's residence, but is rented out in its
  /// entirety or by the room(s) to paying guest(s) for vacation stays. Not for
  /// lease-based, long-term residency.
  core.bool? privateHome;

  /// Private home exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? privateHomeException;

  /// Suite.
  ///
  /// A guestroom category that implies both a bedroom area and a separate
  /// living area. There may or may not be full walls and doors separating the
  /// two areas, but regardless, they are very distinct. Does not mean a couch
  /// or chair in a bedroom.
  core.bool? suite;

  /// Suite exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? suiteException;

  /// Tier.
  ///
  /// Classification of the unit based on available features/amenities. A
  /// non-standard tier is only permitted if at least one other unit type falls
  /// under the standard tier.
  /// Possible string values are:
  /// - "UNIT_TIER_UNSPECIFIED" : Default tier. Equivalent to STANDARD. Prefer
  /// using STANDARD directly.
  /// - "STANDARD_UNIT" : Standard unit. The predominant and most basic
  /// guestroom type available at the hotel. All other guestroom types include
  /// the features/amenities of this room, as well as additional
  /// features/amenities.
  /// - "DELUXE_UNIT" : Deluxe unit. A guestroom type that builds on the
  /// features of the standard guestroom by offering additional amenities and/or
  /// more space, and/or views. The room rate is higher than that of the
  /// standard room type. Also known as Superior. Only allowed if another unit
  /// type is a standard tier.
  core.String? tier;

  /// Tier exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? tierException;

  /// Features available in the living areas in the guest unit.
  LivingArea? totalLivingAreas;

  /// Views available from the guest unit itself.
  ViewsFromUnit? views;

  GuestUnitFeatures();

  GuestUnitFeatures.fromJson(core.Map _json) {
    if (_json.containsKey('bungalowOrVilla')) {
      bungalowOrVilla = _json['bungalowOrVilla'] as core.bool;
    }
    if (_json.containsKey('bungalowOrVillaException')) {
      bungalowOrVillaException =
          _json['bungalowOrVillaException'] as core.String;
    }
    if (_json.containsKey('connectingUnitAvailable')) {
      connectingUnitAvailable = _json['connectingUnitAvailable'] as core.bool;
    }
    if (_json.containsKey('connectingUnitAvailableException')) {
      connectingUnitAvailableException =
          _json['connectingUnitAvailableException'] as core.String;
    }
    if (_json.containsKey('executiveFloor')) {
      executiveFloor = _json['executiveFloor'] as core.bool;
    }
    if (_json.containsKey('executiveFloorException')) {
      executiveFloorException = _json['executiveFloorException'] as core.String;
    }
    if (_json.containsKey('maxAdultOccupantsCount')) {
      maxAdultOccupantsCount = _json['maxAdultOccupantsCount'] as core.int;
    }
    if (_json.containsKey('maxAdultOccupantsCountException')) {
      maxAdultOccupantsCountException =
          _json['maxAdultOccupantsCountException'] as core.String;
    }
    if (_json.containsKey('maxChildOccupantsCount')) {
      maxChildOccupantsCount = _json['maxChildOccupantsCount'] as core.int;
    }
    if (_json.containsKey('maxChildOccupantsCountException')) {
      maxChildOccupantsCountException =
          _json['maxChildOccupantsCountException'] as core.String;
    }
    if (_json.containsKey('maxOccupantsCount')) {
      maxOccupantsCount = _json['maxOccupantsCount'] as core.int;
    }
    if (_json.containsKey('maxOccupantsCountException')) {
      maxOccupantsCountException =
          _json['maxOccupantsCountException'] as core.String;
    }
    if (_json.containsKey('privateHome')) {
      privateHome = _json['privateHome'] as core.bool;
    }
    if (_json.containsKey('privateHomeException')) {
      privateHomeException = _json['privateHomeException'] as core.String;
    }
    if (_json.containsKey('suite')) {
      suite = _json['suite'] as core.bool;
    }
    if (_json.containsKey('suiteException')) {
      suiteException = _json['suiteException'] as core.String;
    }
    if (_json.containsKey('tier')) {
      tier = _json['tier'] as core.String;
    }
    if (_json.containsKey('tierException')) {
      tierException = _json['tierException'] as core.String;
    }
    if (_json.containsKey('totalLivingAreas')) {
      totalLivingAreas = LivingArea.fromJson(
          _json['totalLivingAreas'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('views')) {
      views = ViewsFromUnit.fromJson(
          _json['views'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bungalowOrVilla != null) 'bungalowOrVilla': bungalowOrVilla!,
        if (bungalowOrVillaException != null)
          'bungalowOrVillaException': bungalowOrVillaException!,
        if (connectingUnitAvailable != null)
          'connectingUnitAvailable': connectingUnitAvailable!,
        if (connectingUnitAvailableException != null)
          'connectingUnitAvailableException': connectingUnitAvailableException!,
        if (executiveFloor != null) 'executiveFloor': executiveFloor!,
        if (executiveFloorException != null)
          'executiveFloorException': executiveFloorException!,
        if (maxAdultOccupantsCount != null)
          'maxAdultOccupantsCount': maxAdultOccupantsCount!,
        if (maxAdultOccupantsCountException != null)
          'maxAdultOccupantsCountException': maxAdultOccupantsCountException!,
        if (maxChildOccupantsCount != null)
          'maxChildOccupantsCount': maxChildOccupantsCount!,
        if (maxChildOccupantsCountException != null)
          'maxChildOccupantsCountException': maxChildOccupantsCountException!,
        if (maxOccupantsCount != null) 'maxOccupantsCount': maxOccupantsCount!,
        if (maxOccupantsCountException != null)
          'maxOccupantsCountException': maxOccupantsCountException!,
        if (privateHome != null) 'privateHome': privateHome!,
        if (privateHomeException != null)
          'privateHomeException': privateHomeException!,
        if (suite != null) 'suite': suite!,
        if (suiteException != null) 'suiteException': suiteException!,
        if (tier != null) 'tier': tier!,
        if (tierException != null) 'tierException': tierException!,
        if (totalLivingAreas != null)
          'totalLivingAreas': totalLivingAreas!.toJson(),
        if (views != null) 'views': views!.toJson(),
      };
}

/// A specific type of unit primarily defined by its features.
class GuestUnitType {
  /// Unit or room code identifiers for a single GuestUnitType.
  ///
  /// Each code must be unique within a Lodging instance.
  ///
  /// Required.
  core.List<core.String>? codes;

  /// Features and available amenities of the GuestUnitType.
  GuestUnitFeatures? features;

  /// Short, English label or name of the GuestUnitType.
  ///
  /// Target <50 chars.
  ///
  /// Required.
  core.String? label;

  GuestUnitType();

  GuestUnitType.fromJson(core.Map _json) {
    if (_json.containsKey('codes')) {
      codes = (_json['codes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('features')) {
      features = GuestUnitFeatures.fromJson(
          _json['features'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('label')) {
      label = _json['label'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (codes != null) 'codes': codes!,
        if (features != null) 'features': features!.toJson(),
        if (label != null) 'label': label!,
      };
}

/// Health and safety measures implemented by the hotel during COVID-19.
class HealthAndSafety {
  /// Enhanced cleaning measures implemented by the hotel during COVID-19.
  EnhancedCleaning? enhancedCleaning;

  /// Increased food safety measures implemented by the hotel during COVID-19.
  IncreasedFoodSafety? increasedFoodSafety;

  /// Minimized contact measures implemented by the hotel during COVID-19.
  MinimizedContact? minimizedContact;

  /// Personal protection measures implemented by the hotel during COVID-19.
  PersonalProtection? personalProtection;

  /// Physical distancing measures implemented by the hotel during COVID-19.
  PhysicalDistancing? physicalDistancing;

  HealthAndSafety();

  HealthAndSafety.fromJson(core.Map _json) {
    if (_json.containsKey('enhancedCleaning')) {
      enhancedCleaning = EnhancedCleaning.fromJson(
          _json['enhancedCleaning'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('increasedFoodSafety')) {
      increasedFoodSafety = IncreasedFoodSafety.fromJson(
          _json['increasedFoodSafety'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('minimizedContact')) {
      minimizedContact = MinimizedContact.fromJson(
          _json['minimizedContact'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('personalProtection')) {
      personalProtection = PersonalProtection.fromJson(
          _json['personalProtection'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('physicalDistancing')) {
      physicalDistancing = PhysicalDistancing.fromJson(
          _json['physicalDistancing'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (enhancedCleaning != null)
          'enhancedCleaning': enhancedCleaning!.toJson(),
        if (increasedFoodSafety != null)
          'increasedFoodSafety': increasedFoodSafety!.toJson(),
        if (minimizedContact != null)
          'minimizedContact': minimizedContact!.toJson(),
        if (personalProtection != null)
          'personalProtection': personalProtection!.toJson(),
        if (physicalDistancing != null)
          'physicalDistancing': physicalDistancing!.toJson(),
      };
}

/// Conveniences provided in guest units to facilitate an easier, more
/// comfortable stay.
class Housekeeping {
  /// Daily housekeeping.
  ///
  /// Guest units are cleaned by hotel staff daily during guest's stay.
  core.bool? dailyHousekeeping;

  /// Daily housekeeping exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? dailyHousekeepingException;

  /// Housekeeping available.
  ///
  /// Guest units are cleaned by hotel staff during guest's stay. Schedule may
  /// vary from daily, weekly, or specific days of the week.
  core.bool? housekeepingAvailable;

  /// Housekeeping available exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? housekeepingAvailableException;

  /// Turndown service.
  ///
  /// Hotel staff enters guest units to prepare the bed for sleep use. May or
  /// may not include some light housekeeping. May or may not include an evening
  /// snack or candy. Also known as evening service.
  core.bool? turndownService;

  /// Turndown service exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? turndownServiceException;

  Housekeeping();

  Housekeeping.fromJson(core.Map _json) {
    if (_json.containsKey('dailyHousekeeping')) {
      dailyHousekeeping = _json['dailyHousekeeping'] as core.bool;
    }
    if (_json.containsKey('dailyHousekeepingException')) {
      dailyHousekeepingException =
          _json['dailyHousekeepingException'] as core.String;
    }
    if (_json.containsKey('housekeepingAvailable')) {
      housekeepingAvailable = _json['housekeepingAvailable'] as core.bool;
    }
    if (_json.containsKey('housekeepingAvailableException')) {
      housekeepingAvailableException =
          _json['housekeepingAvailableException'] as core.String;
    }
    if (_json.containsKey('turndownService')) {
      turndownService = _json['turndownService'] as core.bool;
    }
    if (_json.containsKey('turndownServiceException')) {
      turndownServiceException =
          _json['turndownServiceException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (dailyHousekeeping != null) 'dailyHousekeeping': dailyHousekeeping!,
        if (dailyHousekeepingException != null)
          'dailyHousekeepingException': dailyHousekeepingException!,
        if (housekeepingAvailable != null)
          'housekeepingAvailable': housekeepingAvailable!,
        if (housekeepingAvailableException != null)
          'housekeepingAvailableException': housekeepingAvailableException!,
        if (turndownService != null) 'turndownService': turndownService!,
        if (turndownServiceException != null)
          'turndownServiceException': turndownServiceException!,
      };
}

/// Increased food safety measures implemented by the hotel during COVID-19.
class IncreasedFoodSafety {
  /// Additional sanitation in dining areas.
  core.bool? diningAreasAdditionalSanitation;

  /// Dining areas additional sanitation exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? diningAreasAdditionalSanitationException;

  /// Disposable flatware.
  core.bool? disposableFlatware;

  /// Disposable flatware exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? disposableFlatwareException;

  /// Additional safety measures during food prep and serving.
  core.bool? foodPreparationAndServingAdditionalSafety;

  /// Food preparation and serving additional safety exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? foodPreparationAndServingAdditionalSafetyException;

  /// Individually-packaged meals.
  core.bool? individualPackagedMeals;

  /// Individual packaged meals exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? individualPackagedMealsException;

  /// Single-use menus.
  core.bool? singleUseFoodMenus;

  /// Single use food menus exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? singleUseFoodMenusException;

  IncreasedFoodSafety();

  IncreasedFoodSafety.fromJson(core.Map _json) {
    if (_json.containsKey('diningAreasAdditionalSanitation')) {
      diningAreasAdditionalSanitation =
          _json['diningAreasAdditionalSanitation'] as core.bool;
    }
    if (_json.containsKey('diningAreasAdditionalSanitationException')) {
      diningAreasAdditionalSanitationException =
          _json['diningAreasAdditionalSanitationException'] as core.String;
    }
    if (_json.containsKey('disposableFlatware')) {
      disposableFlatware = _json['disposableFlatware'] as core.bool;
    }
    if (_json.containsKey('disposableFlatwareException')) {
      disposableFlatwareException =
          _json['disposableFlatwareException'] as core.String;
    }
    if (_json.containsKey('foodPreparationAndServingAdditionalSafety')) {
      foodPreparationAndServingAdditionalSafety =
          _json['foodPreparationAndServingAdditionalSafety'] as core.bool;
    }
    if (_json
        .containsKey('foodPreparationAndServingAdditionalSafetyException')) {
      foodPreparationAndServingAdditionalSafetyException =
          _json['foodPreparationAndServingAdditionalSafetyException']
              as core.String;
    }
    if (_json.containsKey('individualPackagedMeals')) {
      individualPackagedMeals = _json['individualPackagedMeals'] as core.bool;
    }
    if (_json.containsKey('individualPackagedMealsException')) {
      individualPackagedMealsException =
          _json['individualPackagedMealsException'] as core.String;
    }
    if (_json.containsKey('singleUseFoodMenus')) {
      singleUseFoodMenus = _json['singleUseFoodMenus'] as core.bool;
    }
    if (_json.containsKey('singleUseFoodMenusException')) {
      singleUseFoodMenusException =
          _json['singleUseFoodMenusException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (diningAreasAdditionalSanitation != null)
          'diningAreasAdditionalSanitation': diningAreasAdditionalSanitation!,
        if (diningAreasAdditionalSanitationException != null)
          'diningAreasAdditionalSanitationException':
              diningAreasAdditionalSanitationException!,
        if (disposableFlatware != null)
          'disposableFlatware': disposableFlatware!,
        if (disposableFlatwareException != null)
          'disposableFlatwareException': disposableFlatwareException!,
        if (foodPreparationAndServingAdditionalSafety != null)
          'foodPreparationAndServingAdditionalSafety':
              foodPreparationAndServingAdditionalSafety!,
        if (foodPreparationAndServingAdditionalSafetyException != null)
          'foodPreparationAndServingAdditionalSafetyException':
              foodPreparationAndServingAdditionalSafetyException!,
        if (individualPackagedMeals != null)
          'individualPackagedMeals': individualPackagedMeals!,
        if (individualPackagedMealsException != null)
          'individualPackagedMealsException': individualPackagedMealsException!,
        if (singleUseFoodMenus != null)
          'singleUseFoodMenus': singleUseFoodMenus!,
        if (singleUseFoodMenusException != null)
          'singleUseFoodMenusException': singleUseFoodMenusException!,
      };
}

/// Language spoken by at least one staff member.
class LanguageSpoken {
  /// The BCP-47 language code for the spoken language.
  ///
  /// Currently accepted codes: ar, de, en, es, fil, fr, hi, id, it, ja, ko, nl,
  /// pt, ru, vi, yue, zh.
  ///
  /// Required.
  core.String? languageCode;

  /// At least one member of the staff can speak the language.
  core.bool? spoken;

  /// Spoken exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? spokenException;

  LanguageSpoken();

  LanguageSpoken.fromJson(core.Map _json) {
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('spoken')) {
      spoken = _json['spoken'] as core.bool;
    }
    if (_json.containsKey('spokenException')) {
      spokenException = _json['spokenException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (languageCode != null) 'languageCode': languageCode!,
        if (spoken != null) 'spoken': spoken!,
        if (spokenException != null) 'spokenException': spokenException!,
      };
}

/// An individual room, such as kitchen, bathroom, bedroom, within a bookable
/// guest unit.
class LivingArea {
  /// Accessibility features of the living area.
  LivingAreaAccessibility? accessibility;

  /// Information about eating features in the living area.
  LivingAreaEating? eating;

  /// Features in the living area.
  LivingAreaFeatures? features;

  /// Information about the layout of the living area.
  LivingAreaLayout? layout;

  /// Information about sleeping features in the living area.
  LivingAreaSleeping? sleeping;

  LivingArea();

  LivingArea.fromJson(core.Map _json) {
    if (_json.containsKey('accessibility')) {
      accessibility = LivingAreaAccessibility.fromJson(
          _json['accessibility'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('eating')) {
      eating = LivingAreaEating.fromJson(
          _json['eating'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('features')) {
      features = LivingAreaFeatures.fromJson(
          _json['features'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('layout')) {
      layout = LivingAreaLayout.fromJson(
          _json['layout'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sleeping')) {
      sleeping = LivingAreaSleeping.fromJson(
          _json['sleeping'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessibility != null) 'accessibility': accessibility!.toJson(),
        if (eating != null) 'eating': eating!.toJson(),
        if (features != null) 'features': features!.toJson(),
        if (layout != null) 'layout': layout!.toJson(),
        if (sleeping != null) 'sleeping': sleeping!.toJson(),
      };
}

/// Accessibility features of the living area.
class LivingAreaAccessibility {
  /// ADA compliant unit.
  ///
  /// A guestroom designed to accommodate the physical challenges of a guest
  /// with mobility and/or auditory and/or visual issues, as determined by
  /// legislative policy. Usually features enlarged doorways, roll-in showers
  /// with seats, bathroom grab bars, and communication equipment for the
  /// hearing and sight challenged.
  core.bool? adaCompliantUnit;

  /// ADA compliant unit exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? adaCompliantUnitException;

  /// Hearing-accessible doorbell.
  ///
  /// A visual indicator(s) of a knock or ring at the door.
  core.bool? hearingAccessibleDoorbell;

  /// Hearing-accessible doorbell exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? hearingAccessibleDoorbellException;

  /// Hearing-accessible fire alarm.
  ///
  /// A device that gives warning of a fire through flashing lights.
  core.bool? hearingAccessibleFireAlarm;

  /// Hearing-accessible fire alarm exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? hearingAccessibleFireAlarmException;

  /// Hearing-accessible unit.
  ///
  /// A guestroom designed to accommodate the physical challenges of a guest
  /// with auditory issues.
  core.bool? hearingAccessibleUnit;

  /// Hearing-accessible unit exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? hearingAccessibleUnitException;

  /// Mobility-accessible bathtub.
  ///
  /// A bathtub that accomodates the physically challenged with additional
  /// railings or hand grips, a transfer seat or lift, and/or a door to enable
  /// walking into the tub.
  core.bool? mobilityAccessibleBathtub;

  /// Mobility-accessible bathtub exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? mobilityAccessibleBathtubException;

  /// Mobility-accessible shower.
  ///
  /// A shower with an enlarged door or access point to accommodate a wheelchair
  /// or a waterproof seat for the physically challenged.
  core.bool? mobilityAccessibleShower;

  /// Mobility-accessible shower exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? mobilityAccessibleShowerException;

  /// Mobility-accessible toilet.
  ///
  /// A toilet with a higher seat, grab bars, and/or a larger area around it to
  /// accommodate the physically challenged.
  core.bool? mobilityAccessibleToilet;

  /// Mobility-accessible toilet exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? mobilityAccessibleToiletException;

  /// Mobility-accessible unit.
  ///
  /// A guestroom designed to accommodate the physical challenges of a guest
  /// with mobility and/or auditory and/or visual issues. Usually features
  /// enlarged doorways, roll-in showers with seats, bathroom grab bars, and
  /// communication equipment for the hearing and sight challenged.
  core.bool? mobilityAccessibleUnit;

  /// Mobility-accessible unit exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? mobilityAccessibleUnitException;

  LivingAreaAccessibility();

  LivingAreaAccessibility.fromJson(core.Map _json) {
    if (_json.containsKey('adaCompliantUnit')) {
      adaCompliantUnit = _json['adaCompliantUnit'] as core.bool;
    }
    if (_json.containsKey('adaCompliantUnitException')) {
      adaCompliantUnitException =
          _json['adaCompliantUnitException'] as core.String;
    }
    if (_json.containsKey('hearingAccessibleDoorbell')) {
      hearingAccessibleDoorbell =
          _json['hearingAccessibleDoorbell'] as core.bool;
    }
    if (_json.containsKey('hearingAccessibleDoorbellException')) {
      hearingAccessibleDoorbellException =
          _json['hearingAccessibleDoorbellException'] as core.String;
    }
    if (_json.containsKey('hearingAccessibleFireAlarm')) {
      hearingAccessibleFireAlarm =
          _json['hearingAccessibleFireAlarm'] as core.bool;
    }
    if (_json.containsKey('hearingAccessibleFireAlarmException')) {
      hearingAccessibleFireAlarmException =
          _json['hearingAccessibleFireAlarmException'] as core.String;
    }
    if (_json.containsKey('hearingAccessibleUnit')) {
      hearingAccessibleUnit = _json['hearingAccessibleUnit'] as core.bool;
    }
    if (_json.containsKey('hearingAccessibleUnitException')) {
      hearingAccessibleUnitException =
          _json['hearingAccessibleUnitException'] as core.String;
    }
    if (_json.containsKey('mobilityAccessibleBathtub')) {
      mobilityAccessibleBathtub =
          _json['mobilityAccessibleBathtub'] as core.bool;
    }
    if (_json.containsKey('mobilityAccessibleBathtubException')) {
      mobilityAccessibleBathtubException =
          _json['mobilityAccessibleBathtubException'] as core.String;
    }
    if (_json.containsKey('mobilityAccessibleShower')) {
      mobilityAccessibleShower = _json['mobilityAccessibleShower'] as core.bool;
    }
    if (_json.containsKey('mobilityAccessibleShowerException')) {
      mobilityAccessibleShowerException =
          _json['mobilityAccessibleShowerException'] as core.String;
    }
    if (_json.containsKey('mobilityAccessibleToilet')) {
      mobilityAccessibleToilet = _json['mobilityAccessibleToilet'] as core.bool;
    }
    if (_json.containsKey('mobilityAccessibleToiletException')) {
      mobilityAccessibleToiletException =
          _json['mobilityAccessibleToiletException'] as core.String;
    }
    if (_json.containsKey('mobilityAccessibleUnit')) {
      mobilityAccessibleUnit = _json['mobilityAccessibleUnit'] as core.bool;
    }
    if (_json.containsKey('mobilityAccessibleUnitException')) {
      mobilityAccessibleUnitException =
          _json['mobilityAccessibleUnitException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adaCompliantUnit != null) 'adaCompliantUnit': adaCompliantUnit!,
        if (adaCompliantUnitException != null)
          'adaCompliantUnitException': adaCompliantUnitException!,
        if (hearingAccessibleDoorbell != null)
          'hearingAccessibleDoorbell': hearingAccessibleDoorbell!,
        if (hearingAccessibleDoorbellException != null)
          'hearingAccessibleDoorbellException':
              hearingAccessibleDoorbellException!,
        if (hearingAccessibleFireAlarm != null)
          'hearingAccessibleFireAlarm': hearingAccessibleFireAlarm!,
        if (hearingAccessibleFireAlarmException != null)
          'hearingAccessibleFireAlarmException':
              hearingAccessibleFireAlarmException!,
        if (hearingAccessibleUnit != null)
          'hearingAccessibleUnit': hearingAccessibleUnit!,
        if (hearingAccessibleUnitException != null)
          'hearingAccessibleUnitException': hearingAccessibleUnitException!,
        if (mobilityAccessibleBathtub != null)
          'mobilityAccessibleBathtub': mobilityAccessibleBathtub!,
        if (mobilityAccessibleBathtubException != null)
          'mobilityAccessibleBathtubException':
              mobilityAccessibleBathtubException!,
        if (mobilityAccessibleShower != null)
          'mobilityAccessibleShower': mobilityAccessibleShower!,
        if (mobilityAccessibleShowerException != null)
          'mobilityAccessibleShowerException':
              mobilityAccessibleShowerException!,
        if (mobilityAccessibleToilet != null)
          'mobilityAccessibleToilet': mobilityAccessibleToilet!,
        if (mobilityAccessibleToiletException != null)
          'mobilityAccessibleToiletException':
              mobilityAccessibleToiletException!,
        if (mobilityAccessibleUnit != null)
          'mobilityAccessibleUnit': mobilityAccessibleUnit!,
        if (mobilityAccessibleUnitException != null)
          'mobilityAccessibleUnitException': mobilityAccessibleUnitException!,
      };
}

/// Information about eating features in the living area.
class LivingAreaEating {
  /// Coffee maker.
  ///
  /// An electric appliance that brews coffee by heating and forcing water
  /// through ground coffee.
  core.bool? coffeeMaker;

  /// Coffee maker exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? coffeeMakerException;

  /// Cookware.
  ///
  /// Kitchen pots, pans and utensils used in connection with the preparation of
  /// food.
  core.bool? cookware;

  /// Cookware exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? cookwareException;

  /// Dishwasher.
  ///
  /// A counter-height electrical cabinet containing racks for dirty dishware,
  /// cookware and cutlery, and a dispenser for soap built into the pull-down
  /// door. The cabinet is attached to the plumbing system to facilitate the
  /// automatic cleaning of its contents.
  core.bool? dishwasher;

  /// Dishwasher exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? dishwasherException;

  /// Indoor grill.
  ///
  /// Metal grates built into an indoor cooktop on which food is cooked over an
  /// open flame or electric heat source.
  core.bool? indoorGrill;

  /// Indoor grill exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? indoorGrillException;

  /// Kettle.
  ///
  /// A covered container with a handle and a spout used for boiling water.
  core.bool? kettle;

  /// Kettle exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? kettleException;

  /// Kitchen available.
  ///
  /// An area of the guestroom designated for the preparation and storage of
  /// food via the presence of a refrigerator, cook top, oven and sink, as well
  /// as cutlery, dishes and cookware. Usually includes small appliances such a
  /// coffee maker and a microwave. May or may not include an automatic
  /// dishwasher.
  core.bool? kitchenAvailable;

  /// Kitchen available exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? kitchenAvailableException;

  /// Microwave.
  ///
  /// An electric oven that quickly cooks and heats food by microwave energy.
  /// Smaller than a standing or wall mounted oven. Usually placed on a kitchen
  /// counter, a shelf or tabletop or mounted above a cooktop.
  core.bool? microwave;

  /// Microwave exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? microwaveException;

  /// Minibar.
  ///
  /// A small refrigerated cabinet in the guestroom containing bottles/cans of
  /// soft drinks, mini bottles of alcohol, and snacks. The items are most
  /// commonly available for a fee.
  core.bool? minibar;

  /// Minibar exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? minibarException;

  /// Outdoor grill.
  ///
  /// Metal grates on which food is cooked over an open flame or electric heat
  /// source. Part of an outdoor apparatus that supports the grates. Also known
  /// as barbecue grill or barbecue.
  core.bool? outdoorGrill;

  /// Outdoor grill exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? outdoorGrillException;

  /// Oven.
  ///
  /// A temperature controlled, heated metal cabinet powered by gas or
  /// electricity in which food is placed for the purpose of cooking or
  /// reheating.
  core.bool? oven;

  /// Oven exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? ovenException;

  /// Refrigerator.
  ///
  /// A large, climate-controlled electrical cabinet with vertical doors. Built
  /// for the purpose of chilling and storing perishable foods.
  core.bool? refrigerator;

  /// Refrigerator exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? refrigeratorException;

  /// Sink.
  ///
  /// A basin with a faucet attached to a water source and used for the purpose
  /// of washing and rinsing.
  core.bool? sink;

  /// Sink exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? sinkException;

  /// Snackbar.
  ///
  /// A small cabinet in the guestroom containing snacks. The items are most
  /// commonly available for a fee.
  core.bool? snackbar;

  /// Snackbar exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? snackbarException;

  /// Stove.
  ///
  /// A kitchen appliance powered by gas or electricity for the purpose of
  /// creating a flame or hot surface on which pots of food can be cooked. Also
  /// known as cooktop or hob.
  core.bool? stove;

  /// Stove exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? stoveException;

  /// Tea station.
  ///
  /// A small area with the supplies needed to heat water and make tea.
  core.bool? teaStation;

  /// Tea station exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? teaStationException;

  /// Toaster.
  ///
  /// A small, temperature controlled electric appliance with rectangular slots
  /// at the top that are lined with heated coils for the purpose of browning
  /// slices of bread products.
  core.bool? toaster;

  /// Toaster exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? toasterException;

  LivingAreaEating();

  LivingAreaEating.fromJson(core.Map _json) {
    if (_json.containsKey('coffeeMaker')) {
      coffeeMaker = _json['coffeeMaker'] as core.bool;
    }
    if (_json.containsKey('coffeeMakerException')) {
      coffeeMakerException = _json['coffeeMakerException'] as core.String;
    }
    if (_json.containsKey('cookware')) {
      cookware = _json['cookware'] as core.bool;
    }
    if (_json.containsKey('cookwareException')) {
      cookwareException = _json['cookwareException'] as core.String;
    }
    if (_json.containsKey('dishwasher')) {
      dishwasher = _json['dishwasher'] as core.bool;
    }
    if (_json.containsKey('dishwasherException')) {
      dishwasherException = _json['dishwasherException'] as core.String;
    }
    if (_json.containsKey('indoorGrill')) {
      indoorGrill = _json['indoorGrill'] as core.bool;
    }
    if (_json.containsKey('indoorGrillException')) {
      indoorGrillException = _json['indoorGrillException'] as core.String;
    }
    if (_json.containsKey('kettle')) {
      kettle = _json['kettle'] as core.bool;
    }
    if (_json.containsKey('kettleException')) {
      kettleException = _json['kettleException'] as core.String;
    }
    if (_json.containsKey('kitchenAvailable')) {
      kitchenAvailable = _json['kitchenAvailable'] as core.bool;
    }
    if (_json.containsKey('kitchenAvailableException')) {
      kitchenAvailableException =
          _json['kitchenAvailableException'] as core.String;
    }
    if (_json.containsKey('microwave')) {
      microwave = _json['microwave'] as core.bool;
    }
    if (_json.containsKey('microwaveException')) {
      microwaveException = _json['microwaveException'] as core.String;
    }
    if (_json.containsKey('minibar')) {
      minibar = _json['minibar'] as core.bool;
    }
    if (_json.containsKey('minibarException')) {
      minibarException = _json['minibarException'] as core.String;
    }
    if (_json.containsKey('outdoorGrill')) {
      outdoorGrill = _json['outdoorGrill'] as core.bool;
    }
    if (_json.containsKey('outdoorGrillException')) {
      outdoorGrillException = _json['outdoorGrillException'] as core.String;
    }
    if (_json.containsKey('oven')) {
      oven = _json['oven'] as core.bool;
    }
    if (_json.containsKey('ovenException')) {
      ovenException = _json['ovenException'] as core.String;
    }
    if (_json.containsKey('refrigerator')) {
      refrigerator = _json['refrigerator'] as core.bool;
    }
    if (_json.containsKey('refrigeratorException')) {
      refrigeratorException = _json['refrigeratorException'] as core.String;
    }
    if (_json.containsKey('sink')) {
      sink = _json['sink'] as core.bool;
    }
    if (_json.containsKey('sinkException')) {
      sinkException = _json['sinkException'] as core.String;
    }
    if (_json.containsKey('snackbar')) {
      snackbar = _json['snackbar'] as core.bool;
    }
    if (_json.containsKey('snackbarException')) {
      snackbarException = _json['snackbarException'] as core.String;
    }
    if (_json.containsKey('stove')) {
      stove = _json['stove'] as core.bool;
    }
    if (_json.containsKey('stoveException')) {
      stoveException = _json['stoveException'] as core.String;
    }
    if (_json.containsKey('teaStation')) {
      teaStation = _json['teaStation'] as core.bool;
    }
    if (_json.containsKey('teaStationException')) {
      teaStationException = _json['teaStationException'] as core.String;
    }
    if (_json.containsKey('toaster')) {
      toaster = _json['toaster'] as core.bool;
    }
    if (_json.containsKey('toasterException')) {
      toasterException = _json['toasterException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (coffeeMaker != null) 'coffeeMaker': coffeeMaker!,
        if (coffeeMakerException != null)
          'coffeeMakerException': coffeeMakerException!,
        if (cookware != null) 'cookware': cookware!,
        if (cookwareException != null) 'cookwareException': cookwareException!,
        if (dishwasher != null) 'dishwasher': dishwasher!,
        if (dishwasherException != null)
          'dishwasherException': dishwasherException!,
        if (indoorGrill != null) 'indoorGrill': indoorGrill!,
        if (indoorGrillException != null)
          'indoorGrillException': indoorGrillException!,
        if (kettle != null) 'kettle': kettle!,
        if (kettleException != null) 'kettleException': kettleException!,
        if (kitchenAvailable != null) 'kitchenAvailable': kitchenAvailable!,
        if (kitchenAvailableException != null)
          'kitchenAvailableException': kitchenAvailableException!,
        if (microwave != null) 'microwave': microwave!,
        if (microwaveException != null)
          'microwaveException': microwaveException!,
        if (minibar != null) 'minibar': minibar!,
        if (minibarException != null) 'minibarException': minibarException!,
        if (outdoorGrill != null) 'outdoorGrill': outdoorGrill!,
        if (outdoorGrillException != null)
          'outdoorGrillException': outdoorGrillException!,
        if (oven != null) 'oven': oven!,
        if (ovenException != null) 'ovenException': ovenException!,
        if (refrigerator != null) 'refrigerator': refrigerator!,
        if (refrigeratorException != null)
          'refrigeratorException': refrigeratorException!,
        if (sink != null) 'sink': sink!,
        if (sinkException != null) 'sinkException': sinkException!,
        if (snackbar != null) 'snackbar': snackbar!,
        if (snackbarException != null) 'snackbarException': snackbarException!,
        if (stove != null) 'stove': stove!,
        if (stoveException != null) 'stoveException': stoveException!,
        if (teaStation != null) 'teaStation': teaStation!,
        if (teaStationException != null)
          'teaStationException': teaStationException!,
        if (toaster != null) 'toaster': toaster!,
        if (toasterException != null) 'toasterException': toasterException!,
      };
}

/// Features in the living area.
class LivingAreaFeatures {
  /// Air conditioning.
  ///
  /// An electrical machine used to cool the temperature of the guestroom.
  core.bool? airConditioning;

  /// Air conditioning exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? airConditioningException;

  /// Bathtub.
  ///
  /// A fixed plumbing feature set on the floor and consisting of a large
  /// container that accommodates the body of an adult for the purpose of seated
  /// bathing. Includes knobs or fixtures to control the temperature of the
  /// water, a faucet through which the water flows, and a drain that can be
  /// closed for filling and opened for draining.
  core.bool? bathtub;

  /// Bathtub exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? bathtubException;

  /// Bidet.
  ///
  /// A plumbing fixture attached to a toilet or a low, fixed sink designed for
  /// the purpose of washing after toilet use.
  core.bool? bidet;

  /// Bidet exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? bidetException;

  /// Dryer.
  ///
  /// An electrical machine designed to dry clothing.
  core.bool? dryer;

  /// Dryer exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? dryerException;

  /// Electronic room key.
  ///
  /// A card coded by the check-in computer that is read by the lock on the
  /// hotel guestroom door to allow for entry.
  core.bool? electronicRoomKey;

  /// Electronic room key exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? electronicRoomKeyException;

  /// Fireplace.
  ///
  /// A framed opening (aka hearth) at the base of a chimney in which logs or an
  /// electrical fire feature are burned to provide a relaxing ambiance or to
  /// heat the room. Often made of bricks or stone.
  core.bool? fireplace;

  /// Fireplace exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? fireplaceException;

  /// Hairdryer.
  ///
  /// A handheld electric appliance that blows temperature-controlled air for
  /// the purpose of drying wet hair. Can be mounted to a bathroom wall or a
  /// freestanding device stored in the guestroom's bathroom or closet.
  core.bool? hairdryer;

  /// Hairdryer exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? hairdryerException;

  /// Heating.
  ///
  /// An electrical machine used to warm the temperature of the guestroom.
  core.bool? heating;

  /// Heating exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? heatingException;

  /// In-unit safe.
  ///
  /// A strong fireproof cabinet with a programmable lock, used for the
  /// protected storage of valuables in a guestroom. Often built into a closet.
  core.bool? inunitSafe;

  /// In-unit safe exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? inunitSafeException;

  /// In-unit Wifi available.
  ///
  /// Guests can wirelessly connect to the Internet in the guestroom. Can be
  /// free or for a fee.
  core.bool? inunitWifiAvailable;

  /// In-unit Wifi available exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? inunitWifiAvailableException;

  /// Ironing equipment.
  ///
  /// A device, usually with a flat metal base, that is heated to smooth,
  /// finish, or press clothes and a flat, padded, cloth-covered surface on
  /// which the clothes are worked.
  core.bool? ironingEquipment;

  /// Ironing equipment exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? ironingEquipmentException;

  /// Pay per view movies.
  ///
  /// Televisions with channels that offer films that can be viewed for a fee,
  /// and have an interface to allow the viewer to accept the terms and approve
  /// payment.
  core.bool? payPerViewMovies;

  /// Pay per view movies exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? payPerViewMoviesException;

  /// Private bathroom.
  ///
  /// A bathroom designated for the express use of the guests staying in a
  /// specific guestroom.
  core.bool? privateBathroom;

  /// Private bathroom exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? privateBathroomException;

  /// Shower.
  ///
  /// A fixed plumbing fixture for standing bathing that features a tall spray
  /// spout or faucet through which water flows, a knob or knobs that control
  /// the water's temperature, and a drain in the floor.
  core.bool? shower;

  /// Shower exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? showerException;

  /// Toilet.
  ///
  /// A fixed bathroom feature connected to a sewer or septic system and
  /// consisting of a water-flushed bowl with a seat, as well as a device that
  /// elicites the water-flushing action. Used for the process and disposal of
  /// human waste.
  core.bool? toilet;

  /// Toilet exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? toiletException;

  /// TV.
  ///
  /// A television is available in the guestroom.
  core.bool? tv;

  /// TV casting.
  ///
  /// A television equipped with a device through which the video entertainment
  /// accessed on a personal computer, phone or tablet can be wirelessly
  /// delivered to and viewed on the guestroom's television.
  core.bool? tvCasting;

  /// TV exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? tvCastingException;

  /// TV exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? tvException;

  /// TV streaming.
  ///
  /// Televisions that embed a range of web-based apps to allow for watching
  /// media from those apps.
  core.bool? tvStreaming;

  /// TV streaming exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? tvStreamingException;

  /// Universal power adapters.
  ///
  /// A power supply for electronic devices which plugs into a wall for the
  /// purpose of converting AC to a single DC voltage. Also know as AC adapter
  /// or charger.
  core.bool? universalPowerAdapters;

  /// Universal power adapters exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? universalPowerAdaptersException;

  /// Washer.
  ///
  /// An electrical machine connected to a running water source designed to
  /// launder clothing.
  core.bool? washer;

  /// Washer exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? washerException;

  LivingAreaFeatures();

  LivingAreaFeatures.fromJson(core.Map _json) {
    if (_json.containsKey('airConditioning')) {
      airConditioning = _json['airConditioning'] as core.bool;
    }
    if (_json.containsKey('airConditioningException')) {
      airConditioningException =
          _json['airConditioningException'] as core.String;
    }
    if (_json.containsKey('bathtub')) {
      bathtub = _json['bathtub'] as core.bool;
    }
    if (_json.containsKey('bathtubException')) {
      bathtubException = _json['bathtubException'] as core.String;
    }
    if (_json.containsKey('bidet')) {
      bidet = _json['bidet'] as core.bool;
    }
    if (_json.containsKey('bidetException')) {
      bidetException = _json['bidetException'] as core.String;
    }
    if (_json.containsKey('dryer')) {
      dryer = _json['dryer'] as core.bool;
    }
    if (_json.containsKey('dryerException')) {
      dryerException = _json['dryerException'] as core.String;
    }
    if (_json.containsKey('electronicRoomKey')) {
      electronicRoomKey = _json['electronicRoomKey'] as core.bool;
    }
    if (_json.containsKey('electronicRoomKeyException')) {
      electronicRoomKeyException =
          _json['electronicRoomKeyException'] as core.String;
    }
    if (_json.containsKey('fireplace')) {
      fireplace = _json['fireplace'] as core.bool;
    }
    if (_json.containsKey('fireplaceException')) {
      fireplaceException = _json['fireplaceException'] as core.String;
    }
    if (_json.containsKey('hairdryer')) {
      hairdryer = _json['hairdryer'] as core.bool;
    }
    if (_json.containsKey('hairdryerException')) {
      hairdryerException = _json['hairdryerException'] as core.String;
    }
    if (_json.containsKey('heating')) {
      heating = _json['heating'] as core.bool;
    }
    if (_json.containsKey('heatingException')) {
      heatingException = _json['heatingException'] as core.String;
    }
    if (_json.containsKey('inunitSafe')) {
      inunitSafe = _json['inunitSafe'] as core.bool;
    }
    if (_json.containsKey('inunitSafeException')) {
      inunitSafeException = _json['inunitSafeException'] as core.String;
    }
    if (_json.containsKey('inunitWifiAvailable')) {
      inunitWifiAvailable = _json['inunitWifiAvailable'] as core.bool;
    }
    if (_json.containsKey('inunitWifiAvailableException')) {
      inunitWifiAvailableException =
          _json['inunitWifiAvailableException'] as core.String;
    }
    if (_json.containsKey('ironingEquipment')) {
      ironingEquipment = _json['ironingEquipment'] as core.bool;
    }
    if (_json.containsKey('ironingEquipmentException')) {
      ironingEquipmentException =
          _json['ironingEquipmentException'] as core.String;
    }
    if (_json.containsKey('payPerViewMovies')) {
      payPerViewMovies = _json['payPerViewMovies'] as core.bool;
    }
    if (_json.containsKey('payPerViewMoviesException')) {
      payPerViewMoviesException =
          _json['payPerViewMoviesException'] as core.String;
    }
    if (_json.containsKey('privateBathroom')) {
      privateBathroom = _json['privateBathroom'] as core.bool;
    }
    if (_json.containsKey('privateBathroomException')) {
      privateBathroomException =
          _json['privateBathroomException'] as core.String;
    }
    if (_json.containsKey('shower')) {
      shower = _json['shower'] as core.bool;
    }
    if (_json.containsKey('showerException')) {
      showerException = _json['showerException'] as core.String;
    }
    if (_json.containsKey('toilet')) {
      toilet = _json['toilet'] as core.bool;
    }
    if (_json.containsKey('toiletException')) {
      toiletException = _json['toiletException'] as core.String;
    }
    if (_json.containsKey('tv')) {
      tv = _json['tv'] as core.bool;
    }
    if (_json.containsKey('tvCasting')) {
      tvCasting = _json['tvCasting'] as core.bool;
    }
    if (_json.containsKey('tvCastingException')) {
      tvCastingException = _json['tvCastingException'] as core.String;
    }
    if (_json.containsKey('tvException')) {
      tvException = _json['tvException'] as core.String;
    }
    if (_json.containsKey('tvStreaming')) {
      tvStreaming = _json['tvStreaming'] as core.bool;
    }
    if (_json.containsKey('tvStreamingException')) {
      tvStreamingException = _json['tvStreamingException'] as core.String;
    }
    if (_json.containsKey('universalPowerAdapters')) {
      universalPowerAdapters = _json['universalPowerAdapters'] as core.bool;
    }
    if (_json.containsKey('universalPowerAdaptersException')) {
      universalPowerAdaptersException =
          _json['universalPowerAdaptersException'] as core.String;
    }
    if (_json.containsKey('washer')) {
      washer = _json['washer'] as core.bool;
    }
    if (_json.containsKey('washerException')) {
      washerException = _json['washerException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (airConditioning != null) 'airConditioning': airConditioning!,
        if (airConditioningException != null)
          'airConditioningException': airConditioningException!,
        if (bathtub != null) 'bathtub': bathtub!,
        if (bathtubException != null) 'bathtubException': bathtubException!,
        if (bidet != null) 'bidet': bidet!,
        if (bidetException != null) 'bidetException': bidetException!,
        if (dryer != null) 'dryer': dryer!,
        if (dryerException != null) 'dryerException': dryerException!,
        if (electronicRoomKey != null) 'electronicRoomKey': electronicRoomKey!,
        if (electronicRoomKeyException != null)
          'electronicRoomKeyException': electronicRoomKeyException!,
        if (fireplace != null) 'fireplace': fireplace!,
        if (fireplaceException != null)
          'fireplaceException': fireplaceException!,
        if (hairdryer != null) 'hairdryer': hairdryer!,
        if (hairdryerException != null)
          'hairdryerException': hairdryerException!,
        if (heating != null) 'heating': heating!,
        if (heatingException != null) 'heatingException': heatingException!,
        if (inunitSafe != null) 'inunitSafe': inunitSafe!,
        if (inunitSafeException != null)
          'inunitSafeException': inunitSafeException!,
        if (inunitWifiAvailable != null)
          'inunitWifiAvailable': inunitWifiAvailable!,
        if (inunitWifiAvailableException != null)
          'inunitWifiAvailableException': inunitWifiAvailableException!,
        if (ironingEquipment != null) 'ironingEquipment': ironingEquipment!,
        if (ironingEquipmentException != null)
          'ironingEquipmentException': ironingEquipmentException!,
        if (payPerViewMovies != null) 'payPerViewMovies': payPerViewMovies!,
        if (payPerViewMoviesException != null)
          'payPerViewMoviesException': payPerViewMoviesException!,
        if (privateBathroom != null) 'privateBathroom': privateBathroom!,
        if (privateBathroomException != null)
          'privateBathroomException': privateBathroomException!,
        if (shower != null) 'shower': shower!,
        if (showerException != null) 'showerException': showerException!,
        if (toilet != null) 'toilet': toilet!,
        if (toiletException != null) 'toiletException': toiletException!,
        if (tv != null) 'tv': tv!,
        if (tvCasting != null) 'tvCasting': tvCasting!,
        if (tvCastingException != null)
          'tvCastingException': tvCastingException!,
        if (tvException != null) 'tvException': tvException!,
        if (tvStreaming != null) 'tvStreaming': tvStreaming!,
        if (tvStreamingException != null)
          'tvStreamingException': tvStreamingException!,
        if (universalPowerAdapters != null)
          'universalPowerAdapters': universalPowerAdapters!,
        if (universalPowerAdaptersException != null)
          'universalPowerAdaptersException': universalPowerAdaptersException!,
        if (washer != null) 'washer': washer!,
        if (washerException != null) 'washerException': washerException!,
      };
}

/// Information about the layout of the living area.
class LivingAreaLayout {
  /// Balcony.
  ///
  /// An outdoor platform attached to a building and surrounded by a short wall,
  /// fence or other safety railing. The balcony is accessed through a door in a
  /// guestroom or suite and is for use by the guest staying in that room. May
  /// or may not include seating or outdoor furniture. Is not located on the
  /// ground floor. Also lanai.
  core.bool? balcony;

  /// Balcony exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? balconyException;

  /// Living area sq meters.
  ///
  /// The measurement in meters of the area of a guestroom's living space.
  core.double? livingAreaSqMeters;

  /// Living area sq meters exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? livingAreaSqMetersException;

  /// Loft.
  ///
  /// A three-walled upper area accessed by stairs or a ladder that overlooks
  /// the lower area of a room.
  core.bool? loft;

  /// Loft exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? loftException;

  /// Non smoking.
  ///
  /// A guestroom in which the smoking of cigarettes, cigars and pipes is
  /// prohibited.
  core.bool? nonSmoking;

  /// Non smoking exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? nonSmokingException;

  /// Patio.
  ///
  /// A paved, outdoor area with seating attached to and accessed through a
  /// ground-floor guestroom for use by the occupants of the guestroom.
  core.bool? patio;

  /// Patio exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? patioException;

  /// Stairs.
  ///
  /// There are steps leading from one level or story to another in the unit.
  core.bool? stairs;

  /// Stairs exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? stairsException;

  LivingAreaLayout();

  LivingAreaLayout.fromJson(core.Map _json) {
    if (_json.containsKey('balcony')) {
      balcony = _json['balcony'] as core.bool;
    }
    if (_json.containsKey('balconyException')) {
      balconyException = _json['balconyException'] as core.String;
    }
    if (_json.containsKey('livingAreaSqMeters')) {
      livingAreaSqMeters = (_json['livingAreaSqMeters'] as core.num).toDouble();
    }
    if (_json.containsKey('livingAreaSqMetersException')) {
      livingAreaSqMetersException =
          _json['livingAreaSqMetersException'] as core.String;
    }
    if (_json.containsKey('loft')) {
      loft = _json['loft'] as core.bool;
    }
    if (_json.containsKey('loftException')) {
      loftException = _json['loftException'] as core.String;
    }
    if (_json.containsKey('nonSmoking')) {
      nonSmoking = _json['nonSmoking'] as core.bool;
    }
    if (_json.containsKey('nonSmokingException')) {
      nonSmokingException = _json['nonSmokingException'] as core.String;
    }
    if (_json.containsKey('patio')) {
      patio = _json['patio'] as core.bool;
    }
    if (_json.containsKey('patioException')) {
      patioException = _json['patioException'] as core.String;
    }
    if (_json.containsKey('stairs')) {
      stairs = _json['stairs'] as core.bool;
    }
    if (_json.containsKey('stairsException')) {
      stairsException = _json['stairsException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (balcony != null) 'balcony': balcony!,
        if (balconyException != null) 'balconyException': balconyException!,
        if (livingAreaSqMeters != null)
          'livingAreaSqMeters': livingAreaSqMeters!,
        if (livingAreaSqMetersException != null)
          'livingAreaSqMetersException': livingAreaSqMetersException!,
        if (loft != null) 'loft': loft!,
        if (loftException != null) 'loftException': loftException!,
        if (nonSmoking != null) 'nonSmoking': nonSmoking!,
        if (nonSmokingException != null)
          'nonSmokingException': nonSmokingException!,
        if (patio != null) 'patio': patio!,
        if (patioException != null) 'patioException': patioException!,
        if (stairs != null) 'stairs': stairs!,
        if (stairsException != null) 'stairsException': stairsException!,
      };
}

/// Information about sleeping features in the living area.
class LivingAreaSleeping {
  /// Beds count.
  ///
  /// The number of permanent beds present in a guestroom. Does not include
  /// rollaway beds, cribs or sofabeds.
  core.int? bedsCount;

  /// Beds count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? bedsCountException;

  /// Bunk beds count.
  ///
  /// The number of furniture pieces in which one framed mattress is fixed
  /// directly above another by means of a physical frame. This allows one
  /// person(s) to sleep in the bottom bunk and one person(s) to sleep in the
  /// top bunk. Also known as double decker bed.
  core.int? bunkBedsCount;

  /// Bunk beds count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? bunkBedsCountException;

  /// Cribs count.
  ///
  /// The number of small beds for an infant or toddler that the guestroom can
  /// obtain. The bed is surrounded by a high railing to prevent the child from
  /// falling or climbing out of the bed
  core.int? cribsCount;

  /// Cribs count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? cribsCountException;

  /// Double beds count.
  ///
  /// The number of medium beds measuring 53"W x 75"L (135cm x 191cm). Also
  /// known as full size bed.
  core.int? doubleBedsCount;

  /// Double beds count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? doubleBedsCountException;

  /// Feather pillows.
  ///
  /// The option for guests to obtain bed pillows that are stuffed with the
  /// feathers and down of ducks or geese.
  core.bool? featherPillows;

  /// Feather pillows exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? featherPillowsException;

  /// Hypoallergenic bedding.
  ///
  /// Bedding such as linens, pillows, mattress covers and/or mattresses that
  /// are made of materials known to be resistant to allergens such as mold,
  /// dust and dander.
  core.bool? hypoallergenicBedding;

  /// Hypoallergenic bedding exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? hypoallergenicBeddingException;

  /// King beds count.
  ///
  /// The number of large beds measuring 76"W x 80"L (193cm x 102cm). Most often
  /// meant to accompany two people. Includes California king and super king.
  core.int? kingBedsCount;

  /// King beds count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? kingBedsCountException;

  /// Memory foam pillows.
  ///
  /// The option for guests to obtain bed pillows that are stuffed with a
  /// man-made foam that responds to body heat by conforming to the body
  /// closely, and then recovers its shape when the pillow cools down.
  core.bool? memoryFoamPillows;

  /// Memory foam pillows exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? memoryFoamPillowsException;

  /// Other beds count.
  ///
  /// The number of beds that are not standard mattress and boxspring setups
  /// such as Japanese tatami mats, trundle beds, air mattresses and cots.
  core.int? otherBedsCount;

  /// Other beds count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? otherBedsCountException;

  /// Queen beds count.
  ///
  /// The number of medium-large beds measuring 60"W x 80"L (152cm x 102cm).
  core.int? queenBedsCount;

  /// Queen beds count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? queenBedsCountException;

  /// Roll away beds count.
  ///
  /// The number of mattresses on wheeled frames that can be folded in half and
  /// rolled away for easy storage that the guestroom can obtain upon request.
  core.int? rollAwayBedsCount;

  /// Roll away beds count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? rollAwayBedsCountException;

  /// Single or twin count beds.
  ///
  /// The number of smaller beds measuring 38"W x 75"L (97cm x 191cm) that can
  /// accommodate one adult.
  core.int? singleOrTwinBedsCount;

  /// Single or twin beds count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? singleOrTwinBedsCountException;

  /// Sofa beds count.
  ///
  /// The number of specially designed sofas that can be made to serve as a bed
  /// by lowering its hinged upholstered back to horizontal position or by
  /// pulling out a concealed mattress.
  core.int? sofaBedsCount;

  /// Sofa beds count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? sofaBedsCountException;

  /// Synthetic pillows.
  ///
  /// The option for guests to obtain bed pillows stuffed with polyester
  /// material crafted to reproduce the feel of a pillow stuffed with down and
  /// feathers.
  core.bool? syntheticPillows;

  /// Synthetic pillows exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? syntheticPillowsException;

  LivingAreaSleeping();

  LivingAreaSleeping.fromJson(core.Map _json) {
    if (_json.containsKey('bedsCount')) {
      bedsCount = _json['bedsCount'] as core.int;
    }
    if (_json.containsKey('bedsCountException')) {
      bedsCountException = _json['bedsCountException'] as core.String;
    }
    if (_json.containsKey('bunkBedsCount')) {
      bunkBedsCount = _json['bunkBedsCount'] as core.int;
    }
    if (_json.containsKey('bunkBedsCountException')) {
      bunkBedsCountException = _json['bunkBedsCountException'] as core.String;
    }
    if (_json.containsKey('cribsCount')) {
      cribsCount = _json['cribsCount'] as core.int;
    }
    if (_json.containsKey('cribsCountException')) {
      cribsCountException = _json['cribsCountException'] as core.String;
    }
    if (_json.containsKey('doubleBedsCount')) {
      doubleBedsCount = _json['doubleBedsCount'] as core.int;
    }
    if (_json.containsKey('doubleBedsCountException')) {
      doubleBedsCountException =
          _json['doubleBedsCountException'] as core.String;
    }
    if (_json.containsKey('featherPillows')) {
      featherPillows = _json['featherPillows'] as core.bool;
    }
    if (_json.containsKey('featherPillowsException')) {
      featherPillowsException = _json['featherPillowsException'] as core.String;
    }
    if (_json.containsKey('hypoallergenicBedding')) {
      hypoallergenicBedding = _json['hypoallergenicBedding'] as core.bool;
    }
    if (_json.containsKey('hypoallergenicBeddingException')) {
      hypoallergenicBeddingException =
          _json['hypoallergenicBeddingException'] as core.String;
    }
    if (_json.containsKey('kingBedsCount')) {
      kingBedsCount = _json['kingBedsCount'] as core.int;
    }
    if (_json.containsKey('kingBedsCountException')) {
      kingBedsCountException = _json['kingBedsCountException'] as core.String;
    }
    if (_json.containsKey('memoryFoamPillows')) {
      memoryFoamPillows = _json['memoryFoamPillows'] as core.bool;
    }
    if (_json.containsKey('memoryFoamPillowsException')) {
      memoryFoamPillowsException =
          _json['memoryFoamPillowsException'] as core.String;
    }
    if (_json.containsKey('otherBedsCount')) {
      otherBedsCount = _json['otherBedsCount'] as core.int;
    }
    if (_json.containsKey('otherBedsCountException')) {
      otherBedsCountException = _json['otherBedsCountException'] as core.String;
    }
    if (_json.containsKey('queenBedsCount')) {
      queenBedsCount = _json['queenBedsCount'] as core.int;
    }
    if (_json.containsKey('queenBedsCountException')) {
      queenBedsCountException = _json['queenBedsCountException'] as core.String;
    }
    if (_json.containsKey('rollAwayBedsCount')) {
      rollAwayBedsCount = _json['rollAwayBedsCount'] as core.int;
    }
    if (_json.containsKey('rollAwayBedsCountException')) {
      rollAwayBedsCountException =
          _json['rollAwayBedsCountException'] as core.String;
    }
    if (_json.containsKey('singleOrTwinBedsCount')) {
      singleOrTwinBedsCount = _json['singleOrTwinBedsCount'] as core.int;
    }
    if (_json.containsKey('singleOrTwinBedsCountException')) {
      singleOrTwinBedsCountException =
          _json['singleOrTwinBedsCountException'] as core.String;
    }
    if (_json.containsKey('sofaBedsCount')) {
      sofaBedsCount = _json['sofaBedsCount'] as core.int;
    }
    if (_json.containsKey('sofaBedsCountException')) {
      sofaBedsCountException = _json['sofaBedsCountException'] as core.String;
    }
    if (_json.containsKey('syntheticPillows')) {
      syntheticPillows = _json['syntheticPillows'] as core.bool;
    }
    if (_json.containsKey('syntheticPillowsException')) {
      syntheticPillowsException =
          _json['syntheticPillowsException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bedsCount != null) 'bedsCount': bedsCount!,
        if (bedsCountException != null)
          'bedsCountException': bedsCountException!,
        if (bunkBedsCount != null) 'bunkBedsCount': bunkBedsCount!,
        if (bunkBedsCountException != null)
          'bunkBedsCountException': bunkBedsCountException!,
        if (cribsCount != null) 'cribsCount': cribsCount!,
        if (cribsCountException != null)
          'cribsCountException': cribsCountException!,
        if (doubleBedsCount != null) 'doubleBedsCount': doubleBedsCount!,
        if (doubleBedsCountException != null)
          'doubleBedsCountException': doubleBedsCountException!,
        if (featherPillows != null) 'featherPillows': featherPillows!,
        if (featherPillowsException != null)
          'featherPillowsException': featherPillowsException!,
        if (hypoallergenicBedding != null)
          'hypoallergenicBedding': hypoallergenicBedding!,
        if (hypoallergenicBeddingException != null)
          'hypoallergenicBeddingException': hypoallergenicBeddingException!,
        if (kingBedsCount != null) 'kingBedsCount': kingBedsCount!,
        if (kingBedsCountException != null)
          'kingBedsCountException': kingBedsCountException!,
        if (memoryFoamPillows != null) 'memoryFoamPillows': memoryFoamPillows!,
        if (memoryFoamPillowsException != null)
          'memoryFoamPillowsException': memoryFoamPillowsException!,
        if (otherBedsCount != null) 'otherBedsCount': otherBedsCount!,
        if (otherBedsCountException != null)
          'otherBedsCountException': otherBedsCountException!,
        if (queenBedsCount != null) 'queenBedsCount': queenBedsCount!,
        if (queenBedsCountException != null)
          'queenBedsCountException': queenBedsCountException!,
        if (rollAwayBedsCount != null) 'rollAwayBedsCount': rollAwayBedsCount!,
        if (rollAwayBedsCountException != null)
          'rollAwayBedsCountException': rollAwayBedsCountException!,
        if (singleOrTwinBedsCount != null)
          'singleOrTwinBedsCount': singleOrTwinBedsCount!,
        if (singleOrTwinBedsCountException != null)
          'singleOrTwinBedsCountException': singleOrTwinBedsCountException!,
        if (sofaBedsCount != null) 'sofaBedsCount': sofaBedsCount!,
        if (sofaBedsCountException != null)
          'sofaBedsCountException': sofaBedsCountException!,
        if (syntheticPillows != null) 'syntheticPillows': syntheticPillows!,
        if (syntheticPillowsException != null)
          'syntheticPillowsException': syntheticPillowsException!,
      };
}

/// Lodging of a location that provides accomodations.
class Lodging {
  /// Physical adaptations made to the property in consideration of varying
  /// levels of human physical ability.
  Accessibility? accessibility;

  /// Amenities and features related to leisure and play.
  Activities? activities;

  /// All units on the property have at least these attributes.
  ///
  /// Output only.
  GuestUnitFeatures? allUnits;

  /// Features of the property of specific interest to the business traveler.
  Business? business;

  /// Features of the shared living areas available in this Lodging.
  LivingArea? commonLivingArea;

  /// The ways in which the property provides guests with the ability to access
  /// the internet.
  Connectivity? connectivity;

  /// Services and amenities for families and young guests.
  Families? families;

  /// Meals, snacks, and beverages available at the property.
  FoodAndDrink? foodAndDrink;

  /// Individual GuestUnitTypes that are available in this Lodging.
  core.List<GuestUnitType>? guestUnits;

  /// Health and safety measures implemented by the hotel during COVID-19.
  HealthAndSafety? healthAndSafety;

  /// Conveniences provided in guest units to facilitate an easier, more
  /// comfortable stay.
  Housekeeping? housekeeping;

  /// Metadata for the lodging.
  ///
  /// Required.
  LodgingMetadata? metadata;

  /// Google identifier for this location in the form:
  /// `locations/{location_id}/lodging`
  ///
  /// Required.
  core.String? name;

  /// Parking options at the property.
  Parking? parking;

  /// Policies regarding guest-owned animals.
  Pets? pets;

  /// Property rules that impact guests.
  Policies? policies;

  /// Swimming pool or recreational water facilities available at the hotel.
  Pools? pools;

  /// General factual information about the property's physical structure and
  /// important dates.
  Property? property;

  /// Conveniences or help provided by the property to facilitate an easier,
  /// more comfortable stay.
  Services? services;

  /// Some units on the property have as much as these attributes.
  ///
  /// Output only.
  GuestUnitFeatures? someUnits;

  /// Vehicles or vehicular services facilitated or owned by the property.
  Transportation? transportation;

  /// Guest facilities at the property to promote or maintain health, beauty,
  /// and fitness.
  Wellness? wellness;

  Lodging();

  Lodging.fromJson(core.Map _json) {
    if (_json.containsKey('accessibility')) {
      accessibility = Accessibility.fromJson(
          _json['accessibility'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('activities')) {
      activities = Activities.fromJson(
          _json['activities'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('allUnits')) {
      allUnits = GuestUnitFeatures.fromJson(
          _json['allUnits'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('business')) {
      business = Business.fromJson(
          _json['business'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('commonLivingArea')) {
      commonLivingArea = LivingArea.fromJson(
          _json['commonLivingArea'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('connectivity')) {
      connectivity = Connectivity.fromJson(
          _json['connectivity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('families')) {
      families = Families.fromJson(
          _json['families'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('foodAndDrink')) {
      foodAndDrink = FoodAndDrink.fromJson(
          _json['foodAndDrink'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('guestUnits')) {
      guestUnits = (_json['guestUnits'] as core.List)
          .map<GuestUnitType>((value) => GuestUnitType.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('healthAndSafety')) {
      healthAndSafety = HealthAndSafety.fromJson(
          _json['healthAndSafety'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('housekeeping')) {
      housekeeping = Housekeeping.fromJson(
          _json['housekeeping'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metadata')) {
      metadata = LodgingMetadata.fromJson(
          _json['metadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parking')) {
      parking = Parking.fromJson(
          _json['parking'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pets')) {
      pets =
          Pets.fromJson(_json['pets'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('policies')) {
      policies = Policies.fromJson(
          _json['policies'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pools')) {
      pools =
          Pools.fromJson(_json['pools'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('property')) {
      property = Property.fromJson(
          _json['property'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('services')) {
      services = Services.fromJson(
          _json['services'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('someUnits')) {
      someUnits = GuestUnitFeatures.fromJson(
          _json['someUnits'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('transportation')) {
      transportation = Transportation.fromJson(
          _json['transportation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('wellness')) {
      wellness = Wellness.fromJson(
          _json['wellness'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessibility != null) 'accessibility': accessibility!.toJson(),
        if (activities != null) 'activities': activities!.toJson(),
        if (allUnits != null) 'allUnits': allUnits!.toJson(),
        if (business != null) 'business': business!.toJson(),
        if (commonLivingArea != null)
          'commonLivingArea': commonLivingArea!.toJson(),
        if (connectivity != null) 'connectivity': connectivity!.toJson(),
        if (families != null) 'families': families!.toJson(),
        if (foodAndDrink != null) 'foodAndDrink': foodAndDrink!.toJson(),
        if (guestUnits != null)
          'guestUnits': guestUnits!.map((value) => value.toJson()).toList(),
        if (healthAndSafety != null)
          'healthAndSafety': healthAndSafety!.toJson(),
        if (housekeeping != null) 'housekeeping': housekeeping!.toJson(),
        if (metadata != null) 'metadata': metadata!.toJson(),
        if (name != null) 'name': name!,
        if (parking != null) 'parking': parking!.toJson(),
        if (pets != null) 'pets': pets!.toJson(),
        if (policies != null) 'policies': policies!.toJson(),
        if (pools != null) 'pools': pools!.toJson(),
        if (property != null) 'property': property!.toJson(),
        if (services != null) 'services': services!.toJson(),
        if (someUnits != null) 'someUnits': someUnits!.toJson(),
        if (transportation != null) 'transportation': transportation!.toJson(),
        if (wellness != null) 'wellness': wellness!.toJson(),
      };
}

/// Metadata for the Lodging.
class LodgingMetadata {
  /// The latest time at which the Lodging data is asserted to be true in the
  /// real world.
  ///
  /// This is not necessarily the time at which the request is made.
  ///
  /// Required.
  core.String? updateTime;

  LodgingMetadata();

  LodgingMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Minimized contact measures implemented by the hotel during COVID-19.
class MinimizedContact {
  /// No-contact check-in and check-out.
  core.bool? contactlessCheckinCheckout;

  /// Contactless check-in check-out exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? contactlessCheckinCheckoutException;

  /// Keyless mobile entry to guest rooms.
  core.bool? digitalGuestRoomKeys;

  /// Digital guest room keys exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? digitalGuestRoomKeysException;

  /// Housekeeping scheduled by request only.
  core.bool? housekeepingScheduledRequestOnly;

  /// Housekeeping scheduled request only exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? housekeepingScheduledRequestOnlyException;

  /// High-touch items, such as magazines, removed from common areas.
  core.bool? noHighTouchItemsCommonAreas;

  /// No high touch items common areas exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? noHighTouchItemsCommonAreasException;

  /// High-touch items, such as decorative pillows, removed from guest rooms.
  core.bool? noHighTouchItemsGuestRooms;

  /// No high touch items guest rooms exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? noHighTouchItemsGuestRoomsException;

  /// Plastic key cards are disinfected or discarded.
  core.bool? plasticKeycardsDisinfected;

  /// Plastic keycards disinfected exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? plasticKeycardsDisinfectedException;

  /// Buffer maintained between room bookings.
  core.bool? roomBookingsBuffer;

  /// Room bookings buffer exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? roomBookingsBufferException;

  MinimizedContact();

  MinimizedContact.fromJson(core.Map _json) {
    if (_json.containsKey('contactlessCheckinCheckout')) {
      contactlessCheckinCheckout =
          _json['contactlessCheckinCheckout'] as core.bool;
    }
    if (_json.containsKey('contactlessCheckinCheckoutException')) {
      contactlessCheckinCheckoutException =
          _json['contactlessCheckinCheckoutException'] as core.String;
    }
    if (_json.containsKey('digitalGuestRoomKeys')) {
      digitalGuestRoomKeys = _json['digitalGuestRoomKeys'] as core.bool;
    }
    if (_json.containsKey('digitalGuestRoomKeysException')) {
      digitalGuestRoomKeysException =
          _json['digitalGuestRoomKeysException'] as core.String;
    }
    if (_json.containsKey('housekeepingScheduledRequestOnly')) {
      housekeepingScheduledRequestOnly =
          _json['housekeepingScheduledRequestOnly'] as core.bool;
    }
    if (_json.containsKey('housekeepingScheduledRequestOnlyException')) {
      housekeepingScheduledRequestOnlyException =
          _json['housekeepingScheduledRequestOnlyException'] as core.String;
    }
    if (_json.containsKey('noHighTouchItemsCommonAreas')) {
      noHighTouchItemsCommonAreas =
          _json['noHighTouchItemsCommonAreas'] as core.bool;
    }
    if (_json.containsKey('noHighTouchItemsCommonAreasException')) {
      noHighTouchItemsCommonAreasException =
          _json['noHighTouchItemsCommonAreasException'] as core.String;
    }
    if (_json.containsKey('noHighTouchItemsGuestRooms')) {
      noHighTouchItemsGuestRooms =
          _json['noHighTouchItemsGuestRooms'] as core.bool;
    }
    if (_json.containsKey('noHighTouchItemsGuestRoomsException')) {
      noHighTouchItemsGuestRoomsException =
          _json['noHighTouchItemsGuestRoomsException'] as core.String;
    }
    if (_json.containsKey('plasticKeycardsDisinfected')) {
      plasticKeycardsDisinfected =
          _json['plasticKeycardsDisinfected'] as core.bool;
    }
    if (_json.containsKey('plasticKeycardsDisinfectedException')) {
      plasticKeycardsDisinfectedException =
          _json['plasticKeycardsDisinfectedException'] as core.String;
    }
    if (_json.containsKey('roomBookingsBuffer')) {
      roomBookingsBuffer = _json['roomBookingsBuffer'] as core.bool;
    }
    if (_json.containsKey('roomBookingsBufferException')) {
      roomBookingsBufferException =
          _json['roomBookingsBufferException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (contactlessCheckinCheckout != null)
          'contactlessCheckinCheckout': contactlessCheckinCheckout!,
        if (contactlessCheckinCheckoutException != null)
          'contactlessCheckinCheckoutException':
              contactlessCheckinCheckoutException!,
        if (digitalGuestRoomKeys != null)
          'digitalGuestRoomKeys': digitalGuestRoomKeys!,
        if (digitalGuestRoomKeysException != null)
          'digitalGuestRoomKeysException': digitalGuestRoomKeysException!,
        if (housekeepingScheduledRequestOnly != null)
          'housekeepingScheduledRequestOnly': housekeepingScheduledRequestOnly!,
        if (housekeepingScheduledRequestOnlyException != null)
          'housekeepingScheduledRequestOnlyException':
              housekeepingScheduledRequestOnlyException!,
        if (noHighTouchItemsCommonAreas != null)
          'noHighTouchItemsCommonAreas': noHighTouchItemsCommonAreas!,
        if (noHighTouchItemsCommonAreasException != null)
          'noHighTouchItemsCommonAreasException':
              noHighTouchItemsCommonAreasException!,
        if (noHighTouchItemsGuestRooms != null)
          'noHighTouchItemsGuestRooms': noHighTouchItemsGuestRooms!,
        if (noHighTouchItemsGuestRoomsException != null)
          'noHighTouchItemsGuestRoomsException':
              noHighTouchItemsGuestRoomsException!,
        if (plasticKeycardsDisinfected != null)
          'plasticKeycardsDisinfected': plasticKeycardsDisinfected!,
        if (plasticKeycardsDisinfectedException != null)
          'plasticKeycardsDisinfectedException':
              plasticKeycardsDisinfectedException!,
        if (roomBookingsBuffer != null)
          'roomBookingsBuffer': roomBookingsBuffer!,
        if (roomBookingsBufferException != null)
          'roomBookingsBufferException': roomBookingsBufferException!,
      };
}

/// Parking options at the property.
class Parking {
  /// Electric car charging stations.
  ///
  /// Electric power stations, usually located outdoors, into which guests plug
  /// their electric cars to receive a charge.
  core.bool? electricCarChargingStations;

  /// Electric car charging stations exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? electricCarChargingStationsException;

  /// Free parking.
  ///
  /// The hotel allows the cars of guests to be parked for free. Parking
  /// facility may be an outdoor lot or an indoor garage, but must be onsite.
  /// Nearby parking does not apply. Parking may be performed by the guest or by
  /// hotel staff. Free parking must be available to all guests (limited
  /// conditions does not apply).
  core.bool? freeParking;

  /// Free parking exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? freeParkingException;

  /// Free self parking.
  ///
  /// Guests park their own cars for free. Parking facility may be an outdoor
  /// lot or an indoor garage, but must be onsite. Nearby parking does not
  /// apply.
  core.bool? freeSelfParking;

  /// Free self parking exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? freeSelfParkingException;

  /// Free valet parking.
  ///
  /// Hotel staff member parks the cars of guests. Parking with this service is
  /// free.
  core.bool? freeValetParking;

  /// Free valet parking exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? freeValetParkingException;

  /// Parking available.
  ///
  /// The hotel allows the cars of guests to be parked. Can be free or for a
  /// fee. Parking facility may be an outdoor lot or an indoor garage, but must
  /// be onsite. Nearby parking does not apply. Parking may be performed by the
  /// guest or by hotel staff.
  core.bool? parkingAvailable;

  /// Parking available exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? parkingAvailableException;

  /// Self parking available.
  ///
  /// Guests park their own cars. Parking facility may be an outdoor lot or an
  /// indoor garage, but must be onsite. Nearby parking does not apply. Can be
  /// free or for a fee.
  core.bool? selfParkingAvailable;

  /// Self parking available exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? selfParkingAvailableException;

  /// Valet parking available.
  ///
  /// Hotel staff member parks the cars of guests. Parking with this service can
  /// be free or for a fee.
  core.bool? valetParkingAvailable;

  /// Valet parking available exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? valetParkingAvailableException;

  Parking();

  Parking.fromJson(core.Map _json) {
    if (_json.containsKey('electricCarChargingStations')) {
      electricCarChargingStations =
          _json['electricCarChargingStations'] as core.bool;
    }
    if (_json.containsKey('electricCarChargingStationsException')) {
      electricCarChargingStationsException =
          _json['electricCarChargingStationsException'] as core.String;
    }
    if (_json.containsKey('freeParking')) {
      freeParking = _json['freeParking'] as core.bool;
    }
    if (_json.containsKey('freeParkingException')) {
      freeParkingException = _json['freeParkingException'] as core.String;
    }
    if (_json.containsKey('freeSelfParking')) {
      freeSelfParking = _json['freeSelfParking'] as core.bool;
    }
    if (_json.containsKey('freeSelfParkingException')) {
      freeSelfParkingException =
          _json['freeSelfParkingException'] as core.String;
    }
    if (_json.containsKey('freeValetParking')) {
      freeValetParking = _json['freeValetParking'] as core.bool;
    }
    if (_json.containsKey('freeValetParkingException')) {
      freeValetParkingException =
          _json['freeValetParkingException'] as core.String;
    }
    if (_json.containsKey('parkingAvailable')) {
      parkingAvailable = _json['parkingAvailable'] as core.bool;
    }
    if (_json.containsKey('parkingAvailableException')) {
      parkingAvailableException =
          _json['parkingAvailableException'] as core.String;
    }
    if (_json.containsKey('selfParkingAvailable')) {
      selfParkingAvailable = _json['selfParkingAvailable'] as core.bool;
    }
    if (_json.containsKey('selfParkingAvailableException')) {
      selfParkingAvailableException =
          _json['selfParkingAvailableException'] as core.String;
    }
    if (_json.containsKey('valetParkingAvailable')) {
      valetParkingAvailable = _json['valetParkingAvailable'] as core.bool;
    }
    if (_json.containsKey('valetParkingAvailableException')) {
      valetParkingAvailableException =
          _json['valetParkingAvailableException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (electricCarChargingStations != null)
          'electricCarChargingStations': electricCarChargingStations!,
        if (electricCarChargingStationsException != null)
          'electricCarChargingStationsException':
              electricCarChargingStationsException!,
        if (freeParking != null) 'freeParking': freeParking!,
        if (freeParkingException != null)
          'freeParkingException': freeParkingException!,
        if (freeSelfParking != null) 'freeSelfParking': freeSelfParking!,
        if (freeSelfParkingException != null)
          'freeSelfParkingException': freeSelfParkingException!,
        if (freeValetParking != null) 'freeValetParking': freeValetParking!,
        if (freeValetParkingException != null)
          'freeValetParkingException': freeValetParkingException!,
        if (parkingAvailable != null) 'parkingAvailable': parkingAvailable!,
        if (parkingAvailableException != null)
          'parkingAvailableException': parkingAvailableException!,
        if (selfParkingAvailable != null)
          'selfParkingAvailable': selfParkingAvailable!,
        if (selfParkingAvailableException != null)
          'selfParkingAvailableException': selfParkingAvailableException!,
        if (valetParkingAvailable != null)
          'valetParkingAvailable': valetParkingAvailable!,
        if (valetParkingAvailableException != null)
          'valetParkingAvailableException': valetParkingAvailableException!,
      };
}

/// Forms of payment accepted at the property.
class PaymentOptions {
  /// Cash.
  ///
  /// The hotel accepts payment by paper/coin currency.
  core.bool? cash;

  /// Cash exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? cashException;

  /// Cheque.
  ///
  /// The hotel accepts a printed document issued by the guest's bank in the
  /// guest's name as a form of payment.
  core.bool? cheque;

  /// Cheque exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? chequeException;

  /// Credit card.
  ///
  /// The hotel accepts payment by a card issued by a bank or credit card
  /// company. Also known as charge card, debit card, bank card, or charge
  /// plate.
  core.bool? creditCard;

  /// Credit card exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? creditCardException;

  /// Debit card.
  ///
  /// The hotel accepts a bank-issued card that immediately deducts the charged
  /// funds from the guest's bank account upon processing.
  core.bool? debitCard;

  /// Debit card exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? debitCardException;

  /// Mobile nfc.
  ///
  /// The hotel has the compatible computer hardware terminal that reads and
  /// charges a payment app on the guest's smartphone without requiring the two
  /// devices to make physical contact. Also known as Apple Pay, Google Pay,
  /// Samsung Pay.
  core.bool? mobileNfc;

  /// Mobile nfc exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? mobileNfcException;

  PaymentOptions();

  PaymentOptions.fromJson(core.Map _json) {
    if (_json.containsKey('cash')) {
      cash = _json['cash'] as core.bool;
    }
    if (_json.containsKey('cashException')) {
      cashException = _json['cashException'] as core.String;
    }
    if (_json.containsKey('cheque')) {
      cheque = _json['cheque'] as core.bool;
    }
    if (_json.containsKey('chequeException')) {
      chequeException = _json['chequeException'] as core.String;
    }
    if (_json.containsKey('creditCard')) {
      creditCard = _json['creditCard'] as core.bool;
    }
    if (_json.containsKey('creditCardException')) {
      creditCardException = _json['creditCardException'] as core.String;
    }
    if (_json.containsKey('debitCard')) {
      debitCard = _json['debitCard'] as core.bool;
    }
    if (_json.containsKey('debitCardException')) {
      debitCardException = _json['debitCardException'] as core.String;
    }
    if (_json.containsKey('mobileNfc')) {
      mobileNfc = _json['mobileNfc'] as core.bool;
    }
    if (_json.containsKey('mobileNfcException')) {
      mobileNfcException = _json['mobileNfcException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cash != null) 'cash': cash!,
        if (cashException != null) 'cashException': cashException!,
        if (cheque != null) 'cheque': cheque!,
        if (chequeException != null) 'chequeException': chequeException!,
        if (creditCard != null) 'creditCard': creditCard!,
        if (creditCardException != null)
          'creditCardException': creditCardException!,
        if (debitCard != null) 'debitCard': debitCard!,
        if (debitCardException != null)
          'debitCardException': debitCardException!,
        if (mobileNfc != null) 'mobileNfc': mobileNfc!,
        if (mobileNfcException != null)
          'mobileNfcException': mobileNfcException!,
      };
}

/// Personal protection measures implemented by the hotel during COVID-19.
class PersonalProtection {
  /// Hand-sanitizer and/or sanitizing wipes are offered in common areas.
  core.bool? commonAreasOfferSanitizingItems;

  /// Common areas offer sanitizing items exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? commonAreasOfferSanitizingItemsException;

  /// Masks required on the property.
  core.bool? faceMaskRequired;

  /// Face mask required exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? faceMaskRequiredException;

  /// In-room hygiene kits with masks, hand sanitizer, and/or antibacterial
  /// wipes.
  core.bool? guestRoomHygieneKitsAvailable;

  /// Guest room hygiene kits available exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? guestRoomHygieneKitsAvailableException;

  /// Masks and/or gloves available for guests.
  core.bool? protectiveEquipmentAvailable;

  /// Protective equipment available exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? protectiveEquipmentAvailableException;

  PersonalProtection();

  PersonalProtection.fromJson(core.Map _json) {
    if (_json.containsKey('commonAreasOfferSanitizingItems')) {
      commonAreasOfferSanitizingItems =
          _json['commonAreasOfferSanitizingItems'] as core.bool;
    }
    if (_json.containsKey('commonAreasOfferSanitizingItemsException')) {
      commonAreasOfferSanitizingItemsException =
          _json['commonAreasOfferSanitizingItemsException'] as core.String;
    }
    if (_json.containsKey('faceMaskRequired')) {
      faceMaskRequired = _json['faceMaskRequired'] as core.bool;
    }
    if (_json.containsKey('faceMaskRequiredException')) {
      faceMaskRequiredException =
          _json['faceMaskRequiredException'] as core.String;
    }
    if (_json.containsKey('guestRoomHygieneKitsAvailable')) {
      guestRoomHygieneKitsAvailable =
          _json['guestRoomHygieneKitsAvailable'] as core.bool;
    }
    if (_json.containsKey('guestRoomHygieneKitsAvailableException')) {
      guestRoomHygieneKitsAvailableException =
          _json['guestRoomHygieneKitsAvailableException'] as core.String;
    }
    if (_json.containsKey('protectiveEquipmentAvailable')) {
      protectiveEquipmentAvailable =
          _json['protectiveEquipmentAvailable'] as core.bool;
    }
    if (_json.containsKey('protectiveEquipmentAvailableException')) {
      protectiveEquipmentAvailableException =
          _json['protectiveEquipmentAvailableException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (commonAreasOfferSanitizingItems != null)
          'commonAreasOfferSanitizingItems': commonAreasOfferSanitizingItems!,
        if (commonAreasOfferSanitizingItemsException != null)
          'commonAreasOfferSanitizingItemsException':
              commonAreasOfferSanitizingItemsException!,
        if (faceMaskRequired != null) 'faceMaskRequired': faceMaskRequired!,
        if (faceMaskRequiredException != null)
          'faceMaskRequiredException': faceMaskRequiredException!,
        if (guestRoomHygieneKitsAvailable != null)
          'guestRoomHygieneKitsAvailable': guestRoomHygieneKitsAvailable!,
        if (guestRoomHygieneKitsAvailableException != null)
          'guestRoomHygieneKitsAvailableException':
              guestRoomHygieneKitsAvailableException!,
        if (protectiveEquipmentAvailable != null)
          'protectiveEquipmentAvailable': protectiveEquipmentAvailable!,
        if (protectiveEquipmentAvailableException != null)
          'protectiveEquipmentAvailableException':
              protectiveEquipmentAvailableException!,
      };
}

/// Policies regarding guest-owned animals.
class Pets {
  /// Cats allowed.
  ///
  /// Domesticated felines are permitted at the property and allowed to stay in
  /// the guest room of their owner. May or may not require a fee.
  core.bool? catsAllowed;

  /// Cats allowed exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? catsAllowedException;

  /// Dogs allowed.
  ///
  /// Domesticated canines are permitted at the property and allowed to stay in
  /// the guest room of their owner. May or may not require a fee.
  core.bool? dogsAllowed;

  /// Dogs allowed exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? dogsAllowedException;

  /// Pets allowed.
  ///
  /// Household animals are allowed at the property and in the specific guest
  /// room of their owner. May or may not include dogs, cats, reptiles and/or
  /// fish. May or may not require a fee. Service animals are not considered to
  /// be pets, so not governed by this policy.
  core.bool? petsAllowed;

  /// Pets allowed exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? petsAllowedException;

  /// Pets allowed free.
  ///
  /// Household animals are allowed at the property and in the specific guest
  /// room of their owner for free. May or may not include dogs, cats, reptiles,
  /// and/or fish.
  core.bool? petsAllowedFree;

  /// Pets allowed free exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? petsAllowedFreeException;

  Pets();

  Pets.fromJson(core.Map _json) {
    if (_json.containsKey('catsAllowed')) {
      catsAllowed = _json['catsAllowed'] as core.bool;
    }
    if (_json.containsKey('catsAllowedException')) {
      catsAllowedException = _json['catsAllowedException'] as core.String;
    }
    if (_json.containsKey('dogsAllowed')) {
      dogsAllowed = _json['dogsAllowed'] as core.bool;
    }
    if (_json.containsKey('dogsAllowedException')) {
      dogsAllowedException = _json['dogsAllowedException'] as core.String;
    }
    if (_json.containsKey('petsAllowed')) {
      petsAllowed = _json['petsAllowed'] as core.bool;
    }
    if (_json.containsKey('petsAllowedException')) {
      petsAllowedException = _json['petsAllowedException'] as core.String;
    }
    if (_json.containsKey('petsAllowedFree')) {
      petsAllowedFree = _json['petsAllowedFree'] as core.bool;
    }
    if (_json.containsKey('petsAllowedFreeException')) {
      petsAllowedFreeException =
          _json['petsAllowedFreeException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (catsAllowed != null) 'catsAllowed': catsAllowed!,
        if (catsAllowedException != null)
          'catsAllowedException': catsAllowedException!,
        if (dogsAllowed != null) 'dogsAllowed': dogsAllowed!,
        if (dogsAllowedException != null)
          'dogsAllowedException': dogsAllowedException!,
        if (petsAllowed != null) 'petsAllowed': petsAllowed!,
        if (petsAllowedException != null)
          'petsAllowedException': petsAllowedException!,
        if (petsAllowedFree != null) 'petsAllowedFree': petsAllowedFree!,
        if (petsAllowedFreeException != null)
          'petsAllowedFreeException': petsAllowedFreeException!,
      };
}

/// Physical distancing measures implemented by the hotel during COVID-19.
class PhysicalDistancing {
  /// Common areas arranged to maintain physical distancing.
  core.bool? commonAreasPhysicalDistancingArranged;

  /// Common areas physical distancing arranged exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? commonAreasPhysicalDistancingArrangedException;

  /// Physical distancing required.
  core.bool? physicalDistancingRequired;

  /// Physical distancing required exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? physicalDistancingRequiredException;

  /// Safety dividers at front desk and other locations.
  core.bool? safetyDividers;

  /// Safety dividers exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? safetyDividersException;

  /// Guest occupancy limited within shared facilities.
  core.bool? sharedAreasLimitedOccupancy;

  /// Shared areas limited occupancy exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? sharedAreasLimitedOccupancyException;

  /// Private spaces designated in spa and wellness areas.
  core.bool? wellnessAreasHavePrivateSpaces;

  /// Wellness areas have private spaces exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? wellnessAreasHavePrivateSpacesException;

  PhysicalDistancing();

  PhysicalDistancing.fromJson(core.Map _json) {
    if (_json.containsKey('commonAreasPhysicalDistancingArranged')) {
      commonAreasPhysicalDistancingArranged =
          _json['commonAreasPhysicalDistancingArranged'] as core.bool;
    }
    if (_json.containsKey('commonAreasPhysicalDistancingArrangedException')) {
      commonAreasPhysicalDistancingArrangedException =
          _json['commonAreasPhysicalDistancingArrangedException']
              as core.String;
    }
    if (_json.containsKey('physicalDistancingRequired')) {
      physicalDistancingRequired =
          _json['physicalDistancingRequired'] as core.bool;
    }
    if (_json.containsKey('physicalDistancingRequiredException')) {
      physicalDistancingRequiredException =
          _json['physicalDistancingRequiredException'] as core.String;
    }
    if (_json.containsKey('safetyDividers')) {
      safetyDividers = _json['safetyDividers'] as core.bool;
    }
    if (_json.containsKey('safetyDividersException')) {
      safetyDividersException = _json['safetyDividersException'] as core.String;
    }
    if (_json.containsKey('sharedAreasLimitedOccupancy')) {
      sharedAreasLimitedOccupancy =
          _json['sharedAreasLimitedOccupancy'] as core.bool;
    }
    if (_json.containsKey('sharedAreasLimitedOccupancyException')) {
      sharedAreasLimitedOccupancyException =
          _json['sharedAreasLimitedOccupancyException'] as core.String;
    }
    if (_json.containsKey('wellnessAreasHavePrivateSpaces')) {
      wellnessAreasHavePrivateSpaces =
          _json['wellnessAreasHavePrivateSpaces'] as core.bool;
    }
    if (_json.containsKey('wellnessAreasHavePrivateSpacesException')) {
      wellnessAreasHavePrivateSpacesException =
          _json['wellnessAreasHavePrivateSpacesException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (commonAreasPhysicalDistancingArranged != null)
          'commonAreasPhysicalDistancingArranged':
              commonAreasPhysicalDistancingArranged!,
        if (commonAreasPhysicalDistancingArrangedException != null)
          'commonAreasPhysicalDistancingArrangedException':
              commonAreasPhysicalDistancingArrangedException!,
        if (physicalDistancingRequired != null)
          'physicalDistancingRequired': physicalDistancingRequired!,
        if (physicalDistancingRequiredException != null)
          'physicalDistancingRequiredException':
              physicalDistancingRequiredException!,
        if (safetyDividers != null) 'safetyDividers': safetyDividers!,
        if (safetyDividersException != null)
          'safetyDividersException': safetyDividersException!,
        if (sharedAreasLimitedOccupancy != null)
          'sharedAreasLimitedOccupancy': sharedAreasLimitedOccupancy!,
        if (sharedAreasLimitedOccupancyException != null)
          'sharedAreasLimitedOccupancyException':
              sharedAreasLimitedOccupancyException!,
        if (wellnessAreasHavePrivateSpaces != null)
          'wellnessAreasHavePrivateSpaces': wellnessAreasHavePrivateSpaces!,
        if (wellnessAreasHavePrivateSpacesException != null)
          'wellnessAreasHavePrivateSpacesException':
              wellnessAreasHavePrivateSpacesException!,
      };
}

/// Property rules that impact guests.
class Policies {
  /// All inclusive available.
  ///
  /// The hotel offers a rate option that includes the cost of the room, meals,
  /// activities, and other amenities that might otherwise be charged
  /// separately.
  core.bool? allInclusiveAvailable;

  /// All inclusive available exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? allInclusiveAvailableException;

  /// All inclusive only.
  ///
  /// The only rate option offered by the hotel is a rate that includes the cost
  /// of the room, meals, activities and other amenities that might otherwise be
  /// charged separately.
  core.bool? allInclusiveOnly;

  /// All inclusive only exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? allInclusiveOnlyException;

  /// Check-in time.
  ///
  /// The time of the day at which the hotel begins providing guests access to
  /// their unit at the beginning of their stay.
  TimeOfDay? checkinTime;

  /// Check-in time exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? checkinTimeException;

  /// Check-out time.
  ///
  /// The time of the day on the last day of a guest's reserved stay at which
  /// the guest must vacate their room and settle their bill. Some hotels may
  /// offer late or early check out for a fee.
  TimeOfDay? checkoutTime;

  /// Check-out time exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? checkoutTimeException;

  /// Kids stay free.
  ///
  /// The children of guests are allowed to stay in the room/suite of a parent
  /// or adult without an additional fee. The policy may or may not stipulate a
  /// limit of the child's age or the overall number of children allowed.
  core.bool? kidsStayFree;

  /// Kids stay free exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? kidsStayFreeException;

  /// Max child age.
  ///
  /// The hotel allows children up to a certain age to stay in the room/suite of
  /// a parent or adult without an additional fee.
  core.int? maxChildAge;

  /// Max child age exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? maxChildAgeException;

  /// Max kids stay free count.
  ///
  /// The hotel allows a specific, defined number of children to stay in the
  /// room/suite of a parent or adult without an additional fee.
  core.int? maxKidsStayFreeCount;

  /// Max kids stay free count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? maxKidsStayFreeCountException;

  /// Forms of payment accepted at the property.
  PaymentOptions? paymentOptions;

  /// Smoke free property.
  ///
  /// Smoking is not allowed inside the building, on balconies, or in outside
  /// spaces. Hotels that offer a designated area for guests to smoke are not
  /// considered smoke-free properties.
  core.bool? smokeFreeProperty;

  /// Smoke free property exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? smokeFreePropertyException;

  Policies();

  Policies.fromJson(core.Map _json) {
    if (_json.containsKey('allInclusiveAvailable')) {
      allInclusiveAvailable = _json['allInclusiveAvailable'] as core.bool;
    }
    if (_json.containsKey('allInclusiveAvailableException')) {
      allInclusiveAvailableException =
          _json['allInclusiveAvailableException'] as core.String;
    }
    if (_json.containsKey('allInclusiveOnly')) {
      allInclusiveOnly = _json['allInclusiveOnly'] as core.bool;
    }
    if (_json.containsKey('allInclusiveOnlyException')) {
      allInclusiveOnlyException =
          _json['allInclusiveOnlyException'] as core.String;
    }
    if (_json.containsKey('checkinTime')) {
      checkinTime = TimeOfDay.fromJson(
          _json['checkinTime'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('checkinTimeException')) {
      checkinTimeException = _json['checkinTimeException'] as core.String;
    }
    if (_json.containsKey('checkoutTime')) {
      checkoutTime = TimeOfDay.fromJson(
          _json['checkoutTime'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('checkoutTimeException')) {
      checkoutTimeException = _json['checkoutTimeException'] as core.String;
    }
    if (_json.containsKey('kidsStayFree')) {
      kidsStayFree = _json['kidsStayFree'] as core.bool;
    }
    if (_json.containsKey('kidsStayFreeException')) {
      kidsStayFreeException = _json['kidsStayFreeException'] as core.String;
    }
    if (_json.containsKey('maxChildAge')) {
      maxChildAge = _json['maxChildAge'] as core.int;
    }
    if (_json.containsKey('maxChildAgeException')) {
      maxChildAgeException = _json['maxChildAgeException'] as core.String;
    }
    if (_json.containsKey('maxKidsStayFreeCount')) {
      maxKidsStayFreeCount = _json['maxKidsStayFreeCount'] as core.int;
    }
    if (_json.containsKey('maxKidsStayFreeCountException')) {
      maxKidsStayFreeCountException =
          _json['maxKidsStayFreeCountException'] as core.String;
    }
    if (_json.containsKey('paymentOptions')) {
      paymentOptions = PaymentOptions.fromJson(
          _json['paymentOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('smokeFreeProperty')) {
      smokeFreeProperty = _json['smokeFreeProperty'] as core.bool;
    }
    if (_json.containsKey('smokeFreePropertyException')) {
      smokeFreePropertyException =
          _json['smokeFreePropertyException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allInclusiveAvailable != null)
          'allInclusiveAvailable': allInclusiveAvailable!,
        if (allInclusiveAvailableException != null)
          'allInclusiveAvailableException': allInclusiveAvailableException!,
        if (allInclusiveOnly != null) 'allInclusiveOnly': allInclusiveOnly!,
        if (allInclusiveOnlyException != null)
          'allInclusiveOnlyException': allInclusiveOnlyException!,
        if (checkinTime != null) 'checkinTime': checkinTime!.toJson(),
        if (checkinTimeException != null)
          'checkinTimeException': checkinTimeException!,
        if (checkoutTime != null) 'checkoutTime': checkoutTime!.toJson(),
        if (checkoutTimeException != null)
          'checkoutTimeException': checkoutTimeException!,
        if (kidsStayFree != null) 'kidsStayFree': kidsStayFree!,
        if (kidsStayFreeException != null)
          'kidsStayFreeException': kidsStayFreeException!,
        if (maxChildAge != null) 'maxChildAge': maxChildAge!,
        if (maxChildAgeException != null)
          'maxChildAgeException': maxChildAgeException!,
        if (maxKidsStayFreeCount != null)
          'maxKidsStayFreeCount': maxKidsStayFreeCount!,
        if (maxKidsStayFreeCountException != null)
          'maxKidsStayFreeCountException': maxKidsStayFreeCountException!,
        if (paymentOptions != null) 'paymentOptions': paymentOptions!.toJson(),
        if (smokeFreeProperty != null) 'smokeFreeProperty': smokeFreeProperty!,
        if (smokeFreePropertyException != null)
          'smokeFreePropertyException': smokeFreePropertyException!,
      };
}

/// Swimming pool or recreational water facilities available at the hotel.
class Pools {
  /// Adult pool.
  ///
  /// A pool restricted for use by adults only. Can be indoors or outdoors.
  core.bool? adultPool;

  /// Adult pool exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? adultPoolException;

  /// Hot tub.
  ///
  /// A man-made pool containing bubbling water maintained at a higher
  /// temperature and circulated by aerating jets for the purpose of soaking,
  /// relaxation and hydrotherapy. Can be indoors or outdoors. Not used for
  /// active swimming. Also known as Jacuzzi. Hot tub must be in a common area
  /// where all guests can access it. Does not apply to room-specific hot tubs
  /// that are only accessible to guest occupying that room.
  core.bool? hotTub;

  /// Hot tub exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? hotTubException;

  /// Indoor pool.
  ///
  /// A pool located inside the hotel and available for guests to use for
  /// swimming and/or soaking. Use may or may not be restricted to adults and/or
  /// children.
  core.bool? indoorPool;

  /// Indoor pool exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? indoorPoolException;

  /// Indoor pools count.
  ///
  /// The sum of all indoor pools at the hotel.
  core.int? indoorPoolsCount;

  /// Indoor pools count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? indoorPoolsCountException;

  /// Lazy river.
  ///
  /// A man-made pool or several interconnected recreational pools built to
  /// mimic the shape and current of a winding river where guests float in the
  /// water on inflated rubber tubes. Can be indoors or outdoors.
  core.bool? lazyRiver;

  /// Lazy river exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? lazyRiverException;

  /// Lifeguard.
  ///
  /// A trained member of the hotel staff stationed by the hotel's indoor or
  /// outdoor swimming area and responsible for the safety of swimming guests.
  core.bool? lifeguard;

  /// Lifeguard exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? lifeguardException;

  /// Outdoor pool.
  ///
  /// A pool located outside on the grounds of the hotel and available for
  /// guests to use for swimming, soaking or recreation. Use may or may not be
  /// restricted to adults and/or children.
  core.bool? outdoorPool;

  /// Outdoor pool exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? outdoorPoolException;

  /// Outdoor pools count.
  ///
  /// The sum of all outdoor pools at the hotel.
  core.int? outdoorPoolsCount;

  /// Outdoor pools count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? outdoorPoolsCountException;

  /// Pool.
  ///
  /// The presence of a pool, either indoors or outdoors, for guests to use for
  /// swimming and/or soaking. Use may or may not be restricted to adults and/or
  /// children.
  core.bool? pool;

  /// Pool exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? poolException;

  /// Pools count.
  ///
  /// The sum of all pools at the hotel.
  core.int? poolsCount;

  /// Pools count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? poolsCountException;

  /// Wading pool.
  ///
  /// A shallow pool designed for small children to play in. Can be indoors or
  /// outdoors. Also known as kiddie pool.
  core.bool? wadingPool;

  /// Wading pool exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? wadingPoolException;

  /// Water park.
  ///
  /// An aquatic recreation area with a large pool or series of pools that has
  /// features such as a water slide or tube, wavepool, fountains, rope swings,
  /// and/or obstacle course. Can be indoors or outdoors. Also known as
  /// adventure pool.
  core.bool? waterPark;

  /// Water park exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? waterParkException;

  /// Waterslide.
  ///
  /// A continuously wetted chute positioned by an indoor or outdoor pool which
  /// people slide down into the water.
  core.bool? waterslide;

  /// Waterslide exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? waterslideException;

  /// Wave pool.
  ///
  /// A large indoor or outdoor pool with a machine that produces water currents
  /// to mimic the ocean's crests.
  core.bool? wavePool;

  /// Wave pool exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? wavePoolException;

  Pools();

  Pools.fromJson(core.Map _json) {
    if (_json.containsKey('adultPool')) {
      adultPool = _json['adultPool'] as core.bool;
    }
    if (_json.containsKey('adultPoolException')) {
      adultPoolException = _json['adultPoolException'] as core.String;
    }
    if (_json.containsKey('hotTub')) {
      hotTub = _json['hotTub'] as core.bool;
    }
    if (_json.containsKey('hotTubException')) {
      hotTubException = _json['hotTubException'] as core.String;
    }
    if (_json.containsKey('indoorPool')) {
      indoorPool = _json['indoorPool'] as core.bool;
    }
    if (_json.containsKey('indoorPoolException')) {
      indoorPoolException = _json['indoorPoolException'] as core.String;
    }
    if (_json.containsKey('indoorPoolsCount')) {
      indoorPoolsCount = _json['indoorPoolsCount'] as core.int;
    }
    if (_json.containsKey('indoorPoolsCountException')) {
      indoorPoolsCountException =
          _json['indoorPoolsCountException'] as core.String;
    }
    if (_json.containsKey('lazyRiver')) {
      lazyRiver = _json['lazyRiver'] as core.bool;
    }
    if (_json.containsKey('lazyRiverException')) {
      lazyRiverException = _json['lazyRiverException'] as core.String;
    }
    if (_json.containsKey('lifeguard')) {
      lifeguard = _json['lifeguard'] as core.bool;
    }
    if (_json.containsKey('lifeguardException')) {
      lifeguardException = _json['lifeguardException'] as core.String;
    }
    if (_json.containsKey('outdoorPool')) {
      outdoorPool = _json['outdoorPool'] as core.bool;
    }
    if (_json.containsKey('outdoorPoolException')) {
      outdoorPoolException = _json['outdoorPoolException'] as core.String;
    }
    if (_json.containsKey('outdoorPoolsCount')) {
      outdoorPoolsCount = _json['outdoorPoolsCount'] as core.int;
    }
    if (_json.containsKey('outdoorPoolsCountException')) {
      outdoorPoolsCountException =
          _json['outdoorPoolsCountException'] as core.String;
    }
    if (_json.containsKey('pool')) {
      pool = _json['pool'] as core.bool;
    }
    if (_json.containsKey('poolException')) {
      poolException = _json['poolException'] as core.String;
    }
    if (_json.containsKey('poolsCount')) {
      poolsCount = _json['poolsCount'] as core.int;
    }
    if (_json.containsKey('poolsCountException')) {
      poolsCountException = _json['poolsCountException'] as core.String;
    }
    if (_json.containsKey('wadingPool')) {
      wadingPool = _json['wadingPool'] as core.bool;
    }
    if (_json.containsKey('wadingPoolException')) {
      wadingPoolException = _json['wadingPoolException'] as core.String;
    }
    if (_json.containsKey('waterPark')) {
      waterPark = _json['waterPark'] as core.bool;
    }
    if (_json.containsKey('waterParkException')) {
      waterParkException = _json['waterParkException'] as core.String;
    }
    if (_json.containsKey('waterslide')) {
      waterslide = _json['waterslide'] as core.bool;
    }
    if (_json.containsKey('waterslideException')) {
      waterslideException = _json['waterslideException'] as core.String;
    }
    if (_json.containsKey('wavePool')) {
      wavePool = _json['wavePool'] as core.bool;
    }
    if (_json.containsKey('wavePoolException')) {
      wavePoolException = _json['wavePoolException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (adultPool != null) 'adultPool': adultPool!,
        if (adultPoolException != null)
          'adultPoolException': adultPoolException!,
        if (hotTub != null) 'hotTub': hotTub!,
        if (hotTubException != null) 'hotTubException': hotTubException!,
        if (indoorPool != null) 'indoorPool': indoorPool!,
        if (indoorPoolException != null)
          'indoorPoolException': indoorPoolException!,
        if (indoorPoolsCount != null) 'indoorPoolsCount': indoorPoolsCount!,
        if (indoorPoolsCountException != null)
          'indoorPoolsCountException': indoorPoolsCountException!,
        if (lazyRiver != null) 'lazyRiver': lazyRiver!,
        if (lazyRiverException != null)
          'lazyRiverException': lazyRiverException!,
        if (lifeguard != null) 'lifeguard': lifeguard!,
        if (lifeguardException != null)
          'lifeguardException': lifeguardException!,
        if (outdoorPool != null) 'outdoorPool': outdoorPool!,
        if (outdoorPoolException != null)
          'outdoorPoolException': outdoorPoolException!,
        if (outdoorPoolsCount != null) 'outdoorPoolsCount': outdoorPoolsCount!,
        if (outdoorPoolsCountException != null)
          'outdoorPoolsCountException': outdoorPoolsCountException!,
        if (pool != null) 'pool': pool!,
        if (poolException != null) 'poolException': poolException!,
        if (poolsCount != null) 'poolsCount': poolsCount!,
        if (poolsCountException != null)
          'poolsCountException': poolsCountException!,
        if (wadingPool != null) 'wadingPool': wadingPool!,
        if (wadingPoolException != null)
          'wadingPoolException': wadingPoolException!,
        if (waterPark != null) 'waterPark': waterPark!,
        if (waterParkException != null)
          'waterParkException': waterParkException!,
        if (waterslide != null) 'waterslide': waterslide!,
        if (waterslideException != null)
          'waterslideException': waterslideException!,
        if (wavePool != null) 'wavePool': wavePool!,
        if (wavePoolException != null) 'wavePoolException': wavePoolException!,
      };
}

/// General factual information about the property's physical structure and
/// important dates.
class Property {
  /// Built year.
  ///
  /// The year that construction of the property was completed.
  core.int? builtYear;

  /// Built year exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? builtYearException;

  /// Floors count.
  ///
  /// The number of stories the building has from the ground floor to the top
  /// floor that are accessible to guests.
  core.int? floorsCount;

  /// Floors count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? floorsCountException;

  /// Last renovated year.
  ///
  /// The year when the most recent renovation of the property was completed.
  /// Renovation may include all or any combination of the following: the units,
  /// the public spaces, the exterior, or the interior.
  core.int? lastRenovatedYear;

  /// Last renovated year exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? lastRenovatedYearException;

  /// Rooms count.
  ///
  /// The total number of rooms and suites bookable by guests for an overnight
  /// stay. Does not include event space, public spaces, conference rooms,
  /// fitness rooms, business centers, spa, salon, restaurants/bars, or shops.
  core.int? roomsCount;

  /// Rooms count exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? roomsCountException;

  Property();

  Property.fromJson(core.Map _json) {
    if (_json.containsKey('builtYear')) {
      builtYear = _json['builtYear'] as core.int;
    }
    if (_json.containsKey('builtYearException')) {
      builtYearException = _json['builtYearException'] as core.String;
    }
    if (_json.containsKey('floorsCount')) {
      floorsCount = _json['floorsCount'] as core.int;
    }
    if (_json.containsKey('floorsCountException')) {
      floorsCountException = _json['floorsCountException'] as core.String;
    }
    if (_json.containsKey('lastRenovatedYear')) {
      lastRenovatedYear = _json['lastRenovatedYear'] as core.int;
    }
    if (_json.containsKey('lastRenovatedYearException')) {
      lastRenovatedYearException =
          _json['lastRenovatedYearException'] as core.String;
    }
    if (_json.containsKey('roomsCount')) {
      roomsCount = _json['roomsCount'] as core.int;
    }
    if (_json.containsKey('roomsCountException')) {
      roomsCountException = _json['roomsCountException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (builtYear != null) 'builtYear': builtYear!,
        if (builtYearException != null)
          'builtYearException': builtYearException!,
        if (floorsCount != null) 'floorsCount': floorsCount!,
        if (floorsCountException != null)
          'floorsCountException': floorsCountException!,
        if (lastRenovatedYear != null) 'lastRenovatedYear': lastRenovatedYear!,
        if (lastRenovatedYearException != null)
          'lastRenovatedYearException': lastRenovatedYearException!,
        if (roomsCount != null) 'roomsCount': roomsCount!,
        if (roomsCountException != null)
          'roomsCountException': roomsCountException!,
      };
}

/// Conveniences or help provided by the property to facilitate an easier, more
/// comfortable stay.
class Services {
  /// Baggage storage.
  ///
  /// A provision for guests to leave their bags at the hotel when they arrive
  /// for their stay before the official check-in time. May or may not apply for
  /// guests who wish to leave their bags after check-out and before departing
  /// the locale. Also known as bag dropoff.
  core.bool? baggageStorage;

  /// Baggage storage exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? baggageStorageException;

  /// Concierge.
  ///
  /// Hotel staff member(s) responsible for facilitating an easy, comfortable
  /// stay through making reservations for meals, sourcing theater tickets,
  /// arranging tours, finding a doctor, making recommendations, and answering
  /// questions.
  core.bool? concierge;

  /// Concierge exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? conciergeException;

  /// Convenience store.
  ///
  /// A shop at the hotel primarily selling snacks, drinks, non-prescription
  /// medicines, health and beauty aids, magazines and newspapers.
  core.bool? convenienceStore;

  /// Convenience store exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? convenienceStoreException;

  /// Currency exchange.
  ///
  /// A staff member or automated machine tasked with the transaction of
  /// providing the native currency of the hotel's locale in exchange for the
  /// foreign currency provided by a guest.
  core.bool? currencyExchange;

  /// Currency exchange exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? currencyExchangeException;

  /// Elevator.
  ///
  /// A passenger elevator that transports guests from one story to another.
  /// Also known as lift.
  core.bool? elevator;

  /// Elevator exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? elevatorException;

  /// Front desk.
  ///
  /// A counter or desk in the lobby or the immediate interior of the hotel
  /// where a member of the staff greets guests and processes the information
  /// related to their stay (including check-in and check-out). May or may not
  /// be manned and open 24/7.
  core.bool? frontDesk;

  /// Front desk exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? frontDeskException;

  /// Full service laundry.
  ///
  /// Laundry and dry cleaning facilitated and handled by the hotel on behalf of
  /// the guest. Does not include the provision for guests to do their own
  /// laundry in on-site machines.
  core.bool? fullServiceLaundry;

  /// Full service laundry exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? fullServiceLaundryException;

  /// Gift shop.
  ///
  /// An on-site store primarily selling souvenirs, mementos and other gift
  /// items. May or may not also sell sundries, magazines and newspapers,
  /// clothing, or snacks.
  core.bool? giftShop;

  /// Gift shop exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? giftShopException;

  /// Languages spoken by at least one staff member.
  core.List<LanguageSpoken>? languagesSpoken;

  /// Self service laundry.
  ///
  /// On-site clothes washers and dryers accessible to guests for the purpose of
  /// washing and drying their own clothes. May or may not require payment to
  /// use the machines.
  core.bool? selfServiceLaundry;

  /// Self service laundry exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? selfServiceLaundryException;

  /// Social hour.
  ///
  /// A reception with complimentary soft drinks, tea, coffee, wine and/or
  /// cocktails in the afternoon or evening. Can be hosted by hotel staff or
  /// guests may serve themselves. Also known as wine hour. The availability of
  /// coffee/tea in the lobby throughout the day does not constitute a social or
  /// wine hour.
  core.bool? socialHour;

  /// Social hour exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? socialHourException;

  /// 24hr front desk.
  ///
  /// Front desk is staffed 24 hours a day.
  core.bool? twentyFourHourFrontDesk;

  /// 24hr front desk exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? twentyFourHourFrontDeskException;

  /// Wake up calls.
  ///
  /// By direction of the guest, a hotel staff member will phone the guest unit
  /// at the requested hour. Also known as morning call.
  core.bool? wakeUpCalls;

  /// Wake up calls exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? wakeUpCallsException;

  Services();

  Services.fromJson(core.Map _json) {
    if (_json.containsKey('baggageStorage')) {
      baggageStorage = _json['baggageStorage'] as core.bool;
    }
    if (_json.containsKey('baggageStorageException')) {
      baggageStorageException = _json['baggageStorageException'] as core.String;
    }
    if (_json.containsKey('concierge')) {
      concierge = _json['concierge'] as core.bool;
    }
    if (_json.containsKey('conciergeException')) {
      conciergeException = _json['conciergeException'] as core.String;
    }
    if (_json.containsKey('convenienceStore')) {
      convenienceStore = _json['convenienceStore'] as core.bool;
    }
    if (_json.containsKey('convenienceStoreException')) {
      convenienceStoreException =
          _json['convenienceStoreException'] as core.String;
    }
    if (_json.containsKey('currencyExchange')) {
      currencyExchange = _json['currencyExchange'] as core.bool;
    }
    if (_json.containsKey('currencyExchangeException')) {
      currencyExchangeException =
          _json['currencyExchangeException'] as core.String;
    }
    if (_json.containsKey('elevator')) {
      elevator = _json['elevator'] as core.bool;
    }
    if (_json.containsKey('elevatorException')) {
      elevatorException = _json['elevatorException'] as core.String;
    }
    if (_json.containsKey('frontDesk')) {
      frontDesk = _json['frontDesk'] as core.bool;
    }
    if (_json.containsKey('frontDeskException')) {
      frontDeskException = _json['frontDeskException'] as core.String;
    }
    if (_json.containsKey('fullServiceLaundry')) {
      fullServiceLaundry = _json['fullServiceLaundry'] as core.bool;
    }
    if (_json.containsKey('fullServiceLaundryException')) {
      fullServiceLaundryException =
          _json['fullServiceLaundryException'] as core.String;
    }
    if (_json.containsKey('giftShop')) {
      giftShop = _json['giftShop'] as core.bool;
    }
    if (_json.containsKey('giftShopException')) {
      giftShopException = _json['giftShopException'] as core.String;
    }
    if (_json.containsKey('languagesSpoken')) {
      languagesSpoken = (_json['languagesSpoken'] as core.List)
          .map<LanguageSpoken>((value) => LanguageSpoken.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('selfServiceLaundry')) {
      selfServiceLaundry = _json['selfServiceLaundry'] as core.bool;
    }
    if (_json.containsKey('selfServiceLaundryException')) {
      selfServiceLaundryException =
          _json['selfServiceLaundryException'] as core.String;
    }
    if (_json.containsKey('socialHour')) {
      socialHour = _json['socialHour'] as core.bool;
    }
    if (_json.containsKey('socialHourException')) {
      socialHourException = _json['socialHourException'] as core.String;
    }
    if (_json.containsKey('twentyFourHourFrontDesk')) {
      twentyFourHourFrontDesk = _json['twentyFourHourFrontDesk'] as core.bool;
    }
    if (_json.containsKey('twentyFourHourFrontDeskException')) {
      twentyFourHourFrontDeskException =
          _json['twentyFourHourFrontDeskException'] as core.String;
    }
    if (_json.containsKey('wakeUpCalls')) {
      wakeUpCalls = _json['wakeUpCalls'] as core.bool;
    }
    if (_json.containsKey('wakeUpCallsException')) {
      wakeUpCallsException = _json['wakeUpCallsException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (baggageStorage != null) 'baggageStorage': baggageStorage!,
        if (baggageStorageException != null)
          'baggageStorageException': baggageStorageException!,
        if (concierge != null) 'concierge': concierge!,
        if (conciergeException != null)
          'conciergeException': conciergeException!,
        if (convenienceStore != null) 'convenienceStore': convenienceStore!,
        if (convenienceStoreException != null)
          'convenienceStoreException': convenienceStoreException!,
        if (currencyExchange != null) 'currencyExchange': currencyExchange!,
        if (currencyExchangeException != null)
          'currencyExchangeException': currencyExchangeException!,
        if (elevator != null) 'elevator': elevator!,
        if (elevatorException != null) 'elevatorException': elevatorException!,
        if (frontDesk != null) 'frontDesk': frontDesk!,
        if (frontDeskException != null)
          'frontDeskException': frontDeskException!,
        if (fullServiceLaundry != null)
          'fullServiceLaundry': fullServiceLaundry!,
        if (fullServiceLaundryException != null)
          'fullServiceLaundryException': fullServiceLaundryException!,
        if (giftShop != null) 'giftShop': giftShop!,
        if (giftShopException != null) 'giftShopException': giftShopException!,
        if (languagesSpoken != null)
          'languagesSpoken':
              languagesSpoken!.map((value) => value.toJson()).toList(),
        if (selfServiceLaundry != null)
          'selfServiceLaundry': selfServiceLaundry!,
        if (selfServiceLaundryException != null)
          'selfServiceLaundryException': selfServiceLaundryException!,
        if (socialHour != null) 'socialHour': socialHour!,
        if (socialHourException != null)
          'socialHourException': socialHourException!,
        if (twentyFourHourFrontDesk != null)
          'twentyFourHourFrontDesk': twentyFourHourFrontDesk!,
        if (twentyFourHourFrontDeskException != null)
          'twentyFourHourFrontDeskException': twentyFourHourFrontDeskException!,
        if (wakeUpCalls != null) 'wakeUpCalls': wakeUpCalls!,
        if (wakeUpCallsException != null)
          'wakeUpCallsException': wakeUpCallsException!,
      };
}

/// Represents a time of day.
///
/// The date and time zone are either not significant or are specified
/// elsewhere. An API may choose to allow leap seconds. Related types are
/// google.type.Date and `google.protobuf.Timestamp`.
class TimeOfDay {
  /// Hours of day in 24 hour format.
  ///
  /// Should be from 0 to 23. An API may choose to allow the value "24:00:00"
  /// for scenarios like business closing time.
  core.int? hours;

  /// Minutes of hour of day.
  ///
  /// Must be from 0 to 59.
  core.int? minutes;

  /// Fractions of seconds in nanoseconds.
  ///
  /// Must be from 0 to 999,999,999.
  core.int? nanos;

  /// Seconds of minutes of the time.
  ///
  /// Must normally be from 0 to 59. An API may allow the value 60 if it allows
  /// leap-seconds.
  core.int? seconds;

  TimeOfDay();

  TimeOfDay.fromJson(core.Map _json) {
    if (_json.containsKey('hours')) {
      hours = _json['hours'] as core.int;
    }
    if (_json.containsKey('minutes')) {
      minutes = _json['minutes'] as core.int;
    }
    if (_json.containsKey('nanos')) {
      nanos = _json['nanos'] as core.int;
    }
    if (_json.containsKey('seconds')) {
      seconds = _json['seconds'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (hours != null) 'hours': hours!,
        if (minutes != null) 'minutes': minutes!,
        if (nanos != null) 'nanos': nanos!,
        if (seconds != null) 'seconds': seconds!,
      };
}

/// Vehicles or vehicular services facilitated or owned by the property.
class Transportation {
  /// Airport shuttle.
  ///
  /// The hotel provides guests with a chauffeured van or bus to and from the
  /// airport. Can be free or for a fee. Guests may share the vehicle with other
  /// guests unknown to them. Applies if the hotel has a third-party shuttle
  /// service (office/desk etc.) within the hotel. As long as hotel provides
  /// this service, it doesn't matter if it's directly with them or a third
  /// party they work with. Does not apply if guest has to coordinate with an
  /// entity outside/other than the hotel.
  core.bool? airportShuttle;

  /// Airport shuttle exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? airportShuttleException;

  /// Car rental on property.
  ///
  /// A branch of a rental car company with a processing desk in the hotel.
  /// Available cars for rent may be awaiting at the hotel or in a nearby lot.
  core.bool? carRentalOnProperty;

  /// Car rental on property exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? carRentalOnPropertyException;

  /// Free airport shuttle.
  ///
  /// Airport shuttle is free to guests. Must be free to all guests without any
  /// conditions.
  core.bool? freeAirportShuttle;

  /// Free airport shuttle exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? freeAirportShuttleException;

  /// Free private car service.
  ///
  /// Private chauffeured car service is free to guests.
  core.bool? freePrivateCarService;

  /// Free private car service exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? freePrivateCarServiceException;

  /// Local shuttle.
  ///
  /// A car, van or bus provided by the hotel to transport guests to
  /// destinations within a specified range of distance around the hotel.
  /// Usually shopping and/or convention centers, downtown districts, or
  /// beaches. Can be free or for a fee.
  core.bool? localShuttle;

  /// Local shuttle exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? localShuttleException;

  /// Private car service.
  ///
  /// Hotel provides a private chauffeured car to transport guests to
  /// destinations. Passengers in the car are either alone or are known to one
  /// another and have requested the car together. Service can be free or for a
  /// fee and travel distance is usually limited to a specific range. Not a
  /// taxi.
  core.bool? privateCarService;

  /// Private car service exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? privateCarServiceException;

  /// Transfer.
  ///
  /// Hotel provides a shuttle service or car service to take guests to and from
  /// the nearest airport or train station. Can be free or for a fee. Guests may
  /// share the vehicle with other guests unknown to them.
  core.bool? transfer;

  /// Transfer exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? transferException;

  Transportation();

  Transportation.fromJson(core.Map _json) {
    if (_json.containsKey('airportShuttle')) {
      airportShuttle = _json['airportShuttle'] as core.bool;
    }
    if (_json.containsKey('airportShuttleException')) {
      airportShuttleException = _json['airportShuttleException'] as core.String;
    }
    if (_json.containsKey('carRentalOnProperty')) {
      carRentalOnProperty = _json['carRentalOnProperty'] as core.bool;
    }
    if (_json.containsKey('carRentalOnPropertyException')) {
      carRentalOnPropertyException =
          _json['carRentalOnPropertyException'] as core.String;
    }
    if (_json.containsKey('freeAirportShuttle')) {
      freeAirportShuttle = _json['freeAirportShuttle'] as core.bool;
    }
    if (_json.containsKey('freeAirportShuttleException')) {
      freeAirportShuttleException =
          _json['freeAirportShuttleException'] as core.String;
    }
    if (_json.containsKey('freePrivateCarService')) {
      freePrivateCarService = _json['freePrivateCarService'] as core.bool;
    }
    if (_json.containsKey('freePrivateCarServiceException')) {
      freePrivateCarServiceException =
          _json['freePrivateCarServiceException'] as core.String;
    }
    if (_json.containsKey('localShuttle')) {
      localShuttle = _json['localShuttle'] as core.bool;
    }
    if (_json.containsKey('localShuttleException')) {
      localShuttleException = _json['localShuttleException'] as core.String;
    }
    if (_json.containsKey('privateCarService')) {
      privateCarService = _json['privateCarService'] as core.bool;
    }
    if (_json.containsKey('privateCarServiceException')) {
      privateCarServiceException =
          _json['privateCarServiceException'] as core.String;
    }
    if (_json.containsKey('transfer')) {
      transfer = _json['transfer'] as core.bool;
    }
    if (_json.containsKey('transferException')) {
      transferException = _json['transferException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (airportShuttle != null) 'airportShuttle': airportShuttle!,
        if (airportShuttleException != null)
          'airportShuttleException': airportShuttleException!,
        if (carRentalOnProperty != null)
          'carRentalOnProperty': carRentalOnProperty!,
        if (carRentalOnPropertyException != null)
          'carRentalOnPropertyException': carRentalOnPropertyException!,
        if (freeAirportShuttle != null)
          'freeAirportShuttle': freeAirportShuttle!,
        if (freeAirportShuttleException != null)
          'freeAirportShuttleException': freeAirportShuttleException!,
        if (freePrivateCarService != null)
          'freePrivateCarService': freePrivateCarService!,
        if (freePrivateCarServiceException != null)
          'freePrivateCarServiceException': freePrivateCarServiceException!,
        if (localShuttle != null) 'localShuttle': localShuttle!,
        if (localShuttleException != null)
          'localShuttleException': localShuttleException!,
        if (privateCarService != null) 'privateCarService': privateCarService!,
        if (privateCarServiceException != null)
          'privateCarServiceException': privateCarServiceException!,
        if (transfer != null) 'transfer': transfer!,
        if (transferException != null) 'transferException': transferException!,
      };
}

/// Views available from the guest unit itself.
class ViewsFromUnit {
  /// Beach view.
  ///
  /// A guestroom that features a window through which guests can see the beach.
  core.bool? beachView;

  /// Beach view exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? beachViewException;

  /// City view.
  ///
  /// A guestroom that features a window through which guests can see the
  /// buildings, parks and/or streets of the city.
  core.bool? cityView;

  /// City view exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? cityViewException;

  /// Garden view.
  ///
  /// A guestroom that features a window through which guests can see a garden.
  core.bool? gardenView;

  /// Garden view exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? gardenViewException;

  /// Lake view.
  core.bool? lakeView;

  /// Lake view exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? lakeViewException;

  /// Landmark view.
  ///
  /// A guestroom that features a window through which guests can see a landmark
  /// such as the countryside, a golf course, the forest, a park, a rain forst,
  /// a mountain or a slope.
  core.bool? landmarkView;

  /// Landmark view exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? landmarkViewException;

  /// Ocean view.
  ///
  /// A guestroom that features a window through which guests can see the ocean.
  core.bool? oceanView;

  /// Ocean view exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? oceanViewException;

  /// Pool view.
  ///
  /// A guestroom that features a window through which guests can see the
  /// hotel's swimming pool.
  core.bool? poolView;

  /// Pool view exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? poolViewException;

  /// Valley view.
  ///
  /// A guestroom that features a window through which guests can see over a
  /// valley.
  core.bool? valleyView;

  /// Valley view exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? valleyViewException;

  ViewsFromUnit();

  ViewsFromUnit.fromJson(core.Map _json) {
    if (_json.containsKey('beachView')) {
      beachView = _json['beachView'] as core.bool;
    }
    if (_json.containsKey('beachViewException')) {
      beachViewException = _json['beachViewException'] as core.String;
    }
    if (_json.containsKey('cityView')) {
      cityView = _json['cityView'] as core.bool;
    }
    if (_json.containsKey('cityViewException')) {
      cityViewException = _json['cityViewException'] as core.String;
    }
    if (_json.containsKey('gardenView')) {
      gardenView = _json['gardenView'] as core.bool;
    }
    if (_json.containsKey('gardenViewException')) {
      gardenViewException = _json['gardenViewException'] as core.String;
    }
    if (_json.containsKey('lakeView')) {
      lakeView = _json['lakeView'] as core.bool;
    }
    if (_json.containsKey('lakeViewException')) {
      lakeViewException = _json['lakeViewException'] as core.String;
    }
    if (_json.containsKey('landmarkView')) {
      landmarkView = _json['landmarkView'] as core.bool;
    }
    if (_json.containsKey('landmarkViewException')) {
      landmarkViewException = _json['landmarkViewException'] as core.String;
    }
    if (_json.containsKey('oceanView')) {
      oceanView = _json['oceanView'] as core.bool;
    }
    if (_json.containsKey('oceanViewException')) {
      oceanViewException = _json['oceanViewException'] as core.String;
    }
    if (_json.containsKey('poolView')) {
      poolView = _json['poolView'] as core.bool;
    }
    if (_json.containsKey('poolViewException')) {
      poolViewException = _json['poolViewException'] as core.String;
    }
    if (_json.containsKey('valleyView')) {
      valleyView = _json['valleyView'] as core.bool;
    }
    if (_json.containsKey('valleyViewException')) {
      valleyViewException = _json['valleyViewException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (beachView != null) 'beachView': beachView!,
        if (beachViewException != null)
          'beachViewException': beachViewException!,
        if (cityView != null) 'cityView': cityView!,
        if (cityViewException != null) 'cityViewException': cityViewException!,
        if (gardenView != null) 'gardenView': gardenView!,
        if (gardenViewException != null)
          'gardenViewException': gardenViewException!,
        if (lakeView != null) 'lakeView': lakeView!,
        if (lakeViewException != null) 'lakeViewException': lakeViewException!,
        if (landmarkView != null) 'landmarkView': landmarkView!,
        if (landmarkViewException != null)
          'landmarkViewException': landmarkViewException!,
        if (oceanView != null) 'oceanView': oceanView!,
        if (oceanViewException != null)
          'oceanViewException': oceanViewException!,
        if (poolView != null) 'poolView': poolView!,
        if (poolViewException != null) 'poolViewException': poolViewException!,
        if (valleyView != null) 'valleyView': valleyView!,
        if (valleyViewException != null)
          'valleyViewException': valleyViewException!,
      };
}

/// Guest facilities at the property to promote or maintain health, beauty, and
/// fitness.
class Wellness {
  /// Doctor on call.
  ///
  /// The hotel has a contract with a medical professional who provides services
  /// to hotel guests should they fall ill during their stay. The doctor may or
  /// may not have an on-site office or be at the hotel at all times.
  core.bool? doctorOnCall;

  /// Doctor on call exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? doctorOnCallException;

  /// Elliptical machine.
  ///
  /// An electric, stationary fitness machine with pedals that simulates
  /// climbing, walking or running and provides a user-controlled range of
  /// speeds and tensions. May not have arm-controlled levers to work out the
  /// upper body as well. Commonly found in a gym, fitness room, health center,
  /// or health club.
  core.bool? ellipticalMachine;

  /// Elliptical machine exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? ellipticalMachineException;

  /// Fitness center.
  ///
  /// A room or building at the hotel containing equipment to promote physical
  /// activity, such as treadmills, elliptical machines, stationary bikes,
  /// weight machines, free weights, and/or stretching mats. Use of the fitness
  /// center can be free or for a fee. May or may not be staffed. May or may not
  /// offer instructor-led classes in various styles of physical conditioning.
  /// May or may not be open 24/7. May or may not include locker rooms and
  /// showers. Also known as health club, gym, fitness room, health center.
  core.bool? fitnessCenter;

  /// Fitness center exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? fitnessCenterException;

  /// Free fitness center.
  ///
  /// Guests may use the fitness center for free.
  core.bool? freeFitnessCenter;

  /// Free fitness center exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? freeFitnessCenterException;

  /// Free weights.
  ///
  /// Individual handheld fitness equipment of varied weights used for upper
  /// body strength training or bodybuilding. Also known as barbells, dumbbells,
  /// or kettlebells. Often stored on a rack with the weights arranged from
  /// light to heavy. Commonly found in a gym, fitness room, health center, or
  /// health club.
  core.bool? freeWeights;

  /// Free weights exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? freeWeightsException;

  /// Massage.
  ///
  /// A service provided by a trained massage therapist involving the physical
  /// manipulation of a guest's muscles in order to achieve relaxation or pain
  /// relief.
  core.bool? massage;

  /// Massage exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? massageException;

  /// Salon.
  ///
  /// A room at the hotel where professionals provide hair styling services such
  /// as shampooing, blow drying, hair dos, hair cutting and hair coloring. Also
  /// known as hairdresser or beauty salon.
  core.bool? salon;

  /// Salon exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? salonException;

  /// Sauna.
  ///
  /// A wood-paneled room heated to a high temperature where guests sit on
  /// built-in wood benches for the purpose of perspiring and relaxing their
  /// muscles. Can be dry or slightly wet heat. Not a steam room.
  core.bool? sauna;

  /// Sauna exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? saunaException;

  /// Spa.
  ///
  /// A designated area, room or building at the hotel offering health and
  /// beauty treatment through such means as steam baths, exercise equipment,
  /// and massage. May also offer facials, nail care, and hair care. Services
  /// are usually available by appointment and for an additional fee. Does not
  /// apply if hotel only offers a steam room; must offer other beauty and/or
  /// health treatments as well.
  core.bool? spa;

  /// Spa exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? spaException;

  /// Treadmill.
  ///
  /// An electric stationary fitness machine that simulates a moving path to
  /// promote walking or running within a range of user-controlled speeds and
  /// inclines. Also known as running machine. Commonly found in a gym, fitness
  /// room, health center, or health club.
  core.bool? treadmill;

  /// Treadmill exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? treadmillException;

  /// Weight machine.
  ///
  /// Non-electronic fitness equipment designed for the user to target the
  /// exertion of different muscles. Usually incorporates a padded seat, a stack
  /// of flat weights and various bars and pulleys. May be designed for toning a
  /// specific part of the body or may involve different user-controlled
  /// settings, hardware and pulleys so as to provide an overall workout in one
  /// machine. Commonly found in a gym, fitness center, fitness room, or health
  /// club.
  core.bool? weightMachine;

  /// Weight machine exception.
  /// Possible string values are:
  /// - "EXCEPTION_UNSPECIFIED" : Default unspecified exception. Use this only
  /// if a more specific exception does not match.
  /// - "UNDER_CONSTRUCTION" : Amenity or service is unavailable due to ongoing
  /// work orders.
  /// - "DEPENDENT_ON_SEASON" : Amenity or service availability is seasonal.
  /// - "DEPENDENT_ON_DAY_OF_WEEK" : Amenity or service availability depends on
  /// the day of the week.
  core.String? weightMachineException;

  Wellness();

  Wellness.fromJson(core.Map _json) {
    if (_json.containsKey('doctorOnCall')) {
      doctorOnCall = _json['doctorOnCall'] as core.bool;
    }
    if (_json.containsKey('doctorOnCallException')) {
      doctorOnCallException = _json['doctorOnCallException'] as core.String;
    }
    if (_json.containsKey('ellipticalMachine')) {
      ellipticalMachine = _json['ellipticalMachine'] as core.bool;
    }
    if (_json.containsKey('ellipticalMachineException')) {
      ellipticalMachineException =
          _json['ellipticalMachineException'] as core.String;
    }
    if (_json.containsKey('fitnessCenter')) {
      fitnessCenter = _json['fitnessCenter'] as core.bool;
    }
    if (_json.containsKey('fitnessCenterException')) {
      fitnessCenterException = _json['fitnessCenterException'] as core.String;
    }
    if (_json.containsKey('freeFitnessCenter')) {
      freeFitnessCenter = _json['freeFitnessCenter'] as core.bool;
    }
    if (_json.containsKey('freeFitnessCenterException')) {
      freeFitnessCenterException =
          _json['freeFitnessCenterException'] as core.String;
    }
    if (_json.containsKey('freeWeights')) {
      freeWeights = _json['freeWeights'] as core.bool;
    }
    if (_json.containsKey('freeWeightsException')) {
      freeWeightsException = _json['freeWeightsException'] as core.String;
    }
    if (_json.containsKey('massage')) {
      massage = _json['massage'] as core.bool;
    }
    if (_json.containsKey('massageException')) {
      massageException = _json['massageException'] as core.String;
    }
    if (_json.containsKey('salon')) {
      salon = _json['salon'] as core.bool;
    }
    if (_json.containsKey('salonException')) {
      salonException = _json['salonException'] as core.String;
    }
    if (_json.containsKey('sauna')) {
      sauna = _json['sauna'] as core.bool;
    }
    if (_json.containsKey('saunaException')) {
      saunaException = _json['saunaException'] as core.String;
    }
    if (_json.containsKey('spa')) {
      spa = _json['spa'] as core.bool;
    }
    if (_json.containsKey('spaException')) {
      spaException = _json['spaException'] as core.String;
    }
    if (_json.containsKey('treadmill')) {
      treadmill = _json['treadmill'] as core.bool;
    }
    if (_json.containsKey('treadmillException')) {
      treadmillException = _json['treadmillException'] as core.String;
    }
    if (_json.containsKey('weightMachine')) {
      weightMachine = _json['weightMachine'] as core.bool;
    }
    if (_json.containsKey('weightMachineException')) {
      weightMachineException = _json['weightMachineException'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (doctorOnCall != null) 'doctorOnCall': doctorOnCall!,
        if (doctorOnCallException != null)
          'doctorOnCallException': doctorOnCallException!,
        if (ellipticalMachine != null) 'ellipticalMachine': ellipticalMachine!,
        if (ellipticalMachineException != null)
          'ellipticalMachineException': ellipticalMachineException!,
        if (fitnessCenter != null) 'fitnessCenter': fitnessCenter!,
        if (fitnessCenterException != null)
          'fitnessCenterException': fitnessCenterException!,
        if (freeFitnessCenter != null) 'freeFitnessCenter': freeFitnessCenter!,
        if (freeFitnessCenterException != null)
          'freeFitnessCenterException': freeFitnessCenterException!,
        if (freeWeights != null) 'freeWeights': freeWeights!,
        if (freeWeightsException != null)
          'freeWeightsException': freeWeightsException!,
        if (massage != null) 'massage': massage!,
        if (massageException != null) 'massageException': massageException!,
        if (salon != null) 'salon': salon!,
        if (salonException != null) 'salonException': salonException!,
        if (sauna != null) 'sauna': sauna!,
        if (saunaException != null) 'saunaException': saunaException!,
        if (spa != null) 'spa': spa!,
        if (spaException != null) 'spaException': spaException!,
        if (treadmill != null) 'treadmill': treadmill!,
        if (treadmillException != null)
          'treadmillException': treadmillException!,
        if (weightMachine != null) 'weightMachine': weightMachine!,
        if (weightMachineException != null)
          'weightMachineException': weightMachineException!,
      };
}
