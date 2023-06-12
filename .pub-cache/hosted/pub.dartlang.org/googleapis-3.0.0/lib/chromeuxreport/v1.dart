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

/// Chrome UX Report API - v1
///
/// The Chrome UX Report API lets you view real user experience data for
/// millions of websites.
///
/// For more information, see
/// <https://developers.google.com/web/tools/chrome-user-experience-report/api/reference>
///
/// Create an instance of [ChromeUXReportApi] to access these resources:
///
/// - [RecordsResource]
library chromeuxreport.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// The Chrome UX Report API lets you view real user experience data for
/// millions of websites.
class ChromeUXReportApi {
  final commons.ApiRequester _requester;

  RecordsResource get records => RecordsResource(_requester);

  ChromeUXReportApi(http.Client client,
      {core.String rootUrl = 'https://chromeuxreport.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class RecordsResource {
  final commons.ApiRequester _requester;

  RecordsResource(commons.ApiRequester client) : _requester = client;

  /// Queries the Chrome User Experience for a single `record` for a given site.
  ///
  /// Returns a `record` that contains one or more `metrics` corresponding to
  /// performance data about the requested site.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [QueryResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<QueryResponse> queryRecord(
    QueryRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/records:queryRecord';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return QueryResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// A bin is a discrete portion of data spanning from start to end, or if no end
/// is given, then from start to +inf.
///
/// A bin's start and end values are given in the value type of the metric it
/// represents. For example, "first contentful paint" is measured in
/// milliseconds and exposed as ints, therefore its metric bins will use int32s
/// for its start and end types. However, "cumulative layout shift" is measured
/// in unitless decimals and is exposed as a decimal encoded as a string,
/// therefore its metric bins will use strings for its value type.
class Bin {
  /// The proportion of users that experienced this bin's value for the given
  /// metric.
  core.double? density;

  /// End is the end of the data bin.
  ///
  /// If end is not populated, then the bin has no end and is valid from start
  /// to +inf.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? end;

  /// Start is the beginning of the data bin.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? start;

  Bin();

  Bin.fromJson(core.Map _json) {
    if (_json.containsKey('density')) {
      density = (_json['density'] as core.num).toDouble();
    }
    if (_json.containsKey('end')) {
      end = _json['end'] as core.Object;
    }
    if (_json.containsKey('start')) {
      start = _json['start'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (density != null) 'density': density!,
        if (end != null) 'end': end!,
        if (start != null) 'start': start!,
      };
}

/// Key defines all the dimensions that identify this record as unique.
class Key {
  /// The effective connection type is the general connection class that all
  /// users experienced for this record.
  ///
  /// This field uses the values \["offline", "slow-2G", "2G", "3G", "4G"\] as
  /// specified in: https://wicg.github.io/netinfo/#effective-connection-types
  /// If the effective connection type is unspecified, then aggregated data over
  /// all effective connection types will be returned.
  core.String? effectiveConnectionType;

  /// The form factor is the device class that all users used to access the site
  /// for this record.
  ///
  /// If the form factor is unspecified, then aggregated data over all form
  /// factors will be returned.
  /// Possible string values are:
  /// - "ALL_FORM_FACTORS" : The default value, representing all device classes.
  /// - "PHONE" : The device class representing a "mobile"/"phone" sized client.
  /// - "DESKTOP" : The device class representing a "desktop"/"laptop" type full
  /// size client.
  /// - "TABLET" : The device class representing a "tablet" type client.
  core.String? formFactor;

  /// Origin specifies the origin that this record is for.
  ///
  /// Note: When specifying an origin, data for loads under this origin over all
  /// pages are aggregated into origin level user experience data.
  core.String? origin;

  /// Url specifies a specific url that this record is for.
  ///
  /// Note: When specifying a "url" only data for that specific url will be
  /// aggregated.
  core.String? url;

  Key();

  Key.fromJson(core.Map _json) {
    if (_json.containsKey('effectiveConnectionType')) {
      effectiveConnectionType = _json['effectiveConnectionType'] as core.String;
    }
    if (_json.containsKey('formFactor')) {
      formFactor = _json['formFactor'] as core.String;
    }
    if (_json.containsKey('origin')) {
      origin = _json['origin'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (effectiveConnectionType != null)
          'effectiveConnectionType': effectiveConnectionType!,
        if (formFactor != null) 'formFactor': formFactor!,
        if (origin != null) 'origin': origin!,
        if (url != null) 'url': url!,
      };
}

/// A `metric` is a set of user experience data for a single web performance
/// metric, like "first contentful paint".
///
/// It contains a summary histogram of real world Chrome usage as a series of
/// `bins`.
class Metric {
  /// The histogram of user experiences for a metric.
  ///
  /// The histogram will have at least one bin and the densities of all bins
  /// will add up to ~1.
  core.List<Bin>? histogram;

  /// Common useful percentiles of the Metric.
  ///
  /// The value type for the percentiles will be the same as the value types
  /// given for the Histogram bins.
  Percentiles? percentiles;

  Metric();

  Metric.fromJson(core.Map _json) {
    if (_json.containsKey('histogram')) {
      histogram = (_json['histogram'] as core.List)
          .map<Bin>((value) =>
              Bin.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('percentiles')) {
      percentiles = Percentiles.fromJson(
          _json['percentiles'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (histogram != null)
          'histogram': histogram!.map((value) => value.toJson()).toList(),
        if (percentiles != null) 'percentiles': percentiles!.toJson(),
      };
}

/// Percentiles contains synthetic values of a metric at a given statistical
/// percentile.
///
/// These are used for estimating a metric's value as experienced by a
/// percentage of users out of the total number of users.
class Percentiles {
  /// 75% of users experienced the given metric at or below this value.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? p75;

  Percentiles();

  Percentiles.fromJson(core.Map _json) {
    if (_json.containsKey('p75')) {
      p75 = _json['p75'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (p75 != null) 'p75': p75!,
      };
}

/// Request payload sent by a physical web client.
///
/// This request includes all necessary context to load a particular user
/// experience record.
class QueryRequest {
  /// The effective connection type is a query dimension that specifies the
  /// effective network class that the record's data should belong to.
  ///
  /// This field uses the values \["offline", "slow-2G", "2G", "3G", "4G"\] as
  /// specified in: https://wicg.github.io/netinfo/#effective-connection-types
  /// Note: If no effective connection type is specified, then a special record
  /// with aggregated data over all effective connection types will be returned.
  core.String? effectiveConnectionType;

  /// The form factor is a query dimension that specifies the device class that
  /// the record's data should belong to.
  ///
  /// Note: If no form factor is specified, then a special record with
  /// aggregated data over all form factors will be returned.
  /// Possible string values are:
  /// - "ALL_FORM_FACTORS" : The default value, representing all device classes.
  /// - "PHONE" : The device class representing a "mobile"/"phone" sized client.
  /// - "DESKTOP" : The device class representing a "desktop"/"laptop" type full
  /// size client.
  /// - "TABLET" : The device class representing a "tablet" type client.
  core.String? formFactor;

  /// The metrics that should be included in the response.
  ///
  /// If none are specified then any metrics found will be returned. Allowed
  /// values: \["first_contentful_paint", "first_input_delay",
  /// "largest_contentful_paint", "cumulative_layout_shift"\]
  core.List<core.String>? metrics;

  /// The url pattern "origin" refers to a url pattern that is the origin of a
  /// website.
  ///
  /// Examples: "https://example.com", "https://cloud.google.com"
  core.String? origin;

  /// The url pattern "url" refers to a url pattern that is any arbitrary url.
  ///
  /// Examples: "https://example.com/",
  /// "https://cloud.google.com/why-google-cloud/"
  core.String? url;

  QueryRequest();

  QueryRequest.fromJson(core.Map _json) {
    if (_json.containsKey('effectiveConnectionType')) {
      effectiveConnectionType = _json['effectiveConnectionType'] as core.String;
    }
    if (_json.containsKey('formFactor')) {
      formFactor = _json['formFactor'] as core.String;
    }
    if (_json.containsKey('metrics')) {
      metrics = (_json['metrics'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('origin')) {
      origin = _json['origin'] as core.String;
    }
    if (_json.containsKey('url')) {
      url = _json['url'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (effectiveConnectionType != null)
          'effectiveConnectionType': effectiveConnectionType!,
        if (formFactor != null) 'formFactor': formFactor!,
        if (metrics != null) 'metrics': metrics!,
        if (origin != null) 'origin': origin!,
        if (url != null) 'url': url!,
      };
}

/// Response payload sent back to a physical web client.
///
/// This response contains the record found based on the identiers present in a
/// `QueryRequest`. The returned response will have a record, and sometimes
/// details on normalization actions taken on the request that were necessary to
/// make the request successful.
class QueryResponse {
  /// The record that was found.
  Record? record;

  /// These are details about automated normalization actions that were taken in
  /// order to make the requested `url_pattern` valid.
  UrlNormalization? urlNormalizationDetails;

  QueryResponse();

  QueryResponse.fromJson(core.Map _json) {
    if (_json.containsKey('record')) {
      record = Record.fromJson(
          _json['record'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('urlNormalizationDetails')) {
      urlNormalizationDetails = UrlNormalization.fromJson(
          _json['urlNormalizationDetails']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (record != null) 'record': record!.toJson(),
        if (urlNormalizationDetails != null)
          'urlNormalizationDetails': urlNormalizationDetails!.toJson(),
      };
}

/// Record is a single Chrome UX report data record.
///
/// It contains use experience statistics for a single url pattern and set of
/// dimensions.
class Record {
  /// Key defines all of the unique querying parameters needed to look up a user
  /// experience record.
  Key? key;

  /// Metrics is the map of user experience data available for the record
  /// defined in the key field.
  ///
  /// Metrics are keyed on the metric name. Allowed key values:
  /// \["first_contentful_paint", "first_input_delay",
  /// "largest_contentful_paint", "cumulative_layout_shift"\]
  core.Map<core.String, Metric>? metrics;

  Record();

  Record.fromJson(core.Map _json) {
    if (_json.containsKey('key')) {
      key = Key.fromJson(_json['key'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metrics')) {
      metrics = (_json['metrics'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          Metric.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (key != null) 'key': key!.toJson(),
        if (metrics != null)
          'metrics':
              metrics!.map((key, item) => core.MapEntry(key, item.toJson())),
      };
}

/// Object representing the normalization actions taken to normalize a url to
/// achieve a higher chance of successful lookup.
///
/// These are simple automated changes that are taken when looking up the
/// provided `url_patten` would be known to fail. Complex actions like following
/// redirects are not handled.
class UrlNormalization {
  /// The URL after any normalization actions.
  ///
  /// This is a valid user experience URL that could reasonably be looked up.
  core.String? normalizedUrl;

  /// The original requested URL prior to any normalization actions.
  core.String? originalUrl;

  UrlNormalization();

  UrlNormalization.fromJson(core.Map _json) {
    if (_json.containsKey('normalizedUrl')) {
      normalizedUrl = _json['normalizedUrl'] as core.String;
    }
    if (_json.containsKey('originalUrl')) {
      originalUrl = _json['originalUrl'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (normalizedUrl != null) 'normalizedUrl': normalizedUrl!,
        if (originalUrl != null) 'originalUrl': originalUrl!,
      };
}
