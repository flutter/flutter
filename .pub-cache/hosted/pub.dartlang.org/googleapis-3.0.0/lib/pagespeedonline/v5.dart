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

/// PageSpeed Insights API - v5
///
/// The PageSpeed Insights API lets you analyze the performance of your website
/// with a simple API. It offers tailored suggestions for how you can optimize
/// your site, and lets you easily integrate PageSpeed Insights analysis into
/// your development tools and workflow.
///
/// For more information, see
/// <https://developers.google.com/speed/docs/insights/v5/about>
///
/// Create an instance of [PagespeedInsightsApi] to access these resources:
///
/// - [PagespeedapiResource]
library pagespeedonline.v5;

import 'dart:async' as async;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// The PageSpeed Insights API lets you analyze the performance of your website
/// with a simple API.
///
/// It offers tailored suggestions for how you can optimize your site, and lets
/// you easily integrate PageSpeed Insights analysis into your development tools
/// and workflow.
class PagespeedInsightsApi {
  /// Associate you with your personal info on Google
  static const openidScope = 'openid';

  final commons.ApiRequester _requester;

  PagespeedapiResource get pagespeedapi => PagespeedapiResource(_requester);

  PagespeedInsightsApi(http.Client client,
      {core.String rootUrl = 'https://pagespeedonline.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class PagespeedapiResource {
  final commons.ApiRequester _requester;

  PagespeedapiResource(commons.ApiRequester client) : _requester = client;

  /// Runs PageSpeed analysis on the page at the specified URL, and returns
  /// PageSpeed scores, a list of suggestions to make that page faster, and
  /// other information.
  ///
  /// Request parameters:
  ///
  /// [url] - Required. The URL to fetch and analyze
  /// Value must have pattern `(?i)(url:|origin:)?http(s)?://.*`.
  ///
  /// [captchaToken] - The captcha token passed when filling out a captcha.
  ///
  /// [category] - A Lighthouse category to run; if none are given, only
  /// Performance category will be run
  ///
  /// [locale] - The locale used to localize formatted results
  /// Value must have pattern `\[a-zA-Z\]+((_|-)\[a-zA-Z\]+)?`.
  ///
  /// [strategy] - The analysis strategy (desktop or mobile) to use, and desktop
  /// is the default
  /// Possible string values are:
  /// - "STRATEGY_UNSPECIFIED" : UNDEFINED.
  /// - "DESKTOP" : Fetch and analyze the URL for desktop browsers.
  /// - "MOBILE" : Fetch and analyze the URL for mobile devices.
  ///
  /// [utmCampaign] - Campaign name for analytics.
  ///
  /// [utmSource] - Campaign source for analytics.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [PagespeedApiPagespeedResponseV5].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<PagespeedApiPagespeedResponseV5> runpagespeed(
    core.String url, {
    core.String? captchaToken,
    core.List<core.String>? category,
    core.String? locale,
    core.String? strategy,
    core.String? utmCampaign,
    core.String? utmSource,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      'url': [url],
      if (captchaToken != null) 'captchaToken': [captchaToken],
      if (category != null) 'category': category,
      if (locale != null) 'locale': [locale],
      if (strategy != null) 'strategy': [strategy],
      if (utmCampaign != null) 'utm_campaign': [utmCampaign],
      if (utmSource != null) 'utm_source': [utmSource],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'pagespeedonline/v5/runPagespeed';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return PagespeedApiPagespeedResponseV5.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// A light reference to an audit by id, used to group and weight audits in a
/// given category.
class AuditRefs {
  /// The category group that the audit belongs to (optional).
  core.String? group;

  /// The audit ref id.
  core.String? id;

  /// The weight this audit's score has on the overall category score.
  core.double? weight;

  AuditRefs();

  AuditRefs.fromJson(core.Map _json) {
    if (_json.containsKey('group')) {
      group = _json['group'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('weight')) {
      weight = (_json['weight'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (group != null) 'group': group!,
        if (id != null) 'id': id!,
        if (weight != null) 'weight': weight!,
      };
}

/// A proportion of data in the total distribution, bucketed by a min/max
/// percentage.
///
/// Each bucket's range is bounded by min <= x < max, In millisecond.
class Bucket {
  /// Upper bound for a bucket's range.
  core.int? max;

  /// Lower bound for a bucket's range.
  core.int? min;

  /// The proportion of data in this bucket.
  core.double? proportion;

  Bucket();

  Bucket.fromJson(core.Map _json) {
    if (_json.containsKey('max')) {
      max = _json['max'] as core.int;
    }
    if (_json.containsKey('min')) {
      min = _json['min'] as core.int;
    }
    if (_json.containsKey('proportion')) {
      proportion = (_json['proportion'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (max != null) 'max': max!,
        if (min != null) 'min': min!,
        if (proportion != null) 'proportion': proportion!,
      };
}

/// The categories in a Lighthouse run.
class Categories {
  /// The accessibility category, containing all accessibility related audits.
  LighthouseCategoryV5? accessibility;

  /// The best practices category, containing all best practices related audits.
  LighthouseCategoryV5? bestPractices;

  /// The performance category, containing all performance related audits.
  LighthouseCategoryV5? performance;

  /// The Progressive-Web-App (PWA) category, containing all pwa related audits.
  LighthouseCategoryV5? pwa;

  /// The Search-Engine-Optimization (SEO) category, containing all seo related
  /// audits.
  LighthouseCategoryV5? seo;

  Categories();

  Categories.fromJson(core.Map _json) {
    if (_json.containsKey('accessibility')) {
      accessibility = LighthouseCategoryV5.fromJson(
          _json['accessibility'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('best-practices')) {
      bestPractices = LighthouseCategoryV5.fromJson(
          _json['best-practices'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('performance')) {
      performance = LighthouseCategoryV5.fromJson(
          _json['performance'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('pwa')) {
      pwa = LighthouseCategoryV5.fromJson(
          _json['pwa'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('seo')) {
      seo = LighthouseCategoryV5.fromJson(
          _json['seo'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessibility != null) 'accessibility': accessibility!.toJson(),
        if (bestPractices != null) 'best-practices': bestPractices!.toJson(),
        if (performance != null) 'performance': performance!.toJson(),
        if (pwa != null) 'pwa': pwa!.toJson(),
        if (seo != null) 'seo': seo!.toJson(),
      };
}

/// Message containing a category
class CategoryGroupV5 {
  /// The description of what the category is grouping
  core.String? description;

  /// The human readable title of the group
  core.String? title;

  CategoryGroupV5();

  CategoryGroupV5.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (title != null) 'title': title!,
      };
}

/// Message containing the configuration settings for the Lighthouse run.
class ConfigSettings {
  /// How Lighthouse was run, e.g. from the Chrome extension or from the npm
  /// module.
  core.String? channel;

  /// The form factor the emulation should use.
  ///
  /// This field is deprecated, form_factor should be used instead.
  core.String? emulatedFormFactor;

  /// How Lighthouse should interpret this run in regards to scoring performance
  /// metrics and skipping mobile-only tests in desktop.
  core.String? formFactor;

  /// The locale setting.
  core.String? locale;

  /// List of categories of audits the run should conduct.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? onlyCategories;

  ConfigSettings();

  ConfigSettings.fromJson(core.Map _json) {
    if (_json.containsKey('channel')) {
      channel = _json['channel'] as core.String;
    }
    if (_json.containsKey('emulatedFormFactor')) {
      emulatedFormFactor = _json['emulatedFormFactor'] as core.String;
    }
    if (_json.containsKey('formFactor')) {
      formFactor = _json['formFactor'] as core.String;
    }
    if (_json.containsKey('locale')) {
      locale = _json['locale'] as core.String;
    }
    if (_json.containsKey('onlyCategories')) {
      onlyCategories = _json['onlyCategories'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (channel != null) 'channel': channel!,
        if (emulatedFormFactor != null)
          'emulatedFormFactor': emulatedFormFactor!,
        if (formFactor != null) 'formFactor': formFactor!,
        if (locale != null) 'locale': locale!,
        if (onlyCategories != null) 'onlyCategories': onlyCategories!,
      };
}

/// Message containing environment configuration for a Lighthouse run.
class Environment {
  /// The benchmark index number that indicates rough device class.
  core.double? benchmarkIndex;

  /// The user agent string of the version of Chrome used.
  core.String? hostUserAgent;

  /// The user agent string that was sent over the network.
  core.String? networkUserAgent;

  Environment();

  Environment.fromJson(core.Map _json) {
    if (_json.containsKey('benchmarkIndex')) {
      benchmarkIndex = (_json['benchmarkIndex'] as core.num).toDouble();
    }
    if (_json.containsKey('hostUserAgent')) {
      hostUserAgent = _json['hostUserAgent'] as core.String;
    }
    if (_json.containsKey('networkUserAgent')) {
      networkUserAgent = _json['networkUserAgent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (benchmarkIndex != null) 'benchmarkIndex': benchmarkIndex!,
        if (hostUserAgent != null) 'hostUserAgent': hostUserAgent!,
        if (networkUserAgent != null) 'networkUserAgent': networkUserAgent!,
      };
}

/// Message containing the i18n data for the LHR - Version 1.
class I18n {
  /// Internationalized strings that are formatted to the locale in
  /// configSettings.
  RendererFormattedStrings? rendererFormattedStrings;

  I18n();

  I18n.fromJson(core.Map _json) {
    if (_json.containsKey('rendererFormattedStrings')) {
      rendererFormattedStrings = RendererFormattedStrings.fromJson(
          _json['rendererFormattedStrings']
              as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rendererFormattedStrings != null)
          'rendererFormattedStrings': rendererFormattedStrings!.toJson(),
      };
}

/// An audit's result object in a Lighthouse result.
class LighthouseAuditResultV5 {
  /// The description of the audit.
  core.String? description;

  /// Freeform details section of the audit.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? details;

  /// The value that should be displayed on the UI for this audit.
  core.String? displayValue;

  /// An error message from a thrown error inside the audit.
  core.String? errorMessage;

  /// An explanation of the errors in the audit.
  core.String? explanation;

  /// The audit's id.
  core.String? id;

  /// A numeric value that has a meaning specific to the audit, e.g. the number
  /// of nodes in the DOM or the timestamp of a specific load event.
  ///
  /// More information can be found in the audit details, if present.
  core.double? numericValue;

  /// The score of the audit, can be null.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? score;

  /// The enumerated score display mode.
  core.String? scoreDisplayMode;

  /// The human readable title.
  core.String? title;

  /// Possible warnings that occurred in the audit, can be null.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? warnings;

  LighthouseAuditResultV5();

  LighthouseAuditResultV5.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('details')) {
      details = (_json['details'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('displayValue')) {
      displayValue = _json['displayValue'] as core.String;
    }
    if (_json.containsKey('errorMessage')) {
      errorMessage = _json['errorMessage'] as core.String;
    }
    if (_json.containsKey('explanation')) {
      explanation = _json['explanation'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('numericValue')) {
      numericValue = (_json['numericValue'] as core.num).toDouble();
    }
    if (_json.containsKey('score')) {
      score = _json['score'] as core.Object;
    }
    if (_json.containsKey('scoreDisplayMode')) {
      scoreDisplayMode = _json['scoreDisplayMode'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
    if (_json.containsKey('warnings')) {
      warnings = _json['warnings'] as core.Object;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (details != null) 'details': details!,
        if (displayValue != null) 'displayValue': displayValue!,
        if (errorMessage != null) 'errorMessage': errorMessage!,
        if (explanation != null) 'explanation': explanation!,
        if (id != null) 'id': id!,
        if (numericValue != null) 'numericValue': numericValue!,
        if (score != null) 'score': score!,
        if (scoreDisplayMode != null) 'scoreDisplayMode': scoreDisplayMode!,
        if (title != null) 'title': title!,
        if (warnings != null) 'warnings': warnings!,
      };
}

/// A Lighthouse category.
class LighthouseCategoryV5 {
  /// An array of references to all the audit members of this category.
  core.List<AuditRefs>? auditRefs;

  /// A more detailed description of the category and its importance.
  core.String? description;

  /// The string identifier of the category.
  core.String? id;

  /// A description for the manual audits in the category.
  core.String? manualDescription;

  /// The overall score of the category, the weighted average of all its audits.
  ///
  /// (The category's score, can be null.)
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Object? score;

  /// The human-friendly name of the category.
  core.String? title;

  LighthouseCategoryV5();

  LighthouseCategoryV5.fromJson(core.Map _json) {
    if (_json.containsKey('auditRefs')) {
      auditRefs = (_json['auditRefs'] as core.List)
          .map<AuditRefs>((value) =>
              AuditRefs.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('manualDescription')) {
      manualDescription = _json['manualDescription'] as core.String;
    }
    if (_json.containsKey('score')) {
      score = _json['score'] as core.Object;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auditRefs != null)
          'auditRefs': auditRefs!.map((value) => value.toJson()).toList(),
        if (description != null) 'description': description!,
        if (id != null) 'id': id!,
        if (manualDescription != null) 'manualDescription': manualDescription!,
        if (score != null) 'score': score!,
        if (title != null) 'title': title!,
      };
}

/// The Lighthouse result object.
class LighthouseResultV5 {
  /// Map of audits in the LHR.
  core.Map<core.String, LighthouseAuditResultV5>? audits;

  /// Map of categories in the LHR.
  Categories? categories;

  /// Map of category groups in the LHR.
  core.Map<core.String, CategoryGroupV5>? categoryGroups;

  /// The configuration settings for this LHR.
  ConfigSettings? configSettings;

  /// Environment settings that were used when making this LHR.
  Environment? environment;

  /// The time that this run was fetched.
  core.String? fetchTime;

  /// The final resolved url that was audited.
  core.String? finalUrl;

  /// The internationalization strings that are required to render the LHR.
  I18n? i18n;

  /// The lighthouse version that was used to generate this LHR.
  core.String? lighthouseVersion;

  /// The original requested url.
  core.String? requestedUrl;

  /// List of all run warnings in the LHR.
  ///
  /// Will always output to at least `[]`.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Object>? runWarnings;

  /// A top-level error message that, if present, indicates a serious enough
  /// problem that this Lighthouse result may need to be discarded.
  RuntimeError? runtimeError;

  /// The Stack Pack advice strings.
  core.List<StackPack>? stackPacks;

  /// Timing information for this LHR.
  Timing? timing;

  /// The user agent that was used to run this LHR.
  core.String? userAgent;

  LighthouseResultV5();

  LighthouseResultV5.fromJson(core.Map _json) {
    if (_json.containsKey('audits')) {
      audits = (_json['audits'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          LighthouseAuditResultV5.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('categories')) {
      categories = Categories.fromJson(
          _json['categories'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('categoryGroups')) {
      categoryGroups =
          (_json['categoryGroups'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          CategoryGroupV5.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('configSettings')) {
      configSettings = ConfigSettings.fromJson(
          _json['configSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('environment')) {
      environment = Environment.fromJson(
          _json['environment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('fetchTime')) {
      fetchTime = _json['fetchTime'] as core.String;
    }
    if (_json.containsKey('finalUrl')) {
      finalUrl = _json['finalUrl'] as core.String;
    }
    if (_json.containsKey('i18n')) {
      i18n =
          I18n.fromJson(_json['i18n'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lighthouseVersion')) {
      lighthouseVersion = _json['lighthouseVersion'] as core.String;
    }
    if (_json.containsKey('requestedUrl')) {
      requestedUrl = _json['requestedUrl'] as core.String;
    }
    if (_json.containsKey('runWarnings')) {
      runWarnings = (_json['runWarnings'] as core.List)
          .map<core.Object>((value) => value as core.Object)
          .toList();
    }
    if (_json.containsKey('runtimeError')) {
      runtimeError = RuntimeError.fromJson(
          _json['runtimeError'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('stackPacks')) {
      stackPacks = (_json['stackPacks'] as core.List)
          .map<StackPack>((value) =>
              StackPack.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('timing')) {
      timing = Timing.fromJson(
          _json['timing'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('userAgent')) {
      userAgent = _json['userAgent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audits != null)
          'audits':
              audits!.map((key, item) => core.MapEntry(key, item.toJson())),
        if (categories != null) 'categories': categories!.toJson(),
        if (categoryGroups != null)
          'categoryGroups': categoryGroups!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (configSettings != null) 'configSettings': configSettings!.toJson(),
        if (environment != null) 'environment': environment!.toJson(),
        if (fetchTime != null) 'fetchTime': fetchTime!,
        if (finalUrl != null) 'finalUrl': finalUrl!,
        if (i18n != null) 'i18n': i18n!.toJson(),
        if (lighthouseVersion != null) 'lighthouseVersion': lighthouseVersion!,
        if (requestedUrl != null) 'requestedUrl': requestedUrl!,
        if (runWarnings != null) 'runWarnings': runWarnings!,
        if (runtimeError != null) 'runtimeError': runtimeError!.toJson(),
        if (stackPacks != null)
          'stackPacks': stackPacks!.map((value) => value.toJson()).toList(),
        if (timing != null) 'timing': timing!.toJson(),
        if (userAgent != null) 'userAgent': userAgent!,
      };
}

/// The CrUX loading experience object that contains CrUX data breakdowns.
class PagespeedApiLoadingExperienceV5 {
  /// The url, pattern or origin which the metrics are on.
  core.String? id;

  /// The requested URL, which may differ from the resolved "id".
  core.String? initialUrl;

  /// The map of .
  core.Map<core.String, UserPageLoadMetricV5>? metrics;

  /// True if the result is an origin fallback from a page, false otherwise.
  core.bool? originFallback;

  /// The human readable speed "category" of the id.
  core.String? overallCategory;

  PagespeedApiLoadingExperienceV5();

  PagespeedApiLoadingExperienceV5.fromJson(core.Map _json) {
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('initial_url')) {
      initialUrl = _json['initial_url'] as core.String;
    }
    if (_json.containsKey('metrics')) {
      metrics = (_json['metrics'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          UserPageLoadMetricV5.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('origin_fallback')) {
      originFallback = _json['origin_fallback'] as core.bool;
    }
    if (_json.containsKey('overall_category')) {
      overallCategory = _json['overall_category'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (id != null) 'id': id!,
        if (initialUrl != null) 'initial_url': initialUrl!,
        if (metrics != null)
          'metrics':
              metrics!.map((key, item) => core.MapEntry(key, item.toJson())),
        if (originFallback != null) 'origin_fallback': originFallback!,
        if (overallCategory != null) 'overall_category': overallCategory!,
      };
}

/// The Pagespeed API response object.
class PagespeedApiPagespeedResponseV5 {
  /// The UTC timestamp of this analysis.
  core.String? analysisUTCTimestamp;

  /// The captcha verify result
  core.String? captchaResult;

  /// Canonicalized and final URL for the document, after following page
  /// redirects (if any).
  core.String? id;

  /// Kind of result.
  core.String? kind;

  /// Lighthouse response for the audit url as an object.
  LighthouseResultV5? lighthouseResult;

  /// Metrics of end users' page loading experience.
  PagespeedApiLoadingExperienceV5? loadingExperience;

  /// Metrics of the aggregated page loading experience of the origin
  PagespeedApiLoadingExperienceV5? originLoadingExperience;

  /// The version of PageSpeed used to generate these results.
  PagespeedVersion? version;

  PagespeedApiPagespeedResponseV5();

  PagespeedApiPagespeedResponseV5.fromJson(core.Map _json) {
    if (_json.containsKey('analysisUTCTimestamp')) {
      analysisUTCTimestamp = _json['analysisUTCTimestamp'] as core.String;
    }
    if (_json.containsKey('captchaResult')) {
      captchaResult = _json['captchaResult'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('kind')) {
      kind = _json['kind'] as core.String;
    }
    if (_json.containsKey('lighthouseResult')) {
      lighthouseResult = LighthouseResultV5.fromJson(
          _json['lighthouseResult'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('loadingExperience')) {
      loadingExperience = PagespeedApiLoadingExperienceV5.fromJson(
          _json['loadingExperience'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('originLoadingExperience')) {
      originLoadingExperience = PagespeedApiLoadingExperienceV5.fromJson(
          _json['originLoadingExperience']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('version')) {
      version = PagespeedVersion.fromJson(
          _json['version'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (analysisUTCTimestamp != null)
          'analysisUTCTimestamp': analysisUTCTimestamp!,
        if (captchaResult != null) 'captchaResult': captchaResult!,
        if (id != null) 'id': id!,
        if (kind != null) 'kind': kind!,
        if (lighthouseResult != null)
          'lighthouseResult': lighthouseResult!.toJson(),
        if (loadingExperience != null)
          'loadingExperience': loadingExperience!.toJson(),
        if (originLoadingExperience != null)
          'originLoadingExperience': originLoadingExperience!.toJson(),
        if (version != null) 'version': version!.toJson(),
      };
}

/// The Pagespeed Version object.
class PagespeedVersion {
  /// The major version number of PageSpeed used to generate these results.
  core.String? major;

  /// The minor version number of PageSpeed used to generate these results.
  core.String? minor;

  PagespeedVersion();

  PagespeedVersion.fromJson(core.Map _json) {
    if (_json.containsKey('major')) {
      major = _json['major'] as core.String;
    }
    if (_json.containsKey('minor')) {
      minor = _json['minor'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (major != null) 'major': major!,
        if (minor != null) 'minor': minor!,
      };
}

/// Message holding the formatted strings used in the renderer.
class RendererFormattedStrings {
  /// The tooltip text on an expandable chevron icon.
  core.String? auditGroupExpandTooltip;

  /// The label for the initial request in a critical request chain.
  core.String? crcInitialNavigation;

  /// The label for values shown in the summary of critical request chains.
  core.String? crcLongestDurationLabel;

  /// The label shown next to an audit or metric that has had an error.
  core.String? errorLabel;

  /// The error string shown next to an erroring audit.
  core.String? errorMissingAuditInfo;

  /// The title of the lab data performance category.
  core.String? labDataTitle;

  /// The disclaimer shown under performance explaning that the network can
  /// vary.
  core.String? lsPerformanceCategoryDescription;

  /// The heading shown above a list of audits that were not computerd in the
  /// run.
  core.String? manualAuditsGroupTitle;

  /// The heading shown above a list of audits that do not apply to a page.
  core.String? notApplicableAuditsGroupTitle;

  /// The heading for the estimated page load savings opportunity of an audit.
  core.String? opportunityResourceColumnLabel;

  /// The heading for the estimated page load savings of opportunity audits.
  core.String? opportunitySavingsColumnLabel;

  /// The heading that is shown above a list of audits that are passing.
  core.String? passedAuditsGroupTitle;

  /// The label that explains the score gauges scale (0-49, 50-89, 90-100).
  core.String? scorescaleLabel;

  /// The label shown preceding important warnings that may have invalidated an
  /// entire report.
  core.String? toplevelWarningsMessage;

  /// The disclaimer shown below a performance metric value.
  core.String? varianceDisclaimer;

  /// The label shown above a bulleted list of warnings.
  core.String? warningHeader;

  RendererFormattedStrings();

  RendererFormattedStrings.fromJson(core.Map _json) {
    if (_json.containsKey('auditGroupExpandTooltip')) {
      auditGroupExpandTooltip = _json['auditGroupExpandTooltip'] as core.String;
    }
    if (_json.containsKey('crcInitialNavigation')) {
      crcInitialNavigation = _json['crcInitialNavigation'] as core.String;
    }
    if (_json.containsKey('crcLongestDurationLabel')) {
      crcLongestDurationLabel = _json['crcLongestDurationLabel'] as core.String;
    }
    if (_json.containsKey('errorLabel')) {
      errorLabel = _json['errorLabel'] as core.String;
    }
    if (_json.containsKey('errorMissingAuditInfo')) {
      errorMissingAuditInfo = _json['errorMissingAuditInfo'] as core.String;
    }
    if (_json.containsKey('labDataTitle')) {
      labDataTitle = _json['labDataTitle'] as core.String;
    }
    if (_json.containsKey('lsPerformanceCategoryDescription')) {
      lsPerformanceCategoryDescription =
          _json['lsPerformanceCategoryDescription'] as core.String;
    }
    if (_json.containsKey('manualAuditsGroupTitle')) {
      manualAuditsGroupTitle = _json['manualAuditsGroupTitle'] as core.String;
    }
    if (_json.containsKey('notApplicableAuditsGroupTitle')) {
      notApplicableAuditsGroupTitle =
          _json['notApplicableAuditsGroupTitle'] as core.String;
    }
    if (_json.containsKey('opportunityResourceColumnLabel')) {
      opportunityResourceColumnLabel =
          _json['opportunityResourceColumnLabel'] as core.String;
    }
    if (_json.containsKey('opportunitySavingsColumnLabel')) {
      opportunitySavingsColumnLabel =
          _json['opportunitySavingsColumnLabel'] as core.String;
    }
    if (_json.containsKey('passedAuditsGroupTitle')) {
      passedAuditsGroupTitle = _json['passedAuditsGroupTitle'] as core.String;
    }
    if (_json.containsKey('scorescaleLabel')) {
      scorescaleLabel = _json['scorescaleLabel'] as core.String;
    }
    if (_json.containsKey('toplevelWarningsMessage')) {
      toplevelWarningsMessage = _json['toplevelWarningsMessage'] as core.String;
    }
    if (_json.containsKey('varianceDisclaimer')) {
      varianceDisclaimer = _json['varianceDisclaimer'] as core.String;
    }
    if (_json.containsKey('warningHeader')) {
      warningHeader = _json['warningHeader'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auditGroupExpandTooltip != null)
          'auditGroupExpandTooltip': auditGroupExpandTooltip!,
        if (crcInitialNavigation != null)
          'crcInitialNavigation': crcInitialNavigation!,
        if (crcLongestDurationLabel != null)
          'crcLongestDurationLabel': crcLongestDurationLabel!,
        if (errorLabel != null) 'errorLabel': errorLabel!,
        if (errorMissingAuditInfo != null)
          'errorMissingAuditInfo': errorMissingAuditInfo!,
        if (labDataTitle != null) 'labDataTitle': labDataTitle!,
        if (lsPerformanceCategoryDescription != null)
          'lsPerformanceCategoryDescription': lsPerformanceCategoryDescription!,
        if (manualAuditsGroupTitle != null)
          'manualAuditsGroupTitle': manualAuditsGroupTitle!,
        if (notApplicableAuditsGroupTitle != null)
          'notApplicableAuditsGroupTitle': notApplicableAuditsGroupTitle!,
        if (opportunityResourceColumnLabel != null)
          'opportunityResourceColumnLabel': opportunityResourceColumnLabel!,
        if (opportunitySavingsColumnLabel != null)
          'opportunitySavingsColumnLabel': opportunitySavingsColumnLabel!,
        if (passedAuditsGroupTitle != null)
          'passedAuditsGroupTitle': passedAuditsGroupTitle!,
        if (scorescaleLabel != null) 'scorescaleLabel': scorescaleLabel!,
        if (toplevelWarningsMessage != null)
          'toplevelWarningsMessage': toplevelWarningsMessage!,
        if (varianceDisclaimer != null)
          'varianceDisclaimer': varianceDisclaimer!,
        if (warningHeader != null) 'warningHeader': warningHeader!,
      };
}

/// Message containing a runtime error config.
class RuntimeError {
  /// The enumerated Lighthouse Error code.
  core.String? code;

  /// A human readable message explaining the error code.
  core.String? message;

  RuntimeError();

  RuntimeError.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (message != null) 'message': message!,
      };
}

/// Message containing Stack Pack information.
class StackPack {
  /// The stack pack advice strings.
  core.Map<core.String, core.String>? descriptions;

  /// The stack pack icon data uri.
  core.String? iconDataURL;

  /// The stack pack id.
  core.String? id;

  /// The stack pack title.
  core.String? title;

  StackPack();

  StackPack.fromJson(core.Map _json) {
    if (_json.containsKey('descriptions')) {
      descriptions =
          (_json['descriptions'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('iconDataURL')) {
      iconDataURL = _json['iconDataURL'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('title')) {
      title = _json['title'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (descriptions != null) 'descriptions': descriptions!,
        if (iconDataURL != null) 'iconDataURL': iconDataURL!,
        if (id != null) 'id': id!,
        if (title != null) 'title': title!,
      };
}

/// Message containing the performance timing data for the Lighthouse run.
class Timing {
  /// The total duration of Lighthouse's run.
  core.double? total;

  Timing();

  Timing.fromJson(core.Map _json) {
    if (_json.containsKey('total')) {
      total = (_json['total'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (total != null) 'total': total!,
      };
}

/// A CrUX metric object for a single metric and form factor.
class UserPageLoadMetricV5 {
  /// The category of the specific time metric.
  core.String? category;

  /// Metric distributions.
  ///
  /// Proportions should sum up to 1.
  core.List<Bucket>? distributions;

  /// Identifies the form factor of the metric being collected.
  core.String? formFactor;

  /// The median number of the metric, in millisecond.
  core.int? median;

  /// Identifies the type of the metric.
  core.String? metricId;

  /// We use this field to store certain percentile value for this metric.
  ///
  /// For v4, this field contains pc50. For v5, this field contains pc90.
  core.int? percentile;

  UserPageLoadMetricV5();

  UserPageLoadMetricV5.fromJson(core.Map _json) {
    if (_json.containsKey('category')) {
      category = _json['category'] as core.String;
    }
    if (_json.containsKey('distributions')) {
      distributions = (_json['distributions'] as core.List)
          .map<Bucket>((value) =>
              Bucket.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('formFactor')) {
      formFactor = _json['formFactor'] as core.String;
    }
    if (_json.containsKey('median')) {
      median = _json['median'] as core.int;
    }
    if (_json.containsKey('metricId')) {
      metricId = _json['metricId'] as core.String;
    }
    if (_json.containsKey('percentile')) {
      percentile = _json['percentile'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (category != null) 'category': category!,
        if (distributions != null)
          'distributions':
              distributions!.map((value) => value.toJson()).toList(),
        if (formFactor != null) 'formFactor': formFactor!,
        if (median != null) 'median': median!,
        if (metricId != null) 'metricId': metricId!,
        if (percentile != null) 'percentile': percentile!,
      };
}
