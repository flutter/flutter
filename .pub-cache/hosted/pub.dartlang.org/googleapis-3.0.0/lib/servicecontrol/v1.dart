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

/// Service Control API - v1
///
/// Provides admission control and telemetry reporting for services integrated
/// with Service Infrastructure.
///
/// For more information, see <https://cloud.google.com/service-control/>
///
/// Create an instance of [ServiceControlApi] to access these resources:
///
/// - [ServicesResource]
library servicecontrol.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Provides admission control and telemetry reporting for services integrated
/// with Service Infrastructure.
class ServiceControlApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// Manage your Google Service Control data
  static const servicecontrolScope =
      'https://www.googleapis.com/auth/servicecontrol';

  final commons.ApiRequester _requester;

  ServicesResource get services => ServicesResource(_requester);

  ServiceControlApi(http.Client client,
      {core.String rootUrl = 'https://servicecontrol.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ServicesResource {
  final commons.ApiRequester _requester;

  ServicesResource(commons.ApiRequester client) : _requester = client;

  /// Attempts to allocate quota for the specified consumer.
  ///
  /// It should be called before the operation is executed. This method requires
  /// the `servicemanagement.services.quota` permission on the specified
  /// service. For more information, see
  /// [Cloud IAM](https://cloud.google.com/iam). **NOTE:** The client **must**
  /// fail-open on server errors `INTERNAL`, `UNKNOWN`, `DEADLINE_EXCEEDED`, and
  /// `UNAVAILABLE`. To ensure system reliability, the server may inject these
  /// errors to prohibit any hard dependency on the quota functionality.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [serviceName] - Name of the service as specified in the service
  /// configuration. For example, `"pubsub.googleapis.com"`. See
  /// google.api.Service for the definition of a service name.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [AllocateQuotaResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<AllocateQuotaResponse> allocateQuota(
    AllocateQuotaRequest request,
    core.String serviceName, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/services/' +
        commons.escapeVariable('$serviceName') +
        ':allocateQuota';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return AllocateQuotaResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Checks whether an operation on a service should be allowed to proceed
  /// based on the configuration of the service and related policies.
  ///
  /// It must be called before the operation is executed. If feasible, the
  /// client should cache the check results and reuse them for 60 seconds. In
  /// case of any server errors, the client should rely on the cached results
  /// for much longer time to avoid outage. WARNING: There is general 60s delay
  /// for the configuration and policy propagation, therefore callers MUST NOT
  /// depend on the `Check` method having the latest policy information. NOTE:
  /// the CheckRequest has the size limit (wire-format byte size) of 1MB. This
  /// method requires the `servicemanagement.services.check` permission on the
  /// specified service. For more information, see
  /// [Cloud IAM](https://cloud.google.com/iam).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [serviceName] - The service name as specified in its service
  /// configuration. For example, `"pubsub.googleapis.com"`. See
  /// [google.api.Service](https://cloud.google.com/service-management/reference/rpc/google.api#google.api.Service)
  /// for the definition of a service name.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [CheckResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<CheckResponse> check(
    CheckRequest request,
    core.String serviceName, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/services/' + commons.escapeVariable('$serviceName') + ':check';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CheckResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Reports operation results to Google Service Control, such as logs and
  /// metrics.
  ///
  /// It should be called after an operation is completed. If feasible, the
  /// client should aggregate reporting data for up to 5 seconds to reduce API
  /// traffic. Limiting aggregation to 5 seconds is to reduce data loss during
  /// client crashes. Clients should carefully choose the aggregation time
  /// window to avoid data loss risk more than 0.01% for business and compliance
  /// reasons. NOTE: the ReportRequest has the size limit (wire-format byte
  /// size) of 1MB. This method requires the `servicemanagement.services.report`
  /// permission on the specified service. For more information, see
  /// [Google Cloud IAM](https://cloud.google.com/iam).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [serviceName] - The service name as specified in its service
  /// configuration. For example, `"pubsub.googleapis.com"`. See
  /// [google.api.Service](https://cloud.google.com/service-management/reference/rpc/google.api#google.api.Service)
  /// for the definition of a service name.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ReportResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ReportResponse> report(
    ReportRequest request,
    core.String serviceName, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url =
        'v1/services/' + commons.escapeVariable('$serviceName') + ':report';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return ReportResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class AllocateInfo {
  /// A list of label keys that were unused by the server in processing the
  /// request.
  ///
  /// Thus, for similar requests repeated in a certain future time window, the
  /// caller can choose to ignore these labels in the requests to achieve better
  /// client-side cache hits and quota aggregation for rate quota. This field is
  /// not populated for allocation quota checks.
  core.List<core.String>? unusedArguments;

  AllocateInfo();

  AllocateInfo.fromJson(core.Map _json) {
    if (_json.containsKey('unusedArguments')) {
      unusedArguments = (_json['unusedArguments'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (unusedArguments != null) 'unusedArguments': unusedArguments!,
      };
}

/// Request message for the AllocateQuota method.
class AllocateQuotaRequest {
  /// Operation that describes the quota allocation.
  QuotaOperation? allocateOperation;

  /// Specifies which version of service configuration should be used to process
  /// the request.
  ///
  /// If unspecified or no matching version can be found, the latest one will be
  /// used.
  core.String? serviceConfigId;

  AllocateQuotaRequest();

  AllocateQuotaRequest.fromJson(core.Map _json) {
    if (_json.containsKey('allocateOperation')) {
      allocateOperation = QuotaOperation.fromJson(
          _json['allocateOperation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('serviceConfigId')) {
      serviceConfigId = _json['serviceConfigId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allocateOperation != null)
          'allocateOperation': allocateOperation!.toJson(),
        if (serviceConfigId != null) 'serviceConfigId': serviceConfigId!,
      };
}

/// Response message for the AllocateQuota method.
class AllocateQuotaResponse {
  /// Indicates the decision of the allocate.
  core.List<QuotaError>? allocateErrors;

  /// WARNING: DO NOT use this field until this warning message is removed.
  AllocateInfo? allocateInfo;

  /// The same operation_id value used in the AllocateQuotaRequest.
  ///
  /// Used for logging and diagnostics purposes.
  core.String? operationId;

  /// Quota metrics to indicate the result of allocation.
  ///
  /// Depending on the request, one or more of the following metrics will be
  /// included: 1. Per quota group or per quota metric incremental usage will be
  /// specified using the following delta metric :
  /// "serviceruntime.googleapis.com/api/consumer/quota_used_count" 2. The quota
  /// limit reached condition will be specified using the following boolean
  /// metric : "serviceruntime.googleapis.com/quota/exceeded"
  core.List<MetricValueSet>? quotaMetrics;

  /// ID of the actual config used to process the request.
  core.String? serviceConfigId;

  AllocateQuotaResponse();

  AllocateQuotaResponse.fromJson(core.Map _json) {
    if (_json.containsKey('allocateErrors')) {
      allocateErrors = (_json['allocateErrors'] as core.List)
          .map<QuotaError>((value) =>
              QuotaError.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('allocateInfo')) {
      allocateInfo = AllocateInfo.fromJson(
          _json['allocateInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('quotaMetrics')) {
      quotaMetrics = (_json['quotaMetrics'] as core.List)
          .map<MetricValueSet>((value) => MetricValueSet.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('serviceConfigId')) {
      serviceConfigId = _json['serviceConfigId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allocateErrors != null)
          'allocateErrors':
              allocateErrors!.map((value) => value.toJson()).toList(),
        if (allocateInfo != null) 'allocateInfo': allocateInfo!.toJson(),
        if (operationId != null) 'operationId': operationId!,
        if (quotaMetrics != null)
          'quotaMetrics': quotaMetrics!.map((value) => value.toJson()).toList(),
        if (serviceConfigId != null) 'serviceConfigId': serviceConfigId!,
      };
}

/// The allowed types for \[VALUE\] in a `[KEY]:[VALUE]` attribute.
class AttributeValue {
  /// A Boolean value represented by `true` or `false`.
  core.bool? boolValue;

  /// A 64-bit signed integer.
  core.String? intValue;

  /// A string up to 256 bytes long.
  TruncatableString? stringValue;

  AttributeValue();

  AttributeValue.fromJson(core.Map _json) {
    if (_json.containsKey('boolValue')) {
      boolValue = _json['boolValue'] as core.bool;
    }
    if (_json.containsKey('intValue')) {
      intValue = _json['intValue'] as core.String;
    }
    if (_json.containsKey('stringValue')) {
      stringValue = TruncatableString.fromJson(
          _json['stringValue'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (boolValue != null) 'boolValue': boolValue!,
        if (intValue != null) 'intValue': intValue!,
        if (stringValue != null) 'stringValue': stringValue!.toJson(),
      };
}

/// A set of attributes, each in the format `[KEY]:[VALUE]`.
class Attributes {
  /// The set of attributes.
  ///
  /// Each attribute's key can be up to 128 bytes long. The value can be a
  /// string up to 256 bytes, a signed 64-bit integer, or the Boolean values
  /// `true` and `false`. For example: "/instance_id": "my-instance"
  /// "/http/user_agent": "" "/http/request_bytes": 300 "abc.com/myattribute":
  /// true
  core.Map<core.String, AttributeValue>? attributeMap;

  /// The number of attributes that were discarded.
  ///
  /// Attributes can be discarded because their keys are too long or because
  /// there are too many attributes. If this value is 0 then all attributes are
  /// valid.
  core.int? droppedAttributesCount;

  Attributes();

  Attributes.fromJson(core.Map _json) {
    if (_json.containsKey('attributeMap')) {
      attributeMap =
          (_json['attributeMap'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          AttributeValue.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('droppedAttributesCount')) {
      droppedAttributesCount = _json['droppedAttributesCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributeMap != null)
          'attributeMap': attributeMap!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (droppedAttributesCount != null)
          'droppedAttributesCount': droppedAttributesCount!,
      };
}

/// Common audit log format for Google Cloud Platform API operations.
class AuditLog {
  /// Authentication information.
  AuthenticationInfo? authenticationInfo;

  /// Authorization information.
  ///
  /// If there are multiple resources or permissions involved, then there is one
  /// AuthorizationInfo element for each {resource, permission} tuple.
  core.List<AuthorizationInfo>? authorizationInfo;

  /// Other service-specific data about the request, response, and other
  /// information associated with the current audited event.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  /// The name of the service method or operation.
  ///
  /// For API calls, this should be the name of the API method. For example,
  /// "google.cloud.bigquery.v2.TableService.InsertTable"
  /// "google.logging.v2.ConfigServiceV2.CreateSink"
  core.String? methodName;

  /// The number of items returned from a List or Query API method, if
  /// applicable.
  core.String? numResponseItems;

  /// The operation request.
  ///
  /// This may not include all request parameters, such as those that are too
  /// large, privacy-sensitive, or duplicated elsewhere in the log record. It
  /// should never include user-generated data, such as file contents. When the
  /// JSON object represented here has a proto equivalent, the proto name will
  /// be indicated in the `@type` property.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? request;

  /// Metadata about the operation.
  RequestMetadata? requestMetadata;

  /// The resource location information.
  ResourceLocation? resourceLocation;

  /// The resource or collection that is the target of the operation.
  ///
  /// The name is a scheme-less URI, not including the API service name. For
  /// example: "projects/PROJECT_ID/zones/us-central1-a/instances"
  /// "projects/PROJECT_ID/datasets/DATASET_ID"
  core.String? resourceName;

  /// The resource's original state before mutation.
  ///
  /// Present only for operations which have successfully modified the targeted
  /// resource(s). In general, this field should contain all changed fields,
  /// except those that are already been included in `request`, `response`,
  /// `metadata` or `service_data` fields. When the JSON object represented here
  /// has a proto equivalent, the proto name will be indicated in the `@type`
  /// property.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? resourceOriginalState;

  /// The operation response.
  ///
  /// This may not include all response elements, such as those that are too
  /// large, privacy-sensitive, or duplicated elsewhere in the log record. It
  /// should never include user-generated data, such as file contents. When the
  /// JSON object represented here has a proto equivalent, the proto name will
  /// be indicated in the `@type` property.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? response;

  /// Use the `metadata` field instead.
  ///
  /// Other service-specific data about the request, response, and other
  /// activities.
  ///
  /// Deprecated.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? serviceData;

  /// The name of the API service performing the operation.
  ///
  /// For example, `"compute.googleapis.com"`.
  core.String? serviceName;

  /// The status of the overall operation.
  Status? status;

  AuditLog();

  AuditLog.fromJson(core.Map _json) {
    if (_json.containsKey('authenticationInfo')) {
      authenticationInfo = AuthenticationInfo.fromJson(
          _json['authenticationInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('authorizationInfo')) {
      authorizationInfo = (_json['authorizationInfo'] as core.List)
          .map<AuthorizationInfo>((value) => AuthorizationInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('methodName')) {
      methodName = _json['methodName'] as core.String;
    }
    if (_json.containsKey('numResponseItems')) {
      numResponseItems = _json['numResponseItems'] as core.String;
    }
    if (_json.containsKey('request')) {
      request = (_json['request'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('requestMetadata')) {
      requestMetadata = RequestMetadata.fromJson(
          _json['requestMetadata'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resourceLocation')) {
      resourceLocation = ResourceLocation.fromJson(
          _json['resourceLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resourceName')) {
      resourceName = _json['resourceName'] as core.String;
    }
    if (_json.containsKey('resourceOriginalState')) {
      resourceOriginalState = (_json['resourceOriginalState']
              as core.Map<core.String, core.dynamic>)
          .map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('response')) {
      response = (_json['response'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('serviceData')) {
      serviceData =
          (_json['serviceData'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('serviceName')) {
      serviceName = _json['serviceName'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = Status.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (authenticationInfo != null)
          'authenticationInfo': authenticationInfo!.toJson(),
        if (authorizationInfo != null)
          'authorizationInfo':
              authorizationInfo!.map((value) => value.toJson()).toList(),
        if (metadata != null) 'metadata': metadata!,
        if (methodName != null) 'methodName': methodName!,
        if (numResponseItems != null) 'numResponseItems': numResponseItems!,
        if (request != null) 'request': request!,
        if (requestMetadata != null)
          'requestMetadata': requestMetadata!.toJson(),
        if (resourceLocation != null)
          'resourceLocation': resourceLocation!.toJson(),
        if (resourceName != null) 'resourceName': resourceName!,
        if (resourceOriginalState != null)
          'resourceOriginalState': resourceOriginalState!,
        if (response != null) 'response': response!,
        if (serviceData != null) 'serviceData': serviceData!,
        if (serviceName != null) 'serviceName': serviceName!,
        if (status != null) 'status': status!.toJson(),
      };
}

/// This message defines request authentication attributes.
///
/// Terminology is based on the JSON Web Token (JWT) standard, but the terms
/// also correlate to concepts in other standards.
class Auth {
  /// A list of access level resource names that allow resources to be accessed
  /// by authenticated requester.
  ///
  /// It is part of Secure GCP processing for the incoming request. An access
  /// level string has the format:
  /// "//{api_service_name}/accessPolicies/{policy_id}/accessLevels/{short_name}"
  /// Example:
  /// "//accesscontextmanager.googleapis.com/accessPolicies/MY_POLICY_ID/accessLevels/MY_LEVEL"
  core.List<core.String>? accessLevels;

  /// The intended audience(s) for this authentication information.
  ///
  /// Reflects the audience (`aud`) claim within a JWT. The audience value(s)
  /// depends on the `issuer`, but typically include one or more of the
  /// following pieces of information: * The services intended to receive the
  /// credential. For example, \["https://pubsub.googleapis.com/",
  /// "https://storage.googleapis.com/"\]. * A set of service-based scopes. For
  /// example, \["https://www.googleapis.com/auth/cloud-platform"\]. * The
  /// client id of an app, such as the Firebase project id for JWTs from
  /// Firebase Auth. Consult the documentation for the credential issuer to
  /// determine the information provided.
  core.List<core.String>? audiences;

  /// Structured claims presented with the credential.
  ///
  /// JWTs include `{key: value}` pairs for standard and private claims. The
  /// following is a subset of the standard required and optional claims that
  /// would typically be presented for a Google-based JWT: {'iss':
  /// 'accounts.google.com', 'sub': '113289723416554971153', 'aud':
  /// \['123456789012', 'pubsub.googleapis.com'\], 'azp':
  /// '123456789012.apps.googleusercontent.com', 'email': 'jsmith@example.com',
  /// 'iat': 1353601026, 'exp': 1353604926} SAML assertions are similarly
  /// specified, but with an identity provider dependent structure.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? claims;

  /// The authorized presenter of the credential.
  ///
  /// Reflects the optional Authorized Presenter (`azp`) claim within a JWT or
  /// the OAuth client id. For example, a Google Cloud Platform client id looks
  /// as follows: "123456789012.apps.googleusercontent.com".
  core.String? presenter;

  /// The authenticated principal.
  ///
  /// Reflects the issuer (`iss`) and subject (`sub`) claims within a JWT. The
  /// issuer and subject should be `/` delimited, with `/` percent-encoded
  /// within the subject fragment. For Google accounts, the principal format is:
  /// "https://accounts.google.com/{id}"
  core.String? principal;

  Auth();

  Auth.fromJson(core.Map _json) {
    if (_json.containsKey('accessLevels')) {
      accessLevels = (_json['accessLevels'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('audiences')) {
      audiences = (_json['audiences'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('claims')) {
      claims = (_json['claims'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('presenter')) {
      presenter = _json['presenter'] as core.String;
    }
    if (_json.containsKey('principal')) {
      principal = _json['principal'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (accessLevels != null) 'accessLevels': accessLevels!,
        if (audiences != null) 'audiences': audiences!,
        if (claims != null) 'claims': claims!,
        if (presenter != null) 'presenter': presenter!,
        if (principal != null) 'principal': principal!,
      };
}

/// Authentication information for the operation.
class AuthenticationInfo {
  /// The authority selector specified by the requestor, if any.
  ///
  /// It is not guaranteed that the principal was allowed to use this authority.
  core.String? authoritySelector;

  /// The email address of the authenticated user (or service account on behalf
  /// of third party principal) making the request.
  ///
  /// For third party identity callers, the `principal_subject` field is
  /// populated instead of this field. For privacy reasons, the principal email
  /// address is sometimes redacted. For more information, see
  /// [Caller identities in audit logs](https://cloud.google.com/logging/docs/audit#user-id).
  core.String? principalEmail;

  /// String representation of identity of requesting party.
  ///
  /// Populated for both first and third party identities.
  core.String? principalSubject;

  /// Identity delegation history of an authenticated service account that makes
  /// the request.
  ///
  /// It contains information on the real authorities that try to access GCP
  /// resources by delegating on a service account. When multiple authorities
  /// present, they are guaranteed to be sorted based on the original ordering
  /// of the identity delegation events.
  core.List<ServiceAccountDelegationInfo>? serviceAccountDelegationInfo;

  /// The name of the service account key used to create or exchange credentials
  /// for authenticating the service account making the request.
  ///
  /// This is a scheme-less URI full resource name. For example:
  /// "//iam.googleapis.com/projects/{PROJECT_ID}/serviceAccounts/{ACCOUNT}/keys/{key}"
  core.String? serviceAccountKeyName;

  /// The third party identification (if any) of the authenticated user making
  /// the request.
  ///
  /// When the JSON object represented here has a proto equivalent, the proto
  /// name will be indicated in the `@type` property.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? thirdPartyPrincipal;

  AuthenticationInfo();

  AuthenticationInfo.fromJson(core.Map _json) {
    if (_json.containsKey('authoritySelector')) {
      authoritySelector = _json['authoritySelector'] as core.String;
    }
    if (_json.containsKey('principalEmail')) {
      principalEmail = _json['principalEmail'] as core.String;
    }
    if (_json.containsKey('principalSubject')) {
      principalSubject = _json['principalSubject'] as core.String;
    }
    if (_json.containsKey('serviceAccountDelegationInfo')) {
      serviceAccountDelegationInfo =
          (_json['serviceAccountDelegationInfo'] as core.List)
              .map<ServiceAccountDelegationInfo>((value) =>
                  ServiceAccountDelegationInfo.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('serviceAccountKeyName')) {
      serviceAccountKeyName = _json['serviceAccountKeyName'] as core.String;
    }
    if (_json.containsKey('thirdPartyPrincipal')) {
      thirdPartyPrincipal =
          (_json['thirdPartyPrincipal'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (authoritySelector != null) 'authoritySelector': authoritySelector!,
        if (principalEmail != null) 'principalEmail': principalEmail!,
        if (principalSubject != null) 'principalSubject': principalSubject!,
        if (serviceAccountDelegationInfo != null)
          'serviceAccountDelegationInfo': serviceAccountDelegationInfo!
              .map((value) => value.toJson())
              .toList(),
        if (serviceAccountKeyName != null)
          'serviceAccountKeyName': serviceAccountKeyName!,
        if (thirdPartyPrincipal != null)
          'thirdPartyPrincipal': thirdPartyPrincipal!,
      };
}

/// Authorization information for the operation.
class AuthorizationInfo {
  /// Whether or not authorization for `resource` and `permission` was granted.
  core.bool? granted;

  /// The required IAM permission.
  core.String? permission;

  /// The resource being accessed, as a REST-style or cloud resource string.
  ///
  /// For example: bigquery.googleapis.com/projects/PROJECTID/datasets/DATASETID
  /// or projects/PROJECTID/datasets/DATASETID
  core.String? resource;

  /// Resource attributes used in IAM condition evaluation.
  ///
  /// This field contains resource attributes like resource type and resource
  /// name. To get the whole view of the attributes used in IAM condition
  /// evaluation, the user must also look into
  /// `AuditLog.request_metadata.request_attributes`.
  Resource? resourceAttributes;

  AuthorizationInfo();

  AuthorizationInfo.fromJson(core.Map _json) {
    if (_json.containsKey('granted')) {
      granted = _json['granted'] as core.bool;
    }
    if (_json.containsKey('permission')) {
      permission = _json['permission'] as core.String;
    }
    if (_json.containsKey('resource')) {
      resource = _json['resource'] as core.String;
    }
    if (_json.containsKey('resourceAttributes')) {
      resourceAttributes = Resource.fromJson(
          _json['resourceAttributes'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (granted != null) 'granted': granted!,
        if (permission != null) 'permission': permission!,
        if (resource != null) 'resource': resource!,
        if (resourceAttributes != null)
          'resourceAttributes': resourceAttributes!.toJson(),
      };
}

/// Defines the errors to be returned in
/// google.api.servicecontrol.v1.CheckResponse.check_errors.
class CheckError {
  /// The error code.
  /// Possible string values are:
  /// - "ERROR_CODE_UNSPECIFIED" : This is never used in `CheckResponse`.
  /// - "NOT_FOUND" : The consumer's project id, network container, or resource
  /// container was not found. Same as google.rpc.Code.NOT_FOUND.
  /// - "PERMISSION_DENIED" : The consumer doesn't have access to the specified
  /// resource. Same as google.rpc.Code.PERMISSION_DENIED.
  /// - "RESOURCE_EXHAUSTED" : Quota check failed. Same as
  /// google.rpc.Code.RESOURCE_EXHAUSTED.
  /// - "BUDGET_EXCEEDED" : Budget check failed.
  /// - "DENIAL_OF_SERVICE_DETECTED" : The consumer's request has been flagged
  /// as a DoS attack.
  /// - "LOAD_SHEDDING" : The consumer's request should be rejected in order to
  /// protect the service from being overloaded.
  /// - "ABUSER_DETECTED" : The consumer has been flagged as an abuser.
  /// - "SERVICE_NOT_ACTIVATED" : The consumer hasn't activated the service.
  /// - "VISIBILITY_DENIED" : The consumer cannot access the service due to
  /// visibility configuration.
  /// - "BILLING_DISABLED" : The consumer cannot access the service because
  /// billing is disabled.
  /// - "PROJECT_DELETED" : The consumer's project has been marked as deleted
  /// (soft deletion).
  /// - "PROJECT_INVALID" : The consumer's project number or id does not
  /// represent a valid project.
  /// - "CONSUMER_INVALID" : The input consumer info does not represent a valid
  /// consumer folder or organization.
  /// - "IP_ADDRESS_BLOCKED" : The IP address of the consumer is invalid for the
  /// specific consumer project.
  /// - "REFERER_BLOCKED" : The referer address of the consumer request is
  /// invalid for the specific consumer project.
  /// - "CLIENT_APP_BLOCKED" : The client application of the consumer request is
  /// invalid for the specific consumer project.
  /// - "API_TARGET_BLOCKED" : The API targeted by this request is invalid for
  /// the specified consumer project.
  /// - "API_KEY_INVALID" : The consumer's API key is invalid.
  /// - "API_KEY_EXPIRED" : The consumer's API Key has expired.
  /// - "API_KEY_NOT_FOUND" : The consumer's API Key was not found in config
  /// record.
  /// - "SPATULA_HEADER_INVALID" : The consumer's spatula header is invalid.
  /// - "LOAS_ROLE_INVALID" : The consumer's LOAS role is invalid.
  /// - "NO_LOAS_PROJECT" : The consumer's LOAS role has no associated project.
  /// - "LOAS_PROJECT_DISABLED" : The consumer's LOAS project is not `ACTIVE` in
  /// LoquatV2.
  /// - "SECURITY_POLICY_VIOLATED" : Request is not allowed as per security
  /// policies defined in Org Policy.
  /// - "INVALID_CREDENTIAL" : The credential in the request can not be
  /// verified.
  /// - "LOCATION_POLICY_VIOLATED" : Request is not allowed as per location
  /// policies defined in Org Policy.
  /// - "NAMESPACE_LOOKUP_UNAVAILABLE" : The backend server for looking up
  /// project id/number is unavailable.
  /// - "SERVICE_STATUS_UNAVAILABLE" : The backend server for checking service
  /// status is unavailable.
  /// - "BILLING_STATUS_UNAVAILABLE" : The backend server for checking billing
  /// status is unavailable.
  /// - "QUOTA_CHECK_UNAVAILABLE" : The backend server for checking quota limits
  /// is unavailable.
  /// - "LOAS_PROJECT_LOOKUP_UNAVAILABLE" : The Spanner for looking up LOAS
  /// project is unavailable.
  /// - "CLOUD_RESOURCE_MANAGER_BACKEND_UNAVAILABLE" : Cloud Resource Manager
  /// backend server is unavailable.
  /// - "SECURITY_POLICY_BACKEND_UNAVAILABLE" : NOTE: for customers in the scope
  /// of Beta/GA of https://cloud.google.com/vpc-service-controls, this error is
  /// no longer returned. If the security backend is unavailable, rpc
  /// UNAVAILABLE status will be returned instead. It should be ignored and
  /// should not be used to reject client requests.
  /// - "LOCATION_POLICY_BACKEND_UNAVAILABLE" : Backend server for evaluating
  /// location policy is unavailable.
  core.String? code;

  /// Free-form text providing details on the error cause of the error.
  core.String? detail;

  /// Contains public information about the check error.
  ///
  /// If available, `status.code` will be non zero and client can propagate it
  /// out as public error.
  Status? status;

  /// Subject to whom this error applies.
  ///
  /// See the specific code enum for more details on this field. For example: -
  /// "project:" - "folder:" - "organization:"
  core.String? subject;

  CheckError();

  CheckError.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('detail')) {
      detail = _json['detail'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = Status.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subject')) {
      subject = _json['subject'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (detail != null) 'detail': detail!,
        if (status != null) 'status': status!.toJson(),
        if (subject != null) 'subject': subject!,
      };
}

/// Contains additional information about the check operation.
class CheckInfo {
  /// Consumer info of this check.
  ConsumerInfo? consumerInfo;

  /// A list of fields and label keys that are ignored by the server.
  ///
  /// The client doesn't need to send them for following requests to improve
  /// performance and allow better aggregation.
  core.List<core.String>? unusedArguments;

  CheckInfo();

  CheckInfo.fromJson(core.Map _json) {
    if (_json.containsKey('consumerInfo')) {
      consumerInfo = ConsumerInfo.fromJson(
          _json['consumerInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('unusedArguments')) {
      unusedArguments = (_json['unusedArguments'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (consumerInfo != null) 'consumerInfo': consumerInfo!.toJson(),
        if (unusedArguments != null) 'unusedArguments': unusedArguments!,
      };
}

/// Request message for the Check method.
class CheckRequest {
  /// The operation to be checked.
  Operation? operation;

  /// Requests the project settings to be returned as part of the check
  /// response.
  core.bool? requestProjectSettings;

  /// Specifies which version of service configuration should be used to process
  /// the request.
  ///
  /// If unspecified or no matching version can be found, the latest one will be
  /// used.
  core.String? serviceConfigId;

  /// Indicates if service activation check should be skipped for this request.
  ///
  /// Default behavior is to perform the check and apply relevant quota.
  /// WARNING: Setting this flag to "true" will disable quota enforcement.
  core.bool? skipActivationCheck;

  CheckRequest();

  CheckRequest.fromJson(core.Map _json) {
    if (_json.containsKey('operation')) {
      operation = Operation.fromJson(
          _json['operation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('requestProjectSettings')) {
      requestProjectSettings = _json['requestProjectSettings'] as core.bool;
    }
    if (_json.containsKey('serviceConfigId')) {
      serviceConfigId = _json['serviceConfigId'] as core.String;
    }
    if (_json.containsKey('skipActivationCheck')) {
      skipActivationCheck = _json['skipActivationCheck'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operation != null) 'operation': operation!.toJson(),
        if (requestProjectSettings != null)
          'requestProjectSettings': requestProjectSettings!,
        if (serviceConfigId != null) 'serviceConfigId': serviceConfigId!,
        if (skipActivationCheck != null)
          'skipActivationCheck': skipActivationCheck!,
      };
}

/// Response message for the Check method.
class CheckResponse {
  /// Indicate the decision of the check.
  ///
  /// If no check errors are present, the service should process the operation.
  /// Otherwise the service should use the list of errors to determine the
  /// appropriate action.
  core.List<CheckError>? checkErrors;

  /// Feedback data returned from the server during processing a Check request.
  CheckInfo? checkInfo;

  /// The same operation_id value used in the CheckRequest.
  ///
  /// Used for logging and diagnostics purposes.
  core.String? operationId;

  /// Quota information for the check request associated with this response.
  QuotaInfo? quotaInfo;

  /// The actual config id used to process the request.
  core.String? serviceConfigId;

  /// The current service rollout id used to process the request.
  core.String? serviceRolloutId;

  CheckResponse();

  CheckResponse.fromJson(core.Map _json) {
    if (_json.containsKey('checkErrors')) {
      checkErrors = (_json['checkErrors'] as core.List)
          .map<CheckError>((value) =>
              CheckError.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('checkInfo')) {
      checkInfo = CheckInfo.fromJson(
          _json['checkInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('quotaInfo')) {
      quotaInfo = QuotaInfo.fromJson(
          _json['quotaInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('serviceConfigId')) {
      serviceConfigId = _json['serviceConfigId'] as core.String;
    }
    if (_json.containsKey('serviceRolloutId')) {
      serviceRolloutId = _json['serviceRolloutId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (checkErrors != null)
          'checkErrors': checkErrors!.map((value) => value.toJson()).toList(),
        if (checkInfo != null) 'checkInfo': checkInfo!.toJson(),
        if (operationId != null) 'operationId': operationId!,
        if (quotaInfo != null) 'quotaInfo': quotaInfo!.toJson(),
        if (serviceConfigId != null) 'serviceConfigId': serviceConfigId!,
        if (serviceRolloutId != null) 'serviceRolloutId': serviceRolloutId!,
      };
}

/// `ConsumerInfo` provides information about the consumer.
class ConsumerInfo {
  /// The consumer identity number, can be Google cloud project number, folder
  /// number or organization number e.g. 1234567890.
  ///
  /// A value of 0 indicates no consumer number is found.
  core.String? consumerNumber;

  /// The Google cloud project number, e.g. 1234567890.
  ///
  /// A value of 0 indicates no project number is found. NOTE: This field is
  /// deprecated after Chemist support flexible consumer id. New code should not
  /// depend on this field anymore.
  core.String? projectNumber;

  /// The type of the consumer which should have been defined in
  /// [Google Resource Manager](https://cloud.google.com/resource-manager/).
  /// Possible string values are:
  /// - "CONSUMER_TYPE_UNSPECIFIED" : This is never used.
  /// - "PROJECT" : The consumer is a Google Cloud Project.
  /// - "FOLDER" : The consumer is a Google Cloud Folder.
  /// - "ORGANIZATION" : The consumer is a Google Cloud Organization.
  /// - "SERVICE_SPECIFIC" : Service-specific resource container which is
  /// defined by the service producer to offer their users the ability to manage
  /// service control functionalities at a finer level of granularity than the
  /// PROJECT.
  core.String? type;

  ConsumerInfo();

  ConsumerInfo.fromJson(core.Map _json) {
    if (_json.containsKey('consumerNumber')) {
      consumerNumber = _json['consumerNumber'] as core.String;
    }
    if (_json.containsKey('projectNumber')) {
      projectNumber = _json['projectNumber'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (consumerNumber != null) 'consumerNumber': consumerNumber!,
        if (projectNumber != null) 'projectNumber': projectNumber!,
        if (type != null) 'type': type!,
      };
}

/// Distribution represents a frequency distribution of double-valued sample
/// points.
///
/// It contains the size of the population of sample points plus additional
/// optional information: - the arithmetic mean of the samples - the minimum and
/// maximum of the samples - the sum-squared-deviation of the samples, used to
/// compute variance - a histogram of the values of the sample points
class Distribution {
  /// The number of samples in each histogram bucket.
  ///
  /// \`bucket_counts\` are optional. If present, they must sum to the \`count\`
  /// value. The buckets are defined below in \`bucket_option\`. There are N
  /// buckets. \`bucket_counts\[0\]\` is the number of samples in the underflow
  /// bucket. \`bucket_counts\[1\]\` to \`bucket_counts\[N-1\]\` are the numbers
  /// of samples in each of the finite buckets. And \`bucket_counts\[N\] is the
  /// number of samples in the overflow bucket. See the comments of
  /// \`bucket_option\` below for more details. Any suffix of trailing zeros may
  /// be omitted.
  core.List<core.String>? bucketCounts;

  /// The total number of samples in the distribution.
  ///
  /// Must be >= 0.
  core.String? count;

  /// Example points.
  ///
  /// Must be in increasing order of `value` field.
  core.List<Exemplar>? exemplars;

  /// Buckets with arbitrary user-provided width.
  ExplicitBuckets? explicitBuckets;

  /// Buckets with exponentially growing width.
  ExponentialBuckets? exponentialBuckets;

  /// Buckets with constant width.
  LinearBuckets? linearBuckets;

  /// The maximum of the population of values.
  ///
  /// Ignored if `count` is zero.
  core.double? maximum;

  /// The arithmetic mean of the samples in the distribution.
  ///
  /// If `count` is zero then this field must be zero.
  core.double? mean;

  /// The minimum of the population of values.
  ///
  /// Ignored if `count` is zero.
  core.double? minimum;

  /// The sum of squared deviations from the mean: Sum\[i=1..count\]((x_i -
  /// mean)^2) where each x_i is a sample values.
  ///
  /// If `count` is zero then this field must be zero, otherwise validation of
  /// the request fails.
  core.double? sumOfSquaredDeviation;

  Distribution();

  Distribution.fromJson(core.Map _json) {
    if (_json.containsKey('bucketCounts')) {
      bucketCounts = (_json['bucketCounts'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('count')) {
      count = _json['count'] as core.String;
    }
    if (_json.containsKey('exemplars')) {
      exemplars = (_json['exemplars'] as core.List)
          .map<Exemplar>((value) =>
              Exemplar.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('explicitBuckets')) {
      explicitBuckets = ExplicitBuckets.fromJson(
          _json['explicitBuckets'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('exponentialBuckets')) {
      exponentialBuckets = ExponentialBuckets.fromJson(
          _json['exponentialBuckets'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('linearBuckets')) {
      linearBuckets = LinearBuckets.fromJson(
          _json['linearBuckets'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('maximum')) {
      maximum = (_json['maximum'] as core.num).toDouble();
    }
    if (_json.containsKey('mean')) {
      mean = (_json['mean'] as core.num).toDouble();
    }
    if (_json.containsKey('minimum')) {
      minimum = (_json['minimum'] as core.num).toDouble();
    }
    if (_json.containsKey('sumOfSquaredDeviation')) {
      sumOfSquaredDeviation =
          (_json['sumOfSquaredDeviation'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bucketCounts != null) 'bucketCounts': bucketCounts!,
        if (count != null) 'count': count!,
        if (exemplars != null)
          'exemplars': exemplars!.map((value) => value.toJson()).toList(),
        if (explicitBuckets != null)
          'explicitBuckets': explicitBuckets!.toJson(),
        if (exponentialBuckets != null)
          'exponentialBuckets': exponentialBuckets!.toJson(),
        if (linearBuckets != null) 'linearBuckets': linearBuckets!.toJson(),
        if (maximum != null) 'maximum': maximum!,
        if (mean != null) 'mean': mean!,
        if (minimum != null) 'minimum': minimum!,
        if (sumOfSquaredDeviation != null)
          'sumOfSquaredDeviation': sumOfSquaredDeviation!,
      };
}

/// Exemplars are example points that may be used to annotate aggregated
/// distribution values.
///
/// They are metadata that gives information about a particular value added to a
/// Distribution bucket, such as a trace ID that was active when a value was
/// added. They may contain further information, such as a example values and
/// timestamps, origin, etc.
class Exemplar {
  /// Contextual information about the example value.
  ///
  /// Examples are: Trace: type.googleapis.com/google.monitoring.v3.SpanContext
  /// Literal string: type.googleapis.com/google.protobuf.StringValue Labels
  /// dropped during aggregation:
  /// type.googleapis.com/google.monitoring.v3.DroppedLabels There may be only a
  /// single attachment of any given message type in a single exemplar, and this
  /// is enforced by the system.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Map<core.String, core.Object>>? attachments;

  /// The observation (sampling) time of the above value.
  core.String? timestamp;

  /// Value of the exemplar point.
  ///
  /// This value determines to which bucket the exemplar belongs.
  core.double? value;

  Exemplar();

  Exemplar.fromJson(core.Map _json) {
    if (_json.containsKey('attachments')) {
      attachments = (_json['attachments'] as core.List)
          .map<core.Map<core.String, core.Object>>(
              (value) => (value as core.Map<core.String, core.dynamic>).map(
                    (key, item) => core.MapEntry(
                      key,
                      item as core.Object,
                    ),
                  ))
          .toList();
    }
    if (_json.containsKey('timestamp')) {
      timestamp = _json['timestamp'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = (_json['value'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attachments != null) 'attachments': attachments!,
        if (timestamp != null) 'timestamp': timestamp!,
        if (value != null) 'value': value!,
      };
}

/// Describing buckets with arbitrary user-provided width.
class ExplicitBuckets {
  /// 'bound' is a list of strictly increasing boundaries between buckets.
  ///
  /// Note that a list of length N-1 defines N buckets because of fenceposting.
  /// See comments on `bucket_options` for details. The i'th finite bucket
  /// covers the interval \[bound\[i-1\], bound\[i\]) where i ranges from 1 to
  /// bound_size() - 1. Note that there are no finite buckets at all if 'bound'
  /// only contains a single element; in that special case the single bound
  /// defines the boundary between the underflow and overflow buckets. bucket
  /// number lower bound upper bound i == 0 (underflow) -inf bound\[i\] 0 < i <
  /// bound_size() bound\[i-1\] bound\[i\] i == bound_size() (overflow)
  /// bound\[i-1\] +inf
  core.List<core.double>? bounds;

  ExplicitBuckets();

  ExplicitBuckets.fromJson(core.Map _json) {
    if (_json.containsKey('bounds')) {
      bounds = (_json['bounds'] as core.List)
          .map<core.double>((value) => (value as core.num).toDouble())
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bounds != null) 'bounds': bounds!,
      };
}

/// Describing buckets with exponentially growing width.
class ExponentialBuckets {
  /// The i'th exponential bucket covers the interval \[scale *
  /// growth_factor^(i-1), scale * growth_factor^i) where i ranges from 1 to
  /// num_finite_buckets inclusive.
  ///
  /// Must be larger than 1.0.
  core.double? growthFactor;

  /// The number of finite buckets.
  ///
  /// With the underflow and overflow buckets, the total number of buckets is
  /// `num_finite_buckets` + 2. See comments on `bucket_options` for details.
  core.int? numFiniteBuckets;

  /// The i'th exponential bucket covers the interval \[scale *
  /// growth_factor^(i-1), scale * growth_factor^i) where i ranges from 1 to
  /// num_finite_buckets inclusive.
  ///
  /// Must be > 0.
  core.double? scale;

  ExponentialBuckets();

  ExponentialBuckets.fromJson(core.Map _json) {
    if (_json.containsKey('growthFactor')) {
      growthFactor = (_json['growthFactor'] as core.num).toDouble();
    }
    if (_json.containsKey('numFiniteBuckets')) {
      numFiniteBuckets = _json['numFiniteBuckets'] as core.int;
    }
    if (_json.containsKey('scale')) {
      scale = (_json['scale'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (growthFactor != null) 'growthFactor': growthFactor!,
        if (numFiniteBuckets != null) 'numFiniteBuckets': numFiniteBuckets!,
        if (scale != null) 'scale': scale!,
      };
}

/// First party identity principal.
class FirstPartyPrincipal {
  /// The email address of a Google account.
  ///
  /// .
  core.String? principalEmail;

  /// Metadata about the service that uses the service account.
  ///
  /// .
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? serviceMetadata;

  FirstPartyPrincipal();

  FirstPartyPrincipal.fromJson(core.Map _json) {
    if (_json.containsKey('principalEmail')) {
      principalEmail = _json['principalEmail'] as core.String;
    }
    if (_json.containsKey('serviceMetadata')) {
      serviceMetadata =
          (_json['serviceMetadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (principalEmail != null) 'principalEmail': principalEmail!,
        if (serviceMetadata != null) 'serviceMetadata': serviceMetadata!,
      };
}

/// A common proto for logging HTTP requests.
///
/// Only contains semantics defined by the HTTP specification. Product-specific
/// logging information MUST be defined in a separate message.
class HttpRequest {
  /// The number of HTTP response bytes inserted into cache.
  ///
  /// Set only when a cache fill was attempted.
  core.String? cacheFillBytes;

  /// Whether or not an entity was served from cache (with or without
  /// validation).
  core.bool? cacheHit;

  /// Whether or not a cache lookup was attempted.
  core.bool? cacheLookup;

  /// Whether or not the response was validated with the origin server before
  /// being served from cache.
  ///
  /// This field is only meaningful if `cache_hit` is True.
  core.bool? cacheValidatedWithOriginServer;

  /// The request processing latency on the server, from the time the request
  /// was received until the response was sent.
  core.String? latency;

  /// Protocol used for the request.
  ///
  /// Examples: "HTTP/1.1", "HTTP/2", "websocket"
  core.String? protocol;

  /// The referer URL of the request, as defined in
  /// [HTTP/1.1 Header Field Definitions](http://www.w3.org/Protocols/rfc2616/rfc2616-sec14.html).
  core.String? referer;

  /// The IP address (IPv4 or IPv6) of the client that issued the HTTP request.
  ///
  /// Examples: `"192.168.1.1"`, `"FE80::0202:B3FF:FE1E:8329"`.
  core.String? remoteIp;

  /// The request method.
  ///
  /// Examples: `"GET"`, `"HEAD"`, `"PUT"`, `"POST"`.
  core.String? requestMethod;

  /// The size of the HTTP request message in bytes, including the request
  /// headers and the request body.
  core.String? requestSize;

  /// The scheme (http, https), the host name, the path, and the query portion
  /// of the URL that was requested.
  ///
  /// Example: `"http://example.com/some/info?color=red"`.
  core.String? requestUrl;

  /// The size of the HTTP response message sent back to the client, in bytes,
  /// including the response headers and the response body.
  core.String? responseSize;

  /// The IP address (IPv4 or IPv6) of the origin server that the request was
  /// sent to.
  core.String? serverIp;

  /// The response code indicating the status of the response.
  ///
  /// Examples: 200, 404.
  core.int? status;

  /// The user agent sent by the client.
  ///
  /// Example: `"Mozilla/4.0 (compatible; MSIE 6.0; Windows 98; Q312461; .NET
  /// CLR 1.0.3705)"`.
  core.String? userAgent;

  HttpRequest();

  HttpRequest.fromJson(core.Map _json) {
    if (_json.containsKey('cacheFillBytes')) {
      cacheFillBytes = _json['cacheFillBytes'] as core.String;
    }
    if (_json.containsKey('cacheHit')) {
      cacheHit = _json['cacheHit'] as core.bool;
    }
    if (_json.containsKey('cacheLookup')) {
      cacheLookup = _json['cacheLookup'] as core.bool;
    }
    if (_json.containsKey('cacheValidatedWithOriginServer')) {
      cacheValidatedWithOriginServer =
          _json['cacheValidatedWithOriginServer'] as core.bool;
    }
    if (_json.containsKey('latency')) {
      latency = _json['latency'] as core.String;
    }
    if (_json.containsKey('protocol')) {
      protocol = _json['protocol'] as core.String;
    }
    if (_json.containsKey('referer')) {
      referer = _json['referer'] as core.String;
    }
    if (_json.containsKey('remoteIp')) {
      remoteIp = _json['remoteIp'] as core.String;
    }
    if (_json.containsKey('requestMethod')) {
      requestMethod = _json['requestMethod'] as core.String;
    }
    if (_json.containsKey('requestSize')) {
      requestSize = _json['requestSize'] as core.String;
    }
    if (_json.containsKey('requestUrl')) {
      requestUrl = _json['requestUrl'] as core.String;
    }
    if (_json.containsKey('responseSize')) {
      responseSize = _json['responseSize'] as core.String;
    }
    if (_json.containsKey('serverIp')) {
      serverIp = _json['serverIp'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = _json['status'] as core.int;
    }
    if (_json.containsKey('userAgent')) {
      userAgent = _json['userAgent'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (cacheFillBytes != null) 'cacheFillBytes': cacheFillBytes!,
        if (cacheHit != null) 'cacheHit': cacheHit!,
        if (cacheLookup != null) 'cacheLookup': cacheLookup!,
        if (cacheValidatedWithOriginServer != null)
          'cacheValidatedWithOriginServer': cacheValidatedWithOriginServer!,
        if (latency != null) 'latency': latency!,
        if (protocol != null) 'protocol': protocol!,
        if (referer != null) 'referer': referer!,
        if (remoteIp != null) 'remoteIp': remoteIp!,
        if (requestMethod != null) 'requestMethod': requestMethod!,
        if (requestSize != null) 'requestSize': requestSize!,
        if (requestUrl != null) 'requestUrl': requestUrl!,
        if (responseSize != null) 'responseSize': responseSize!,
        if (serverIp != null) 'serverIp': serverIp!,
        if (status != null) 'status': status!,
        if (userAgent != null) 'userAgent': userAgent!,
      };
}

/// Describing buckets with constant width.
class LinearBuckets {
  /// The number of finite buckets.
  ///
  /// With the underflow and overflow buckets, the total number of buckets is
  /// `num_finite_buckets` + 2. See comments on `bucket_options` for details.
  core.int? numFiniteBuckets;

  /// The i'th linear bucket covers the interval \[offset + (i-1) * width,
  /// offset + i * width) where i ranges from 1 to num_finite_buckets,
  /// inclusive.
  core.double? offset;

  /// The i'th linear bucket covers the interval \[offset + (i-1) * width,
  /// offset + i * width) where i ranges from 1 to num_finite_buckets,
  /// inclusive.
  ///
  /// Must be strictly positive.
  core.double? width;

  LinearBuckets();

  LinearBuckets.fromJson(core.Map _json) {
    if (_json.containsKey('numFiniteBuckets')) {
      numFiniteBuckets = _json['numFiniteBuckets'] as core.int;
    }
    if (_json.containsKey('offset')) {
      offset = (_json['offset'] as core.num).toDouble();
    }
    if (_json.containsKey('width')) {
      width = (_json['width'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (numFiniteBuckets != null) 'numFiniteBuckets': numFiniteBuckets!,
        if (offset != null) 'offset': offset!,
        if (width != null) 'width': width!,
      };
}

/// An individual log entry.
class LogEntry {
  /// Information about the HTTP request associated with this log entry, if
  /// applicable.
  ///
  /// Optional.
  HttpRequest? httpRequest;

  /// A unique ID for the log entry used for deduplication.
  ///
  /// If omitted, the implementation will generate one based on operation_id.
  core.String? insertId;

  /// A set of user-defined (key, value) data that provides additional
  /// information about the log entry.
  core.Map<core.String, core.String>? labels;

  /// The log to which this log entry belongs.
  ///
  /// Examples: `"syslog"`, `"book_log"`.
  ///
  /// Required.
  core.String? name;

  /// Information about an operation associated with the log entry, if
  /// applicable.
  ///
  /// Optional.
  LogEntryOperation? operation;

  /// The log entry payload, represented as a protocol buffer that is expressed
  /// as a JSON object.
  ///
  /// The only accepted type currently is AuditLog.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? protoPayload;

  /// The severity of the log entry.
  ///
  /// The default value is `LogSeverity.DEFAULT`.
  /// Possible string values are:
  /// - "DEFAULT" : (0) The log entry has no assigned severity level.
  /// - "DEBUG" : (100) Debug or trace information.
  /// - "INFO" : (200) Routine information, such as ongoing status or
  /// performance.
  /// - "NOTICE" : (300) Normal but significant events, such as start up, shut
  /// down, or a configuration change.
  /// - "WARNING" : (400) Warning events might cause problems.
  /// - "ERROR" : (500) Error events are likely to cause problems.
  /// - "CRITICAL" : (600) Critical events cause more severe problems or
  /// outages.
  /// - "ALERT" : (700) A person must take an action immediately.
  /// - "EMERGENCY" : (800) One or more systems are unusable.
  core.String? severity;

  /// Source code location information associated with the log entry, if any.
  ///
  /// Optional.
  LogEntrySourceLocation? sourceLocation;

  /// The log entry payload, represented as a structure that is expressed as a
  /// JSON object.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? structPayload;

  /// The log entry payload, represented as a Unicode string (UTF-8).
  core.String? textPayload;

  /// The time the event described by the log entry occurred.
  ///
  /// If omitted, defaults to operation start time.
  core.String? timestamp;

  /// Resource name of the trace associated with the log entry, if any.
  ///
  /// If this field contains a relative resource name, you can assume the name
  /// is relative to `//tracing.googleapis.com`. Example:
  /// `projects/my-projectid/traces/06796866738c859f2f19b7cfb3214824`
  ///
  /// Optional.
  core.String? trace;

  LogEntry();

  LogEntry.fromJson(core.Map _json) {
    if (_json.containsKey('httpRequest')) {
      httpRequest = HttpRequest.fromJson(
          _json['httpRequest'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('insertId')) {
      insertId = _json['insertId'] as core.String;
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
    if (_json.containsKey('operation')) {
      operation = LogEntryOperation.fromJson(
          _json['operation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('protoPayload')) {
      protoPayload =
          (_json['protoPayload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('severity')) {
      severity = _json['severity'] as core.String;
    }
    if (_json.containsKey('sourceLocation')) {
      sourceLocation = LogEntrySourceLocation.fromJson(
          _json['sourceLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('structPayload')) {
      structPayload =
          (_json['structPayload'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('textPayload')) {
      textPayload = _json['textPayload'] as core.String;
    }
    if (_json.containsKey('timestamp')) {
      timestamp = _json['timestamp'] as core.String;
    }
    if (_json.containsKey('trace')) {
      trace = _json['trace'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (httpRequest != null) 'httpRequest': httpRequest!.toJson(),
        if (insertId != null) 'insertId': insertId!,
        if (labels != null) 'labels': labels!,
        if (name != null) 'name': name!,
        if (operation != null) 'operation': operation!.toJson(),
        if (protoPayload != null) 'protoPayload': protoPayload!,
        if (severity != null) 'severity': severity!,
        if (sourceLocation != null) 'sourceLocation': sourceLocation!.toJson(),
        if (structPayload != null) 'structPayload': structPayload!,
        if (textPayload != null) 'textPayload': textPayload!,
        if (timestamp != null) 'timestamp': timestamp!,
        if (trace != null) 'trace': trace!,
      };
}

/// Additional information about a potentially long-running operation with which
/// a log entry is associated.
class LogEntryOperation {
  /// Set this to True if this is the first log entry in the operation.
  ///
  /// Optional.
  core.bool? first;

  /// An arbitrary operation identifier.
  ///
  /// Log entries with the same identifier are assumed to be part of the same
  /// operation.
  ///
  /// Optional.
  core.String? id;

  /// Set this to True if this is the last log entry in the operation.
  ///
  /// Optional.
  core.bool? last;

  /// An arbitrary producer identifier.
  ///
  /// The combination of `id` and `producer` must be globally unique. Examples
  /// for `producer`: `"MyDivision.MyBigCompany.com"`,
  /// `"github.com/MyProject/MyApplication"`.
  ///
  /// Optional.
  core.String? producer;

  LogEntryOperation();

  LogEntryOperation.fromJson(core.Map _json) {
    if (_json.containsKey('first')) {
      first = _json['first'] as core.bool;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('last')) {
      last = _json['last'] as core.bool;
    }
    if (_json.containsKey('producer')) {
      producer = _json['producer'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (first != null) 'first': first!,
        if (id != null) 'id': id!,
        if (last != null) 'last': last!,
        if (producer != null) 'producer': producer!,
      };
}

/// Additional information about the source code location that produced the log
/// entry.
class LogEntrySourceLocation {
  /// Source file name.
  ///
  /// Depending on the runtime environment, this might be a simple name or a
  /// fully-qualified name.
  ///
  /// Optional.
  core.String? file;

  /// Human-readable name of the function or method being invoked, with optional
  /// context such as the class or package name.
  ///
  /// This information may be used in contexts such as the logs viewer, where a
  /// file and line number are less meaningful. The format can vary by language.
  /// For example: `qual.if.ied.Class.method` (Java), `dir/package.func` (Go),
  /// `function` (Python).
  ///
  /// Optional.
  core.String? function;

  /// Line within the source file.
  ///
  /// 1-based; 0 indicates no line number available.
  ///
  /// Optional.
  core.String? line;

  LogEntrySourceLocation();

  LogEntrySourceLocation.fromJson(core.Map _json) {
    if (_json.containsKey('file')) {
      file = _json['file'] as core.String;
    }
    if (_json.containsKey('function')) {
      function = _json['function'] as core.String;
    }
    if (_json.containsKey('line')) {
      line = _json['line'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (file != null) 'file': file!,
        if (function != null) 'function': function!,
        if (line != null) 'line': line!,
      };
}

/// Represents a single metric value.
class MetricValue {
  /// A boolean value.
  core.bool? boolValue;

  /// A distribution value.
  Distribution? distributionValue;

  /// A double precision floating point value.
  core.double? doubleValue;

  /// The end of the time period over which this metric value's measurement
  /// applies.
  ///
  /// If not specified, google.api.servicecontrol.v1.Operation.end_time will be
  /// used.
  core.String? endTime;

  /// A signed 64-bit integer value.
  core.String? int64Value;

  /// The labels describing the metric value.
  ///
  /// See comments on google.api.servicecontrol.v1.Operation.labels for the
  /// overriding relationship. Note that this map must not contain monitored
  /// resource labels.
  core.Map<core.String, core.String>? labels;

  /// A money value.
  Money? moneyValue;

  /// The start of the time period over which this metric value's measurement
  /// applies.
  ///
  /// The time period has different semantics for different metric types
  /// (cumulative, delta, and gauge). See the metric definition documentation in
  /// the service configuration for details. If not specified,
  /// google.api.servicecontrol.v1.Operation.start_time will be used.
  core.String? startTime;

  /// A text string value.
  core.String? stringValue;

  MetricValue();

  MetricValue.fromJson(core.Map _json) {
    if (_json.containsKey('boolValue')) {
      boolValue = _json['boolValue'] as core.bool;
    }
    if (_json.containsKey('distributionValue')) {
      distributionValue = Distribution.fromJson(
          _json['distributionValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('doubleValue')) {
      doubleValue = (_json['doubleValue'] as core.num).toDouble();
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('int64Value')) {
      int64Value = _json['int64Value'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('moneyValue')) {
      moneyValue = Money.fromJson(
          _json['moneyValue'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('stringValue')) {
      stringValue = _json['stringValue'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (boolValue != null) 'boolValue': boolValue!,
        if (distributionValue != null)
          'distributionValue': distributionValue!.toJson(),
        if (doubleValue != null) 'doubleValue': doubleValue!,
        if (endTime != null) 'endTime': endTime!,
        if (int64Value != null) 'int64Value': int64Value!,
        if (labels != null) 'labels': labels!,
        if (moneyValue != null) 'moneyValue': moneyValue!.toJson(),
        if (startTime != null) 'startTime': startTime!,
        if (stringValue != null) 'stringValue': stringValue!,
      };
}

/// Represents a set of metric values in the same metric.
///
/// Each metric value in the set should have a unique combination of start time,
/// end time, and label values.
class MetricValueSet {
  /// The metric name defined in the service configuration.
  core.String? metricName;

  /// The values in this metric.
  core.List<MetricValue>? metricValues;

  MetricValueSet();

  MetricValueSet.fromJson(core.Map _json) {
    if (_json.containsKey('metricName')) {
      metricName = _json['metricName'] as core.String;
    }
    if (_json.containsKey('metricValues')) {
      metricValues = (_json['metricValues'] as core.List)
          .map<MetricValue>((value) => MetricValue.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (metricName != null) 'metricName': metricName!,
        if (metricValues != null)
          'metricValues': metricValues!.map((value) => value.toJson()).toList(),
      };
}

/// Represents an amount of money with its currency type.
class Money {
  /// The three-letter currency code defined in ISO 4217.
  core.String? currencyCode;

  /// Number of nano (10^-9) units of the amount.
  ///
  /// The value must be between -999,999,999 and +999,999,999 inclusive. If
  /// `units` is positive, `nanos` must be positive or zero. If `units` is zero,
  /// `nanos` can be positive, zero, or negative. If `units` is negative,
  /// `nanos` must be negative or zero. For example $-1.75 is represented as
  /// `units`=-1 and `nanos`=-750,000,000.
  core.int? nanos;

  /// The whole units of the amount.
  ///
  /// For example if `currencyCode` is `"USD"`, then 1 unit is one US dollar.
  core.String? units;

  Money();

  Money.fromJson(core.Map _json) {
    if (_json.containsKey('currencyCode')) {
      currencyCode = _json['currencyCode'] as core.String;
    }
    if (_json.containsKey('nanos')) {
      nanos = _json['nanos'] as core.int;
    }
    if (_json.containsKey('units')) {
      units = _json['units'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currencyCode != null) 'currencyCode': currencyCode!,
        if (nanos != null) 'nanos': nanos!,
        if (units != null) 'units': units!,
      };
}

/// Represents information regarding an operation.
class Operation {
  /// Identity of the consumer who is using the service.
  ///
  /// This field should be filled in for the operations initiated by a consumer,
  /// but not for service-initiated operations that are not related to a
  /// specific consumer. - This can be in one of the following formats: -
  /// project:PROJECT_ID, - project`_`number:PROJECT_NUMBER, -
  /// projects/PROJECT_ID or PROJECT_NUMBER, - folders/FOLDER_NUMBER, -
  /// organizations/ORGANIZATION_NUMBER, - api`_`key:API_KEY.
  core.String? consumerId;

  /// End time of the operation.
  ///
  /// Required when the operation is used in ServiceController.Report, but
  /// optional when the operation is used in ServiceController.Check.
  core.String? endTime;

  /// Unimplemented.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Map<core.String, core.Object>>? extensions;

  /// DO NOT USE.
  ///
  /// This is an experimental field.
  /// Possible string values are:
  /// - "LOW" : Allows data caching, batching, and aggregation. It provides
  /// higher performance with higher data loss risk.
  /// - "HIGH" : Disables data aggregation to minimize data loss. It is for
  /// operations that contains significant monetary value or audit trail. This
  /// feature only applies to the client libraries.
  /// - "DEBUG" : Deprecated. Do not use. Disables data aggregation and enables
  /// additional validation logic. It should only be used during the onboarding
  /// process. It is only available to Google internal services, and the service
  /// must be approved by chemist-dev@google.com in order to use this level.
  core.String? importance;

  /// Labels describing the operation.
  ///
  /// Only the following labels are allowed: - Labels describing monitored
  /// resources as defined in the service configuration. - Default labels of
  /// metric values. When specified, labels defined in the metric value override
  /// these default. - The following labels defined by Google Cloud Platform: -
  /// `cloud.googleapis.com/location` describing the location where the
  /// operation happened, - `servicecontrol.googleapis.com/user_agent`
  /// describing the user agent of the API request, -
  /// `servicecontrol.googleapis.com/service_agent` describing the service used
  /// to handle the API request (e.g. ESP), -
  /// `servicecontrol.googleapis.com/platform` describing the platform where the
  /// API is served, such as App Engine, Compute Engine, or Kubernetes Engine.
  core.Map<core.String, core.String>? labels;

  /// Represents information to be logged.
  core.List<LogEntry>? logEntries;

  /// Represents information about this operation.
  ///
  /// Each MetricValueSet corresponds to a metric defined in the service
  /// configuration. The data type used in the MetricValueSet must agree with
  /// the data type specified in the metric definition. Within a single
  /// operation, it is not allowed to have more than one MetricValue instances
  /// that have the same metric names and identical label value combinations. If
  /// a request has such duplicated MetricValue instances, the entire request is
  /// rejected with an invalid argument error.
  core.List<MetricValueSet>? metricValueSets;

  /// Identity of the operation.
  ///
  /// This must be unique within the scope of the service that generated the
  /// operation. If the service calls Check() and Report() on the same
  /// operation, the two calls should carry the same id. UUID version 4 is
  /// recommended, though not required. In scenarios where an operation is
  /// computed from existing information and an idempotent id is desirable for
  /// deduplication purpose, UUID version 5 is recommended. See RFC 4122 for
  /// details.
  core.String? operationId;

  /// Fully qualified name of the operation.
  ///
  /// Reserved for future use.
  core.String? operationName;

  /// Represents the properties needed for quota check.
  ///
  /// Applicable only if this operation is for a quota check request. If this is
  /// not specified, no quota check will be performed.
  QuotaProperties? quotaProperties;

  /// The resources that are involved in the operation.
  ///
  /// The maximum supported number of entries in this field is 100.
  core.List<ResourceInfo>? resources;

  /// Start time of the operation.
  ///
  /// Required.
  core.String? startTime;

  /// A list of Cloud Trace spans.
  ///
  /// The span names shall contain the id of the destination project which can
  /// be either the produce or the consumer project.
  ///
  /// Unimplemented.
  core.List<TraceSpan>? traceSpans;

  /// Private Preview.
  ///
  /// This feature is only available for approved services. User defined labels
  /// for the resource that this operation is associated with.
  core.Map<core.String, core.String>? userLabels;

  Operation();

  Operation.fromJson(core.Map _json) {
    if (_json.containsKey('consumerId')) {
      consumerId = _json['consumerId'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('extensions')) {
      extensions = (_json['extensions'] as core.List)
          .map<core.Map<core.String, core.Object>>(
              (value) => (value as core.Map<core.String, core.dynamic>).map(
                    (key, item) => core.MapEntry(
                      key,
                      item as core.Object,
                    ),
                  ))
          .toList();
    }
    if (_json.containsKey('importance')) {
      importance = _json['importance'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('logEntries')) {
      logEntries = (_json['logEntries'] as core.List)
          .map<LogEntry>((value) =>
              LogEntry.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('metricValueSets')) {
      metricValueSets = (_json['metricValueSets'] as core.List)
          .map<MetricValueSet>((value) => MetricValueSet.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('operationName')) {
      operationName = _json['operationName'] as core.String;
    }
    if (_json.containsKey('quotaProperties')) {
      quotaProperties = QuotaProperties.fromJson(
          _json['quotaProperties'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<ResourceInfo>((value) => ResourceInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('traceSpans')) {
      traceSpans = (_json['traceSpans'] as core.List)
          .map<TraceSpan>((value) =>
              TraceSpan.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('userLabels')) {
      userLabels =
          (_json['userLabels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (consumerId != null) 'consumerId': consumerId!,
        if (endTime != null) 'endTime': endTime!,
        if (extensions != null) 'extensions': extensions!,
        if (importance != null) 'importance': importance!,
        if (labels != null) 'labels': labels!,
        if (logEntries != null)
          'logEntries': logEntries!.map((value) => value.toJson()).toList(),
        if (metricValueSets != null)
          'metricValueSets':
              metricValueSets!.map((value) => value.toJson()).toList(),
        if (operationId != null) 'operationId': operationId!,
        if (operationName != null) 'operationName': operationName!,
        if (quotaProperties != null)
          'quotaProperties': quotaProperties!.toJson(),
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
        if (startTime != null) 'startTime': startTime!,
        if (traceSpans != null)
          'traceSpans': traceSpans!.map((value) => value.toJson()).toList(),
        if (userLabels != null) 'userLabels': userLabels!,
      };
}

/// This message defines attributes for a node that handles a network request.
///
/// The node can be either a service or an application that sends, forwards, or
/// receives the request. Service peers should fill in `principal` and `labels`
/// as appropriate.
class Peer {
  /// The IP address of the peer.
  core.String? ip;

  /// The labels associated with the peer.
  core.Map<core.String, core.String>? labels;

  /// The network port of the peer.
  core.String? port;

  /// The identity of this peer.
  ///
  /// Similar to `Request.auth.principal`, but relative to the peer instead of
  /// the request. For example, the idenity associated with a load balancer that
  /// forwared the request.
  core.String? principal;

  /// The CLDR country/region code associated with the above IP address.
  ///
  /// If the IP address is private, the `region_code` should reflect the
  /// physical location where this peer is running.
  core.String? regionCode;

  Peer();

  Peer.fromJson(core.Map _json) {
    if (_json.containsKey('ip')) {
      ip = _json['ip'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('port')) {
      port = _json['port'] as core.String;
    }
    if (_json.containsKey('principal')) {
      principal = _json['principal'] as core.String;
    }
    if (_json.containsKey('regionCode')) {
      regionCode = _json['regionCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (ip != null) 'ip': ip!,
        if (labels != null) 'labels': labels!,
        if (port != null) 'port': port!,
        if (principal != null) 'principal': principal!,
        if (regionCode != null) 'regionCode': regionCode!,
      };
}

/// Represents error information for QuotaOperation.
class QuotaError {
  /// Error code.
  /// Possible string values are:
  /// - "UNSPECIFIED" : This is never used.
  /// - "RESOURCE_EXHAUSTED" : Quota allocation failed. Same as
  /// google.rpc.Code.RESOURCE_EXHAUSTED.
  /// - "OUT_OF_RANGE" : Quota release failed. This error is ONLY returned on a
  /// NORMAL release. More formally: if a user requests a release of 10 tokens,
  /// but only 5 tokens were previously allocated, in a BEST_EFFORT release,
  /// this will be considered a success, 5 tokens will be released, and the
  /// result will be "Ok". If this is done in NORMAL mode, no tokens will be
  /// released, and an OUT_OF_RANGE error will be returned. Same as
  /// google.rpc.Code.OUT_OF_RANGE.
  /// - "BILLING_NOT_ACTIVE" : Consumer cannot access the service because the
  /// service requires active billing.
  /// - "PROJECT_DELETED" : Consumer's project has been marked as deleted (soft
  /// deletion).
  /// - "API_KEY_INVALID" : Specified API key is invalid.
  /// - "API_KEY_EXPIRED" : Specified API Key has expired.
  /// - "SPATULA_HEADER_INVALID" : Consumer's spatula header is invalid.
  /// - "LOAS_ROLE_INVALID" : The consumer's LOAS role is invalid.
  /// - "NO_LOAS_PROJECT" : The consumer's LOAS role has no associated project.
  /// - "PROJECT_STATUS_UNAVAILABLE" : The backend server for looking up project
  /// id/number is unavailable.
  /// - "SERVICE_STATUS_UNAVAILABLE" : The backend server for checking service
  /// status is unavailable.
  /// - "BILLING_STATUS_UNAVAILABLE" : The backend server for checking billing
  /// status is unavailable.
  /// - "QUOTA_SYSTEM_UNAVAILABLE" : The backend server for checking quota
  /// limits is unavailable.
  core.String? code;

  /// Free-form text that provides details on the cause of the error.
  core.String? description;

  /// Contains additional information about the quota error.
  ///
  /// If available, `status.code` will be non zero.
  Status? status;

  /// Subject to whom this error applies.
  ///
  /// See the specific enum for more details on this field. For example,
  /// "clientip:" or "project:".
  core.String? subject;

  QuotaError();

  QuotaError.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = Status.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('subject')) {
      subject = _json['subject'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (description != null) 'description': description!,
        if (status != null) 'status': status!.toJson(),
        if (subject != null) 'subject': subject!,
      };
}

/// Contains the quota information for a quota check response.
class QuotaInfo {
  /// Quota Metrics that have exceeded quota limits.
  ///
  /// For QuotaGroup-based quota, this is QuotaGroup.name For QuotaLimit-based
  /// quota, this is QuotaLimit.name See: google.api.Quota Deprecated: Use
  /// quota_metrics to get per quota group limit exceeded status.
  core.List<core.String>? limitExceeded;

  /// Map of quota group name to the actual number of tokens consumed.
  ///
  /// If the quota check was not successful, then this will not be populated due
  /// to no quota consumption. We are not merging this field with
  /// 'quota_metrics' field because of the complexity of scaling in Chemist
  /// client code base. For simplicity, we will keep this field for Castor (that
  /// scales quota usage) and 'quota_metrics' for SuperQuota (that doesn't scale
  /// quota usage).
  core.Map<core.String, core.int>? quotaConsumed;

  /// Quota metrics to indicate the usage.
  ///
  /// Depending on the check request, one or more of the following metrics will
  /// be included: 1. For rate quota, per quota group or per quota metric
  /// incremental usage will be specified using the following delta metric:
  /// "serviceruntime.googleapis.com/api/consumer/quota_used_count" 2. For
  /// allocation quota, per quota metric total usage will be specified using the
  /// following gauge metric:
  /// "serviceruntime.googleapis.com/allocation/consumer/quota_used_count" 3.
  /// For both rate quota and allocation quota, the quota limit reached
  /// condition will be specified using the following boolean metric:
  /// "serviceruntime.googleapis.com/quota/exceeded"
  core.List<MetricValueSet>? quotaMetrics;

  QuotaInfo();

  QuotaInfo.fromJson(core.Map _json) {
    if (_json.containsKey('limitExceeded')) {
      limitExceeded = (_json['limitExceeded'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('quotaConsumed')) {
      quotaConsumed =
          (_json['quotaConsumed'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.int,
        ),
      );
    }
    if (_json.containsKey('quotaMetrics')) {
      quotaMetrics = (_json['quotaMetrics'] as core.List)
          .map<MetricValueSet>((value) => MetricValueSet.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (limitExceeded != null) 'limitExceeded': limitExceeded!,
        if (quotaConsumed != null) 'quotaConsumed': quotaConsumed!,
        if (quotaMetrics != null)
          'quotaMetrics': quotaMetrics!.map((value) => value.toJson()).toList(),
      };
}

/// Represents information regarding a quota operation.
class QuotaOperation {
  /// Identity of the consumer for whom this quota operation is being performed.
  ///
  /// This can be in one of the following formats: project:, project_number:,
  /// api_key:.
  core.String? consumerId;

  /// Labels describing the operation.
  core.Map<core.String, core.String>? labels;

  /// Fully qualified name of the API method for which this quota operation is
  /// requested.
  ///
  /// This name is used for matching quota rules or metric rules and billing
  /// status rules defined in service configuration. This field should not be
  /// set if any of the following is true: (1) the quota operation is performed
  /// on non-API resources. (2) quota_metrics is set because the caller is doing
  /// quota override. Example of an RPC method name:
  /// google.example.library.v1.LibraryService.CreateShelf
  core.String? methodName;

  /// Identity of the operation.
  ///
  /// This is expected to be unique within the scope of the service that
  /// generated the operation, and guarantees idempotency in case of retries. In
  /// order to ensure best performance and latency in the Quota backends,
  /// operation_ids are optimally associated with time, so that related
  /// operations can be accessed fast in storage. For this reason, the
  /// recommended token for services that intend to operate at a high QPS is
  /// Unix time in nanos + UUID
  core.String? operationId;

  /// Represents information about this operation.
  ///
  /// Each MetricValueSet corresponds to a metric defined in the service
  /// configuration. The data type used in the MetricValueSet must agree with
  /// the data type specified in the metric definition. Within a single
  /// operation, it is not allowed to have more than one MetricValue instances
  /// that have the same metric names and identical label value combinations. If
  /// a request has such duplicated MetricValue instances, the entire request is
  /// rejected with an invalid argument error. This field is mutually exclusive
  /// with method_name.
  core.List<MetricValueSet>? quotaMetrics;

  /// Quota mode for this operation.
  /// Possible string values are:
  /// - "UNSPECIFIED" : Guard against implicit default. Must not be used.
  /// - "NORMAL" : For AllocateQuota request, allocates quota for the amount
  /// specified in the service configuration or specified using the quota
  /// metrics. If the amount is higher than the available quota, allocation
  /// error will be returned and no quota will be allocated. If multiple quotas
  /// are part of the request, and one fails, none of the quotas are allocated
  /// or released.
  /// - "BEST_EFFORT" : The operation allocates quota for the amount specified
  /// in the service configuration or specified using the quota metrics. If the
  /// amount is higher than the available quota, request does not fail but all
  /// available quota will be allocated. For rate quota, BEST_EFFORT will
  /// continue to deduct from other groups even if one does not have enough
  /// quota. For allocation, it will find the minimum available amount across
  /// all groups and deduct that amount from all the affected groups.
  /// - "CHECK_ONLY" : For AllocateQuota request, only checks if there is enough
  /// quota available and does not change the available quota. No lock is placed
  /// on the available quota either.
  /// - "QUERY_ONLY" : Unimplemented. When used in AllocateQuotaRequest, this
  /// returns the effective quota limit(s) in the response, and no quota check
  /// will be performed. Not supported for other requests, and even for
  /// AllocateQuotaRequest, this is currently supported only for allowlisted
  /// services.
  /// - "ADJUST_ONLY" : The operation allocates quota for the amount specified
  /// in the service configuration or specified using the quota metrics. If the
  /// requested amount is higher than the available quota, request does not fail
  /// and remaining quota would become negative (going over the limit). Not
  /// supported for Rate Quota.
  core.String? quotaMode;

  QuotaOperation();

  QuotaOperation.fromJson(core.Map _json) {
    if (_json.containsKey('consumerId')) {
      consumerId = _json['consumerId'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('methodName')) {
      methodName = _json['methodName'] as core.String;
    }
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('quotaMetrics')) {
      quotaMetrics = (_json['quotaMetrics'] as core.List)
          .map<MetricValueSet>((value) => MetricValueSet.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('quotaMode')) {
      quotaMode = _json['quotaMode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (consumerId != null) 'consumerId': consumerId!,
        if (labels != null) 'labels': labels!,
        if (methodName != null) 'methodName': methodName!,
        if (operationId != null) 'operationId': operationId!,
        if (quotaMetrics != null)
          'quotaMetrics': quotaMetrics!.map((value) => value.toJson()).toList(),
        if (quotaMode != null) 'quotaMode': quotaMode!,
      };
}

/// Represents the properties needed for quota operations.
class QuotaProperties {
  /// Quota mode for this operation.
  /// Possible string values are:
  /// - "ACQUIRE" : Decreases available quota by the cost specified for the
  /// operation. If cost is higher than available quota, operation fails and
  /// returns error.
  /// - "ACQUIRE_BEST_EFFORT" : Decreases available quota by the cost specified
  /// for the operation. If cost is higher than available quota, operation does
  /// not fail and available quota goes down to zero but it returns error.
  /// - "CHECK" : Does not change any available quota. Only checks if there is
  /// enough quota. No lock is placed on the checked tokens neither.
  /// - "RELEASE" : DEPRECATED: Increases available quota by the operation cost
  /// specified for the operation.
  core.String? quotaMode;

  QuotaProperties();

  QuotaProperties.fromJson(core.Map _json) {
    if (_json.containsKey('quotaMode')) {
      quotaMode = _json['quotaMode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (quotaMode != null) 'quotaMode': quotaMode!,
      };
}

/// Represents the processing error of one Operation in the request.
class ReportError {
  /// The Operation.operation_id value from the request.
  core.String? operationId;

  /// Details of the error when processing the Operation.
  Status? status;

  ReportError();

  ReportError.fromJson(core.Map _json) {
    if (_json.containsKey('operationId')) {
      operationId = _json['operationId'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = Status.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operationId != null) 'operationId': operationId!,
        if (status != null) 'status': status!.toJson(),
      };
}

/// Request message for the Report method.
class ReportRequest {
  /// Operations to be reported.
  ///
  /// Typically the service should report one operation per request. Putting
  /// multiple operations into a single request is allowed, but should be used
  /// only when multiple operations are natually available at the time of the
  /// report. There is no limit on the number of operations in the same
  /// ReportRequest, however the ReportRequest size should be no larger than
  /// 1MB. See ReportResponse.report_errors for partial failure behavior.
  core.List<Operation>? operations;

  /// Specifies which version of service config should be used to process the
  /// request.
  ///
  /// If unspecified or no matching version can be found, the latest one will be
  /// used.
  core.String? serviceConfigId;

  ReportRequest();

  ReportRequest.fromJson(core.Map _json) {
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<Operation>((value) =>
              Operation.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('serviceConfigId')) {
      serviceConfigId = _json['serviceConfigId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
        if (serviceConfigId != null) 'serviceConfigId': serviceConfigId!,
      };
}

/// Response message for the Report method.
class ReportResponse {
  /// Partial failures, one for each `Operation` in the request that failed
  /// processing.
  ///
  /// There are three possible combinations of the RPC status: 1. The
  /// combination of a successful RPC status and an empty `report_errors` list
  /// indicates a complete success where all `Operations` in the request are
  /// processed successfully. 2. The combination of a successful RPC status and
  /// a non-empty `report_errors` list indicates a partial success where some
  /// `Operations` in the request succeeded. Each `Operation` that failed
  /// processing has a corresponding item in this list. 3. A failed RPC status
  /// indicates a general non-deterministic failure. When this happens, it's
  /// impossible to know which of the 'Operations' in the request succeeded or
  /// failed.
  core.List<ReportError>? reportErrors;

  /// The actual config id used to process the request.
  core.String? serviceConfigId;

  /// The current service rollout id used to process the request.
  core.String? serviceRolloutId;

  ReportResponse();

  ReportResponse.fromJson(core.Map _json) {
    if (_json.containsKey('reportErrors')) {
      reportErrors = (_json['reportErrors'] as core.List)
          .map<ReportError>((value) => ReportError.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('serviceConfigId')) {
      serviceConfigId = _json['serviceConfigId'] as core.String;
    }
    if (_json.containsKey('serviceRolloutId')) {
      serviceRolloutId = _json['serviceRolloutId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (reportErrors != null)
          'reportErrors': reportErrors!.map((value) => value.toJson()).toList(),
        if (serviceConfigId != null) 'serviceConfigId': serviceConfigId!,
        if (serviceRolloutId != null) 'serviceRolloutId': serviceRolloutId!,
      };
}

/// This message defines attributes for an HTTP request.
///
/// If the actual request is not an HTTP request, the runtime system should try
/// to map the actual request to an equivalent HTTP request.
class Request {
  /// The request authentication.
  ///
  /// May be absent for unauthenticated requests. Derived from the HTTP request
  /// `Authorization` header or equivalent.
  Auth? auth;

  /// The HTTP request headers.
  ///
  /// If multiple headers share the same key, they must be merged according to
  /// the HTTP spec. All header keys must be lowercased, because HTTP header
  /// keys are case-insensitive.
  core.Map<core.String, core.String>? headers;

  /// The HTTP request `Host` header value.
  core.String? host;

  /// The unique ID for a request, which can be propagated to downstream
  /// systems.
  ///
  /// The ID should have low probability of collision within a single day for a
  /// specific service.
  core.String? id;

  /// The HTTP request method, such as `GET`, `POST`.
  core.String? method;

  /// The HTTP URL path, excluding the query parameters.
  core.String? path;

  /// The network protocol used with the request, such as "http/1.1", "spdy/3",
  /// "h2", "h2c", "webrtc", "tcp", "udp", "quic".
  ///
  /// See
  /// https://www.iana.org/assignments/tls-extensiontype-values/tls-extensiontype-values.xhtml#alpn-protocol-ids
  /// for details.
  core.String? protocol;

  /// The HTTP URL query in the format of `name1=value1&name2=value2`, as it
  /// appears in the first line of the HTTP request.
  ///
  /// No decoding is performed.
  core.String? query;

  /// A special parameter for request reason.
  ///
  /// It is used by security systems to associate auditing information with a
  /// request.
  core.String? reason;

  /// The HTTP URL scheme, such as `http` and `https`.
  core.String? scheme;

  /// The HTTP request size in bytes.
  ///
  /// If unknown, it must be -1.
  core.String? size;

  /// The timestamp when the `destination` service receives the last byte of the
  /// request.
  core.String? time;

  Request();

  Request.fromJson(core.Map _json) {
    if (_json.containsKey('auth')) {
      auth =
          Auth.fromJson(_json['auth'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('headers')) {
      headers = (_json['headers'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('host')) {
      host = _json['host'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('method')) {
      method = _json['method'] as core.String;
    }
    if (_json.containsKey('path')) {
      path = _json['path'] as core.String;
    }
    if (_json.containsKey('protocol')) {
      protocol = _json['protocol'] as core.String;
    }
    if (_json.containsKey('query')) {
      query = _json['query'] as core.String;
    }
    if (_json.containsKey('reason')) {
      reason = _json['reason'] as core.String;
    }
    if (_json.containsKey('scheme')) {
      scheme = _json['scheme'] as core.String;
    }
    if (_json.containsKey('size')) {
      size = _json['size'] as core.String;
    }
    if (_json.containsKey('time')) {
      time = _json['time'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (auth != null) 'auth': auth!.toJson(),
        if (headers != null) 'headers': headers!,
        if (host != null) 'host': host!,
        if (id != null) 'id': id!,
        if (method != null) 'method': method!,
        if (path != null) 'path': path!,
        if (protocol != null) 'protocol': protocol!,
        if (query != null) 'query': query!,
        if (reason != null) 'reason': reason!,
        if (scheme != null) 'scheme': scheme!,
        if (size != null) 'size': size!,
        if (time != null) 'time': time!,
      };
}

/// Metadata about the request.
class RequestMetadata {
  /// The IP address of the caller.
  ///
  /// For caller from internet, this will be public IPv4 or IPv6 address. For
  /// caller from a Compute Engine VM with external IP address, this will be the
  /// VM's external IP address. For caller from a Compute Engine VM without
  /// external IP address, if the VM is in the same organization (or project) as
  /// the accessed resource, `caller_ip` will be the VM's internal IPv4 address,
  /// otherwise the `caller_ip` will be redacted to "gce-internal-ip". See
  /// https://cloud.google.com/compute/docs/vpc/ for more information.
  core.String? callerIp;

  /// The network of the caller.
  ///
  /// Set only if the network host project is part of the same GCP organization
  /// (or project) as the accessed resource. See
  /// https://cloud.google.com/compute/docs/vpc/ for more information. This is a
  /// scheme-less URI full resource name. For example:
  /// "//compute.googleapis.com/projects/PROJECT_ID/global/networks/NETWORK_ID"
  core.String? callerNetwork;

  /// The user agent of the caller.
  ///
  /// This information is not authenticated and should be treated accordingly.
  /// For example: + `google-api-python-client/1.4.0`: The request was made by
  /// the Google API client for Python. + `Cloud SDK Command Line Tool
  /// apitools-client/1.0 gcloud/0.9.62`: The request was made by the Google
  /// Cloud SDK CLI (gcloud). + `AppEngine-Google;
  /// (+http://code.google.com/appengine; appid: s~my-project`: The request was
  /// made from the `my-project` App Engine app. NOLINT
  core.String? callerSuppliedUserAgent;

  /// The destination of a network activity, such as accepting a TCP connection.
  ///
  /// In a multi hop network activity, the destination represents the receiver
  /// of the last hop. Only two fields are used in this message, Peer.port and
  /// Peer.ip. These fields are optionally populated by those services utilizing
  /// the IAM condition feature.
  Peer? destinationAttributes;

  /// Request attributes used in IAM condition evaluation.
  ///
  /// This field contains request attributes like request time and access levels
  /// associated with the request. To get the whole view of the attributes used
  /// in IAM condition evaluation, the user must also look into
  /// `AuditLog.authentication_info.resource_attributes`.
  Request? requestAttributes;

  RequestMetadata();

  RequestMetadata.fromJson(core.Map _json) {
    if (_json.containsKey('callerIp')) {
      callerIp = _json['callerIp'] as core.String;
    }
    if (_json.containsKey('callerNetwork')) {
      callerNetwork = _json['callerNetwork'] as core.String;
    }
    if (_json.containsKey('callerSuppliedUserAgent')) {
      callerSuppliedUserAgent = _json['callerSuppliedUserAgent'] as core.String;
    }
    if (_json.containsKey('destinationAttributes')) {
      destinationAttributes = Peer.fromJson(_json['destinationAttributes']
          as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('requestAttributes')) {
      requestAttributes = Request.fromJson(
          _json['requestAttributes'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (callerIp != null) 'callerIp': callerIp!,
        if (callerNetwork != null) 'callerNetwork': callerNetwork!,
        if (callerSuppliedUserAgent != null)
          'callerSuppliedUserAgent': callerSuppliedUserAgent!,
        if (destinationAttributes != null)
          'destinationAttributes': destinationAttributes!.toJson(),
        if (requestAttributes != null)
          'requestAttributes': requestAttributes!.toJson(),
      };
}

/// This message defines core attributes for a resource.
///
/// A resource is an addressable (named) entity provided by the destination
/// service. For example, a file stored on a network storage service.
class Resource {
  /// Annotations is an unstructured key-value map stored with a resource that
  /// may be set by external tools to store and retrieve arbitrary metadata.
  ///
  /// They are not queryable and should be preserved when modifying objects.
  /// More info: https://kubernetes.io/docs/user-guide/annotations
  core.Map<core.String, core.String>? annotations;

  /// The timestamp when the resource was created.
  ///
  /// This may be either the time creation was initiated or when it was
  /// completed.
  ///
  /// Output only.
  core.String? createTime;

  /// The timestamp when the resource was deleted.
  ///
  /// If the resource is not deleted, this must be empty.
  ///
  /// Output only.
  core.String? deleteTime;

  /// Mutable.
  ///
  /// The display name set by clients. Must be <= 63 characters.
  core.String? displayName;

  /// An opaque value that uniquely identifies a version or generation of a
  /// resource.
  ///
  /// It can be used to confirm that the client and server agree on the ordering
  /// of a resource being written.
  ///
  /// Output only.
  core.String? etag;

  /// The labels or tags on the resource, such as AWS resource tags and
  /// Kubernetes resource labels.
  core.Map<core.String, core.String>? labels;

  /// The location of the resource.
  ///
  /// The location encoding is specific to the service provider, and new
  /// encoding may be introduced as the service evolves. For Google Cloud
  /// products, the encoding is what is used by Google Cloud APIs, such as
  /// `us-east1`, `aws-us-east-1`, and `azure-eastus2`. The semantics of
  /// `location` is identical to the `cloud.googleapis.com/location` label used
  /// by some Google Cloud APIs.
  ///
  /// Immutable.
  core.String? location;

  /// The stable identifier (name) of a resource on the `service`.
  ///
  /// A resource can be logically identified as
  /// "//{resource.service}/{resource.name}". The differences between a resource
  /// name and a URI are: * Resource name is a logical identifier, independent
  /// of network protocol and API version. For example,
  /// `//pubsub.googleapis.com/projects/123/topics/news-feed`. * URI often
  /// includes protocol and version information, so it can be used directly by
  /// applications. For example,
  /// `https://pubsub.googleapis.com/v1/projects/123/topics/news-feed`. See
  /// https://cloud.google.com/apis/design/resource_names for details.
  core.String? name;

  /// The name of the service that this resource belongs to, such as
  /// `pubsub.googleapis.com`.
  ///
  /// The service may be different from the DNS hostname that actually serves
  /// the request.
  core.String? service;

  /// The type of the resource.
  ///
  /// The syntax is platform-specific because different platforms define their
  /// resources differently. For Google APIs, the type format must be
  /// "{service}/{kind}".
  core.String? type;

  /// The unique identifier of the resource.
  ///
  /// UID is unique in the time and space for this resource within the scope of
  /// the service. It is typically generated by the server on successful
  /// creation of a resource and must not be changed. UID is used to uniquely
  /// identify resources with resource name reuses. This should be a UUID4.
  core.String? uid;

  /// The timestamp when the resource was last updated.
  ///
  /// Any change to the resource made by users must refresh this value. Changes
  /// to a resource made by the service should refresh this value.
  ///
  /// Output only.
  core.String? updateTime;

  Resource();

  Resource.fromJson(core.Map _json) {
    if (_json.containsKey('annotations')) {
      annotations =
          (_json['annotations'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('deleteTime')) {
      deleteTime = _json['deleteTime'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('etag')) {
      etag = _json['etag'] as core.String;
    }
    if (_json.containsKey('labels')) {
      labels = (_json['labels'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('location')) {
      location = _json['location'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('service')) {
      service = _json['service'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('uid')) {
      uid = _json['uid'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotations != null) 'annotations': annotations!,
        if (createTime != null) 'createTime': createTime!,
        if (deleteTime != null) 'deleteTime': deleteTime!,
        if (displayName != null) 'displayName': displayName!,
        if (etag != null) 'etag': etag!,
        if (labels != null) 'labels': labels!,
        if (location != null) 'location': location!,
        if (name != null) 'name': name!,
        if (service != null) 'service': service!,
        if (type != null) 'type': type!,
        if (uid != null) 'uid': uid!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Describes a resource associated with this operation.
class ResourceInfo {
  /// The identifier of the parent of this resource instance.
  ///
  /// Must be in one of the following formats: - `projects/` - `folders/` -
  /// `organizations/`
  core.String? resourceContainer;

  /// The location of the resource.
  ///
  /// If not empty, the resource will be checked against location policy. The
  /// value must be a valid zone, region or multiregion. For example:
  /// "europe-west4" or "northamerica-northeast1-a"
  core.String? resourceLocation;

  /// Name of the resource.
  ///
  /// This is used for auditing purposes.
  core.String? resourceName;

  ResourceInfo();

  ResourceInfo.fromJson(core.Map _json) {
    if (_json.containsKey('resourceContainer')) {
      resourceContainer = _json['resourceContainer'] as core.String;
    }
    if (_json.containsKey('resourceLocation')) {
      resourceLocation = _json['resourceLocation'] as core.String;
    }
    if (_json.containsKey('resourceName')) {
      resourceName = _json['resourceName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (resourceContainer != null) 'resourceContainer': resourceContainer!,
        if (resourceLocation != null) 'resourceLocation': resourceLocation!,
        if (resourceName != null) 'resourceName': resourceName!,
      };
}

/// Location information about a resource.
class ResourceLocation {
  /// The locations of a resource after the execution of the operation.
  ///
  /// Requests to create or delete a location based resource must populate the
  /// 'current_locations' field and not the 'original_locations' field. For
  /// example: "europe-west1-a" "us-east1" "nam3"
  core.List<core.String>? currentLocations;

  /// The locations of a resource prior to the execution of the operation.
  ///
  /// Requests that mutate the resource's location must populate both the
  /// 'original_locations' as well as the 'current_locations' fields. For
  /// example: "europe-west1-a" "us-east1" "nam3"
  core.List<core.String>? originalLocations;

  ResourceLocation();

  ResourceLocation.fromJson(core.Map _json) {
    if (_json.containsKey('currentLocations')) {
      currentLocations = (_json['currentLocations'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('originalLocations')) {
      originalLocations = (_json['originalLocations'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (currentLocations != null) 'currentLocations': currentLocations!,
        if (originalLocations != null) 'originalLocations': originalLocations!,
      };
}

/// Identity delegation history of an authenticated service account.
class ServiceAccountDelegationInfo {
  /// First party (Google) identity as the real authority.
  FirstPartyPrincipal? firstPartyPrincipal;

  /// A string representing the principal_subject associated with the identity.
  ///
  /// See go/3pical for more info on how principal_subject is formatted.
  core.String? principalSubject;

  /// Third party identity as the real authority.
  ThirdPartyPrincipal? thirdPartyPrincipal;

  ServiceAccountDelegationInfo();

  ServiceAccountDelegationInfo.fromJson(core.Map _json) {
    if (_json.containsKey('firstPartyPrincipal')) {
      firstPartyPrincipal = FirstPartyPrincipal.fromJson(
          _json['firstPartyPrincipal'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('principalSubject')) {
      principalSubject = _json['principalSubject'] as core.String;
    }
    if (_json.containsKey('thirdPartyPrincipal')) {
      thirdPartyPrincipal = ThirdPartyPrincipal.fromJson(
          _json['thirdPartyPrincipal'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (firstPartyPrincipal != null)
          'firstPartyPrincipal': firstPartyPrincipal!.toJson(),
        if (principalSubject != null) 'principalSubject': principalSubject!,
        if (thirdPartyPrincipal != null)
          'thirdPartyPrincipal': thirdPartyPrincipal!.toJson(),
      };
}

/// The context of a span.
///
/// This is attached to an Exemplar in Distribution values during aggregation.
/// It contains the name of a span with format:
/// projects/\[PROJECT_ID_OR_NUMBER\]/traces/\[TRACE_ID\]/spans/\[SPAN_ID\]
class SpanContext {
  /// The resource name of the span.
  ///
  /// The format is:
  /// projects/\[PROJECT_ID_OR_NUMBER\]/traces/\[TRACE_ID\]/spans/\[SPAN_ID\]
  /// `[TRACE_ID]` is a unique identifier for a trace within a project; it is a
  /// 32-character hexadecimal encoding of a 16-byte array. `[SPAN_ID]` is a
  /// unique identifier for a span within a trace; it is a 16-character
  /// hexadecimal encoding of an 8-byte array.
  core.String? spanName;

  SpanContext();

  SpanContext.fromJson(core.Map _json) {
    if (_json.containsKey('spanName')) {
      spanName = _json['spanName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (spanName != null) 'spanName': spanName!,
      };
}

/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs.
///
/// It is used by [gRPC](https://github.com/grpc). Each `Status` message
/// contains three pieces of data: error code, error message, and error details.
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
class Status {
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

  Status();

  Status.fromJson(core.Map _json) {
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

/// Third party identity principal.
class ThirdPartyPrincipal {
  /// Metadata about third party identity.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? thirdPartyClaims;

  ThirdPartyPrincipal();

  ThirdPartyPrincipal.fromJson(core.Map _json) {
    if (_json.containsKey('thirdPartyClaims')) {
      thirdPartyClaims =
          (_json['thirdPartyClaims'] as core.Map<core.String, core.dynamic>)
              .map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (thirdPartyClaims != null) 'thirdPartyClaims': thirdPartyClaims!,
      };
}

/// A span represents a single operation within a trace.
///
/// Spans can be nested to form a trace tree. Often, a trace contains a root
/// span that describes the end-to-end latency, and one or more subspans for its
/// sub-operations. A trace can also contain multiple root spans, or none at
/// all. Spans do not need to be contiguous—there may be gaps or overlaps
/// between spans in a trace.
class TraceSpan {
  /// A set of attributes on the span.
  ///
  /// You can have up to 32 attributes per span.
  Attributes? attributes;

  /// An optional number of child spans that were generated while this span was
  /// active.
  ///
  /// If set, allows implementation to detect missing child spans.
  core.int? childSpanCount;

  /// A description of the span's operation (up to 128 bytes).
  ///
  /// Stackdriver Trace displays the description in the Google Cloud Platform
  /// Console. For example, the display name can be a qualified method name or a
  /// file name and a line number where the operation is called. A best practice
  /// is to use the same display name within an application and at the same call
  /// point. This makes it easier to correlate spans in different traces.
  TruncatableString? displayName;

  /// The end time of the span.
  ///
  /// On the client side, this is the time kept by the local machine where the
  /// span execution ends. On the server side, this is the time when the server
  /// application handler stops running.
  core.String? endTime;

  /// The resource name of the span in the following format:
  /// projects/\[PROJECT_ID\]/traces/\[TRACE_ID\]/spans/SPAN_ID is a unique
  /// identifier for a trace within a project; it is a 32-character hexadecimal
  /// encoding of a 16-byte array.
  ///
  /// \[SPAN_ID\] is a unique identifier for a span within a trace; it is a
  /// 16-character hexadecimal encoding of an 8-byte array.
  core.String? name;

  /// The \[SPAN_ID\] of this span's parent span.
  ///
  /// If this is a root span, then this field must be empty.
  core.String? parentSpanId;

  /// (Optional) Set this parameter to indicate whether this span is in the same
  /// process as its parent.
  ///
  /// If you do not set this parameter, Stackdriver Trace is unable to take
  /// advantage of this helpful information.
  core.bool? sameProcessAsParentSpan;

  /// The \[SPAN_ID\] portion of the span's resource name.
  core.String? spanId;

  /// Distinguishes between spans generated in a particular context.
  ///
  /// For example, two spans with the same name may be distinguished using
  /// `CLIENT` (caller) and `SERVER` (callee) to identify an RPC call.
  /// Possible string values are:
  /// - "SPAN_KIND_UNSPECIFIED" : Unspecified. Do NOT use as default.
  /// Implementations MAY assume SpanKind.INTERNAL to be default.
  /// - "INTERNAL" : Indicates that the span is used internally. Default value.
  /// - "SERVER" : Indicates that the span covers server-side handling of an RPC
  /// or other remote network request.
  /// - "CLIENT" : Indicates that the span covers the client-side wrapper around
  /// an RPC or other remote request.
  /// - "PRODUCER" : Indicates that the span describes producer sending a
  /// message to a broker. Unlike client and server, there is no direct critical
  /// path latency relationship between producer and consumer spans (e.g.
  /// publishing a message to a pubsub service).
  /// - "CONSUMER" : Indicates that the span describes consumer receiving a
  /// message from a broker. Unlike client and server, there is no direct
  /// critical path latency relationship between producer and consumer spans
  /// (e.g. receiving a message from a pubsub service subscription).
  core.String? spanKind;

  /// The start time of the span.
  ///
  /// On the client side, this is the time kept by the local machine where the
  /// span execution starts. On the server side, this is the time when the
  /// server's application handler starts running.
  core.String? startTime;

  /// An optional final status for this span.
  Status? status;

  TraceSpan();

  TraceSpan.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = Attributes.fromJson(
          _json['attributes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('childSpanCount')) {
      childSpanCount = _json['childSpanCount'] as core.int;
    }
    if (_json.containsKey('displayName')) {
      displayName = TruncatableString.fromJson(
          _json['displayName'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parentSpanId')) {
      parentSpanId = _json['parentSpanId'] as core.String;
    }
    if (_json.containsKey('sameProcessAsParentSpan')) {
      sameProcessAsParentSpan = _json['sameProcessAsParentSpan'] as core.bool;
    }
    if (_json.containsKey('spanId')) {
      spanId = _json['spanId'] as core.String;
    }
    if (_json.containsKey('spanKind')) {
      spanKind = _json['spanKind'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = Status.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null) 'attributes': attributes!.toJson(),
        if (childSpanCount != null) 'childSpanCount': childSpanCount!,
        if (displayName != null) 'displayName': displayName!.toJson(),
        if (endTime != null) 'endTime': endTime!,
        if (name != null) 'name': name!,
        if (parentSpanId != null) 'parentSpanId': parentSpanId!,
        if (sameProcessAsParentSpan != null)
          'sameProcessAsParentSpan': sameProcessAsParentSpan!,
        if (spanId != null) 'spanId': spanId!,
        if (spanKind != null) 'spanKind': spanKind!,
        if (startTime != null) 'startTime': startTime!,
        if (status != null) 'status': status!.toJson(),
      };
}

/// Represents a string that might be shortened to a specified length.
class TruncatableString {
  /// The number of bytes removed from the original string.
  ///
  /// If this value is 0, then the string was not shortened.
  core.int? truncatedByteCount;

  /// The shortened string.
  ///
  /// For example, if the original string is 500 bytes long and the limit of the
  /// string is 128 bytes, then `value` contains the first 128 bytes of the
  /// 500-byte string. Truncation always happens on a UTF8 character boundary.
  /// If there are multi-byte characters in the string, then the length of the
  /// shortened string might be less than the size limit.
  core.String? value;

  TruncatableString();

  TruncatableString.fromJson(core.Map _json) {
    if (_json.containsKey('truncatedByteCount')) {
      truncatedByteCount = _json['truncatedByteCount'] as core.int;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (truncatedByteCount != null)
          'truncatedByteCount': truncatedByteCount!,
        if (value != null) 'value': value!,
      };
}
