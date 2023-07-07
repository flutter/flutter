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

/// Safe Browsing API - v4
///
/// Enables client applications to check web resources (most commonly URLs)
/// against Google-generated lists of unsafe web resources. The Safe Browsing
/// APIs are for non-commercial use only. If you need to use APIs to detect
/// malicious URLs for commercial purposes – meaning “for sale or
/// revenue-generating purposes” – please refer to the Web Risk API.
///
/// For more information, see <https://developers.google.com/safe-browsing/>
///
/// Create an instance of [SafebrowsingApi] to access these resources:
///
/// - [EncodedFullHashesResource]
/// - [EncodedUpdatesResource]
/// - [FullHashesResource]
/// - [ThreatHitsResource]
/// - [ThreatListUpdatesResource]
/// - [ThreatListsResource]
/// - [ThreatMatchesResource]
library safebrowsing.v4;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Enables client applications to check web resources (most commonly URLs)
/// against Google-generated lists of unsafe web resources.
///
/// The Safe Browsing APIs are for non-commercial use only. If you need to use
/// APIs to detect malicious URLs for commercial purposes – meaning “for sale or
/// revenue-generating purposes” – please refer to the Web Risk API.
class SafebrowsingApi {
  final commons.ApiRequester _requester;

  EncodedFullHashesResource get encodedFullHashes =>
      EncodedFullHashesResource(_requester);
  EncodedUpdatesResource get encodedUpdates =>
      EncodedUpdatesResource(_requester);
  FullHashesResource get fullHashes => FullHashesResource(_requester);
  ThreatHitsResource get threatHits => ThreatHitsResource(_requester);
  ThreatListUpdatesResource get threatListUpdates =>
      ThreatListUpdatesResource(_requester);
  ThreatListsResource get threatLists => ThreatListsResource(_requester);
  ThreatMatchesResource get threatMatches => ThreatMatchesResource(_requester);

  SafebrowsingApi(http.Client client,
      {core.String rootUrl = 'https://safebrowsing.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class EncodedFullHashesResource {
  final commons.ApiRequester _requester;

  EncodedFullHashesResource(commons.ApiRequester client) : _requester = client;

  /// Request parameters:
  ///
  /// [encodedRequest] - A serialized FindFullHashesRequest proto.
  ///
  /// [clientId] - A client ID that (hopefully) uniquely identifies the client
  /// implementation of the Safe Browsing API.
  ///
  /// [clientVersion] - The version of the client implementation.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleSecuritySafebrowsingV4FindFullHashesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleSecuritySafebrowsingV4FindFullHashesResponse> get(
    core.String encodedRequest, {
    core.String? clientId,
    core.String? clientVersion,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (clientId != null) 'clientId': [clientId],
      if (clientVersion != null) 'clientVersion': [clientVersion],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v4/encodedFullHashes/' + commons.escapeVariable('$encodedRequest');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleSecuritySafebrowsingV4FindFullHashesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class EncodedUpdatesResource {
  final commons.ApiRequester _requester;

  EncodedUpdatesResource(commons.ApiRequester client) : _requester = client;

  /// Request parameters:
  ///
  /// [encodedRequest] - A serialized FetchThreatListUpdatesRequest proto.
  ///
  /// [clientId] - A client ID that uniquely identifies the client
  /// implementation of the Safe Browsing API.
  ///
  /// [clientVersion] - The version of the client implementation.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponse> get(
    core.String encodedRequest, {
    core.String? clientId,
    core.String? clientVersion,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (clientId != null) 'clientId': [clientId],
      if (clientVersion != null) 'clientVersion': [clientVersion],
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v4/encodedUpdates/' + commons.escapeVariable('$encodedRequest');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class FullHashesResource {
  final commons.ApiRequester _requester;

  FullHashesResource(commons.ApiRequester client) : _requester = client;

  /// Finds the full hashes that match the requested hash prefixes.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleSecuritySafebrowsingV4FindFullHashesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleSecuritySafebrowsingV4FindFullHashesResponse> find(
    GoogleSecuritySafebrowsingV4FindFullHashesRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v4/fullHashes:find';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleSecuritySafebrowsingV4FindFullHashesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ThreatHitsResource {
  final commons.ApiRequester _requester;

  ThreatHitsResource(commons.ApiRequester client) : _requester = client;

  /// Reports a Safe Browsing threat list hit to Google.
  ///
  /// Only projects with TRUSTED_REPORTER visibility can use this method.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
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
  async.Future<GoogleProtobufEmpty> create(
    GoogleSecuritySafebrowsingV4ThreatHit request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v4/threatHits';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ThreatListUpdatesResource {
  final commons.ApiRequester _requester;

  ThreatListUpdatesResource(commons.ApiRequester client) : _requester = client;

  /// Fetches the most recent threat list updates.
  ///
  /// A client can request updates for multiple lists at once.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponse>
      fetch(
    GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v4/threatListUpdates:fetch';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ThreatListsResource {
  final commons.ApiRequester _requester;

  ThreatListsResource(commons.ApiRequester client) : _requester = client;

  /// Lists the Safe Browsing threat lists available for download.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleSecuritySafebrowsingV4ListThreatListsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleSecuritySafebrowsingV4ListThreatListsResponse> list({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v4/threatLists';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleSecuritySafebrowsingV4ListThreatListsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ThreatMatchesResource {
  final commons.ApiRequester _requester;

  ThreatMatchesResource(commons.ApiRequester client) : _requester = client;

  /// Finds the threat entries that match the Safe Browsing lists.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleSecuritySafebrowsingV4FindThreatMatchesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleSecuritySafebrowsingV4FindThreatMatchesResponse> find(
    GoogleSecuritySafebrowsingV4FindThreatMatchesRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v4/threatMatches:find';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleSecuritySafebrowsingV4FindThreatMatchesResponse.fromJson(
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
class GoogleProtobufEmpty {
  GoogleProtobufEmpty();

  GoogleProtobufEmpty.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The expected state of a client's local database.
class GoogleSecuritySafebrowsingV4Checksum {
  /// The SHA256 hash of the client state; that is, of the sorted list of all
  /// hashes present in the database.
  core.String? sha256;
  core.List<core.int> get sha256AsBytes => convert.base64.decode(sha256!);

  set sha256AsBytes(core.List<core.int> _bytes) {
    sha256 =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  GoogleSecuritySafebrowsingV4Checksum();

  GoogleSecuritySafebrowsingV4Checksum.fromJson(core.Map _json) {
    if (_json.containsKey('sha256')) {
      sha256 = _json['sha256'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (sha256 != null) 'sha256': sha256!,
      };
}

/// The client metadata associated with Safe Browsing API requests.
class GoogleSecuritySafebrowsingV4ClientInfo {
  /// A client ID that (hopefully) uniquely identifies the client implementation
  /// of the Safe Browsing API.
  core.String? clientId;

  /// The version of the client implementation.
  core.String? clientVersion;

  GoogleSecuritySafebrowsingV4ClientInfo();

  GoogleSecuritySafebrowsingV4ClientInfo.fromJson(core.Map _json) {
    if (_json.containsKey('clientId')) {
      clientId = _json['clientId'] as core.String;
    }
    if (_json.containsKey('clientVersion')) {
      clientVersion = _json['clientVersion'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clientId != null) 'clientId': clientId!,
        if (clientVersion != null) 'clientVersion': clientVersion!,
      };
}

/// Describes a Safe Browsing API update request.
///
/// Clients can request updates for multiple lists in a single request. The
/// server may not respond to all requests, if the server has no updates for
/// that list. NOTE: Field index 2 is unused. NEXT: 5
class GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequest {
  /// The client metadata.
  GoogleSecuritySafebrowsingV4ClientInfo? client;

  /// The requested threat list updates.
  core.List<
          GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequestListUpdateRequest>?
      listUpdateRequests;

  GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequest();

  GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('client')) {
      client = GoogleSecuritySafebrowsingV4ClientInfo.fromJson(
          _json['client'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('listUpdateRequests')) {
      listUpdateRequests = (_json['listUpdateRequests'] as core.List)
          .map<GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequestListUpdateRequest>(
              (value) =>
                  GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequestListUpdateRequest
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (client != null) 'client': client!.toJson(),
        if (listUpdateRequests != null)
          'listUpdateRequests':
              listUpdateRequests!.map((value) => value.toJson()).toList(),
      };
}

/// A single list update request.
class GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequestListUpdateRequest {
  /// The constraints associated with this request.
  GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequestListUpdateRequestConstraints?
      constraints;

  /// The type of platform at risk by entries present in the list.
  /// Possible string values are:
  /// - "PLATFORM_TYPE_UNSPECIFIED" : Unknown platform.
  /// - "WINDOWS" : Threat posed to Windows.
  /// - "LINUX" : Threat posed to Linux.
  /// - "ANDROID" : Threat posed to Android.
  /// - "OSX" : Threat posed to OS X.
  /// - "IOS" : Threat posed to iOS.
  /// - "ANY_PLATFORM" : Threat posed to at least one of the defined platforms.
  /// - "ALL_PLATFORMS" : Threat posed to all defined platforms.
  /// - "CHROME" : Threat posed to Chrome.
  core.String? platformType;

  /// The current state of the client for the requested list (the encrypted
  /// client state that was received from the last successful list update).
  core.String? state;
  core.List<core.int> get stateAsBytes => convert.base64.decode(state!);

  set stateAsBytes(core.List<core.int> _bytes) {
    state =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The types of entries present in the list.
  /// Possible string values are:
  /// - "THREAT_ENTRY_TYPE_UNSPECIFIED" : Unspecified.
  /// - "URL" : A URL.
  /// - "EXECUTABLE" : An executable program.
  /// - "IP_RANGE" : An IP range.
  /// - "CHROME_EXTENSION" : Chrome extension.
  /// - "FILENAME" : Filename.
  /// - "CERT" : CERT
  core.String? threatEntryType;

  /// The type of threat posed by entries present in the list.
  /// Possible string values are:
  /// - "THREAT_TYPE_UNSPECIFIED" : Unknown.
  /// - "MALWARE" : Malware threat type.
  /// - "SOCIAL_ENGINEERING" : Social engineering threat type.
  /// - "UNWANTED_SOFTWARE" : Unwanted software threat type.
  /// - "POTENTIALLY_HARMFUL_APPLICATION" : Potentially harmful application
  /// threat type.
  /// - "SOCIAL_ENGINEERING_INTERNAL" : Social engineering threat type for
  /// internal use.
  /// - "API_ABUSE" : API abuse threat type.
  /// - "MALICIOUS_BINARY" : Malicious binary threat type.
  /// - "CSD_WHITELIST" : Client side detection whitelist threat type.
  /// - "CSD_DOWNLOAD_WHITELIST" : Client side download detection whitelist
  /// threat type.
  /// - "CLIENT_INCIDENT" : Client incident threat type.
  /// - "CLIENT_INCIDENT_WHITELIST" : Whitelist used when detecting client
  /// incident threats. This enum was never launched and should be re-used for
  /// the next list.
  /// - "APK_MALWARE_OFFLINE" : List used for offline APK checks in PAM.
  /// - "SUBRESOURCE_FILTER" : Patterns to be used for activating the
  /// subresource filter. Interstitial will not be shown for patterns from this
  /// list.
  /// - "SUSPICIOUS" : Entities that are suspected to present a threat.
  /// - "TRICK_TO_BILL" : Trick-to-bill threat list.
  /// - "HIGH_CONFIDENCE_ALLOWLIST" : Safe list to ship hashes of known safe URL
  /// expressions.
  core.String? threatType;

  GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequestListUpdateRequest();

  GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequestListUpdateRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('constraints')) {
      constraints =
          GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequestListUpdateRequestConstraints
              .fromJson(
                  _json['constraints'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('platformType')) {
      platformType = _json['platformType'] as core.String;
    }
    if (_json.containsKey('state')) {
      state = _json['state'] as core.String;
    }
    if (_json.containsKey('threatEntryType')) {
      threatEntryType = _json['threatEntryType'] as core.String;
    }
    if (_json.containsKey('threatType')) {
      threatType = _json['threatType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (constraints != null) 'constraints': constraints!.toJson(),
        if (platformType != null) 'platformType': platformType!,
        if (state != null) 'state': state!,
        if (threatEntryType != null) 'threatEntryType': threatEntryType!,
        if (threatType != null) 'threatType': threatType!,
      };
}

/// The constraints for this update.
class GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequestListUpdateRequestConstraints {
  /// A client's physical location, expressed as a ISO 31166-1 alpha-2 region
  /// code.
  core.String? deviceLocation;

  /// Requests the lists for a specific language.
  ///
  /// Expects ISO 639 alpha-2 format.
  core.String? language;

  /// Sets the maximum number of entries that the client is willing to have in
  /// the local database for the specified list.
  ///
  /// This should be a power of 2 between 2**10 and 2**20. If zero, no database
  /// size limit is set.
  core.int? maxDatabaseEntries;

  /// The maximum size in number of entries.
  ///
  /// The update will not contain more entries than this value. This should be a
  /// power of 2 between 2**10 and 2**20. If zero, no update size limit is set.
  core.int? maxUpdateEntries;

  /// Requests the list for a specific geographic location.
  ///
  /// If not set the server may pick that value based on the user's IP address.
  /// Expects ISO 3166-1 alpha-2 format.
  core.String? region;

  /// The compression types supported by the client.
  core.List<core.String>? supportedCompressions;

  GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequestListUpdateRequestConstraints();

  GoogleSecuritySafebrowsingV4FetchThreatListUpdatesRequestListUpdateRequestConstraints.fromJson(
      core.Map _json) {
    if (_json.containsKey('deviceLocation')) {
      deviceLocation = _json['deviceLocation'] as core.String;
    }
    if (_json.containsKey('language')) {
      language = _json['language'] as core.String;
    }
    if (_json.containsKey('maxDatabaseEntries')) {
      maxDatabaseEntries = _json['maxDatabaseEntries'] as core.int;
    }
    if (_json.containsKey('maxUpdateEntries')) {
      maxUpdateEntries = _json['maxUpdateEntries'] as core.int;
    }
    if (_json.containsKey('region')) {
      region = _json['region'] as core.String;
    }
    if (_json.containsKey('supportedCompressions')) {
      supportedCompressions = (_json['supportedCompressions'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deviceLocation != null) 'deviceLocation': deviceLocation!,
        if (language != null) 'language': language!,
        if (maxDatabaseEntries != null)
          'maxDatabaseEntries': maxDatabaseEntries!,
        if (maxUpdateEntries != null) 'maxUpdateEntries': maxUpdateEntries!,
        if (region != null) 'region': region!,
        if (supportedCompressions != null)
          'supportedCompressions': supportedCompressions!,
      };
}

class GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponse {
  /// The list updates requested by the clients.
  ///
  /// The number of responses here may be less than the number of requests sent
  /// by clients. This is the case, for example, if the server has no updates
  /// for a particular list.
  core.List<
          GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponseListUpdateResponse>?
      listUpdateResponses;

  /// The minimum duration the client must wait before issuing any update
  /// request.
  ///
  /// If this field is not set clients may update as soon as they want.
  core.String? minimumWaitDuration;

  GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponse();

  GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('listUpdateResponses')) {
      listUpdateResponses = (_json['listUpdateResponses'] as core.List)
          .map<GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponseListUpdateResponse>(
              (value) =>
                  GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponseListUpdateResponse
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('minimumWaitDuration')) {
      minimumWaitDuration = _json['minimumWaitDuration'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (listUpdateResponses != null)
          'listUpdateResponses':
              listUpdateResponses!.map((value) => value.toJson()).toList(),
        if (minimumWaitDuration != null)
          'minimumWaitDuration': minimumWaitDuration!,
      };
}

/// An update to an individual list.
class GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponseListUpdateResponse {
  /// A set of entries to add to a local threat type's list.
  ///
  /// Repeated to allow for a combination of compressed and raw data to be sent
  /// in a single response.
  core.List<GoogleSecuritySafebrowsingV4ThreatEntrySet>? additions;

  /// The expected SHA256 hash of the client state; that is, of the sorted list
  /// of all hashes present in the database after applying the provided update.
  ///
  /// If the client state doesn't match the expected state, the client must
  /// disregard this update and retry later.
  GoogleSecuritySafebrowsingV4Checksum? checksum;

  /// The new client state, in encrypted format.
  ///
  /// Opaque to clients.
  core.String? newClientState;
  core.List<core.int> get newClientStateAsBytes =>
      convert.base64.decode(newClientState!);

  set newClientStateAsBytes(core.List<core.int> _bytes) {
    newClientState =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The platform type for which data is returned.
  /// Possible string values are:
  /// - "PLATFORM_TYPE_UNSPECIFIED" : Unknown platform.
  /// - "WINDOWS" : Threat posed to Windows.
  /// - "LINUX" : Threat posed to Linux.
  /// - "ANDROID" : Threat posed to Android.
  /// - "OSX" : Threat posed to OS X.
  /// - "IOS" : Threat posed to iOS.
  /// - "ANY_PLATFORM" : Threat posed to at least one of the defined platforms.
  /// - "ALL_PLATFORMS" : Threat posed to all defined platforms.
  /// - "CHROME" : Threat posed to Chrome.
  core.String? platformType;

  /// A set of entries to remove from a local threat type's list.
  ///
  /// In practice, this field is empty or contains exactly one ThreatEntrySet.
  core.List<GoogleSecuritySafebrowsingV4ThreatEntrySet>? removals;

  /// The type of response.
  ///
  /// This may indicate that an action is required by the client when the
  /// response is received.
  /// Possible string values are:
  /// - "RESPONSE_TYPE_UNSPECIFIED" : Unknown.
  /// - "PARTIAL_UPDATE" : Partial updates are applied to the client's existing
  /// local database.
  /// - "FULL_UPDATE" : Full updates replace the client's entire local database.
  /// This means that either the client was seriously out-of-date or the client
  /// is believed to be corrupt.
  core.String? responseType;

  /// The format of the threats.
  /// Possible string values are:
  /// - "THREAT_ENTRY_TYPE_UNSPECIFIED" : Unspecified.
  /// - "URL" : A URL.
  /// - "EXECUTABLE" : An executable program.
  /// - "IP_RANGE" : An IP range.
  /// - "CHROME_EXTENSION" : Chrome extension.
  /// - "FILENAME" : Filename.
  /// - "CERT" : CERT
  core.String? threatEntryType;

  /// The threat type for which data is returned.
  /// Possible string values are:
  /// - "THREAT_TYPE_UNSPECIFIED" : Unknown.
  /// - "MALWARE" : Malware threat type.
  /// - "SOCIAL_ENGINEERING" : Social engineering threat type.
  /// - "UNWANTED_SOFTWARE" : Unwanted software threat type.
  /// - "POTENTIALLY_HARMFUL_APPLICATION" : Potentially harmful application
  /// threat type.
  /// - "SOCIAL_ENGINEERING_INTERNAL" : Social engineering threat type for
  /// internal use.
  /// - "API_ABUSE" : API abuse threat type.
  /// - "MALICIOUS_BINARY" : Malicious binary threat type.
  /// - "CSD_WHITELIST" : Client side detection whitelist threat type.
  /// - "CSD_DOWNLOAD_WHITELIST" : Client side download detection whitelist
  /// threat type.
  /// - "CLIENT_INCIDENT" : Client incident threat type.
  /// - "CLIENT_INCIDENT_WHITELIST" : Whitelist used when detecting client
  /// incident threats. This enum was never launched and should be re-used for
  /// the next list.
  /// - "APK_MALWARE_OFFLINE" : List used for offline APK checks in PAM.
  /// - "SUBRESOURCE_FILTER" : Patterns to be used for activating the
  /// subresource filter. Interstitial will not be shown for patterns from this
  /// list.
  /// - "SUSPICIOUS" : Entities that are suspected to present a threat.
  /// - "TRICK_TO_BILL" : Trick-to-bill threat list.
  /// - "HIGH_CONFIDENCE_ALLOWLIST" : Safe list to ship hashes of known safe URL
  /// expressions.
  core.String? threatType;

  GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponseListUpdateResponse();

  GoogleSecuritySafebrowsingV4FetchThreatListUpdatesResponseListUpdateResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('additions')) {
      additions = (_json['additions'] as core.List)
          .map<GoogleSecuritySafebrowsingV4ThreatEntrySet>((value) =>
              GoogleSecuritySafebrowsingV4ThreatEntrySet.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('checksum')) {
      checksum = GoogleSecuritySafebrowsingV4Checksum.fromJson(
          _json['checksum'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('newClientState')) {
      newClientState = _json['newClientState'] as core.String;
    }
    if (_json.containsKey('platformType')) {
      platformType = _json['platformType'] as core.String;
    }
    if (_json.containsKey('removals')) {
      removals = (_json['removals'] as core.List)
          .map<GoogleSecuritySafebrowsingV4ThreatEntrySet>((value) =>
              GoogleSecuritySafebrowsingV4ThreatEntrySet.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('responseType')) {
      responseType = _json['responseType'] as core.String;
    }
    if (_json.containsKey('threatEntryType')) {
      threatEntryType = _json['threatEntryType'] as core.String;
    }
    if (_json.containsKey('threatType')) {
      threatType = _json['threatType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (additions != null)
          'additions': additions!.map((value) => value.toJson()).toList(),
        if (checksum != null) 'checksum': checksum!.toJson(),
        if (newClientState != null) 'newClientState': newClientState!,
        if (platformType != null) 'platformType': platformType!,
        if (removals != null)
          'removals': removals!.map((value) => value.toJson()).toList(),
        if (responseType != null) 'responseType': responseType!,
        if (threatEntryType != null) 'threatEntryType': threatEntryType!,
        if (threatType != null) 'threatType': threatType!,
      };
}

/// Request to return full hashes matched by the provided hash prefixes.
class GoogleSecuritySafebrowsingV4FindFullHashesRequest {
  /// Client metadata associated with callers of higher-level APIs built on top
  /// of the client's implementation.
  GoogleSecuritySafebrowsingV4ClientInfo? apiClient;

  /// The client metadata.
  GoogleSecuritySafebrowsingV4ClientInfo? client;

  /// The current client states for each of the client's local threat lists.
  core.List<core.String>? clientStates;

  /// The lists and hashes to be checked.
  GoogleSecuritySafebrowsingV4ThreatInfo? threatInfo;

  GoogleSecuritySafebrowsingV4FindFullHashesRequest();

  GoogleSecuritySafebrowsingV4FindFullHashesRequest.fromJson(core.Map _json) {
    if (_json.containsKey('apiClient')) {
      apiClient = GoogleSecuritySafebrowsingV4ClientInfo.fromJson(
          _json['apiClient'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('client')) {
      client = GoogleSecuritySafebrowsingV4ClientInfo.fromJson(
          _json['client'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('clientStates')) {
      clientStates = (_json['clientStates'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('threatInfo')) {
      threatInfo = GoogleSecuritySafebrowsingV4ThreatInfo.fromJson(
          _json['threatInfo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (apiClient != null) 'apiClient': apiClient!.toJson(),
        if (client != null) 'client': client!.toJson(),
        if (clientStates != null) 'clientStates': clientStates!,
        if (threatInfo != null) 'threatInfo': threatInfo!.toJson(),
      };
}

class GoogleSecuritySafebrowsingV4FindFullHashesResponse {
  /// The full hashes that matched the requested prefixes.
  core.List<GoogleSecuritySafebrowsingV4ThreatMatch>? matches;

  /// The minimum duration the client must wait before issuing any find hashes
  /// request.
  ///
  /// If this field is not set, clients can issue a request as soon as they
  /// want.
  core.String? minimumWaitDuration;

  /// For requested entities that did not match the threat list, how long to
  /// cache the response.
  core.String? negativeCacheDuration;

  GoogleSecuritySafebrowsingV4FindFullHashesResponse();

  GoogleSecuritySafebrowsingV4FindFullHashesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('matches')) {
      matches = (_json['matches'] as core.List)
          .map<GoogleSecuritySafebrowsingV4ThreatMatch>((value) =>
              GoogleSecuritySafebrowsingV4ThreatMatch.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('minimumWaitDuration')) {
      minimumWaitDuration = _json['minimumWaitDuration'] as core.String;
    }
    if (_json.containsKey('negativeCacheDuration')) {
      negativeCacheDuration = _json['negativeCacheDuration'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (matches != null)
          'matches': matches!.map((value) => value.toJson()).toList(),
        if (minimumWaitDuration != null)
          'minimumWaitDuration': minimumWaitDuration!,
        if (negativeCacheDuration != null)
          'negativeCacheDuration': negativeCacheDuration!,
      };
}

/// Request to check entries against lists.
class GoogleSecuritySafebrowsingV4FindThreatMatchesRequest {
  /// The client metadata.
  GoogleSecuritySafebrowsingV4ClientInfo? client;

  /// The lists and entries to be checked for matches.
  GoogleSecuritySafebrowsingV4ThreatInfo? threatInfo;

  GoogleSecuritySafebrowsingV4FindThreatMatchesRequest();

  GoogleSecuritySafebrowsingV4FindThreatMatchesRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('client')) {
      client = GoogleSecuritySafebrowsingV4ClientInfo.fromJson(
          _json['client'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('threatInfo')) {
      threatInfo = GoogleSecuritySafebrowsingV4ThreatInfo.fromJson(
          _json['threatInfo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (client != null) 'client': client!.toJson(),
        if (threatInfo != null) 'threatInfo': threatInfo!.toJson(),
      };
}

class GoogleSecuritySafebrowsingV4FindThreatMatchesResponse {
  /// The threat list matches.
  core.List<GoogleSecuritySafebrowsingV4ThreatMatch>? matches;

  GoogleSecuritySafebrowsingV4FindThreatMatchesResponse();

  GoogleSecuritySafebrowsingV4FindThreatMatchesResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('matches')) {
      matches = (_json['matches'] as core.List)
          .map<GoogleSecuritySafebrowsingV4ThreatMatch>((value) =>
              GoogleSecuritySafebrowsingV4ThreatMatch.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (matches != null)
          'matches': matches!.map((value) => value.toJson()).toList(),
      };
}

class GoogleSecuritySafebrowsingV4ListThreatListsResponse {
  /// The lists available for download by the client.
  core.List<GoogleSecuritySafebrowsingV4ThreatListDescriptor>? threatLists;

  GoogleSecuritySafebrowsingV4ListThreatListsResponse();

  GoogleSecuritySafebrowsingV4ListThreatListsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('threatLists')) {
      threatLists = (_json['threatLists'] as core.List)
          .map<GoogleSecuritySafebrowsingV4ThreatListDescriptor>((value) =>
              GoogleSecuritySafebrowsingV4ThreatListDescriptor.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (threatLists != null)
          'threatLists': threatLists!.map((value) => value.toJson()).toList(),
      };
}

/// The uncompressed threat entries in hash format of a particular prefix
/// length.
///
/// Hashes can be anywhere from 4 to 32 bytes in size. A large majority are 4
/// bytes, but some hashes are lengthened if they collide with the hash of a
/// popular URL. Used for sending ThreatEntrySet to clients that do not support
/// compression, or when sending non-4-byte hashes to clients that do support
/// compression.
class GoogleSecuritySafebrowsingV4RawHashes {
  /// The number of bytes for each prefix encoded below.
  ///
  /// This field can be anywhere from 4 (shortest prefix) to 32 (full SHA256
  /// hash).
  core.int? prefixSize;

  /// The hashes, in binary format, concatenated into one long string.
  ///
  /// Hashes are sorted in lexicographic order. For JSON API users, hashes are
  /// base64-encoded.
  core.String? rawHashes;
  core.List<core.int> get rawHashesAsBytes => convert.base64.decode(rawHashes!);

  set rawHashesAsBytes(core.List<core.int> _bytes) {
    rawHashes =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  GoogleSecuritySafebrowsingV4RawHashes();

  GoogleSecuritySafebrowsingV4RawHashes.fromJson(core.Map _json) {
    if (_json.containsKey('prefixSize')) {
      prefixSize = _json['prefixSize'] as core.int;
    }
    if (_json.containsKey('rawHashes')) {
      rawHashes = _json['rawHashes'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (prefixSize != null) 'prefixSize': prefixSize!,
        if (rawHashes != null) 'rawHashes': rawHashes!,
      };
}

/// A set of raw indices to remove from a local list.
class GoogleSecuritySafebrowsingV4RawIndices {
  /// The indices to remove from a lexicographically-sorted local list.
  core.List<core.int>? indices;

  GoogleSecuritySafebrowsingV4RawIndices();

  GoogleSecuritySafebrowsingV4RawIndices.fromJson(core.Map _json) {
    if (_json.containsKey('indices')) {
      indices = (_json['indices'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (indices != null) 'indices': indices!,
      };
}

/// The Rice-Golomb encoded data.
///
/// Used for sending compressed 4-byte hashes or compressed removal indices.
class GoogleSecuritySafebrowsingV4RiceDeltaEncoding {
  /// The encoded deltas that are encoded using the Golomb-Rice coder.
  core.String? encodedData;
  core.List<core.int> get encodedDataAsBytes =>
      convert.base64.decode(encodedData!);

  set encodedDataAsBytes(core.List<core.int> _bytes) {
    encodedData =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The offset of the first entry in the encoded data, or, if only a single
  /// integer was encoded, that single integer's value.
  ///
  /// If the field is empty or missing, assume zero.
  core.String? firstValue;

  /// The number of entries that are delta encoded in the encoded data.
  ///
  /// If only a single integer was encoded, this will be zero and the single
  /// value will be stored in `first_value`.
  core.int? numEntries;

  /// The Golomb-Rice parameter, which is a number between 2 and 28.
  ///
  /// This field is missing (that is, zero) if `num_entries` is zero.
  core.int? riceParameter;

  GoogleSecuritySafebrowsingV4RiceDeltaEncoding();

  GoogleSecuritySafebrowsingV4RiceDeltaEncoding.fromJson(core.Map _json) {
    if (_json.containsKey('encodedData')) {
      encodedData = _json['encodedData'] as core.String;
    }
    if (_json.containsKey('firstValue')) {
      firstValue = _json['firstValue'] as core.String;
    }
    if (_json.containsKey('numEntries')) {
      numEntries = _json['numEntries'] as core.int;
    }
    if (_json.containsKey('riceParameter')) {
      riceParameter = _json['riceParameter'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (encodedData != null) 'encodedData': encodedData!,
        if (firstValue != null) 'firstValue': firstValue!,
        if (numEntries != null) 'numEntries': numEntries!,
        if (riceParameter != null) 'riceParameter': riceParameter!,
      };
}

/// An individual threat; for example, a malicious URL or its hash
/// representation.
///
/// Only one of these fields should be set.
class GoogleSecuritySafebrowsingV4ThreatEntry {
  /// The digest of an executable in SHA256 format.
  ///
  /// The API supports both binary and hex digests. For JSON requests, digests
  /// are base64-encoded.
  core.String? digest;
  core.List<core.int> get digestAsBytes => convert.base64.decode(digest!);

  set digestAsBytes(core.List<core.int> _bytes) {
    digest =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// A hash prefix, consisting of the most significant 4-32 bytes of a SHA256
  /// hash.
  ///
  /// This field is in binary format. For JSON requests, hashes are
  /// base64-encoded.
  core.String? hash;
  core.List<core.int> get hashAsBytes => convert.base64.decode(hash!);

  set hashAsBytes(core.List<core.int> _bytes) {
    hash =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// A URL.
  core.String? url;

  GoogleSecuritySafebrowsingV4ThreatEntry();

  GoogleSecuritySafebrowsingV4ThreatEntry.fromJson(core.Map _json) {
    if (_json.containsKey('digest')) {
      digest = _json['digest'] as core.String;
    }
    if (_json.containsKey('hash')) {
      hash = _json['hash'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (digest != null) 'digest': digest!,
        if (hash != null) 'hash': hash!,
        if (url != null) 'url': url!,
      };
}

/// The metadata associated with a specific threat entry.
///
/// The client is expected to know the metadata key/value pairs associated with
/// each threat type.
class GoogleSecuritySafebrowsingV4ThreatEntryMetadata {
  /// The metadata entries.
  core.List<GoogleSecuritySafebrowsingV4ThreatEntryMetadataMetadataEntry>?
      entries;

  GoogleSecuritySafebrowsingV4ThreatEntryMetadata();

  GoogleSecuritySafebrowsingV4ThreatEntryMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('entries')) {
      entries = (_json['entries'] as core.List)
          .map<GoogleSecuritySafebrowsingV4ThreatEntryMetadataMetadataEntry>(
              (value) =>
                  GoogleSecuritySafebrowsingV4ThreatEntryMetadataMetadataEntry
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entries != null)
          'entries': entries!.map((value) => value.toJson()).toList(),
      };
}

/// A single metadata entry.
class GoogleSecuritySafebrowsingV4ThreatEntryMetadataMetadataEntry {
  /// The metadata entry key.
  ///
  /// For JSON requests, the key is base64-encoded.
  core.String? key;
  core.List<core.int> get keyAsBytes => convert.base64.decode(key!);

  set keyAsBytes(core.List<core.int> _bytes) {
    key =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The metadata entry value.
  ///
  /// For JSON requests, the value is base64-encoded.
  core.String? value;
  core.List<core.int> get valueAsBytes => convert.base64.decode(value!);

  set valueAsBytes(core.List<core.int> _bytes) {
    value =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  GoogleSecuritySafebrowsingV4ThreatEntryMetadataMetadataEntry();

  GoogleSecuritySafebrowsingV4ThreatEntryMetadataMetadataEntry.fromJson(
      core.Map _json) {
    if (_json.containsKey('key')) {
      key = _json['key'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!,
        if (value != null) 'value': value!,
      };
}

/// A set of threats that should be added or removed from a client's local
/// database.
class GoogleSecuritySafebrowsingV4ThreatEntrySet {
  /// The compression type for the entries in this set.
  /// Possible string values are:
  /// - "COMPRESSION_TYPE_UNSPECIFIED" : Unknown.
  /// - "RAW" : Raw, uncompressed data.
  /// - "RICE" : Rice-Golomb encoded data.
  core.String? compressionType;

  /// The raw SHA256-formatted entries.
  GoogleSecuritySafebrowsingV4RawHashes? rawHashes;

  /// The raw removal indices for a local list.
  GoogleSecuritySafebrowsingV4RawIndices? rawIndices;

  /// The encoded 4-byte prefixes of SHA256-formatted entries, using a
  /// Golomb-Rice encoding.
  ///
  /// The hashes are converted to uint32, sorted in ascending order, then delta
  /// encoded and stored as encoded_data.
  GoogleSecuritySafebrowsingV4RiceDeltaEncoding? riceHashes;

  /// The encoded local, lexicographically-sorted list indices, using a
  /// Golomb-Rice encoding.
  ///
  /// Used for sending compressed removal indices. The removal indices (uint32)
  /// are sorted in ascending order, then delta encoded and stored as
  /// encoded_data.
  GoogleSecuritySafebrowsingV4RiceDeltaEncoding? riceIndices;

  GoogleSecuritySafebrowsingV4ThreatEntrySet();

  GoogleSecuritySafebrowsingV4ThreatEntrySet.fromJson(core.Map _json) {
    if (_json.containsKey('compressionType')) {
      compressionType = _json['compressionType'] as core.String;
    }
    if (_json.containsKey('rawHashes')) {
      rawHashes = GoogleSecuritySafebrowsingV4RawHashes.fromJson(
          _json['rawHashes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('rawIndices')) {
      rawIndices = GoogleSecuritySafebrowsingV4RawIndices.fromJson(
          _json['rawIndices'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('riceHashes')) {
      riceHashes = GoogleSecuritySafebrowsingV4RiceDeltaEncoding.fromJson(
          _json['riceHashes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('riceIndices')) {
      riceIndices = GoogleSecuritySafebrowsingV4RiceDeltaEncoding.fromJson(
          _json['riceIndices'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (compressionType != null) 'compressionType': compressionType!,
        if (rawHashes != null) 'rawHashes': rawHashes!.toJson(),
        if (rawIndices != null) 'rawIndices': rawIndices!.toJson(),
        if (riceHashes != null) 'riceHashes': riceHashes!.toJson(),
        if (riceIndices != null) 'riceIndices': riceIndices!.toJson(),
      };
}

class GoogleSecuritySafebrowsingV4ThreatHit {
  /// Client-reported identification.
  GoogleSecuritySafebrowsingV4ClientInfo? clientInfo;

  /// The threat entry responsible for the hit.
  ///
  /// Full hash should be reported for hash-based hits.
  GoogleSecuritySafebrowsingV4ThreatEntry? entry;

  /// The platform type reported.
  /// Possible string values are:
  /// - "PLATFORM_TYPE_UNSPECIFIED" : Unknown platform.
  /// - "WINDOWS" : Threat posed to Windows.
  /// - "LINUX" : Threat posed to Linux.
  /// - "ANDROID" : Threat posed to Android.
  /// - "OSX" : Threat posed to OS X.
  /// - "IOS" : Threat posed to iOS.
  /// - "ANY_PLATFORM" : Threat posed to at least one of the defined platforms.
  /// - "ALL_PLATFORMS" : Threat posed to all defined platforms.
  /// - "CHROME" : Threat posed to Chrome.
  core.String? platformType;

  /// The resources related to the threat hit.
  core.List<GoogleSecuritySafebrowsingV4ThreatHitThreatSource>? resources;

  /// The threat type reported.
  /// Possible string values are:
  /// - "THREAT_TYPE_UNSPECIFIED" : Unknown.
  /// - "MALWARE" : Malware threat type.
  /// - "SOCIAL_ENGINEERING" : Social engineering threat type.
  /// - "UNWANTED_SOFTWARE" : Unwanted software threat type.
  /// - "POTENTIALLY_HARMFUL_APPLICATION" : Potentially harmful application
  /// threat type.
  /// - "SOCIAL_ENGINEERING_INTERNAL" : Social engineering threat type for
  /// internal use.
  /// - "API_ABUSE" : API abuse threat type.
  /// - "MALICIOUS_BINARY" : Malicious binary threat type.
  /// - "CSD_WHITELIST" : Client side detection whitelist threat type.
  /// - "CSD_DOWNLOAD_WHITELIST" : Client side download detection whitelist
  /// threat type.
  /// - "CLIENT_INCIDENT" : Client incident threat type.
  /// - "CLIENT_INCIDENT_WHITELIST" : Whitelist used when detecting client
  /// incident threats. This enum was never launched and should be re-used for
  /// the next list.
  /// - "APK_MALWARE_OFFLINE" : List used for offline APK checks in PAM.
  /// - "SUBRESOURCE_FILTER" : Patterns to be used for activating the
  /// subresource filter. Interstitial will not be shown for patterns from this
  /// list.
  /// - "SUSPICIOUS" : Entities that are suspected to present a threat.
  /// - "TRICK_TO_BILL" : Trick-to-bill threat list.
  /// - "HIGH_CONFIDENCE_ALLOWLIST" : Safe list to ship hashes of known safe URL
  /// expressions.
  core.String? threatType;

  /// Details about the user that encountered the threat.
  GoogleSecuritySafebrowsingV4ThreatHitUserInfo? userInfo;

  GoogleSecuritySafebrowsingV4ThreatHit();

  GoogleSecuritySafebrowsingV4ThreatHit.fromJson(core.Map _json) {
    if (_json.containsKey('clientInfo')) {
      clientInfo = GoogleSecuritySafebrowsingV4ClientInfo.fromJson(
          _json['clientInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('entry')) {
      entry = GoogleSecuritySafebrowsingV4ThreatEntry.fromJson(
          _json['entry'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('platformType')) {
      platformType = _json['platformType'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<GoogleSecuritySafebrowsingV4ThreatHitThreatSource>((value) =>
              GoogleSecuritySafebrowsingV4ThreatHitThreatSource.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('threatType')) {
      threatType = _json['threatType'] as core.String;
    }
    if (_json.containsKey('userInfo')) {
      userInfo = GoogleSecuritySafebrowsingV4ThreatHitUserInfo.fromJson(
          _json['userInfo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (clientInfo != null) 'clientInfo': clientInfo!.toJson(),
        if (entry != null) 'entry': entry!.toJson(),
        if (platformType != null) 'platformType': platformType!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
        if (threatType != null) 'threatType': threatType!,
        if (userInfo != null) 'userInfo': userInfo!.toJson(),
      };
}

/// A single resource related to a threat hit.
class GoogleSecuritySafebrowsingV4ThreatHitThreatSource {
  /// Referrer of the resource.
  ///
  /// Only set if the referrer is available.
  core.String? referrer;

  /// The remote IP of the resource in ASCII format.
  ///
  /// Either IPv4 or IPv6.
  core.String? remoteIp;

  /// The type of source reported.
  /// Possible string values are:
  /// - "THREAT_SOURCE_TYPE_UNSPECIFIED" : Unknown.
  /// - "MATCHING_URL" : The URL that matched the threat list (for which
  /// GetFullHash returned a valid hash).
  /// - "TAB_URL" : The final top-level URL of the tab that the client was
  /// browsing when the match occurred.
  /// - "TAB_REDIRECT" : A redirect URL that was fetched before hitting the
  /// final TAB_URL.
  /// - "TAB_RESOURCE" : A resource loaded within the final TAB_URL.
  core.String? type;

  /// The URL of the resource.
  core.String? url;

  GoogleSecuritySafebrowsingV4ThreatHitThreatSource();

  GoogleSecuritySafebrowsingV4ThreatHitThreatSource.fromJson(core.Map _json) {
    if (_json.containsKey('referrer')) {
      referrer = _json['referrer'] as core.String;
    }
    if (_json.containsKey('remoteIp')) {
      remoteIp = _json['remoteIp'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (referrer != null) 'referrer': referrer!,
        if (remoteIp != null) 'remoteIp': remoteIp!,
        if (type != null) 'type': type!,
        if (url != null) 'url': url!,
      };
}

/// Details about the user that encountered the threat.
class GoogleSecuritySafebrowsingV4ThreatHitUserInfo {
  /// The UN M.49 region code associated with the user's location.
  core.String? regionCode;

  /// Unique user identifier defined by the client.
  core.String? userId;
  core.List<core.int> get userIdAsBytes => convert.base64.decode(userId!);

  set userIdAsBytes(core.List<core.int> _bytes) {
    userId =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  GoogleSecuritySafebrowsingV4ThreatHitUserInfo();

  GoogleSecuritySafebrowsingV4ThreatHitUserInfo.fromJson(core.Map _json) {
    if (_json.containsKey('regionCode')) {
      regionCode = _json['regionCode'] as core.String;
    }
    if (_json.containsKey('userId')) {
      userId = _json['userId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (regionCode != null) 'regionCode': regionCode!,
        if (userId != null) 'userId': userId!,
      };
}

/// The information regarding one or more threats that a client submits when
/// checking for matches in threat lists.
class GoogleSecuritySafebrowsingV4ThreatInfo {
  /// The platform types to be checked.
  core.List<core.String>? platformTypes;

  /// The threat entries to be checked.
  core.List<GoogleSecuritySafebrowsingV4ThreatEntry>? threatEntries;

  /// The entry types to be checked.
  core.List<core.String>? threatEntryTypes;

  /// The threat types to be checked.
  core.List<core.String>? threatTypes;

  GoogleSecuritySafebrowsingV4ThreatInfo();

  GoogleSecuritySafebrowsingV4ThreatInfo.fromJson(core.Map _json) {
    if (_json.containsKey('platformTypes')) {
      platformTypes = (_json['platformTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('threatEntries')) {
      threatEntries = (_json['threatEntries'] as core.List)
          .map<GoogleSecuritySafebrowsingV4ThreatEntry>((value) =>
              GoogleSecuritySafebrowsingV4ThreatEntry.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('threatEntryTypes')) {
      threatEntryTypes = (_json['threatEntryTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('threatTypes')) {
      threatTypes = (_json['threatTypes'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (platformTypes != null) 'platformTypes': platformTypes!,
        if (threatEntries != null)
          'threatEntries':
              threatEntries!.map((value) => value.toJson()).toList(),
        if (threatEntryTypes != null) 'threatEntryTypes': threatEntryTypes!,
        if (threatTypes != null) 'threatTypes': threatTypes!,
      };
}

/// Describes an individual threat list.
///
/// A list is defined by three parameters: the type of threat posed, the type of
/// platform targeted by the threat, and the type of entries in the list.
class GoogleSecuritySafebrowsingV4ThreatListDescriptor {
  /// The platform type targeted by the list's entries.
  /// Possible string values are:
  /// - "PLATFORM_TYPE_UNSPECIFIED" : Unknown platform.
  /// - "WINDOWS" : Threat posed to Windows.
  /// - "LINUX" : Threat posed to Linux.
  /// - "ANDROID" : Threat posed to Android.
  /// - "OSX" : Threat posed to OS X.
  /// - "IOS" : Threat posed to iOS.
  /// - "ANY_PLATFORM" : Threat posed to at least one of the defined platforms.
  /// - "ALL_PLATFORMS" : Threat posed to all defined platforms.
  /// - "CHROME" : Threat posed to Chrome.
  core.String? platformType;

  /// The entry types contained in the list.
  /// Possible string values are:
  /// - "THREAT_ENTRY_TYPE_UNSPECIFIED" : Unspecified.
  /// - "URL" : A URL.
  /// - "EXECUTABLE" : An executable program.
  /// - "IP_RANGE" : An IP range.
  /// - "CHROME_EXTENSION" : Chrome extension.
  /// - "FILENAME" : Filename.
  /// - "CERT" : CERT
  core.String? threatEntryType;

  /// The threat type posed by the list's entries.
  /// Possible string values are:
  /// - "THREAT_TYPE_UNSPECIFIED" : Unknown.
  /// - "MALWARE" : Malware threat type.
  /// - "SOCIAL_ENGINEERING" : Social engineering threat type.
  /// - "UNWANTED_SOFTWARE" : Unwanted software threat type.
  /// - "POTENTIALLY_HARMFUL_APPLICATION" : Potentially harmful application
  /// threat type.
  /// - "SOCIAL_ENGINEERING_INTERNAL" : Social engineering threat type for
  /// internal use.
  /// - "API_ABUSE" : API abuse threat type.
  /// - "MALICIOUS_BINARY" : Malicious binary threat type.
  /// - "CSD_WHITELIST" : Client side detection whitelist threat type.
  /// - "CSD_DOWNLOAD_WHITELIST" : Client side download detection whitelist
  /// threat type.
  /// - "CLIENT_INCIDENT" : Client incident threat type.
  /// - "CLIENT_INCIDENT_WHITELIST" : Whitelist used when detecting client
  /// incident threats. This enum was never launched and should be re-used for
  /// the next list.
  /// - "APK_MALWARE_OFFLINE" : List used for offline APK checks in PAM.
  /// - "SUBRESOURCE_FILTER" : Patterns to be used for activating the
  /// subresource filter. Interstitial will not be shown for patterns from this
  /// list.
  /// - "SUSPICIOUS" : Entities that are suspected to present a threat.
  /// - "TRICK_TO_BILL" : Trick-to-bill threat list.
  /// - "HIGH_CONFIDENCE_ALLOWLIST" : Safe list to ship hashes of known safe URL
  /// expressions.
  core.String? threatType;

  GoogleSecuritySafebrowsingV4ThreatListDescriptor();

  GoogleSecuritySafebrowsingV4ThreatListDescriptor.fromJson(core.Map _json) {
    if (_json.containsKey('platformType')) {
      platformType = _json['platformType'] as core.String;
    }
    if (_json.containsKey('threatEntryType')) {
      threatEntryType = _json['threatEntryType'] as core.String;
    }
    if (_json.containsKey('threatType')) {
      threatType = _json['threatType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (platformType != null) 'platformType': platformType!,
        if (threatEntryType != null) 'threatEntryType': threatEntryType!,
        if (threatType != null) 'threatType': threatType!,
      };
}

/// A match when checking a threat entry in the Safe Browsing threat lists.
class GoogleSecuritySafebrowsingV4ThreatMatch {
  /// The cache lifetime for the returned match.
  ///
  /// Clients must not cache this response for more than this duration to avoid
  /// false positives.
  core.String? cacheDuration;

  /// The platform type matching this threat.
  /// Possible string values are:
  /// - "PLATFORM_TYPE_UNSPECIFIED" : Unknown platform.
  /// - "WINDOWS" : Threat posed to Windows.
  /// - "LINUX" : Threat posed to Linux.
  /// - "ANDROID" : Threat posed to Android.
  /// - "OSX" : Threat posed to OS X.
  /// - "IOS" : Threat posed to iOS.
  /// - "ANY_PLATFORM" : Threat posed to at least one of the defined platforms.
  /// - "ALL_PLATFORMS" : Threat posed to all defined platforms.
  /// - "CHROME" : Threat posed to Chrome.
  core.String? platformType;

  /// The threat matching this threat.
  GoogleSecuritySafebrowsingV4ThreatEntry? threat;

  /// Optional metadata associated with this threat.
  GoogleSecuritySafebrowsingV4ThreatEntryMetadata? threatEntryMetadata;

  /// The threat entry type matching this threat.
  /// Possible string values are:
  /// - "THREAT_ENTRY_TYPE_UNSPECIFIED" : Unspecified.
  /// - "URL" : A URL.
  /// - "EXECUTABLE" : An executable program.
  /// - "IP_RANGE" : An IP range.
  /// - "CHROME_EXTENSION" : Chrome extension.
  /// - "FILENAME" : Filename.
  /// - "CERT" : CERT
  core.String? threatEntryType;

  /// The threat type matching this threat.
  /// Possible string values are:
  /// - "THREAT_TYPE_UNSPECIFIED" : Unknown.
  /// - "MALWARE" : Malware threat type.
  /// - "SOCIAL_ENGINEERING" : Social engineering threat type.
  /// - "UNWANTED_SOFTWARE" : Unwanted software threat type.
  /// - "POTENTIALLY_HARMFUL_APPLICATION" : Potentially harmful application
  /// threat type.
  /// - "SOCIAL_ENGINEERING_INTERNAL" : Social engineering threat type for
  /// internal use.
  /// - "API_ABUSE" : API abuse threat type.
  /// - "MALICIOUS_BINARY" : Malicious binary threat type.
  /// - "CSD_WHITELIST" : Client side detection whitelist threat type.
  /// - "CSD_DOWNLOAD_WHITELIST" : Client side download detection whitelist
  /// threat type.
  /// - "CLIENT_INCIDENT" : Client incident threat type.
  /// - "CLIENT_INCIDENT_WHITELIST" : Whitelist used when detecting client
  /// incident threats. This enum was never launched and should be re-used for
  /// the next list.
  /// - "APK_MALWARE_OFFLINE" : List used for offline APK checks in PAM.
  /// - "SUBRESOURCE_FILTER" : Patterns to be used for activating the
  /// subresource filter. Interstitial will not be shown for patterns from this
  /// list.
  /// - "SUSPICIOUS" : Entities that are suspected to present a threat.
  /// - "TRICK_TO_BILL" : Trick-to-bill threat list.
  /// - "HIGH_CONFIDENCE_ALLOWLIST" : Safe list to ship hashes of known safe URL
  /// expressions.
  core.String? threatType;

  GoogleSecuritySafebrowsingV4ThreatMatch();

  GoogleSecuritySafebrowsingV4ThreatMatch.fromJson(core.Map _json) {
    if (_json.containsKey('cacheDuration')) {
      cacheDuration = _json['cacheDuration'] as core.String;
    }
    if (_json.containsKey('platformType')) {
      platformType = _json['platformType'] as core.String;
    }
    if (_json.containsKey('threat')) {
      threat = GoogleSecuritySafebrowsingV4ThreatEntry.fromJson(
          _json['threat'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('threatEntryMetadata')) {
      threatEntryMetadata =
          GoogleSecuritySafebrowsingV4ThreatEntryMetadata.fromJson(
              _json['threatEntryMetadata']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('threatEntryType')) {
      threatEntryType = _json['threatEntryType'] as core.String;
    }
    if (_json.containsKey('threatType')) {
      threatType = _json['threatType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cacheDuration != null) 'cacheDuration': cacheDuration!,
        if (platformType != null) 'platformType': platformType!,
        if (threat != null) 'threat': threat!.toJson(),
        if (threatEntryMetadata != null)
          'threatEntryMetadata': threatEntryMetadata!.toJson(),
        if (threatEntryType != null) 'threatEntryType': threatEntryType!,
        if (threatType != null) 'threatType': threatType!,
      };
}
