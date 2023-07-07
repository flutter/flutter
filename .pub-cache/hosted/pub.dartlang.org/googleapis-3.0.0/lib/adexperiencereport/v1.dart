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

/// Ad Experience Report API - v1
///
/// Views Ad Experience Report data, and gets a list of sites that have a
/// significant number of annoying ads.
///
/// For more information, see
/// <https://developers.google.com/ad-experience-report/>
///
/// Create an instance of [AdExperienceReportApi] to access these resources:
///
/// - [SitesResource]
/// - [ViolatingSitesResource]
library adexperiencereport.v1;

import 'dart:async' as async;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Views Ad Experience Report data, and gets a list of sites that have a
/// significant number of annoying ads.
class AdExperienceReportApi {
  final commons.ApiRequester _requester;

  SitesResource get sites => SitesResource(_requester);
  ViolatingSitesResource get violatingSites =>
      ViolatingSitesResource(_requester);

  AdExperienceReportApi(http.Client client,
      {core.String rootUrl = 'https://adexperiencereport.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class SitesResource {
  final commons.ApiRequester _requester;

  SitesResource(commons.ApiRequester client) : _requester = client;

  /// Gets a site's Ad Experience Report summary.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the site whose summary to get, e.g.
  /// `sites/http%3A%2F%2Fwww.google.com%2F`. Format: `sites/{site}`
  /// Value must have pattern `^sites/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [SiteSummaryResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<SiteSummaryResponse> get(
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
    return SiteSummaryResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ViolatingSitesResource {
  final commons.ApiRequester _requester;

  ViolatingSitesResource(commons.ApiRequester client) : _requester = client;

  /// Lists sites that are failing in the Ad Experience Report on at least one
  /// platform.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ViolatingSitesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ViolatingSitesResponse> list({
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/violatingSites';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ViolatingSitesResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// A site's Ad Experience Report summary on a single platform.
class PlatformSummary {
  /// The site's Ad Experience Report status on this platform.
  /// Possible string values are:
  /// - "UNKNOWN" : Not reviewed.
  /// - "PASSING" : Passing.
  /// - "WARNING" : Warning. No longer a possible status.
  /// - "FAILING" : Failing.
  core.String? betterAdsStatus;

  /// The time at which
  /// [enforcement](https://support.google.com/webtools/answer/7308033) against
  /// the site began or will begin on this platform.
  ///
  /// Not set when the filter_status is OFF.
  core.String? enforcementTime;

  /// The site's
  /// [enforcement status](https://support.google.com/webtools/answer/7308033)
  /// on this platform.
  /// Possible string values are:
  /// - "UNKNOWN" : N/A.
  /// - "ON" : Ad filtering is on.
  /// - "OFF" : Ad filtering is off.
  /// - "PAUSED" : Ad filtering is paused.
  /// - "PENDING" : Ad filtering is pending.
  core.String? filterStatus;

  /// The time at which the site's status last changed on this platform.
  core.String? lastChangeTime;

  /// The site's regions on this platform.
  ///
  /// No longer populated, because there is no longer any semantic difference
  /// between sites in different regions.
  core.List<core.String>? region;

  /// A link to the full Ad Experience Report for the site on this platform..
  ///
  /// Not set in ViolatingSitesResponse. Note that you must complete the
  /// [Search Console verification process](https://support.google.com/webmasters/answer/9008080)
  /// for the site before you can access the full report.
  core.String? reportUrl;

  /// Whether the site is currently under review on this platform.
  core.bool? underReview;

  PlatformSummary();

  PlatformSummary.fromJson(core.Map _json) {
    if (_json.containsKey('betterAdsStatus')) {
      betterAdsStatus = _json['betterAdsStatus'] as core.String;
    }
    if (_json.containsKey('enforcementTime')) {
      enforcementTime = _json['enforcementTime'] as core.String;
    }
    if (_json.containsKey('filterStatus')) {
      filterStatus = _json['filterStatus'] as core.String;
    }
    if (_json.containsKey('lastChangeTime')) {
      lastChangeTime = _json['lastChangeTime'] as core.String;
    }
    if (_json.containsKey('region')) {
      region = (_json['region'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('reportUrl')) {
      reportUrl = _json['reportUrl'] as core.String;
    }
    if (_json.containsKey('underReview')) {
      underReview = _json['underReview'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (betterAdsStatus != null) 'betterAdsStatus': betterAdsStatus!,
        if (enforcementTime != null) 'enforcementTime': enforcementTime!,
        if (filterStatus != null) 'filterStatus': filterStatus!,
        if (lastChangeTime != null) 'lastChangeTime': lastChangeTime!,
        if (region != null) 'region': region!,
        if (reportUrl != null) 'reportUrl': reportUrl!,
        if (underReview != null) 'underReview': underReview!,
      };
}

/// Response message for GetSiteSummary.
class SiteSummaryResponse {
  /// The site's Ad Experience Report summary on desktop.
  PlatformSummary? desktopSummary;

  /// The site's Ad Experience Report summary on mobile.
  PlatformSummary? mobileSummary;

  /// The name of the reviewed site, e.g. `google.com`.
  core.String? reviewedSite;

  SiteSummaryResponse();

  SiteSummaryResponse.fromJson(core.Map _json) {
    if (_json.containsKey('desktopSummary')) {
      desktopSummary = PlatformSummary.fromJson(
          _json['desktopSummary'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('mobileSummary')) {
      mobileSummary = PlatformSummary.fromJson(
          _json['mobileSummary'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('reviewedSite')) {
      reviewedSite = _json['reviewedSite'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (desktopSummary != null) 'desktopSummary': desktopSummary!.toJson(),
        if (mobileSummary != null) 'mobileSummary': mobileSummary!.toJson(),
        if (reviewedSite != null) 'reviewedSite': reviewedSite!,
      };
}

/// Response message for ListViolatingSites.
class ViolatingSitesResponse {
  /// The list of violating sites.
  core.List<SiteSummaryResponse>? violatingSites;

  ViolatingSitesResponse();

  ViolatingSitesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('violatingSites')) {
      violatingSites = (_json['violatingSites'] as core.List)
          .map<SiteSummaryResponse>((value) => SiteSummaryResponse.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (violatingSites != null)
          'violatingSites':
              violatingSites!.map((value) => value.toJson()).toList(),
      };
}
