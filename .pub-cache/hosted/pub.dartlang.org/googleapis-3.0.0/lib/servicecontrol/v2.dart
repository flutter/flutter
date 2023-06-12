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

/// Service Control API - v2
///
/// Provides admission control and telemetry reporting for services integrated
/// with Service Infrastructure.
///
/// For more information, see <https://cloud.google.com/service-control/>
///
/// Create an instance of [ServiceControlApi] to access these resources:
///
/// - [ServicesResource]
library servicecontrol.v2;

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

  /// Private Preview.
  ///
  /// This feature is only available for approved services. This method provides
  /// admission control for services that are integrated with \[Service
  /// Infrastructure\](/service-infrastructure). It checks whether an operation
  /// should be allowed based on the service configuration and relevant
  /// policies. It must be called before the operation is executed. For more
  /// information, see \[Admission
  /// Control\](/service-infrastructure/docs/admission-control). NOTE: The
  /// admission control has an expected policy propagation delay of 60s. The
  /// caller **must** not depend on the most recent policy changes. NOTE: The
  /// admission control has a hard limit of 1 referenced resources per call. If
  /// an operation refers to more than 1 resources, the caller must call the
  /// Check method multiple times. This method requires the
  /// `servicemanagement.services.check` permission on the specified service.
  /// For more information, see
  /// [Service Control API Access Control](https://cloud.google.com/service-infrastructure/docs/service-control/access-control).
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
        'v2/services/' + commons.escapeVariable('$serviceName') + ':check';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return CheckResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Private Preview.
  ///
  /// This feature is only available for approved services. This method provides
  /// telemetry reporting for services that are integrated with \[Service
  /// Infrastructure\](/service-infrastructure). It reports a list of operations
  /// that have occurred on a service. It must be called after the operations
  /// have been executed. For more information, see \[Telemetry
  /// Reporting\](/service-infrastructure/docs/telemetry-reporting). NOTE: The
  /// telemetry reporting has a hard limit of 1000 operations and 1MB per Report
  /// call. It is recommended to have no more than 100 operations per call. This
  /// method requires the `servicemanagement.services.report` permission on the
  /// specified service. For more information, see
  /// [Service Control API Access Control](https://cloud.google.com/service-infrastructure/docs/service-control/access-control).
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
        'v2/services/' + commons.escapeVariable('$serviceName') + ':report';

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

/// This message defines attributes associated with API operations, such as a
/// network API request.
///
/// The terminology is based on the conventions used by Google APIs, Istio, and
/// OpenAPI.
class Api {
  /// The API operation name.
  ///
  /// For gRPC requests, it is the fully qualified API method name, such as
  /// "google.pubsub.v1.Publisher.Publish". For OpenAPI requests, it is the
  /// `operationId`, such as "getPet".
  core.String? operation;

  /// The API protocol used for sending the request, such as "http", "https",
  /// "grpc", or "internal".
  core.String? protocol;

  /// The API service name.
  ///
  /// It is a logical identifier for a networked API, such as
  /// "pubsub.googleapis.com". The naming syntax depends on the API management
  /// system being used for handling the request.
  core.String? service;

  /// The API version associated with the API operation above, such as "v1" or
  /// "v1alpha1".
  core.String? version;

  Api();

  Api.fromJson(core.Map _json) {
    if (_json.containsKey('operation')) {
      operation = _json['operation'] as core.String;
    }
    if (_json.containsKey('protocol')) {
      protocol = _json['protocol'] as core.String;
    }
    if (_json.containsKey('service')) {
      service = _json['service'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (operation != null) 'operation': operation!,
        if (protocol != null) 'protocol': protocol!,
        if (service != null) 'service': service!,
        if (version != null) 'version': version!,
      };
}

/// This message defines the standard attribute vocabulary for Google APIs.
///
/// An attribute is a piece of metadata that describes an activity on a network
/// service. For example, the size of an HTTP request, or the status code of an
/// HTTP response. Each attribute has a type and a name, which is logically
/// defined as a proto message field in `AttributeContext`. The field type
/// becomes the attribute type, and the field path becomes the attribute name.
/// For example, the attribute `source.ip` maps to field
/// `AttributeContext.source.ip`. This message definition is guaranteed not to
/// have any wire breaking change. So you can use it directly for passing
/// attributes across different systems. NOTE: Different system may generate
/// different subset of attributes. Please verify the system specification
/// before relying on an attribute generated a system.
class AttributeContext {
  /// Represents an API operation that is involved to a network activity.
  Api? api;

  /// The destination of a network activity, such as accepting a TCP connection.
  ///
  /// In a multi hop network activity, the destination represents the receiver
  /// of the last hop.
  Peer? destination;

  /// Supports extensions for advanced use cases, such as logs and metrics.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Map<core.String, core.Object>>? extensions;

  /// The origin of a network activity.
  ///
  /// In a multi hop network activity, the origin represents the sender of the
  /// first hop. For the first hop, the `source` and the `origin` must have the
  /// same content.
  Peer? origin;

  /// Represents a network request, such as an HTTP request.
  Request? request;

  /// Represents a target resource that is involved with a network activity.
  ///
  /// If multiple resources are involved with an activity, this must be the
  /// primary one.
  Resource? resource;

  /// Represents a network response, such as an HTTP response.
  Response? response;

  /// The source of a network activity, such as starting a TCP connection.
  ///
  /// In a multi hop network activity, the source represents the sender of the
  /// last hop.
  Peer? source;

  AttributeContext();

  AttributeContext.fromJson(core.Map _json) {
    if (_json.containsKey('api')) {
      api = Api.fromJson(_json['api'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('destination')) {
      destination = Peer.fromJson(
          _json['destination'] as core.Map<core.String, core.dynamic>);
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
    if (_json.containsKey('origin')) {
      origin =
          Peer.fromJson(_json['origin'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('request')) {
      request = Request.fromJson(
          _json['request'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('resource')) {
      resource = Resource.fromJson(
          _json['resource'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('response')) {
      response = Response.fromJson(
          _json['response'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('source')) {
      source =
          Peer.fromJson(_json['source'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (api != null) 'api': api!.toJson(),
        if (destination != null) 'destination': destination!.toJson(),
        if (extensions != null) 'extensions': extensions!,
        if (origin != null) 'origin': origin!.toJson(),
        if (request != null) 'request': request!.toJson(),
        if (resource != null) 'resource': resource!.toJson(),
        if (response != null) 'response': response!.toJson(),
        if (source != null) 'source': source!.toJson(),
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

/// Request message for the Check method.
class CheckRequest {
  /// Describes attributes about the operation being executed by the service.
  AttributeContext? attributes;

  /// Contains a comma-separated list of flags.
  ///
  /// Optional.
  core.String? flags;

  /// Describes the resources and the policies applied to each resource.
  core.List<ResourceInfo>? resources;

  /// Specifies the version of the service configuration that should be used to
  /// process the request.
  ///
  /// Must not be empty. Set this field to 'latest' to specify using the latest
  /// configuration.
  core.String? serviceConfigId;

  CheckRequest();

  CheckRequest.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = AttributeContext.fromJson(
          _json['attributes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('flags')) {
      flags = _json['flags'] as core.String;
    }
    if (_json.containsKey('resources')) {
      resources = (_json['resources'] as core.List)
          .map<ResourceInfo>((value) => ResourceInfo.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('serviceConfigId')) {
      serviceConfigId = _json['serviceConfigId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null) 'attributes': attributes!.toJson(),
        if (flags != null) 'flags': flags!,
        if (resources != null)
          'resources': resources!.map((value) => value.toJson()).toList(),
        if (serviceConfigId != null) 'serviceConfigId': serviceConfigId!,
      };
}

/// Response message for the Check method.
class CheckResponse {
  /// Returns a set of request contexts generated from the `CheckRequest`.
  core.Map<core.String, core.String>? headers;

  /// Operation is allowed when this field is not set.
  ///
  /// Any non-'OK' status indicates a denial; \[google.rpc.Status.details\]()
  /// would contain additional details about the denial.
  Status? status;

  CheckResponse();

  CheckResponse.fromJson(core.Map _json) {
    if (_json.containsKey('headers')) {
      headers = (_json['headers'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('status')) {
      status = Status.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (headers != null) 'headers': headers!,
        if (status != null) 'status': status!.toJson(),
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

/// Request message for the Report method.
class ReportRequest {
  /// Describes the list of operations to be reported.
  ///
  /// Each operation is represented as an AttributeContext, and contains all
  /// attributes around an API access.
  core.List<AttributeContext>? operations;

  /// Specifies the version of the service configuration that should be used to
  /// process the request.
  ///
  /// Must not be empty. Set this field to 'latest' to specify using the latest
  /// configuration.
  core.String? serviceConfigId;

  ReportRequest();

  ReportRequest.fromJson(core.Map _json) {
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<AttributeContext>((value) => AttributeContext.fromJson(
              value as core.Map<core.String, core.dynamic>))
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
///
/// If the request contains any invalid data, the server returns an RPC error.
class ReportResponse {
  ReportResponse();

  ReportResponse.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
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

/// Describes a resource referenced in the request.
class ResourceInfo {
  /// The name of the resource referenced in the request.
  core.String? name;

  /// The resource permission needed for this request.
  ///
  /// The format must be "{service}/{plural}.{verb}".
  core.String? permission;

  /// The resource type in the format of "{service}/{kind}".
  core.String? type;

  ResourceInfo();

  ResourceInfo.fromJson(core.Map _json) {
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('permission')) {
      permission = _json['permission'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (name != null) 'name': name!,
        if (permission != null) 'permission': permission!,
        if (type != null) 'type': type!,
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

/// This message defines attributes for a typical network response.
///
/// It generally models semantics of an HTTP response.
class Response {
  /// The amount of time it takes the backend service to fully respond to a
  /// request.
  ///
  /// Measured from when the destination service starts to send the request to
  /// the backend until when the destination service receives the complete
  /// response from the backend.
  core.String? backendLatency;

  /// The HTTP response status code, such as `200` and `404`.
  core.String? code;

  /// The HTTP response headers.
  ///
  /// If multiple headers share the same key, they must be merged according to
  /// HTTP spec. All header keys must be lowercased, because HTTP header keys
  /// are case-insensitive.
  core.Map<core.String, core.String>? headers;

  /// The HTTP response size in bytes.
  ///
  /// If unknown, it must be -1.
  core.String? size;

  /// The timestamp when the `destination` service sends the last byte of the
  /// response.
  core.String? time;

  Response();

  Response.fromJson(core.Map _json) {
    if (_json.containsKey('backendLatency')) {
      backendLatency = _json['backendLatency'] as core.String;
    }
    if (_json.containsKey('code')) {
      code = _json['code'] as core.String;
    }
    if (_json.containsKey('headers')) {
      headers = (_json['headers'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.String,
        ),
      );
    }
    if (_json.containsKey('size')) {
      size = _json['size'] as core.String;
    }
    if (_json.containsKey('time')) {
      time = _json['time'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (backendLatency != null) 'backendLatency': backendLatency!,
        if (code != null) 'code': code!,
        if (headers != null) 'headers': headers!,
        if (size != null) 'size': size!,
        if (time != null) 'time': time!,
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
