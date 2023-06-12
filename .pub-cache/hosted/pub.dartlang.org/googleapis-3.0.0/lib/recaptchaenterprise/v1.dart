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

/// reCAPTCHA Enterprise API - v1
///
/// For more information, see <https://cloud.google.com/recaptcha-enterprise/>
///
/// Create an instance of [RecaptchaEnterpriseApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsAssessmentsResource]
///   - [ProjectsKeysResource]
library recaptchaenterprise.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

class RecaptchaEnterpriseApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  RecaptchaEnterpriseApi(http.Client client,
      {core.String rootUrl = 'https://recaptchaenterprise.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsAssessmentsResource get assessments =>
      ProjectsAssessmentsResource(_requester);
  ProjectsKeysResource get keys => ProjectsKeysResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsAssessmentsResource {
  final commons.ApiRequester _requester;

  ProjectsAssessmentsResource(commons.ApiRequester client)
      : _requester = client;

  /// Annotates a previously created Assessment to provide additional
  /// information on whether the event turned out to be authentic or fraudulent.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the Assessment, in the format
  /// "projects/{project}/assessments/{assessment}".
  /// Value must have pattern `^projects/\[^/\]+/assessments/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a
  /// [GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse>
      annotate(
    GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':annotate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Creates an Assessment of the likelihood an event is legitimate.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the project in which the assessment will
  /// be created, in the format "projects/{project}".
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudRecaptchaenterpriseV1Assessment].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRecaptchaenterpriseV1Assessment> create(
    GoogleCloudRecaptchaenterpriseV1Assessment request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/assessments';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudRecaptchaenterpriseV1Assessment.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsKeysResource {
  final commons.ApiRequester _requester;

  ProjectsKeysResource(commons.ApiRequester client) : _requester = client;

  /// Creates a new reCAPTCHA Enterprise key.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the project in which the key will be
  /// created, in the format "projects/{project}".
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudRecaptchaenterpriseV1Key].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRecaptchaenterpriseV1Key> create(
    GoogleCloudRecaptchaenterpriseV1Key request,
    core.String parent, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/keys';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudRecaptchaenterpriseV1Key.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes the specified key.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the key to be deleted, in the format
  /// "projects/{project}/keys/{key}".
  /// Value must have pattern `^projects/\[^/\]+/keys/\[^/\]+$`.
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

    final _url = 'v1/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the specified key.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the requested key, in the format
  /// "projects/{project}/keys/{key}".
  /// Value must have pattern `^projects/\[^/\]+/keys/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudRecaptchaenterpriseV1Key].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRecaptchaenterpriseV1Key> get(
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
    return GoogleCloudRecaptchaenterpriseV1Key.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Get some aggregated metrics for a Key.
  ///
  /// This data can be used to build dashboards.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the requested metrics, in the format
  /// "projects/{project}/keys/{key}/metrics".
  /// Value must have pattern `^projects/\[^/\]+/keys/\[^/\]+/metrics$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudRecaptchaenterpriseV1Metrics].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRecaptchaenterpriseV1Metrics> getMetrics(
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
    return GoogleCloudRecaptchaenterpriseV1Metrics.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Returns the list of all keys that belong to a project.
  ///
  /// Request parameters:
  ///
  /// [parent] - Required. The name of the project that contains the keys that
  /// will be listed, in the format "projects/{project}".
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [pageSize] - Optional. The maximum number of keys to return. Default is
  /// 10. Max limit is 1000.
  ///
  /// [pageToken] - Optional. The next_page_token value returned from a
  /// previous. ListKeysRequest, if any.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudRecaptchaenterpriseV1ListKeysResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRecaptchaenterpriseV1ListKeysResponse> list(
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

    final _url = 'v1/' + core.Uri.encodeFull('$parent') + '/keys';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleCloudRecaptchaenterpriseV1ListKeysResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Migrates an existing key from reCAPTCHA to reCAPTCHA Enterprise.
  ///
  /// Once a key is migrated, it can be used from either product. SiteVerify
  /// requests are billed as CreateAssessment calls. You must be authenticated
  /// as one of the current owners of the reCAPTCHA Site Key, and your user must
  /// have the reCAPTCHA Enterprise Admin IAM role in the destination project.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the key to be migrated, in the format
  /// "projects/{project}/keys/{key}".
  /// Value must have pattern `^projects/\[^/\]+/keys/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudRecaptchaenterpriseV1Key].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRecaptchaenterpriseV1Key> migrate(
    GoogleCloudRecaptchaenterpriseV1MigrateKeyRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':migrate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleCloudRecaptchaenterpriseV1Key.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Updates the specified key.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The resource name for the Key in the format
  /// "projects/{project}/keys/{key}".
  /// Value must have pattern `^projects/\[^/\]+/keys/\[^/\]+$`.
  ///
  /// [updateMask] - Optional. The mask to control which fields of the key get
  /// updated. If the mask is not present, all fields will be updated.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleCloudRecaptchaenterpriseV1Key].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleCloudRecaptchaenterpriseV1Key> patch(
    GoogleCloudRecaptchaenterpriseV1Key request,
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
    return GoogleCloudRecaptchaenterpriseV1Key.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Settings specific to keys that can be used by Android apps.
class GoogleCloudRecaptchaenterpriseV1AndroidKeySettings {
  /// Android package names of apps allowed to use the key.
  ///
  /// Example: 'com.companyname.appname'
  core.List<core.String>? allowedPackageNames;

  GoogleCloudRecaptchaenterpriseV1AndroidKeySettings();

  GoogleCloudRecaptchaenterpriseV1AndroidKeySettings.fromJson(core.Map _json) {
    if (_json.containsKey('allowedPackageNames')) {
      allowedPackageNames = (_json['allowedPackageNames'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedPackageNames != null)
          'allowedPackageNames': allowedPackageNames!,
      };
}

/// The request message to annotate an Assessment.
class GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest {
  /// The annotation that will be assigned to the Event.
  ///
  /// This field can be left empty to provide reasons that apply to an event
  /// without concluding whether the event is legitimate or fraudulent.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "ANNOTATION_UNSPECIFIED" : Default unspecified type.
  /// - "LEGITIMATE" : Provides information that the event turned out to be
  /// legitimate.
  /// - "FRAUDULENT" : Provides information that the event turned out to be
  /// fraudulent.
  /// - "PASSWORD_CORRECT" : Provides information that the event was related to
  /// a login event in which the user typed the correct password. Deprecated,
  /// prefer indicating CORRECT_PASSWORD through the reasons field instead.
  /// - "PASSWORD_INCORRECT" : Provides information that the event was related
  /// to a login event in which the user typed the incorrect password.
  /// Deprecated, prefer indicating INCORRECT_PASSWORD through the reasons field
  /// instead.
  core.String? annotation;

  /// Optional reasons for the annotation that will be assigned to the Event.
  ///
  /// Optional.
  core.List<core.String>? reasons;

  GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest();

  GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentRequest.fromJson(
      core.Map _json) {
    if (_json.containsKey('annotation')) {
      annotation = _json['annotation'] as core.String;
    }
    if (_json.containsKey('reasons')) {
      reasons = (_json['reasons'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotation != null) 'annotation': annotation!,
        if (reasons != null) 'reasons': reasons!,
      };
}

/// Empty response for AnnotateAssessment.
class GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse {
  GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse();

  GoogleCloudRecaptchaenterpriseV1AnnotateAssessmentResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A recaptcha assessment resource.
class GoogleCloudRecaptchaenterpriseV1Assessment {
  /// The event being assessed.
  GoogleCloudRecaptchaenterpriseV1Event? event;

  /// The resource name for the Assessment in the format
  /// "projects/{project}/assessments/{assessment}".
  ///
  /// Output only.
  core.String? name;

  /// The risk analysis result for the event being assessed.
  ///
  /// Output only.
  GoogleCloudRecaptchaenterpriseV1RiskAnalysis? riskAnalysis;

  /// Properties of the provided event token.
  ///
  /// Output only.
  GoogleCloudRecaptchaenterpriseV1TokenProperties? tokenProperties;

  GoogleCloudRecaptchaenterpriseV1Assessment();

  GoogleCloudRecaptchaenterpriseV1Assessment.fromJson(core.Map _json) {
    if (_json.containsKey('event')) {
      event = GoogleCloudRecaptchaenterpriseV1Event.fromJson(
          _json['event'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('riskAnalysis')) {
      riskAnalysis = GoogleCloudRecaptchaenterpriseV1RiskAnalysis.fromJson(
          _json['riskAnalysis'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('tokenProperties')) {
      tokenProperties =
          GoogleCloudRecaptchaenterpriseV1TokenProperties.fromJson(
              _json['tokenProperties'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (event != null) 'event': event!.toJson(),
        if (name != null) 'name': name!,
        if (riskAnalysis != null) 'riskAnalysis': riskAnalysis!.toJson(),
        if (tokenProperties != null)
          'tokenProperties': tokenProperties!.toJson(),
      };
}

/// Metrics related to challenges.
class GoogleCloudRecaptchaenterpriseV1ChallengeMetrics {
  /// Count of submitted challenge solutions that were incorrect or otherwise
  /// deemed suspicious such that a subsequent challenge was triggered.
  core.String? failedCount;

  /// Count of nocaptchas (successful verification without a challenge) issued.
  core.String? nocaptchaCount;

  /// Count of reCAPTCHA checkboxes or badges rendered.
  ///
  /// This is mostly equivalent to a count of pageloads for pages that include
  /// reCAPTCHA.
  core.String? pageloadCount;

  /// Count of nocaptchas (successful verification without a challenge) plus
  /// submitted challenge solutions that were correct and resulted in
  /// verification.
  core.String? passedCount;

  GoogleCloudRecaptchaenterpriseV1ChallengeMetrics();

  GoogleCloudRecaptchaenterpriseV1ChallengeMetrics.fromJson(core.Map _json) {
    if (_json.containsKey('failedCount')) {
      failedCount = _json['failedCount'] as core.String;
    }
    if (_json.containsKey('nocaptchaCount')) {
      nocaptchaCount = _json['nocaptchaCount'] as core.String;
    }
    if (_json.containsKey('pageloadCount')) {
      pageloadCount = _json['pageloadCount'] as core.String;
    }
    if (_json.containsKey('passedCount')) {
      passedCount = _json['passedCount'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (failedCount != null) 'failedCount': failedCount!,
        if (nocaptchaCount != null) 'nocaptchaCount': nocaptchaCount!,
        if (pageloadCount != null) 'pageloadCount': pageloadCount!,
        if (passedCount != null) 'passedCount': passedCount!,
      };
}

class GoogleCloudRecaptchaenterpriseV1Event {
  /// The expected action for this type of event.
  ///
  /// This should be the same action provided at token generation time on
  /// client-side platforms already integrated with recaptcha enterprise.
  ///
  /// Optional.
  core.String? expectedAction;

  /// The site key that was used to invoke reCAPTCHA on your site and generate
  /// the token.
  ///
  /// Optional.
  core.String? siteKey;

  /// The user response token provided by the reCAPTCHA client-side integration
  /// on your site.
  ///
  /// Optional.
  core.String? token;

  /// The user agent present in the request from the user's device related to
  /// this event.
  ///
  /// Optional.
  core.String? userAgent;

  /// The IP address in the request from the user's device related to this
  /// event.
  ///
  /// Optional.
  core.String? userIpAddress;

  GoogleCloudRecaptchaenterpriseV1Event();

  GoogleCloudRecaptchaenterpriseV1Event.fromJson(core.Map _json) {
    if (_json.containsKey('expectedAction')) {
      expectedAction = _json['expectedAction'] as core.String;
    }
    if (_json.containsKey('siteKey')) {
      siteKey = _json['siteKey'] as core.String;
    }
    if (_json.containsKey('token')) {
      token = _json['token'] as core.String;
    }
    if (_json.containsKey('userAgent')) {
      userAgent = _json['userAgent'] as core.String;
    }
    if (_json.containsKey('userIpAddress')) {
      userIpAddress = _json['userIpAddress'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (expectedAction != null) 'expectedAction': expectedAction!,
        if (siteKey != null) 'siteKey': siteKey!,
        if (token != null) 'token': token!,
        if (userAgent != null) 'userAgent': userAgent!,
        if (userIpAddress != null) 'userIpAddress': userIpAddress!,
      };
}

/// Settings specific to keys that can be used by iOS apps.
class GoogleCloudRecaptchaenterpriseV1IOSKeySettings {
  /// iOS bundle ids of apps allowed to use the key.
  ///
  /// Example: 'com.companyname.productname.appname'
  core.List<core.String>? allowedBundleIds;

  GoogleCloudRecaptchaenterpriseV1IOSKeySettings();

  GoogleCloudRecaptchaenterpriseV1IOSKeySettings.fromJson(core.Map _json) {
    if (_json.containsKey('allowedBundleIds')) {
      allowedBundleIds = (_json['allowedBundleIds'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowedBundleIds != null) 'allowedBundleIds': allowedBundleIds!,
      };
}

/// A key used to identify and configure applications (web and/or mobile) that
/// use reCAPTCHA Enterprise.
class GoogleCloudRecaptchaenterpriseV1Key {
  /// Settings for keys that can be used by Android apps.
  GoogleCloudRecaptchaenterpriseV1AndroidKeySettings? androidSettings;

  /// The timestamp corresponding to the creation of this Key.
  core.String? createTime;

  /// Human-readable display name of this key.
  ///
  /// Modifiable by user.
  core.String? displayName;

  /// Settings for keys that can be used by iOS apps.
  GoogleCloudRecaptchaenterpriseV1IOSKeySettings? iosSettings;

  /// See Creating and managing labels.
  core.Map<core.String, core.String>? labels;

  /// The resource name for the Key in the format
  /// "projects/{project}/keys/{key}".
  core.String? name;

  /// Options for user acceptance testing.
  GoogleCloudRecaptchaenterpriseV1TestingOptions? testingOptions;

  /// Settings for keys that can be used by websites.
  GoogleCloudRecaptchaenterpriseV1WebKeySettings? webSettings;

  GoogleCloudRecaptchaenterpriseV1Key();

  GoogleCloudRecaptchaenterpriseV1Key.fromJson(core.Map _json) {
    if (_json.containsKey('androidSettings')) {
      androidSettings =
          GoogleCloudRecaptchaenterpriseV1AndroidKeySettings.fromJson(
              _json['androidSettings'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('iosSettings')) {
      iosSettings = GoogleCloudRecaptchaenterpriseV1IOSKeySettings.fromJson(
          _json['iosSettings'] as core.Map<core.String, core.dynamic>);
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
    if (_json.containsKey('testingOptions')) {
      testingOptions = GoogleCloudRecaptchaenterpriseV1TestingOptions.fromJson(
          _json['testingOptions'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('webSettings')) {
      webSettings = GoogleCloudRecaptchaenterpriseV1WebKeySettings.fromJson(
          _json['webSettings'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (androidSettings != null)
          'androidSettings': androidSettings!.toJson(),
        if (createTime != null) 'createTime': createTime!,
        if (displayName != null) 'displayName': displayName!,
        if (iosSettings != null) 'iosSettings': iosSettings!.toJson(),
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (testingOptions != null) 'testingOptions': testingOptions!.toJson(),
        if (webSettings != null) 'webSettings': webSettings!.toJson(),
      };
}

/// Response to request to list keys in a project.
class GoogleCloudRecaptchaenterpriseV1ListKeysResponse {
  /// Key details.
  core.List<GoogleCloudRecaptchaenterpriseV1Key>? keys;

  /// Token to retrieve the next page of results.
  ///
  /// It is set to empty if no keys remain in results.
  core.String? nextPageToken;

  GoogleCloudRecaptchaenterpriseV1ListKeysResponse();

  GoogleCloudRecaptchaenterpriseV1ListKeysResponse.fromJson(core.Map _json) {
    if (_json.containsKey('keys')) {
      keys = (_json['keys'] as core.List)
          .map<GoogleCloudRecaptchaenterpriseV1Key>((value) =>
              GoogleCloudRecaptchaenterpriseV1Key.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (keys != null) 'keys': keys!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Metrics for a single Key.
class GoogleCloudRecaptchaenterpriseV1Metrics {
  /// Metrics will be continuous and in order by dates, and in the granularity
  /// of day.
  ///
  /// Only challenge-based keys (CHECKBOX, INVISIBLE), will have challenge-based
  /// data.
  core.List<GoogleCloudRecaptchaenterpriseV1ChallengeMetrics>? challengeMetrics;

  /// Metrics will be continuous and in order by dates, and in the granularity
  /// of day.
  ///
  /// All Key types should have score-based data.
  core.List<GoogleCloudRecaptchaenterpriseV1ScoreMetrics>? scoreMetrics;

  /// Inclusive start time aligned to a day (UTC).
  core.String? startTime;

  GoogleCloudRecaptchaenterpriseV1Metrics();

  GoogleCloudRecaptchaenterpriseV1Metrics.fromJson(core.Map _json) {
    if (_json.containsKey('challengeMetrics')) {
      challengeMetrics = (_json['challengeMetrics'] as core.List)
          .map<GoogleCloudRecaptchaenterpriseV1ChallengeMetrics>((value) =>
              GoogleCloudRecaptchaenterpriseV1ChallengeMetrics.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('scoreMetrics')) {
      scoreMetrics = (_json['scoreMetrics'] as core.List)
          .map<GoogleCloudRecaptchaenterpriseV1ScoreMetrics>((value) =>
              GoogleCloudRecaptchaenterpriseV1ScoreMetrics.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (challengeMetrics != null)
          'challengeMetrics':
              challengeMetrics!.map((value) => value.toJson()).toList(),
        if (scoreMetrics != null)
          'scoreMetrics': scoreMetrics!.map((value) => value.toJson()).toList(),
        if (startTime != null) 'startTime': startTime!,
      };
}

/// The migrate key request message.
class GoogleCloudRecaptchaenterpriseV1MigrateKeyRequest {
  GoogleCloudRecaptchaenterpriseV1MigrateKeyRequest();

  GoogleCloudRecaptchaenterpriseV1MigrateKeyRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// Risk analysis result for an event.
class GoogleCloudRecaptchaenterpriseV1RiskAnalysis {
  /// Reasons contributing to the risk analysis verdict.
  core.List<core.String>? reasons;

  /// Legitimate event score from 0.0 to 1.0.
  ///
  /// (1.0 means very likely legitimate traffic while 0.0 means very likely
  /// non-legitimate traffic).
  core.double? score;

  GoogleCloudRecaptchaenterpriseV1RiskAnalysis();

  GoogleCloudRecaptchaenterpriseV1RiskAnalysis.fromJson(core.Map _json) {
    if (_json.containsKey('reasons')) {
      reasons = (_json['reasons'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('score')) {
      score = (_json['score'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (reasons != null) 'reasons': reasons!,
        if (score != null) 'score': score!,
      };
}

/// Score distribution.
class GoogleCloudRecaptchaenterpriseV1ScoreDistribution {
  /// Map key is score value multiplied by 100.
  ///
  /// The scores are discrete values between \[0, 1\]. The maximum number of
  /// buckets is on order of a few dozen, but typically much lower (ie. 10).
  core.Map<core.String, core.String>? scoreBuckets;

  GoogleCloudRecaptchaenterpriseV1ScoreDistribution();

  GoogleCloudRecaptchaenterpriseV1ScoreDistribution.fromJson(core.Map _json) {
    if (_json.containsKey('scoreBuckets')) {
      scoreBuckets =
          (_json['scoreBuckets'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (scoreBuckets != null) 'scoreBuckets': scoreBuckets!,
      };
}

/// Metrics related to scoring.
class GoogleCloudRecaptchaenterpriseV1ScoreMetrics {
  /// Action-based metrics.
  ///
  /// The map key is the action name which specified by the site owners at time
  /// of the "execute" client-side call. Populated only for SCORE keys.
  core.Map<core.String, GoogleCloudRecaptchaenterpriseV1ScoreDistribution>?
      actionMetrics;

  /// Aggregated score metrics for all traffic.
  GoogleCloudRecaptchaenterpriseV1ScoreDistribution? overallMetrics;

  GoogleCloudRecaptchaenterpriseV1ScoreMetrics();

  GoogleCloudRecaptchaenterpriseV1ScoreMetrics.fromJson(core.Map _json) {
    if (_json.containsKey('actionMetrics')) {
      actionMetrics =
          (_json['actionMetrics'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          GoogleCloudRecaptchaenterpriseV1ScoreDistribution.fromJson(
              item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('overallMetrics')) {
      overallMetrics =
          GoogleCloudRecaptchaenterpriseV1ScoreDistribution.fromJson(
              _json['overallMetrics'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (actionMetrics != null)
          'actionMetrics': actionMetrics!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (overallMetrics != null) 'overallMetrics': overallMetrics!.toJson(),
      };
}

/// Options for user acceptance testing.
class GoogleCloudRecaptchaenterpriseV1TestingOptions {
  /// For challenge-based keys only (CHECKBOX, INVISIBLE), all challenge
  /// requests for this site will return nocaptcha if NOCAPTCHA, or an
  /// unsolvable challenge if CHALLENGE.
  /// Possible string values are:
  /// - "TESTING_CHALLENGE_UNSPECIFIED" : Perform the normal risk analysis and
  /// return either nocaptcha or a challenge depending on risk and trust
  /// factors.
  /// - "NOCAPTCHA" : Challenge requests for this key will always return a
  /// nocaptcha, which does not require a solution.
  /// - "CHALLENGE" : Challenge requests for this key will always return an
  /// unsolvable challenge.
  core.String? testingChallenge;

  /// All assessments for this Key will return this score.
  ///
  /// Must be between 0 (likely not legitimate) and 1 (likely legitimate)
  /// inclusive.
  core.double? testingScore;

  GoogleCloudRecaptchaenterpriseV1TestingOptions();

  GoogleCloudRecaptchaenterpriseV1TestingOptions.fromJson(core.Map _json) {
    if (_json.containsKey('testingChallenge')) {
      testingChallenge = _json['testingChallenge'] as core.String;
    }
    if (_json.containsKey('testingScore')) {
      testingScore = (_json['testingScore'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (testingChallenge != null) 'testingChallenge': testingChallenge!,
        if (testingScore != null) 'testingScore': testingScore!,
      };
}

class GoogleCloudRecaptchaenterpriseV1TokenProperties {
  /// Action name provided at token generation.
  core.String? action;

  /// The timestamp corresponding to the generation of the token.
  core.String? createTime;

  /// The hostname of the page on which the token was generated.
  core.String? hostname;

  /// Reason associated with the response when valid = false.
  /// Possible string values are:
  /// - "INVALID_REASON_UNSPECIFIED" : Default unspecified type.
  /// - "UNKNOWN_INVALID_REASON" : If the failure reason was not accounted for.
  /// - "MALFORMED" : The provided user verification token was malformed.
  /// - "EXPIRED" : The user verification token had expired.
  /// - "DUPE" : The user verification had already been seen.
  /// - "MISSING" : The user verification token was not present.
  /// - "BROWSER_ERROR" : A retriable error (such as network failure) occurred
  /// on the browser. Could easily be simulated by an attacker.
  core.String? invalidReason;

  /// Whether the provided user response token is valid.
  ///
  /// When valid = false, the reason could be specified in invalid_reason or it
  /// could also be due to a user failing to solve a challenge or a sitekey
  /// mismatch (i.e the sitekey used to generate the token was different than
  /// the one specified in the assessment).
  core.bool? valid;

  GoogleCloudRecaptchaenterpriseV1TokenProperties();

  GoogleCloudRecaptchaenterpriseV1TokenProperties.fromJson(core.Map _json) {
    if (_json.containsKey('action')) {
      action = _json['action'] as core.String;
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('hostname')) {
      hostname = _json['hostname'] as core.String;
    }
    if (_json.containsKey('invalidReason')) {
      invalidReason = _json['invalidReason'] as core.String;
    }
    if (_json.containsKey('valid')) {
      valid = _json['valid'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (action != null) 'action': action!,
        if (createTime != null) 'createTime': createTime!,
        if (hostname != null) 'hostname': hostname!,
        if (invalidReason != null) 'invalidReason': invalidReason!,
        if (valid != null) 'valid': valid!,
      };
}

/// Settings specific to keys that can be used by websites.
class GoogleCloudRecaptchaenterpriseV1WebKeySettings {
  /// If set to true, it means allowed_domains will not be enforced.
  core.bool? allowAllDomains;

  /// Whether this key can be used on AMP (Accelerated Mobile Pages) websites.
  ///
  /// This can only be set for the SCORE integration type.
  ///
  /// Required.
  core.bool? allowAmpTraffic;

  /// Domains or subdomains of websites allowed to use the key.
  ///
  /// All subdomains of an allowed domain are automatically allowed. A valid
  /// domain requires a host and must not include any path, port, query or
  /// fragment. Examples: 'example.com' or 'subdomain.example.com'
  core.List<core.String>? allowedDomains;

  /// Settings for the frequency and difficulty at which this key triggers
  /// captcha challenges.
  ///
  /// This should only be specified for IntegrationTypes CHECKBOX and INVISIBLE.
  /// Possible string values are:
  /// - "CHALLENGE_SECURITY_PREFERENCE_UNSPECIFIED" : Default type that
  /// indicates this enum hasn't been specified.
  /// - "USABILITY" : Key tends to show fewer and easier challenges.
  /// - "BALANCE" : Key tends to show balanced (in amount and difficulty)
  /// challenges.
  /// - "SECURITY" : Key tends to show more and harder challenges.
  core.String? challengeSecurityPreference;

  /// Describes how this key is integrated with the website.
  ///
  /// Required.
  /// Possible string values are:
  /// - "INTEGRATION_TYPE_UNSPECIFIED" : Default type that indicates this enum
  /// hasn't been specified. This is not a valid IntegrationType, one of the
  /// other types must be specified instead.
  /// - "SCORE" : Only used to produce scores. It doesn't display the "I'm not a
  /// robot" checkbox and never shows captcha challenges.
  /// - "CHECKBOX" : Displays the "I'm not a robot" checkbox and may show
  /// captcha challenges after it is checked.
  /// - "INVISIBLE" : Doesn't display the "I'm not a robot" checkbox, but may
  /// show captcha challenges after risk analysis.
  core.String? integrationType;

  GoogleCloudRecaptchaenterpriseV1WebKeySettings();

  GoogleCloudRecaptchaenterpriseV1WebKeySettings.fromJson(core.Map _json) {
    if (_json.containsKey('allowAllDomains')) {
      allowAllDomains = _json['allowAllDomains'] as core.bool;
    }
    if (_json.containsKey('allowAmpTraffic')) {
      allowAmpTraffic = _json['allowAmpTraffic'] as core.bool;
    }
    if (_json.containsKey('allowedDomains')) {
      allowedDomains = (_json['allowedDomains'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('challengeSecurityPreference')) {
      challengeSecurityPreference =
          _json['challengeSecurityPreference'] as core.String;
    }
    if (_json.containsKey('integrationType')) {
      integrationType = _json['integrationType'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowAllDomains != null) 'allowAllDomains': allowAllDomains!,
        if (allowAmpTraffic != null) 'allowAmpTraffic': allowAmpTraffic!,
        if (allowedDomains != null) 'allowedDomains': allowedDomains!,
        if (challengeSecurityPreference != null)
          'challengeSecurityPreference': challengeSecurityPreference!,
        if (integrationType != null) 'integrationType': integrationType!,
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
