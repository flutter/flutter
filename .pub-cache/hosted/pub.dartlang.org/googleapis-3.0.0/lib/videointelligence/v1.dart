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

/// Cloud Video Intelligence API - v1
///
/// Detects objects, explicit content, and scene changes in videos. It also
/// specifies the region for annotation and transcribes speech to text. Supports
/// both asynchronous API and streaming API.
///
/// For more information, see
/// <https://cloud.google.com/video-intelligence/docs/>
///
/// Create an instance of [CloudVideoIntelligenceApi] to access these resources:
///
/// - [OperationsResource]
///   - [OperationsProjectsResource]
///     - [OperationsProjectsLocationsResource]
///       - [OperationsProjectsLocationsOperationsResource]
/// - [ProjectsResource]
///   - [ProjectsLocationsResource]
///     - [ProjectsLocationsOperationsResource]
/// - [VideosResource]
library videointelligence.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Detects objects, explicit content, and scene changes in videos.
///
/// It also specifies the region for annotation and transcribes speech to text.
/// Supports both asynchronous API and streaming API.
class CloudVideoIntelligenceApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  final commons.ApiRequester _requester;

  OperationsResource get operations => OperationsResource(_requester);
  ProjectsResource get projects => ProjectsResource(_requester);
  VideosResource get videos => VideosResource(_requester);

  CloudVideoIntelligenceApi(http.Client client,
      {core.String rootUrl = 'https://videointelligence.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class OperationsResource {
  final commons.ApiRequester _requester;

  OperationsProjectsResource get projects =>
      OperationsProjectsResource(_requester);

  OperationsResource(commons.ApiRequester client) : _requester = client;
}

class OperationsProjectsResource {
  final commons.ApiRequester _requester;

  OperationsProjectsLocationsResource get locations =>
      OperationsProjectsLocationsResource(_requester);

  OperationsProjectsResource(commons.ApiRequester client) : _requester = client;
}

class OperationsProjectsLocationsResource {
  final commons.ApiRequester _requester;

  OperationsProjectsLocationsOperationsResource get operations =>
      OperationsProjectsLocationsOperationsResource(_requester);

  OperationsProjectsLocationsResource(commons.ApiRequester client)
      : _requester = client;
}

class OperationsProjectsLocationsOperationsResource {
  final commons.ApiRequester _requester;

  OperationsProjectsLocationsOperationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Starts asynchronous cancellation on a long-running operation.
  ///
  /// The server makes a best effort to cancel the operation, but success is not
  /// guaranteed. If the server doesn't support this method, it returns
  /// `google.rpc.Code.UNIMPLEMENTED`. Clients can use Operations.GetOperation
  /// or other methods to check whether the cancellation succeeded or whether
  /// the operation completed despite cancellation. On successful cancellation,
  /// the operation is not deleted; instead, it becomes an operation with an
  /// Operation.error value with a google.rpc.Status.code of 1, corresponding to
  /// `Code.CANCELLED`.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be cancelled.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
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
  async.Future<GoogleProtobufEmpty> cancel(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/operations/' + core.Uri.encodeFull('$name') + ':cancel';

    final _response = await _requester.request(
      _url,
      'POST',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a long-running operation.
  ///
  /// This method indicates that the client is no longer interested in the
  /// operation result. It does not cancel the operation. If the server doesn't
  /// support this method, it returns `google.rpc.Code.UNIMPLEMENTED`.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be deleted.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
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

    final _url = 'v1/operations/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Gets the latest state of a long-running operation.
  ///
  /// Clients can use this method to poll the operation result at intervals as
  /// recommended by the API service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> get(
    core.String name, {
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/operations/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsResource get locations =>
      ProjectsLocationsResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsOperationsResource get operations =>
      ProjectsLocationsOperationsResource(_requester);

  ProjectsLocationsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsLocationsOperationsResource {
  final commons.ApiRequester _requester;

  ProjectsLocationsOperationsResource(commons.ApiRequester client)
      : _requester = client;

  /// Starts asynchronous cancellation on a long-running operation.
  ///
  /// The server makes a best effort to cancel the operation, but success is not
  /// guaranteed. If the server doesn't support this method, it returns
  /// `google.rpc.Code.UNIMPLEMENTED`. Clients can use Operations.GetOperation
  /// or other methods to check whether the cancellation succeeded or whether
  /// the operation completed despite cancellation. On successful cancellation,
  /// the operation is not deleted; instead, it becomes an operation with an
  /// Operation.error value with a google.rpc.Status.code of 1, corresponding to
  /// `Code.CANCELLED`.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be cancelled.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
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
  async.Future<GoogleProtobufEmpty> cancel(
    GoogleLongrunningCancelOperationRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + ':cancel';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleProtobufEmpty.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a long-running operation.
  ///
  /// This method indicates that the client is no longer interested in the
  /// operation result. It does not cancel the operation. If the server doesn't
  /// support this method, it returns `google.rpc.Code.UNIMPLEMENTED`.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource to be deleted.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
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

  /// Gets the latest state of a long-running operation.
  ///
  /// Clients can use this method to poll the operation result at intervals as
  /// recommended by the API service.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation resource.
  /// Value must have pattern
  /// `^projects/\[^/\]+/locations/\[^/\]+/operations/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> get(
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
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }

  /// Lists operations that match the specified filter in the request.
  ///
  /// If the server doesn't support this method, it returns `UNIMPLEMENTED`.
  /// NOTE: the `name` binding allows API services to override the binding to
  /// use different resource name schemes, such as `users / * /operations`. To
  /// override the binding, API services can add a binding such as
  /// `"/v1/{name=users / * }/operations"` to their service configuration. For
  /// backwards compatibility, the default name includes the operations
  /// collection id, however overriding users must ensure the name binding is
  /// the parent resource, without the operations collection id.
  ///
  /// Request parameters:
  ///
  /// [name] - The name of the operation's parent resource.
  /// Value must have pattern `^projects/\[^/\]+/locations/\[^/\]+$`.
  ///
  /// [filter] - The standard list filter.
  ///
  /// [pageSize] - The standard list page size.
  ///
  /// [pageToken] - The standard list page token.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningListOperationsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningListOperationsResponse> list(
    core.String name, {
    core.String? filter,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (filter != null) 'filter': [filter],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/' + core.Uri.encodeFull('$name') + '/operations';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return GoogleLongrunningListOperationsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class VideosResource {
  final commons.ApiRequester _requester;

  VideosResource(commons.ApiRequester client) : _requester = client;

  /// Performs asynchronous video annotation.
  ///
  /// Progress and results can be retrieved through the
  /// `google.longrunning.Operations` interface. `Operation.metadata` contains
  /// `AnnotateVideoProgress` (progress). `Operation.response` contains
  /// `AnnotateVideoResponse` (results).
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [GoogleLongrunningOperation].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<GoogleLongrunningOperation> annotate(
    GoogleCloudVideointelligenceV1AnnotateVideoRequest request, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/videos:annotate';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return GoogleLongrunningOperation.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

/// Video annotation progress.
///
/// Included in the `metadata` field of the `Operation` returned by the
/// `GetOperation` call of the `google::longrunning::Operations` service.
class GoogleCloudVideointelligenceV1AnnotateVideoProgress {
  /// Progress metadata for all videos specified in `AnnotateVideoRequest`.
  core.List<GoogleCloudVideointelligenceV1VideoAnnotationProgress>?
      annotationProgress;

  GoogleCloudVideointelligenceV1AnnotateVideoProgress();

  GoogleCloudVideointelligenceV1AnnotateVideoProgress.fromJson(core.Map _json) {
    if (_json.containsKey('annotationProgress')) {
      annotationProgress = (_json['annotationProgress'] as core.List)
          .map<GoogleCloudVideointelligenceV1VideoAnnotationProgress>((value) =>
              GoogleCloudVideointelligenceV1VideoAnnotationProgress.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationProgress != null)
          'annotationProgress':
              annotationProgress!.map((value) => value.toJson()).toList(),
      };
}

/// Video annotation request.
class GoogleCloudVideointelligenceV1AnnotateVideoRequest {
  /// Requested video annotation features.
  ///
  /// Required.
  core.List<core.String>? features;

  /// The video data bytes.
  ///
  /// If unset, the input video(s) should be specified via the `input_uri`. If
  /// set, `input_uri` must be unset.
  core.String? inputContent;
  core.List<core.int> get inputContentAsBytes =>
      convert.base64.decode(inputContent!);

  set inputContentAsBytes(core.List<core.int> _bytes) {
    inputContent =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// Input video location.
  ///
  /// Currently, only [Cloud Storage](https://cloud.google.com/storage/) URIs
  /// are supported. URIs must be specified in the following format:
  /// `gs://bucket-id/object-id` (other URI formats return
  /// google.rpc.Code.INVALID_ARGUMENT). For more information, see
  /// [Request URIs](https://cloud.google.com/storage/docs/request-endpoints).
  /// To identify multiple videos, a video URI may include wildcards in the
  /// `object-id`. Supported wildcards: '*' to match 0 or more characters; '?'
  /// to match 1 character. If unset, the input video should be embedded in the
  /// request as `input_content`. If set, `input_content` must be unset.
  core.String? inputUri;

  /// Cloud region where annotation should take place.
  ///
  /// Supported cloud regions are: `us-east1`, `us-west1`, `europe-west1`,
  /// `asia-east1`. If no region is specified, the region will be determined
  /// based on video file location.
  ///
  /// Optional.
  core.String? locationId;

  /// Location where the output (in JSON format) should be stored.
  ///
  /// Currently, only [Cloud Storage](https://cloud.google.com/storage/) URIs
  /// are supported. These must be specified in the following format:
  /// `gs://bucket-id/object-id` (other URI formats return
  /// google.rpc.Code.INVALID_ARGUMENT). For more information, see
  /// [Request URIs](https://cloud.google.com/storage/docs/request-endpoints).
  ///
  /// Optional.
  core.String? outputUri;

  /// Additional video context and/or feature-specific parameters.
  GoogleCloudVideointelligenceV1VideoContext? videoContext;

  GoogleCloudVideointelligenceV1AnnotateVideoRequest();

  GoogleCloudVideointelligenceV1AnnotateVideoRequest.fromJson(core.Map _json) {
    if (_json.containsKey('features')) {
      features = (_json['features'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('inputContent')) {
      inputContent = _json['inputContent'] as core.String;
    }
    if (_json.containsKey('inputUri')) {
      inputUri = _json['inputUri'] as core.String;
    }
    if (_json.containsKey('locationId')) {
      locationId = _json['locationId'] as core.String;
    }
    if (_json.containsKey('outputUri')) {
      outputUri = _json['outputUri'] as core.String;
    }
    if (_json.containsKey('videoContext')) {
      videoContext = GoogleCloudVideointelligenceV1VideoContext.fromJson(
          _json['videoContext'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (features != null) 'features': features!,
        if (inputContent != null) 'inputContent': inputContent!,
        if (inputUri != null) 'inputUri': inputUri!,
        if (locationId != null) 'locationId': locationId!,
        if (outputUri != null) 'outputUri': outputUri!,
        if (videoContext != null) 'videoContext': videoContext!.toJson(),
      };
}

/// Video annotation response.
///
/// Included in the `response` field of the `Operation` returned by the
/// `GetOperation` call of the `google::longrunning::Operations` service.
class GoogleCloudVideointelligenceV1AnnotateVideoResponse {
  /// Annotation results for all videos specified in `AnnotateVideoRequest`.
  core.List<GoogleCloudVideointelligenceV1VideoAnnotationResults>?
      annotationResults;

  GoogleCloudVideointelligenceV1AnnotateVideoResponse();

  GoogleCloudVideointelligenceV1AnnotateVideoResponse.fromJson(core.Map _json) {
    if (_json.containsKey('annotationResults')) {
      annotationResults = (_json['annotationResults'] as core.List)
          .map<GoogleCloudVideointelligenceV1VideoAnnotationResults>((value) =>
              GoogleCloudVideointelligenceV1VideoAnnotationResults.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationResults != null)
          'annotationResults':
              annotationResults!.map((value) => value.toJson()).toList(),
      };
}

/// A generic detected attribute represented by name in string format.
class GoogleCloudVideointelligenceV1DetectedAttribute {
  /// Detected attribute confidence.
  ///
  /// Range \[0, 1\].
  core.double? confidence;

  /// The name of the attribute, for example, glasses, dark_glasses, mouth_open.
  ///
  /// A full list of supported type names will be provided in the document.
  core.String? name;

  /// Text value of the detection result.
  ///
  /// For example, the value for "HairColor" can be "black", "blonde", etc.
  core.String? value;

  GoogleCloudVideointelligenceV1DetectedAttribute();

  GoogleCloudVideointelligenceV1DetectedAttribute.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (name != null) 'name': name!,
        if (value != null) 'value': value!,
      };
}

/// A generic detected landmark represented by name in string format and a 2D
/// location.
class GoogleCloudVideointelligenceV1DetectedLandmark {
  /// The confidence score of the detected landmark.
  ///
  /// Range \[0, 1\].
  core.double? confidence;

  /// The name of this landmark, for example, left_hand, right_shoulder.
  core.String? name;

  /// The 2D point of the detected landmark using the normalized image
  /// coordindate system.
  ///
  /// The normalized coordinates have the range from 0 to 1.
  GoogleCloudVideointelligenceV1NormalizedVertex? point;

  GoogleCloudVideointelligenceV1DetectedLandmark();

  GoogleCloudVideointelligenceV1DetectedLandmark.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('point')) {
      point = GoogleCloudVideointelligenceV1NormalizedVertex.fromJson(
          _json['point'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (name != null) 'name': name!,
        if (point != null) 'point': point!.toJson(),
      };
}

/// Detected entity from video analysis.
class GoogleCloudVideointelligenceV1Entity {
  /// Textual description, e.g., `Fixed-gear bicycle`.
  core.String? description;

  /// Opaque entity ID.
  ///
  /// Some IDs may be available in
  /// [Google Knowledge Graph Search API](https://developers.google.com/knowledge-graph/).
  core.String? entityId;

  /// Language code for `description` in BCP-47 format.
  core.String? languageCode;

  GoogleCloudVideointelligenceV1Entity();

  GoogleCloudVideointelligenceV1Entity.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('entityId')) {
      entityId = _json['entityId'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (entityId != null) 'entityId': entityId!,
        if (languageCode != null) 'languageCode': languageCode!,
      };
}

/// Explicit content annotation (based on per-frame visual signals only).
///
/// If no explicit content has been detected in a frame, no annotations are
/// present for that frame.
class GoogleCloudVideointelligenceV1ExplicitContentAnnotation {
  /// All video frames where explicit content was detected.
  core.List<GoogleCloudVideointelligenceV1ExplicitContentFrame>? frames;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1ExplicitContentAnnotation();

  GoogleCloudVideointelligenceV1ExplicitContentAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1ExplicitContentFrame>((value) =>
              GoogleCloudVideointelligenceV1ExplicitContentFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Config for EXPLICIT_CONTENT_DETECTION.
class GoogleCloudVideointelligenceV1ExplicitContentDetectionConfig {
  /// Model to use for explicit content detection.
  ///
  /// Supported values: "builtin/stable" (the default if unset) and
  /// "builtin/latest".
  core.String? model;

  GoogleCloudVideointelligenceV1ExplicitContentDetectionConfig();

  GoogleCloudVideointelligenceV1ExplicitContentDetectionConfig.fromJson(
      core.Map _json) {
    if (_json.containsKey('model')) {
      model = _json['model'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (model != null) 'model': model!,
      };
}

/// Video frame level annotation results for explicit content.
class GoogleCloudVideointelligenceV1ExplicitContentFrame {
  /// Likelihood of the pornography content..
  /// Possible string values are:
  /// - "LIKELIHOOD_UNSPECIFIED" : Unspecified likelihood.
  /// - "VERY_UNLIKELY" : Very unlikely.
  /// - "UNLIKELY" : Unlikely.
  /// - "POSSIBLE" : Possible.
  /// - "LIKELY" : Likely.
  /// - "VERY_LIKELY" : Very likely.
  core.String? pornographyLikelihood;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1ExplicitContentFrame();

  GoogleCloudVideointelligenceV1ExplicitContentFrame.fromJson(core.Map _json) {
    if (_json.containsKey('pornographyLikelihood')) {
      pornographyLikelihood = _json['pornographyLikelihood'] as core.String;
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pornographyLikelihood != null)
          'pornographyLikelihood': pornographyLikelihood!,
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// No effect.
///
/// Deprecated.
class GoogleCloudVideointelligenceV1FaceAnnotation {
  /// All video frames where a face was detected.
  core.List<GoogleCloudVideointelligenceV1FaceFrame>? frames;

  /// All video segments where a face was detected.
  core.List<GoogleCloudVideointelligenceV1FaceSegment>? segments;

  /// Thumbnail of a representative face view (in JPEG format).
  core.String? thumbnail;
  core.List<core.int> get thumbnailAsBytes => convert.base64.decode(thumbnail!);

  set thumbnailAsBytes(core.List<core.int> _bytes) {
    thumbnail =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  GoogleCloudVideointelligenceV1FaceAnnotation();

  GoogleCloudVideointelligenceV1FaceAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1FaceFrame>((value) =>
              GoogleCloudVideointelligenceV1FaceFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1FaceSegment>((value) =>
              GoogleCloudVideointelligenceV1FaceSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('thumbnail')) {
      thumbnail = _json['thumbnail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (thumbnail != null) 'thumbnail': thumbnail!,
      };
}

/// Face detection annotation.
class GoogleCloudVideointelligenceV1FaceDetectionAnnotation {
  /// The thumbnail of a person's face.
  core.String? thumbnail;
  core.List<core.int> get thumbnailAsBytes => convert.base64.decode(thumbnail!);

  set thumbnailAsBytes(core.List<core.int> _bytes) {
    thumbnail =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The face tracks with attributes.
  core.List<GoogleCloudVideointelligenceV1Track>? tracks;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1FaceDetectionAnnotation();

  GoogleCloudVideointelligenceV1FaceDetectionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('thumbnail')) {
      thumbnail = _json['thumbnail'] as core.String;
    }
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1Track>((value) =>
              GoogleCloudVideointelligenceV1Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (thumbnail != null) 'thumbnail': thumbnail!,
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Config for FACE_DETECTION.
class GoogleCloudVideointelligenceV1FaceDetectionConfig {
  /// Whether to enable face attributes detection, such as glasses,
  /// dark_glasses, mouth_open etc.
  ///
  /// Ignored if 'include_bounding_boxes' is set to false.
  core.bool? includeAttributes;

  /// Whether bounding boxes are included in the face annotation output.
  core.bool? includeBoundingBoxes;

  /// Model to use for face detection.
  ///
  /// Supported values: "builtin/stable" (the default if unset) and
  /// "builtin/latest".
  core.String? model;

  GoogleCloudVideointelligenceV1FaceDetectionConfig();

  GoogleCloudVideointelligenceV1FaceDetectionConfig.fromJson(core.Map _json) {
    if (_json.containsKey('includeAttributes')) {
      includeAttributes = _json['includeAttributes'] as core.bool;
    }
    if (_json.containsKey('includeBoundingBoxes')) {
      includeBoundingBoxes = _json['includeBoundingBoxes'] as core.bool;
    }
    if (_json.containsKey('model')) {
      model = _json['model'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (includeAttributes != null) 'includeAttributes': includeAttributes!,
        if (includeBoundingBoxes != null)
          'includeBoundingBoxes': includeBoundingBoxes!,
        if (model != null) 'model': model!,
      };
}

/// No effect.
///
/// Deprecated.
class GoogleCloudVideointelligenceV1FaceFrame {
  /// Normalized Bounding boxes in a frame.
  ///
  /// There can be more than one boxes if the same face is detected in multiple
  /// locations within the current frame.
  core.List<GoogleCloudVideointelligenceV1NormalizedBoundingBox>?
      normalizedBoundingBoxes;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1FaceFrame();

  GoogleCloudVideointelligenceV1FaceFrame.fromJson(core.Map _json) {
    if (_json.containsKey('normalizedBoundingBoxes')) {
      normalizedBoundingBoxes = (_json['normalizedBoundingBoxes'] as core.List)
          .map<GoogleCloudVideointelligenceV1NormalizedBoundingBox>((value) =>
              GoogleCloudVideointelligenceV1NormalizedBoundingBox.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (normalizedBoundingBoxes != null)
          'normalizedBoundingBoxes':
              normalizedBoundingBoxes!.map((value) => value.toJson()).toList(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for face detection.
class GoogleCloudVideointelligenceV1FaceSegment {
  /// Video segment where a face was detected.
  GoogleCloudVideointelligenceV1VideoSegment? segment;

  GoogleCloudVideointelligenceV1FaceSegment();

  GoogleCloudVideointelligenceV1FaceSegment.fromJson(core.Map _json) {
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// Label annotation.
class GoogleCloudVideointelligenceV1LabelAnnotation {
  /// Common categories for the detected entity.
  ///
  /// For example, when the label is `Terrier`, the category is likely `dog`.
  /// And in some cases there might be more than one categories e.g., `Terrier`
  /// could also be a `pet`.
  core.List<GoogleCloudVideointelligenceV1Entity>? categoryEntities;

  /// Detected entity.
  GoogleCloudVideointelligenceV1Entity? entity;

  /// All video frames where a label was detected.
  core.List<GoogleCloudVideointelligenceV1LabelFrame>? frames;

  /// All video segments where a label was detected.
  core.List<GoogleCloudVideointelligenceV1LabelSegment>? segments;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1LabelAnnotation();

  GoogleCloudVideointelligenceV1LabelAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('categoryEntities')) {
      categoryEntities = (_json['categoryEntities'] as core.List)
          .map<GoogleCloudVideointelligenceV1Entity>((value) =>
              GoogleCloudVideointelligenceV1Entity.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1LabelFrame>((value) =>
              GoogleCloudVideointelligenceV1LabelFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1LabelSegment>((value) =>
              GoogleCloudVideointelligenceV1LabelSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (categoryEntities != null)
          'categoryEntities':
              categoryEntities!.map((value) => value.toJson()).toList(),
        if (entity != null) 'entity': entity!.toJson(),
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Config for LABEL_DETECTION.
class GoogleCloudVideointelligenceV1LabelDetectionConfig {
  /// The confidence threshold we perform filtering on the labels from
  /// frame-level detection.
  ///
  /// If not set, it is set to 0.4 by default. The valid range for this
  /// threshold is \[0.1, 0.9\]. Any value set outside of this range will be
  /// clipped. Note: For best results, follow the default threshold. We will
  /// update the default threshold everytime when we release a new model.
  core.double? frameConfidenceThreshold;

  /// What labels should be detected with LABEL_DETECTION, in addition to
  /// video-level labels or segment-level labels.
  ///
  /// If unspecified, defaults to `SHOT_MODE`.
  /// Possible string values are:
  /// - "LABEL_DETECTION_MODE_UNSPECIFIED" : Unspecified.
  /// - "SHOT_MODE" : Detect shot-level labels.
  /// - "FRAME_MODE" : Detect frame-level labels.
  /// - "SHOT_AND_FRAME_MODE" : Detect both shot-level and frame-level labels.
  core.String? labelDetectionMode;

  /// Model to use for label detection.
  ///
  /// Supported values: "builtin/stable" (the default if unset) and
  /// "builtin/latest".
  core.String? model;

  /// Whether the video has been shot from a stationary (i.e., non-moving)
  /// camera.
  ///
  /// When set to true, might improve detection accuracy for moving objects.
  /// Should be used with `SHOT_AND_FRAME_MODE` enabled.
  core.bool? stationaryCamera;

  /// The confidence threshold we perform filtering on the labels from
  /// video-level and shot-level detections.
  ///
  /// If not set, it's set to 0.3 by default. The valid range for this threshold
  /// is \[0.1, 0.9\]. Any value set outside of this range will be clipped.
  /// Note: For best results, follow the default threshold. We will update the
  /// default threshold everytime when we release a new model.
  core.double? videoConfidenceThreshold;

  GoogleCloudVideointelligenceV1LabelDetectionConfig();

  GoogleCloudVideointelligenceV1LabelDetectionConfig.fromJson(core.Map _json) {
    if (_json.containsKey('frameConfidenceThreshold')) {
      frameConfidenceThreshold =
          (_json['frameConfidenceThreshold'] as core.num).toDouble();
    }
    if (_json.containsKey('labelDetectionMode')) {
      labelDetectionMode = _json['labelDetectionMode'] as core.String;
    }
    if (_json.containsKey('model')) {
      model = _json['model'] as core.String;
    }
    if (_json.containsKey('stationaryCamera')) {
      stationaryCamera = _json['stationaryCamera'] as core.bool;
    }
    if (_json.containsKey('videoConfidenceThreshold')) {
      videoConfidenceThreshold =
          (_json['videoConfidenceThreshold'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (frameConfidenceThreshold != null)
          'frameConfidenceThreshold': frameConfidenceThreshold!,
        if (labelDetectionMode != null)
          'labelDetectionMode': labelDetectionMode!,
        if (model != null) 'model': model!,
        if (stationaryCamera != null) 'stationaryCamera': stationaryCamera!,
        if (videoConfidenceThreshold != null)
          'videoConfidenceThreshold': videoConfidenceThreshold!,
      };
}

/// Video frame level annotation results for label detection.
class GoogleCloudVideointelligenceV1LabelFrame {
  /// Confidence that the label is accurate.
  ///
  /// Range: \[0, 1\].
  core.double? confidence;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1LabelFrame();

  GoogleCloudVideointelligenceV1LabelFrame.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for label detection.
class GoogleCloudVideointelligenceV1LabelSegment {
  /// Confidence that the label is accurate.
  ///
  /// Range: \[0, 1\].
  core.double? confidence;

  /// Video segment where a label was detected.
  GoogleCloudVideointelligenceV1VideoSegment? segment;

  GoogleCloudVideointelligenceV1LabelSegment();

  GoogleCloudVideointelligenceV1LabelSegment.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// Annotation corresponding to one detected, tracked and recognized logo class.
class GoogleCloudVideointelligenceV1LogoRecognitionAnnotation {
  /// Entity category information to specify the logo class that all the logo
  /// tracks within this LogoRecognitionAnnotation are recognized as.
  GoogleCloudVideointelligenceV1Entity? entity;

  /// All video segments where the recognized logo appears.
  ///
  /// There might be multiple instances of the same logo class appearing in one
  /// VideoSegment.
  core.List<GoogleCloudVideointelligenceV1VideoSegment>? segments;

  /// All logo tracks where the recognized logo appears.
  ///
  /// Each track corresponds to one logo instance appearing in consecutive
  /// frames.
  core.List<GoogleCloudVideointelligenceV1Track>? tracks;

  GoogleCloudVideointelligenceV1LogoRecognitionAnnotation();

  GoogleCloudVideointelligenceV1LogoRecognitionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1VideoSegment>((value) =>
              GoogleCloudVideointelligenceV1VideoSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1Track>((value) =>
              GoogleCloudVideointelligenceV1Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entity != null) 'entity': entity!.toJson(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
      };
}

/// Normalized bounding box.
///
/// The normalized vertex coordinates are relative to the original image. Range:
/// \[0, 1\].
class GoogleCloudVideointelligenceV1NormalizedBoundingBox {
  /// Bottom Y coordinate.
  core.double? bottom;

  /// Left X coordinate.
  core.double? left;

  /// Right X coordinate.
  core.double? right;

  /// Top Y coordinate.
  core.double? top;

  GoogleCloudVideointelligenceV1NormalizedBoundingBox();

  GoogleCloudVideointelligenceV1NormalizedBoundingBox.fromJson(core.Map _json) {
    if (_json.containsKey('bottom')) {
      bottom = (_json['bottom'] as core.num).toDouble();
    }
    if (_json.containsKey('left')) {
      left = (_json['left'] as core.num).toDouble();
    }
    if (_json.containsKey('right')) {
      right = (_json['right'] as core.num).toDouble();
    }
    if (_json.containsKey('top')) {
      top = (_json['top'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bottom != null) 'bottom': bottom!,
        if (left != null) 'left': left!,
        if (right != null) 'right': right!,
        if (top != null) 'top': top!,
      };
}

/// Normalized bounding polygon for text (that might not be aligned with axis).
///
/// Contains list of the corner points in clockwise order starting from top-left
/// corner. For example, for a rectangular bounding box: When the text is
/// horizontal it might look like: 0----1 | | 3----2 When it's clockwise rotated
/// 180 degrees around the top-left corner it becomes: 2----3 | | 1----0 and the
/// vertex order will still be (0, 1, 2, 3). Note that values can be less than
/// 0, or greater than 1 due to trignometric calculations for location of the
/// box.
class GoogleCloudVideointelligenceV1NormalizedBoundingPoly {
  /// Normalized vertices of the bounding polygon.
  core.List<GoogleCloudVideointelligenceV1NormalizedVertex>? vertices;

  GoogleCloudVideointelligenceV1NormalizedBoundingPoly();

  GoogleCloudVideointelligenceV1NormalizedBoundingPoly.fromJson(
      core.Map _json) {
    if (_json.containsKey('vertices')) {
      vertices = (_json['vertices'] as core.List)
          .map<GoogleCloudVideointelligenceV1NormalizedVertex>((value) =>
              GoogleCloudVideointelligenceV1NormalizedVertex.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (vertices != null)
          'vertices': vertices!.map((value) => value.toJson()).toList(),
      };
}

/// A vertex represents a 2D point in the image.
///
/// NOTE: the normalized vertex coordinates are relative to the original image
/// and range from 0 to 1.
class GoogleCloudVideointelligenceV1NormalizedVertex {
  /// X coordinate.
  core.double? x;

  /// Y coordinate.
  core.double? y;

  GoogleCloudVideointelligenceV1NormalizedVertex();

  GoogleCloudVideointelligenceV1NormalizedVertex.fromJson(core.Map _json) {
    if (_json.containsKey('x')) {
      x = (_json['x'] as core.num).toDouble();
    }
    if (_json.containsKey('y')) {
      y = (_json['y'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (x != null) 'x': x!,
        if (y != null) 'y': y!,
      };
}

/// Annotations corresponding to one tracked object.
class GoogleCloudVideointelligenceV1ObjectTrackingAnnotation {
  /// Object category's labeling confidence of this track.
  core.double? confidence;

  /// Entity to specify the object category that this track is labeled as.
  GoogleCloudVideointelligenceV1Entity? entity;

  /// Information corresponding to all frames where this object track appears.
  ///
  /// Non-streaming batch mode: it may be one or multiple ObjectTrackingFrame
  /// messages in frames. Streaming mode: it can only be one ObjectTrackingFrame
  /// message in frames.
  core.List<GoogleCloudVideointelligenceV1ObjectTrackingFrame>? frames;

  /// Non-streaming batch mode ONLY.
  ///
  /// Each object track corresponds to one video segment where it appears.
  GoogleCloudVideointelligenceV1VideoSegment? segment;

  /// Streaming mode ONLY.
  ///
  /// In streaming mode, we do not know the end time of a tracked object before
  /// it is completed. Hence, there is no VideoSegment info returned. Instead,
  /// we provide a unique identifiable integer track_id so that the customers
  /// can correlate the results of the ongoing ObjectTrackAnnotation of the same
  /// track_id over time.
  core.String? trackId;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1ObjectTrackingAnnotation();

  GoogleCloudVideointelligenceV1ObjectTrackingAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1ObjectTrackingFrame>((value) =>
              GoogleCloudVideointelligenceV1ObjectTrackingFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('trackId')) {
      trackId = _json['trackId'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (entity != null) 'entity': entity!.toJson(),
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segment != null) 'segment': segment!.toJson(),
        if (trackId != null) 'trackId': trackId!,
        if (version != null) 'version': version!,
      };
}

/// Config for OBJECT_TRACKING.
class GoogleCloudVideointelligenceV1ObjectTrackingConfig {
  /// Model to use for object tracking.
  ///
  /// Supported values: "builtin/stable" (the default if unset) and
  /// "builtin/latest".
  core.String? model;

  GoogleCloudVideointelligenceV1ObjectTrackingConfig();

  GoogleCloudVideointelligenceV1ObjectTrackingConfig.fromJson(core.Map _json) {
    if (_json.containsKey('model')) {
      model = _json['model'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (model != null) 'model': model!,
      };
}

/// Video frame level annotations for object detection and tracking.
///
/// This field stores per frame location, time offset, and confidence.
class GoogleCloudVideointelligenceV1ObjectTrackingFrame {
  /// The normalized bounding box location of this object track for the frame.
  GoogleCloudVideointelligenceV1NormalizedBoundingBox? normalizedBoundingBox;

  /// The timestamp of the frame in microseconds.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1ObjectTrackingFrame();

  GoogleCloudVideointelligenceV1ObjectTrackingFrame.fromJson(core.Map _json) {
    if (_json.containsKey('normalizedBoundingBox')) {
      normalizedBoundingBox =
          GoogleCloudVideointelligenceV1NormalizedBoundingBox.fromJson(
              _json['normalizedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (normalizedBoundingBox != null)
          'normalizedBoundingBox': normalizedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Person detection annotation per video.
class GoogleCloudVideointelligenceV1PersonDetectionAnnotation {
  /// The detected tracks of a person.
  core.List<GoogleCloudVideointelligenceV1Track>? tracks;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1PersonDetectionAnnotation();

  GoogleCloudVideointelligenceV1PersonDetectionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1Track>((value) =>
              GoogleCloudVideointelligenceV1Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Config for PERSON_DETECTION.
class GoogleCloudVideointelligenceV1PersonDetectionConfig {
  /// Whether to enable person attributes detection, such as cloth color (black,
  /// blue, etc), type (coat, dress, etc), pattern (plain, floral, etc), hair,
  /// etc.
  ///
  /// Ignored if 'include_bounding_boxes' is set to false.
  core.bool? includeAttributes;

  /// Whether bounding boxes are included in the person detection annotation
  /// output.
  core.bool? includeBoundingBoxes;

  /// Whether to enable pose landmarks detection.
  ///
  /// Ignored if 'include_bounding_boxes' is set to false.
  core.bool? includePoseLandmarks;

  GoogleCloudVideointelligenceV1PersonDetectionConfig();

  GoogleCloudVideointelligenceV1PersonDetectionConfig.fromJson(core.Map _json) {
    if (_json.containsKey('includeAttributes')) {
      includeAttributes = _json['includeAttributes'] as core.bool;
    }
    if (_json.containsKey('includeBoundingBoxes')) {
      includeBoundingBoxes = _json['includeBoundingBoxes'] as core.bool;
    }
    if (_json.containsKey('includePoseLandmarks')) {
      includePoseLandmarks = _json['includePoseLandmarks'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (includeAttributes != null) 'includeAttributes': includeAttributes!,
        if (includeBoundingBoxes != null)
          'includeBoundingBoxes': includeBoundingBoxes!,
        if (includePoseLandmarks != null)
          'includePoseLandmarks': includePoseLandmarks!,
      };
}

/// Config for SHOT_CHANGE_DETECTION.
class GoogleCloudVideointelligenceV1ShotChangeDetectionConfig {
  /// Model to use for shot change detection.
  ///
  /// Supported values: "builtin/stable" (the default if unset) and
  /// "builtin/latest".
  core.String? model;

  GoogleCloudVideointelligenceV1ShotChangeDetectionConfig();

  GoogleCloudVideointelligenceV1ShotChangeDetectionConfig.fromJson(
      core.Map _json) {
    if (_json.containsKey('model')) {
      model = _json['model'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (model != null) 'model': model!,
      };
}

/// Provides "hints" to the speech recognizer to favor specific words and
/// phrases in the results.
class GoogleCloudVideointelligenceV1SpeechContext {
  /// A list of strings containing words and phrases "hints" so that the speech
  /// recognition is more likely to recognize them.
  ///
  /// This can be used to improve the accuracy for specific words and phrases,
  /// for example, if specific commands are typically spoken by the user. This
  /// can also be used to add additional words to the vocabulary of the
  /// recognizer. See
  /// [usage limits](https://cloud.google.com/speech/limits#content).
  ///
  /// Optional.
  core.List<core.String>? phrases;

  GoogleCloudVideointelligenceV1SpeechContext();

  GoogleCloudVideointelligenceV1SpeechContext.fromJson(core.Map _json) {
    if (_json.containsKey('phrases')) {
      phrases = (_json['phrases'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (phrases != null) 'phrases': phrases!,
      };
}

/// Alternative hypotheses (a.k.a. n-best list).
class GoogleCloudVideointelligenceV1SpeechRecognitionAlternative {
  /// The confidence estimate between 0.0 and 1.0.
  ///
  /// A higher number indicates an estimated greater likelihood that the
  /// recognized words are correct. This field is set only for the top
  /// alternative. This field is not guaranteed to be accurate and users should
  /// not rely on it to be always provided. The default of 0.0 is a sentinel
  /// value indicating `confidence` was not set.
  ///
  /// Output only.
  core.double? confidence;

  /// Transcript text representing the words that the user spoke.
  core.String? transcript;

  /// A list of word-specific information for each recognized word.
  ///
  /// Note: When `enable_speaker_diarization` is set to true, you will see all
  /// the words from the beginning of the audio.
  ///
  /// Output only.
  core.List<GoogleCloudVideointelligenceV1WordInfo>? words;

  GoogleCloudVideointelligenceV1SpeechRecognitionAlternative();

  GoogleCloudVideointelligenceV1SpeechRecognitionAlternative.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('transcript')) {
      transcript = _json['transcript'] as core.String;
    }
    if (_json.containsKey('words')) {
      words = (_json['words'] as core.List)
          .map<GoogleCloudVideointelligenceV1WordInfo>((value) =>
              GoogleCloudVideointelligenceV1WordInfo.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (transcript != null) 'transcript': transcript!,
        if (words != null)
          'words': words!.map((value) => value.toJson()).toList(),
      };
}

/// A speech recognition result corresponding to a portion of the audio.
class GoogleCloudVideointelligenceV1SpeechTranscription {
  /// May contain one or more recognition hypotheses (up to the maximum
  /// specified in `max_alternatives`).
  ///
  /// These alternatives are ordered in terms of accuracy, with the top (first)
  /// alternative being the most probable, as ranked by the recognizer.
  core.List<GoogleCloudVideointelligenceV1SpeechRecognitionAlternative>?
      alternatives;

  /// The \[BCP-47\](https://www.rfc-editor.org/rfc/bcp/bcp47.txt) language tag
  /// of the language in this result.
  ///
  /// This language code was detected to have the most likelihood of being
  /// spoken in the audio.
  ///
  /// Output only.
  core.String? languageCode;

  GoogleCloudVideointelligenceV1SpeechTranscription();

  GoogleCloudVideointelligenceV1SpeechTranscription.fromJson(core.Map _json) {
    if (_json.containsKey('alternatives')) {
      alternatives = (_json['alternatives'] as core.List)
          .map<GoogleCloudVideointelligenceV1SpeechRecognitionAlternative>(
              (value) =>
                  GoogleCloudVideointelligenceV1SpeechRecognitionAlternative
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alternatives != null)
          'alternatives': alternatives!.map((value) => value.toJson()).toList(),
        if (languageCode != null) 'languageCode': languageCode!,
      };
}

/// Config for SPEECH_TRANSCRIPTION.
class GoogleCloudVideointelligenceV1SpeechTranscriptionConfig {
  /// For file formats, such as MXF or MKV, supporting multiple audio tracks,
  /// specify up to two tracks.
  ///
  /// Default: track 0.
  ///
  /// Optional.
  core.List<core.int>? audioTracks;

  /// If set, specifies the estimated number of speakers in the conversation.
  ///
  /// If not set, defaults to '2'. Ignored unless enable_speaker_diarization is
  /// set to true.
  ///
  /// Optional.
  core.int? diarizationSpeakerCount;

  /// If 'true', adds punctuation to recognition result hypotheses.
  ///
  /// This feature is only available in select languages. Setting this for
  /// requests in other languages has no effect at all. The default 'false'
  /// value does not add punctuation to result hypotheses. NOTE: "This is
  /// currently offered as an experimental service, complimentary to all users.
  /// In the future this may be exclusively available as a premium feature."
  ///
  /// Optional.
  core.bool? enableAutomaticPunctuation;

  /// If 'true', enables speaker detection for each recognized word in the top
  /// alternative of the recognition result using a speaker_tag provided in the
  /// WordInfo.
  ///
  /// Note: When this is true, we send all the words from the beginning of the
  /// audio for the top alternative in every consecutive response. This is done
  /// in order to improve our speaker tags as our models learn to identify the
  /// speakers in the conversation over time.
  ///
  /// Optional.
  core.bool? enableSpeakerDiarization;

  /// If `true`, the top result includes a list of words and the confidence for
  /// those words.
  ///
  /// If `false`, no word-level confidence information is returned. The default
  /// is `false`.
  ///
  /// Optional.
  core.bool? enableWordConfidence;

  /// If set to `true`, the server will attempt to filter out profanities,
  /// replacing all but the initial character in each filtered word with
  /// asterisks, e.g. "f***".
  ///
  /// If set to `false` or omitted, profanities won't be filtered out.
  ///
  /// Optional.
  core.bool? filterProfanity;

  /// *Required* The language of the supplied audio as a
  /// \[BCP-47\](https://www.rfc-editor.org/rfc/bcp/bcp47.txt) language tag.
  ///
  /// Example: "en-US". See
  /// [Language Support](https://cloud.google.com/speech/docs/languages) for a
  /// list of the currently supported language codes.
  ///
  /// Required.
  core.String? languageCode;

  /// Maximum number of recognition hypotheses to be returned.
  ///
  /// Specifically, the maximum number of `SpeechRecognitionAlternative`
  /// messages within each `SpeechTranscription`. The server may return fewer
  /// than `max_alternatives`. Valid values are `0`-`30`. A value of `0` or `1`
  /// will return a maximum of one. If omitted, will return a maximum of one.
  ///
  /// Optional.
  core.int? maxAlternatives;

  /// A means to provide context to assist the speech recognition.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1SpeechContext>? speechContexts;

  GoogleCloudVideointelligenceV1SpeechTranscriptionConfig();

  GoogleCloudVideointelligenceV1SpeechTranscriptionConfig.fromJson(
      core.Map _json) {
    if (_json.containsKey('audioTracks')) {
      audioTracks = (_json['audioTracks'] as core.List)
          .map<core.int>((value) => value as core.int)
          .toList();
    }
    if (_json.containsKey('diarizationSpeakerCount')) {
      diarizationSpeakerCount = _json['diarizationSpeakerCount'] as core.int;
    }
    if (_json.containsKey('enableAutomaticPunctuation')) {
      enableAutomaticPunctuation =
          _json['enableAutomaticPunctuation'] as core.bool;
    }
    if (_json.containsKey('enableSpeakerDiarization')) {
      enableSpeakerDiarization = _json['enableSpeakerDiarization'] as core.bool;
    }
    if (_json.containsKey('enableWordConfidence')) {
      enableWordConfidence = _json['enableWordConfidence'] as core.bool;
    }
    if (_json.containsKey('filterProfanity')) {
      filterProfanity = _json['filterProfanity'] as core.bool;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
    if (_json.containsKey('maxAlternatives')) {
      maxAlternatives = _json['maxAlternatives'] as core.int;
    }
    if (_json.containsKey('speechContexts')) {
      speechContexts = (_json['speechContexts'] as core.List)
          .map<GoogleCloudVideointelligenceV1SpeechContext>((value) =>
              GoogleCloudVideointelligenceV1SpeechContext.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (audioTracks != null) 'audioTracks': audioTracks!,
        if (diarizationSpeakerCount != null)
          'diarizationSpeakerCount': diarizationSpeakerCount!,
        if (enableAutomaticPunctuation != null)
          'enableAutomaticPunctuation': enableAutomaticPunctuation!,
        if (enableSpeakerDiarization != null)
          'enableSpeakerDiarization': enableSpeakerDiarization!,
        if (enableWordConfidence != null)
          'enableWordConfidence': enableWordConfidence!,
        if (filterProfanity != null) 'filterProfanity': filterProfanity!,
        if (languageCode != null) 'languageCode': languageCode!,
        if (maxAlternatives != null) 'maxAlternatives': maxAlternatives!,
        if (speechContexts != null)
          'speechContexts':
              speechContexts!.map((value) => value.toJson()).toList(),
      };
}

/// Annotations related to one detected OCR text snippet.
///
/// This will contain the corresponding text, confidence value, and frame level
/// information for each detection.
class GoogleCloudVideointelligenceV1TextAnnotation {
  /// All video segments where OCR detected text appears.
  core.List<GoogleCloudVideointelligenceV1TextSegment>? segments;

  /// The detected text.
  core.String? text;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1TextAnnotation();

  GoogleCloudVideointelligenceV1TextAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1TextSegment>((value) =>
              GoogleCloudVideointelligenceV1TextSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (text != null) 'text': text!,
        if (version != null) 'version': version!,
      };
}

/// Config for TEXT_DETECTION.
class GoogleCloudVideointelligenceV1TextDetectionConfig {
  /// Language hint can be specified if the language to be detected is known a
  /// priori.
  ///
  /// It can increase the accuracy of the detection. Language hint must be
  /// language code in BCP-47 format. Automatic language detection is performed
  /// if no hint is provided.
  core.List<core.String>? languageHints;

  /// Model to use for text detection.
  ///
  /// Supported values: "builtin/stable" (the default if unset) and
  /// "builtin/latest".
  core.String? model;

  GoogleCloudVideointelligenceV1TextDetectionConfig();

  GoogleCloudVideointelligenceV1TextDetectionConfig.fromJson(core.Map _json) {
    if (_json.containsKey('languageHints')) {
      languageHints = (_json['languageHints'] as core.List)
          .map<core.String>((value) => value as core.String)
          .toList();
    }
    if (_json.containsKey('model')) {
      model = _json['model'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (languageHints != null) 'languageHints': languageHints!,
        if (model != null) 'model': model!,
      };
}

/// Video frame level annotation results for text annotation (OCR).
///
/// Contains information regarding timestamp and bounding box locations for the
/// frames containing detected OCR text snippets.
class GoogleCloudVideointelligenceV1TextFrame {
  /// Bounding polygon of the detected text for this frame.
  GoogleCloudVideointelligenceV1NormalizedBoundingPoly? rotatedBoundingBox;

  /// Timestamp of this frame.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1TextFrame();

  GoogleCloudVideointelligenceV1TextFrame.fromJson(core.Map _json) {
    if (_json.containsKey('rotatedBoundingBox')) {
      rotatedBoundingBox =
          GoogleCloudVideointelligenceV1NormalizedBoundingPoly.fromJson(
              _json['rotatedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rotatedBoundingBox != null)
          'rotatedBoundingBox': rotatedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for text detection.
class GoogleCloudVideointelligenceV1TextSegment {
  /// Confidence for the track of detected text.
  ///
  /// It is calculated as the highest over all frames where OCR detected text
  /// appears.
  core.double? confidence;

  /// Information related to the frames where OCR detected text appears.
  core.List<GoogleCloudVideointelligenceV1TextFrame>? frames;

  /// Video segment where a text snippet was detected.
  GoogleCloudVideointelligenceV1VideoSegment? segment;

  GoogleCloudVideointelligenceV1TextSegment();

  GoogleCloudVideointelligenceV1TextSegment.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1TextFrame>((value) =>
              GoogleCloudVideointelligenceV1TextFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// For tracking related features.
///
/// An object at time_offset with attributes, and located with
/// normalized_bounding_box.
class GoogleCloudVideointelligenceV1TimestampedObject {
  /// The attributes of the object in the bounding box.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1DetectedAttribute>? attributes;

  /// The detected landmarks.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1DetectedLandmark>? landmarks;

  /// Normalized Bounding box in a frame, where the object is located.
  GoogleCloudVideointelligenceV1NormalizedBoundingBox? normalizedBoundingBox;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this object.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1TimestampedObject();

  GoogleCloudVideointelligenceV1TimestampedObject.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = (_json['attributes'] as core.List)
          .map<GoogleCloudVideointelligenceV1DetectedAttribute>((value) =>
              GoogleCloudVideointelligenceV1DetectedAttribute.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('landmarks')) {
      landmarks = (_json['landmarks'] as core.List)
          .map<GoogleCloudVideointelligenceV1DetectedLandmark>((value) =>
              GoogleCloudVideointelligenceV1DetectedLandmark.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('normalizedBoundingBox')) {
      normalizedBoundingBox =
          GoogleCloudVideointelligenceV1NormalizedBoundingBox.fromJson(
              _json['normalizedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null)
          'attributes': attributes!.map((value) => value.toJson()).toList(),
        if (landmarks != null)
          'landmarks': landmarks!.map((value) => value.toJson()).toList(),
        if (normalizedBoundingBox != null)
          'normalizedBoundingBox': normalizedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// A track of an object instance.
class GoogleCloudVideointelligenceV1Track {
  /// Attributes in the track level.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1DetectedAttribute>? attributes;

  /// The confidence score of the tracked object.
  ///
  /// Optional.
  core.double? confidence;

  /// Video segment of a track.
  GoogleCloudVideointelligenceV1VideoSegment? segment;

  /// The object with timestamp and attributes per frame in the track.
  core.List<GoogleCloudVideointelligenceV1TimestampedObject>?
      timestampedObjects;

  GoogleCloudVideointelligenceV1Track();

  GoogleCloudVideointelligenceV1Track.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = (_json['attributes'] as core.List)
          .map<GoogleCloudVideointelligenceV1DetectedAttribute>((value) =>
              GoogleCloudVideointelligenceV1DetectedAttribute.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timestampedObjects')) {
      timestampedObjects = (_json['timestampedObjects'] as core.List)
          .map<GoogleCloudVideointelligenceV1TimestampedObject>((value) =>
              GoogleCloudVideointelligenceV1TimestampedObject.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null)
          'attributes': attributes!.map((value) => value.toJson()).toList(),
        if (confidence != null) 'confidence': confidence!,
        if (segment != null) 'segment': segment!.toJson(),
        if (timestampedObjects != null)
          'timestampedObjects':
              timestampedObjects!.map((value) => value.toJson()).toList(),
      };
}

/// Annotation progress for a single video.
class GoogleCloudVideointelligenceV1VideoAnnotationProgress {
  /// Specifies which feature is being tracked if the request contains more than
  /// one feature.
  /// Possible string values are:
  /// - "FEATURE_UNSPECIFIED" : Unspecified.
  /// - "LABEL_DETECTION" : Label detection. Detect objects, such as dog or
  /// flower.
  /// - "SHOT_CHANGE_DETECTION" : Shot change detection.
  /// - "EXPLICIT_CONTENT_DETECTION" : Explicit content detection.
  /// - "FACE_DETECTION" : Human face detection.
  /// - "SPEECH_TRANSCRIPTION" : Speech transcription.
  /// - "TEXT_DETECTION" : OCR text detection and tracking.
  /// - "OBJECT_TRACKING" : Object detection and tracking.
  /// - "LOGO_RECOGNITION" : Logo detection, tracking, and recognition.
  /// - "PERSON_DETECTION" : Person detection.
  core.String? feature;

  /// Video file location in [Cloud Storage](https://cloud.google.com/storage/).
  core.String? inputUri;

  /// Approximate percentage processed thus far.
  ///
  /// Guaranteed to be 100 when fully processed.
  core.int? progressPercent;

  /// Specifies which segment is being tracked if the request contains more than
  /// one segment.
  GoogleCloudVideointelligenceV1VideoSegment? segment;

  /// Time when the request was received.
  core.String? startTime;

  /// Time of the most recent update.
  core.String? updateTime;

  GoogleCloudVideointelligenceV1VideoAnnotationProgress();

  GoogleCloudVideointelligenceV1VideoAnnotationProgress.fromJson(
      core.Map _json) {
    if (_json.containsKey('feature')) {
      feature = _json['feature'] as core.String;
    }
    if (_json.containsKey('inputUri')) {
      inputUri = _json['inputUri'] as core.String;
    }
    if (_json.containsKey('progressPercent')) {
      progressPercent = _json['progressPercent'] as core.int;
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (feature != null) 'feature': feature!,
        if (inputUri != null) 'inputUri': inputUri!,
        if (progressPercent != null) 'progressPercent': progressPercent!,
        if (segment != null) 'segment': segment!.toJson(),
        if (startTime != null) 'startTime': startTime!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Annotation results for a single video.
class GoogleCloudVideointelligenceV1VideoAnnotationResults {
  /// If set, indicates an error.
  ///
  /// Note that for a single `AnnotateVideoRequest` some videos may succeed and
  /// some may fail.
  GoogleRpcStatus? error;

  /// Explicit content annotation.
  GoogleCloudVideointelligenceV1ExplicitContentAnnotation? explicitAnnotation;

  /// Please use `face_detection_annotations` instead.
  ///
  /// Deprecated.
  core.List<GoogleCloudVideointelligenceV1FaceAnnotation>? faceAnnotations;

  /// Face detection annotations.
  core.List<GoogleCloudVideointelligenceV1FaceDetectionAnnotation>?
      faceDetectionAnnotations;

  /// Label annotations on frame level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1LabelAnnotation>?
      frameLabelAnnotations;

  /// Video file location in [Cloud Storage](https://cloud.google.com/storage/).
  core.String? inputUri;

  /// Annotations for list of logos detected, tracked and recognized in video.
  core.List<GoogleCloudVideointelligenceV1LogoRecognitionAnnotation>?
      logoRecognitionAnnotations;

  /// Annotations for list of objects detected and tracked in video.
  core.List<GoogleCloudVideointelligenceV1ObjectTrackingAnnotation>?
      objectAnnotations;

  /// Person detection annotations.
  core.List<GoogleCloudVideointelligenceV1PersonDetectionAnnotation>?
      personDetectionAnnotations;

  /// Video segment on which the annotation is run.
  GoogleCloudVideointelligenceV1VideoSegment? segment;

  /// Topical label annotations on video level or user-specified segment level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1LabelAnnotation>?
      segmentLabelAnnotations;

  /// Presence label annotations on video level or user-specified segment level.
  ///
  /// There is exactly one element for each unique label. Compared to the
  /// existing topical `segment_label_annotations`, this field presents more
  /// fine-grained, segment-level labels detected in video content and is made
  /// available only when the client sets `LabelDetectionConfig.model` to
  /// "builtin/latest" in the request.
  core.List<GoogleCloudVideointelligenceV1LabelAnnotation>?
      segmentPresenceLabelAnnotations;

  /// Shot annotations.
  ///
  /// Each shot is represented as a video segment.
  core.List<GoogleCloudVideointelligenceV1VideoSegment>? shotAnnotations;

  /// Topical label annotations on shot level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1LabelAnnotation>?
      shotLabelAnnotations;

  /// Presence label annotations on shot level.
  ///
  /// There is exactly one element for each unique label. Compared to the
  /// existing topical `shot_label_annotations`, this field presents more
  /// fine-grained, shot-level labels detected in video content and is made
  /// available only when the client sets `LabelDetectionConfig.model` to
  /// "builtin/latest" in the request.
  core.List<GoogleCloudVideointelligenceV1LabelAnnotation>?
      shotPresenceLabelAnnotations;

  /// Speech transcription.
  core.List<GoogleCloudVideointelligenceV1SpeechTranscription>?
      speechTranscriptions;

  /// OCR text detection and tracking.
  ///
  /// Annotations for list of detected text snippets. Each will have list of
  /// frame information associated with it.
  core.List<GoogleCloudVideointelligenceV1TextAnnotation>? textAnnotations;

  GoogleCloudVideointelligenceV1VideoAnnotationResults();

  GoogleCloudVideointelligenceV1VideoAnnotationResults.fromJson(
      core.Map _json) {
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('explicitAnnotation')) {
      explicitAnnotation =
          GoogleCloudVideointelligenceV1ExplicitContentAnnotation.fromJson(
              _json['explicitAnnotation']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('faceAnnotations')) {
      faceAnnotations = (_json['faceAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1FaceAnnotation>((value) =>
              GoogleCloudVideointelligenceV1FaceAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('faceDetectionAnnotations')) {
      faceDetectionAnnotations = (_json['faceDetectionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1FaceDetectionAnnotation>((value) =>
              GoogleCloudVideointelligenceV1FaceDetectionAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('frameLabelAnnotations')) {
      frameLabelAnnotations = (_json['frameLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('inputUri')) {
      inputUri = _json['inputUri'] as core.String;
    }
    if (_json.containsKey('logoRecognitionAnnotations')) {
      logoRecognitionAnnotations = (_json['logoRecognitionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1LogoRecognitionAnnotation>(
              (value) => GoogleCloudVideointelligenceV1LogoRecognitionAnnotation
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('objectAnnotations')) {
      objectAnnotations = (_json['objectAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1ObjectTrackingAnnotation>(
              (value) => GoogleCloudVideointelligenceV1ObjectTrackingAnnotation
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('personDetectionAnnotations')) {
      personDetectionAnnotations = (_json['personDetectionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1PersonDetectionAnnotation>(
              (value) => GoogleCloudVideointelligenceV1PersonDetectionAnnotation
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('segmentLabelAnnotations')) {
      segmentLabelAnnotations = (_json['segmentLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segmentPresenceLabelAnnotations')) {
      segmentPresenceLabelAnnotations =
          (_json['segmentPresenceLabelAnnotations'] as core.List)
              .map<GoogleCloudVideointelligenceV1LabelAnnotation>((value) =>
                  GoogleCloudVideointelligenceV1LabelAnnotation.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('shotAnnotations')) {
      shotAnnotations = (_json['shotAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1VideoSegment>((value) =>
              GoogleCloudVideointelligenceV1VideoSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotLabelAnnotations')) {
      shotLabelAnnotations = (_json['shotLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotPresenceLabelAnnotations')) {
      shotPresenceLabelAnnotations =
          (_json['shotPresenceLabelAnnotations'] as core.List)
              .map<GoogleCloudVideointelligenceV1LabelAnnotation>((value) =>
                  GoogleCloudVideointelligenceV1LabelAnnotation.fromJson(
                      value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('speechTranscriptions')) {
      speechTranscriptions = (_json['speechTranscriptions'] as core.List)
          .map<GoogleCloudVideointelligenceV1SpeechTranscription>((value) =>
              GoogleCloudVideointelligenceV1SpeechTranscription.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('textAnnotations')) {
      textAnnotations = (_json['textAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1TextAnnotation>((value) =>
              GoogleCloudVideointelligenceV1TextAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (error != null) 'error': error!.toJson(),
        if (explicitAnnotation != null)
          'explicitAnnotation': explicitAnnotation!.toJson(),
        if (faceAnnotations != null)
          'faceAnnotations':
              faceAnnotations!.map((value) => value.toJson()).toList(),
        if (faceDetectionAnnotations != null)
          'faceDetectionAnnotations':
              faceDetectionAnnotations!.map((value) => value.toJson()).toList(),
        if (frameLabelAnnotations != null)
          'frameLabelAnnotations':
              frameLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (inputUri != null) 'inputUri': inputUri!,
        if (logoRecognitionAnnotations != null)
          'logoRecognitionAnnotations': logoRecognitionAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (objectAnnotations != null)
          'objectAnnotations':
              objectAnnotations!.map((value) => value.toJson()).toList(),
        if (personDetectionAnnotations != null)
          'personDetectionAnnotations': personDetectionAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (segment != null) 'segment': segment!.toJson(),
        if (segmentLabelAnnotations != null)
          'segmentLabelAnnotations':
              segmentLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (segmentPresenceLabelAnnotations != null)
          'segmentPresenceLabelAnnotations': segmentPresenceLabelAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (shotAnnotations != null)
          'shotAnnotations':
              shotAnnotations!.map((value) => value.toJson()).toList(),
        if (shotLabelAnnotations != null)
          'shotLabelAnnotations':
              shotLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (shotPresenceLabelAnnotations != null)
          'shotPresenceLabelAnnotations': shotPresenceLabelAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (speechTranscriptions != null)
          'speechTranscriptions':
              speechTranscriptions!.map((value) => value.toJson()).toList(),
        if (textAnnotations != null)
          'textAnnotations':
              textAnnotations!.map((value) => value.toJson()).toList(),
      };
}

/// Video context and/or feature-specific parameters.
class GoogleCloudVideointelligenceV1VideoContext {
  /// Config for EXPLICIT_CONTENT_DETECTION.
  GoogleCloudVideointelligenceV1ExplicitContentDetectionConfig?
      explicitContentDetectionConfig;

  /// Config for FACE_DETECTION.
  GoogleCloudVideointelligenceV1FaceDetectionConfig? faceDetectionConfig;

  /// Config for LABEL_DETECTION.
  GoogleCloudVideointelligenceV1LabelDetectionConfig? labelDetectionConfig;

  /// Config for OBJECT_TRACKING.
  GoogleCloudVideointelligenceV1ObjectTrackingConfig? objectTrackingConfig;

  /// Config for PERSON_DETECTION.
  GoogleCloudVideointelligenceV1PersonDetectionConfig? personDetectionConfig;

  /// Video segments to annotate.
  ///
  /// The segments may overlap and are not required to be contiguous or span the
  /// whole video. If unspecified, each video is treated as a single segment.
  core.List<GoogleCloudVideointelligenceV1VideoSegment>? segments;

  /// Config for SHOT_CHANGE_DETECTION.
  GoogleCloudVideointelligenceV1ShotChangeDetectionConfig?
      shotChangeDetectionConfig;

  /// Config for SPEECH_TRANSCRIPTION.
  GoogleCloudVideointelligenceV1SpeechTranscriptionConfig?
      speechTranscriptionConfig;

  /// Config for TEXT_DETECTION.
  GoogleCloudVideointelligenceV1TextDetectionConfig? textDetectionConfig;

  GoogleCloudVideointelligenceV1VideoContext();

  GoogleCloudVideointelligenceV1VideoContext.fromJson(core.Map _json) {
    if (_json.containsKey('explicitContentDetectionConfig')) {
      explicitContentDetectionConfig =
          GoogleCloudVideointelligenceV1ExplicitContentDetectionConfig.fromJson(
              _json['explicitContentDetectionConfig']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('faceDetectionConfig')) {
      faceDetectionConfig =
          GoogleCloudVideointelligenceV1FaceDetectionConfig.fromJson(
              _json['faceDetectionConfig']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('labelDetectionConfig')) {
      labelDetectionConfig =
          GoogleCloudVideointelligenceV1LabelDetectionConfig.fromJson(
              _json['labelDetectionConfig']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectTrackingConfig')) {
      objectTrackingConfig =
          GoogleCloudVideointelligenceV1ObjectTrackingConfig.fromJson(
              _json['objectTrackingConfig']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('personDetectionConfig')) {
      personDetectionConfig =
          GoogleCloudVideointelligenceV1PersonDetectionConfig.fromJson(
              _json['personDetectionConfig']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1VideoSegment>((value) =>
              GoogleCloudVideointelligenceV1VideoSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotChangeDetectionConfig')) {
      shotChangeDetectionConfig =
          GoogleCloudVideointelligenceV1ShotChangeDetectionConfig.fromJson(
              _json['shotChangeDetectionConfig']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('speechTranscriptionConfig')) {
      speechTranscriptionConfig =
          GoogleCloudVideointelligenceV1SpeechTranscriptionConfig.fromJson(
              _json['speechTranscriptionConfig']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('textDetectionConfig')) {
      textDetectionConfig =
          GoogleCloudVideointelligenceV1TextDetectionConfig.fromJson(
              _json['textDetectionConfig']
                  as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (explicitContentDetectionConfig != null)
          'explicitContentDetectionConfig':
              explicitContentDetectionConfig!.toJson(),
        if (faceDetectionConfig != null)
          'faceDetectionConfig': faceDetectionConfig!.toJson(),
        if (labelDetectionConfig != null)
          'labelDetectionConfig': labelDetectionConfig!.toJson(),
        if (objectTrackingConfig != null)
          'objectTrackingConfig': objectTrackingConfig!.toJson(),
        if (personDetectionConfig != null)
          'personDetectionConfig': personDetectionConfig!.toJson(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (shotChangeDetectionConfig != null)
          'shotChangeDetectionConfig': shotChangeDetectionConfig!.toJson(),
        if (speechTranscriptionConfig != null)
          'speechTranscriptionConfig': speechTranscriptionConfig!.toJson(),
        if (textDetectionConfig != null)
          'textDetectionConfig': textDetectionConfig!.toJson(),
      };
}

/// Video segment.
class GoogleCloudVideointelligenceV1VideoSegment {
  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// end of the segment (inclusive).
  core.String? endTimeOffset;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// start of the segment (inclusive).
  core.String? startTimeOffset;

  GoogleCloudVideointelligenceV1VideoSegment();

  GoogleCloudVideointelligenceV1VideoSegment.fromJson(core.Map _json) {
    if (_json.containsKey('endTimeOffset')) {
      endTimeOffset = _json['endTimeOffset'] as core.String;
    }
    if (_json.containsKey('startTimeOffset')) {
      startTimeOffset = _json['startTimeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTimeOffset != null) 'endTimeOffset': endTimeOffset!,
        if (startTimeOffset != null) 'startTimeOffset': startTimeOffset!,
      };
}

/// Word-specific information for recognized words.
///
/// Word information is only included in the response when certain request
/// parameters are set, such as `enable_word_time_offsets`.
class GoogleCloudVideointelligenceV1WordInfo {
  /// The confidence estimate between 0.0 and 1.0.
  ///
  /// A higher number indicates an estimated greater likelihood that the
  /// recognized words are correct. This field is set only for the top
  /// alternative. This field is not guaranteed to be accurate and users should
  /// not rely on it to be always provided. The default of 0.0 is a sentinel
  /// value indicating `confidence` was not set.
  ///
  /// Output only.
  core.double? confidence;

  /// Time offset relative to the beginning of the audio, and corresponding to
  /// the end of the spoken word.
  ///
  /// This field is only set if `enable_word_time_offsets=true` and only in the
  /// top hypothesis. This is an experimental feature and the accuracy of the
  /// time offset can vary.
  core.String? endTime;

  /// A distinct integer value is assigned for every speaker within the audio.
  ///
  /// This field specifies which one of those speakers was detected to have
  /// spoken this word. Value ranges from 1 up to diarization_speaker_count, and
  /// is only set if speaker diarization is enabled.
  ///
  /// Output only.
  core.int? speakerTag;

  /// Time offset relative to the beginning of the audio, and corresponding to
  /// the start of the spoken word.
  ///
  /// This field is only set if `enable_word_time_offsets=true` and only in the
  /// top hypothesis. This is an experimental feature and the accuracy of the
  /// time offset can vary.
  core.String? startTime;

  /// The word corresponding to this set of information.
  core.String? word;

  GoogleCloudVideointelligenceV1WordInfo();

  GoogleCloudVideointelligenceV1WordInfo.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('speakerTag')) {
      speakerTag = _json['speakerTag'] as core.int;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('word')) {
      word = _json['word'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (endTime != null) 'endTime': endTime!,
        if (speakerTag != null) 'speakerTag': speakerTag!,
        if (startTime != null) 'startTime': startTime!,
        if (word != null) 'word': word!,
      };
}

/// Video annotation progress.
///
/// Included in the `metadata` field of the `Operation` returned by the
/// `GetOperation` call of the `google::longrunning::Operations` service.
class GoogleCloudVideointelligenceV1beta2AnnotateVideoProgress {
  /// Progress metadata for all videos specified in `AnnotateVideoRequest`.
  core.List<GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress>?
      annotationProgress;

  GoogleCloudVideointelligenceV1beta2AnnotateVideoProgress();

  GoogleCloudVideointelligenceV1beta2AnnotateVideoProgress.fromJson(
      core.Map _json) {
    if (_json.containsKey('annotationProgress')) {
      annotationProgress = (_json['annotationProgress'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress>(
              (value) =>
                  GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationProgress != null)
          'annotationProgress':
              annotationProgress!.map((value) => value.toJson()).toList(),
      };
}

/// Video annotation response.
///
/// Included in the `response` field of the `Operation` returned by the
/// `GetOperation` call of the `google::longrunning::Operations` service.
class GoogleCloudVideointelligenceV1beta2AnnotateVideoResponse {
  /// Annotation results for all videos specified in `AnnotateVideoRequest`.
  core.List<GoogleCloudVideointelligenceV1beta2VideoAnnotationResults>?
      annotationResults;

  GoogleCloudVideointelligenceV1beta2AnnotateVideoResponse();

  GoogleCloudVideointelligenceV1beta2AnnotateVideoResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('annotationResults')) {
      annotationResults = (_json['annotationResults'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2VideoAnnotationResults>(
              (value) =>
                  GoogleCloudVideointelligenceV1beta2VideoAnnotationResults
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationResults != null)
          'annotationResults':
              annotationResults!.map((value) => value.toJson()).toList(),
      };
}

/// A generic detected attribute represented by name in string format.
class GoogleCloudVideointelligenceV1beta2DetectedAttribute {
  /// Detected attribute confidence.
  ///
  /// Range \[0, 1\].
  core.double? confidence;

  /// The name of the attribute, for example, glasses, dark_glasses, mouth_open.
  ///
  /// A full list of supported type names will be provided in the document.
  core.String? name;

  /// Text value of the detection result.
  ///
  /// For example, the value for "HairColor" can be "black", "blonde", etc.
  core.String? value;

  GoogleCloudVideointelligenceV1beta2DetectedAttribute();

  GoogleCloudVideointelligenceV1beta2DetectedAttribute.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (name != null) 'name': name!,
        if (value != null) 'value': value!,
      };
}

/// A generic detected landmark represented by name in string format and a 2D
/// location.
class GoogleCloudVideointelligenceV1beta2DetectedLandmark {
  /// The confidence score of the detected landmark.
  ///
  /// Range \[0, 1\].
  core.double? confidence;

  /// The name of this landmark, for example, left_hand, right_shoulder.
  core.String? name;

  /// The 2D point of the detected landmark using the normalized image
  /// coordindate system.
  ///
  /// The normalized coordinates have the range from 0 to 1.
  GoogleCloudVideointelligenceV1beta2NormalizedVertex? point;

  GoogleCloudVideointelligenceV1beta2DetectedLandmark();

  GoogleCloudVideointelligenceV1beta2DetectedLandmark.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('point')) {
      point = GoogleCloudVideointelligenceV1beta2NormalizedVertex.fromJson(
          _json['point'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (name != null) 'name': name!,
        if (point != null) 'point': point!.toJson(),
      };
}

/// Detected entity from video analysis.
class GoogleCloudVideointelligenceV1beta2Entity {
  /// Textual description, e.g., `Fixed-gear bicycle`.
  core.String? description;

  /// Opaque entity ID.
  ///
  /// Some IDs may be available in
  /// [Google Knowledge Graph Search API](https://developers.google.com/knowledge-graph/).
  core.String? entityId;

  /// Language code for `description` in BCP-47 format.
  core.String? languageCode;

  GoogleCloudVideointelligenceV1beta2Entity();

  GoogleCloudVideointelligenceV1beta2Entity.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('entityId')) {
      entityId = _json['entityId'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (entityId != null) 'entityId': entityId!,
        if (languageCode != null) 'languageCode': languageCode!,
      };
}

/// Explicit content annotation (based on per-frame visual signals only).
///
/// If no explicit content has been detected in a frame, no annotations are
/// present for that frame.
class GoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation {
  /// All video frames where explicit content was detected.
  core.List<GoogleCloudVideointelligenceV1beta2ExplicitContentFrame>? frames;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation();

  GoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2ExplicitContentFrame>(
              (value) => GoogleCloudVideointelligenceV1beta2ExplicitContentFrame
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotation results for explicit content.
class GoogleCloudVideointelligenceV1beta2ExplicitContentFrame {
  /// Likelihood of the pornography content..
  /// Possible string values are:
  /// - "LIKELIHOOD_UNSPECIFIED" : Unspecified likelihood.
  /// - "VERY_UNLIKELY" : Very unlikely.
  /// - "UNLIKELY" : Unlikely.
  /// - "POSSIBLE" : Possible.
  /// - "LIKELY" : Likely.
  /// - "VERY_LIKELY" : Very likely.
  core.String? pornographyLikelihood;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1beta2ExplicitContentFrame();

  GoogleCloudVideointelligenceV1beta2ExplicitContentFrame.fromJson(
      core.Map _json) {
    if (_json.containsKey('pornographyLikelihood')) {
      pornographyLikelihood = _json['pornographyLikelihood'] as core.String;
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pornographyLikelihood != null)
          'pornographyLikelihood': pornographyLikelihood!,
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// No effect.
///
/// Deprecated.
class GoogleCloudVideointelligenceV1beta2FaceAnnotation {
  /// All video frames where a face was detected.
  core.List<GoogleCloudVideointelligenceV1beta2FaceFrame>? frames;

  /// All video segments where a face was detected.
  core.List<GoogleCloudVideointelligenceV1beta2FaceSegment>? segments;

  /// Thumbnail of a representative face view (in JPEG format).
  core.String? thumbnail;
  core.List<core.int> get thumbnailAsBytes => convert.base64.decode(thumbnail!);

  set thumbnailAsBytes(core.List<core.int> _bytes) {
    thumbnail =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  GoogleCloudVideointelligenceV1beta2FaceAnnotation();

  GoogleCloudVideointelligenceV1beta2FaceAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2FaceFrame>((value) =>
              GoogleCloudVideointelligenceV1beta2FaceFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2FaceSegment>((value) =>
              GoogleCloudVideointelligenceV1beta2FaceSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('thumbnail')) {
      thumbnail = _json['thumbnail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (thumbnail != null) 'thumbnail': thumbnail!,
      };
}

/// Face detection annotation.
class GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation {
  /// The thumbnail of a person's face.
  core.String? thumbnail;
  core.List<core.int> get thumbnailAsBytes => convert.base64.decode(thumbnail!);

  set thumbnailAsBytes(core.List<core.int> _bytes) {
    thumbnail =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The face tracks with attributes.
  core.List<GoogleCloudVideointelligenceV1beta2Track>? tracks;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation();

  GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('thumbnail')) {
      thumbnail = _json['thumbnail'] as core.String;
    }
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2Track>((value) =>
              GoogleCloudVideointelligenceV1beta2Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (thumbnail != null) 'thumbnail': thumbnail!,
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// No effect.
///
/// Deprecated.
class GoogleCloudVideointelligenceV1beta2FaceFrame {
  /// Normalized Bounding boxes in a frame.
  ///
  /// There can be more than one boxes if the same face is detected in multiple
  /// locations within the current frame.
  core.List<GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox>?
      normalizedBoundingBoxes;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1beta2FaceFrame();

  GoogleCloudVideointelligenceV1beta2FaceFrame.fromJson(core.Map _json) {
    if (_json.containsKey('normalizedBoundingBoxes')) {
      normalizedBoundingBoxes = (_json['normalizedBoundingBoxes'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox>(
              (value) =>
                  GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (normalizedBoundingBoxes != null)
          'normalizedBoundingBoxes':
              normalizedBoundingBoxes!.map((value) => value.toJson()).toList(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for face detection.
class GoogleCloudVideointelligenceV1beta2FaceSegment {
  /// Video segment where a face was detected.
  GoogleCloudVideointelligenceV1beta2VideoSegment? segment;

  GoogleCloudVideointelligenceV1beta2FaceSegment();

  GoogleCloudVideointelligenceV1beta2FaceSegment.fromJson(core.Map _json) {
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1beta2VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// Label annotation.
class GoogleCloudVideointelligenceV1beta2LabelAnnotation {
  /// Common categories for the detected entity.
  ///
  /// For example, when the label is `Terrier`, the category is likely `dog`.
  /// And in some cases there might be more than one categories e.g., `Terrier`
  /// could also be a `pet`.
  core.List<GoogleCloudVideointelligenceV1beta2Entity>? categoryEntities;

  /// Detected entity.
  GoogleCloudVideointelligenceV1beta2Entity? entity;

  /// All video frames where a label was detected.
  core.List<GoogleCloudVideointelligenceV1beta2LabelFrame>? frames;

  /// All video segments where a label was detected.
  core.List<GoogleCloudVideointelligenceV1beta2LabelSegment>? segments;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1beta2LabelAnnotation();

  GoogleCloudVideointelligenceV1beta2LabelAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('categoryEntities')) {
      categoryEntities = (_json['categoryEntities'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2Entity>((value) =>
              GoogleCloudVideointelligenceV1beta2Entity.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1beta2Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2LabelFrame>((value) =>
              GoogleCloudVideointelligenceV1beta2LabelFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2LabelSegment>((value) =>
              GoogleCloudVideointelligenceV1beta2LabelSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (categoryEntities != null)
          'categoryEntities':
              categoryEntities!.map((value) => value.toJson()).toList(),
        if (entity != null) 'entity': entity!.toJson(),
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotation results for label detection.
class GoogleCloudVideointelligenceV1beta2LabelFrame {
  /// Confidence that the label is accurate.
  ///
  /// Range: \[0, 1\].
  core.double? confidence;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1beta2LabelFrame();

  GoogleCloudVideointelligenceV1beta2LabelFrame.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for label detection.
class GoogleCloudVideointelligenceV1beta2LabelSegment {
  /// Confidence that the label is accurate.
  ///
  /// Range: \[0, 1\].
  core.double? confidence;

  /// Video segment where a label was detected.
  GoogleCloudVideointelligenceV1beta2VideoSegment? segment;

  GoogleCloudVideointelligenceV1beta2LabelSegment();

  GoogleCloudVideointelligenceV1beta2LabelSegment.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1beta2VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// Annotation corresponding to one detected, tracked and recognized logo class.
class GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation {
  /// Entity category information to specify the logo class that all the logo
  /// tracks within this LogoRecognitionAnnotation are recognized as.
  GoogleCloudVideointelligenceV1beta2Entity? entity;

  /// All video segments where the recognized logo appears.
  ///
  /// There might be multiple instances of the same logo class appearing in one
  /// VideoSegment.
  core.List<GoogleCloudVideointelligenceV1beta2VideoSegment>? segments;

  /// All logo tracks where the recognized logo appears.
  ///
  /// Each track corresponds to one logo instance appearing in consecutive
  /// frames.
  core.List<GoogleCloudVideointelligenceV1beta2Track>? tracks;

  GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation();

  GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1beta2Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2VideoSegment>((value) =>
              GoogleCloudVideointelligenceV1beta2VideoSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2Track>((value) =>
              GoogleCloudVideointelligenceV1beta2Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entity != null) 'entity': entity!.toJson(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
      };
}

/// Normalized bounding box.
///
/// The normalized vertex coordinates are relative to the original image. Range:
/// \[0, 1\].
class GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox {
  /// Bottom Y coordinate.
  core.double? bottom;

  /// Left X coordinate.
  core.double? left;

  /// Right X coordinate.
  core.double? right;

  /// Top Y coordinate.
  core.double? top;

  GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox();

  GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox.fromJson(
      core.Map _json) {
    if (_json.containsKey('bottom')) {
      bottom = (_json['bottom'] as core.num).toDouble();
    }
    if (_json.containsKey('left')) {
      left = (_json['left'] as core.num).toDouble();
    }
    if (_json.containsKey('right')) {
      right = (_json['right'] as core.num).toDouble();
    }
    if (_json.containsKey('top')) {
      top = (_json['top'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bottom != null) 'bottom': bottom!,
        if (left != null) 'left': left!,
        if (right != null) 'right': right!,
        if (top != null) 'top': top!,
      };
}

/// Normalized bounding polygon for text (that might not be aligned with axis).
///
/// Contains list of the corner points in clockwise order starting from top-left
/// corner. For example, for a rectangular bounding box: When the text is
/// horizontal it might look like: 0----1 | | 3----2 When it's clockwise rotated
/// 180 degrees around the top-left corner it becomes: 2----3 | | 1----0 and the
/// vertex order will still be (0, 1, 2, 3). Note that values can be less than
/// 0, or greater than 1 due to trignometric calculations for location of the
/// box.
class GoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly {
  /// Normalized vertices of the bounding polygon.
  core.List<GoogleCloudVideointelligenceV1beta2NormalizedVertex>? vertices;

  GoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly();

  GoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly.fromJson(
      core.Map _json) {
    if (_json.containsKey('vertices')) {
      vertices = (_json['vertices'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2NormalizedVertex>((value) =>
              GoogleCloudVideointelligenceV1beta2NormalizedVertex.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (vertices != null)
          'vertices': vertices!.map((value) => value.toJson()).toList(),
      };
}

/// A vertex represents a 2D point in the image.
///
/// NOTE: the normalized vertex coordinates are relative to the original image
/// and range from 0 to 1.
class GoogleCloudVideointelligenceV1beta2NormalizedVertex {
  /// X coordinate.
  core.double? x;

  /// Y coordinate.
  core.double? y;

  GoogleCloudVideointelligenceV1beta2NormalizedVertex();

  GoogleCloudVideointelligenceV1beta2NormalizedVertex.fromJson(core.Map _json) {
    if (_json.containsKey('x')) {
      x = (_json['x'] as core.num).toDouble();
    }
    if (_json.containsKey('y')) {
      y = (_json['y'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (x != null) 'x': x!,
        if (y != null) 'y': y!,
      };
}

/// Annotations corresponding to one tracked object.
class GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation {
  /// Object category's labeling confidence of this track.
  core.double? confidence;

  /// Entity to specify the object category that this track is labeled as.
  GoogleCloudVideointelligenceV1beta2Entity? entity;

  /// Information corresponding to all frames where this object track appears.
  ///
  /// Non-streaming batch mode: it may be one or multiple ObjectTrackingFrame
  /// messages in frames. Streaming mode: it can only be one ObjectTrackingFrame
  /// message in frames.
  core.List<GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame>? frames;

  /// Non-streaming batch mode ONLY.
  ///
  /// Each object track corresponds to one video segment where it appears.
  GoogleCloudVideointelligenceV1beta2VideoSegment? segment;

  /// Streaming mode ONLY.
  ///
  /// In streaming mode, we do not know the end time of a tracked object before
  /// it is completed. Hence, there is no VideoSegment info returned. Instead,
  /// we provide a unique identifiable integer track_id so that the customers
  /// can correlate the results of the ongoing ObjectTrackAnnotation of the same
  /// track_id over time.
  core.String? trackId;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation();

  GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1beta2Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame>(
              (value) => GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1beta2VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('trackId')) {
      trackId = _json['trackId'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (entity != null) 'entity': entity!.toJson(),
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segment != null) 'segment': segment!.toJson(),
        if (trackId != null) 'trackId': trackId!,
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotations for object detection and tracking.
///
/// This field stores per frame location, time offset, and confidence.
class GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame {
  /// The normalized bounding box location of this object track for the frame.
  GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox?
      normalizedBoundingBox;

  /// The timestamp of the frame in microseconds.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame();

  GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame.fromJson(
      core.Map _json) {
    if (_json.containsKey('normalizedBoundingBox')) {
      normalizedBoundingBox =
          GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox.fromJson(
              _json['normalizedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (normalizedBoundingBox != null)
          'normalizedBoundingBox': normalizedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Person detection annotation per video.
class GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation {
  /// The detected tracks of a person.
  core.List<GoogleCloudVideointelligenceV1beta2Track>? tracks;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation();

  GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2Track>((value) =>
              GoogleCloudVideointelligenceV1beta2Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Alternative hypotheses (a.k.a. n-best list).
class GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative {
  /// The confidence estimate between 0.0 and 1.0.
  ///
  /// A higher number indicates an estimated greater likelihood that the
  /// recognized words are correct. This field is set only for the top
  /// alternative. This field is not guaranteed to be accurate and users should
  /// not rely on it to be always provided. The default of 0.0 is a sentinel
  /// value indicating `confidence` was not set.
  ///
  /// Output only.
  core.double? confidence;

  /// Transcript text representing the words that the user spoke.
  core.String? transcript;

  /// A list of word-specific information for each recognized word.
  ///
  /// Note: When `enable_speaker_diarization` is set to true, you will see all
  /// the words from the beginning of the audio.
  ///
  /// Output only.
  core.List<GoogleCloudVideointelligenceV1beta2WordInfo>? words;

  GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative();

  GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('transcript')) {
      transcript = _json['transcript'] as core.String;
    }
    if (_json.containsKey('words')) {
      words = (_json['words'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2WordInfo>((value) =>
              GoogleCloudVideointelligenceV1beta2WordInfo.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (transcript != null) 'transcript': transcript!,
        if (words != null)
          'words': words!.map((value) => value.toJson()).toList(),
      };
}

/// A speech recognition result corresponding to a portion of the audio.
class GoogleCloudVideointelligenceV1beta2SpeechTranscription {
  /// May contain one or more recognition hypotheses (up to the maximum
  /// specified in `max_alternatives`).
  ///
  /// These alternatives are ordered in terms of accuracy, with the top (first)
  /// alternative being the most probable, as ranked by the recognizer.
  core.List<GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative>?
      alternatives;

  /// The \[BCP-47\](https://www.rfc-editor.org/rfc/bcp/bcp47.txt) language tag
  /// of the language in this result.
  ///
  /// This language code was detected to have the most likelihood of being
  /// spoken in the audio.
  ///
  /// Output only.
  core.String? languageCode;

  GoogleCloudVideointelligenceV1beta2SpeechTranscription();

  GoogleCloudVideointelligenceV1beta2SpeechTranscription.fromJson(
      core.Map _json) {
    if (_json.containsKey('alternatives')) {
      alternatives = (_json['alternatives'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative>(
              (value) =>
                  GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alternatives != null)
          'alternatives': alternatives!.map((value) => value.toJson()).toList(),
        if (languageCode != null) 'languageCode': languageCode!,
      };
}

/// Annotations related to one detected OCR text snippet.
///
/// This will contain the corresponding text, confidence value, and frame level
/// information for each detection.
class GoogleCloudVideointelligenceV1beta2TextAnnotation {
  /// All video segments where OCR detected text appears.
  core.List<GoogleCloudVideointelligenceV1beta2TextSegment>? segments;

  /// The detected text.
  core.String? text;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1beta2TextAnnotation();

  GoogleCloudVideointelligenceV1beta2TextAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2TextSegment>((value) =>
              GoogleCloudVideointelligenceV1beta2TextSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (text != null) 'text': text!,
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotation results for text annotation (OCR).
///
/// Contains information regarding timestamp and bounding box locations for the
/// frames containing detected OCR text snippets.
class GoogleCloudVideointelligenceV1beta2TextFrame {
  /// Bounding polygon of the detected text for this frame.
  GoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly? rotatedBoundingBox;

  /// Timestamp of this frame.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1beta2TextFrame();

  GoogleCloudVideointelligenceV1beta2TextFrame.fromJson(core.Map _json) {
    if (_json.containsKey('rotatedBoundingBox')) {
      rotatedBoundingBox =
          GoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly.fromJson(
              _json['rotatedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rotatedBoundingBox != null)
          'rotatedBoundingBox': rotatedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for text detection.
class GoogleCloudVideointelligenceV1beta2TextSegment {
  /// Confidence for the track of detected text.
  ///
  /// It is calculated as the highest over all frames where OCR detected text
  /// appears.
  core.double? confidence;

  /// Information related to the frames where OCR detected text appears.
  core.List<GoogleCloudVideointelligenceV1beta2TextFrame>? frames;

  /// Video segment where a text snippet was detected.
  GoogleCloudVideointelligenceV1beta2VideoSegment? segment;

  GoogleCloudVideointelligenceV1beta2TextSegment();

  GoogleCloudVideointelligenceV1beta2TextSegment.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2TextFrame>((value) =>
              GoogleCloudVideointelligenceV1beta2TextFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1beta2VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// For tracking related features.
///
/// An object at time_offset with attributes, and located with
/// normalized_bounding_box.
class GoogleCloudVideointelligenceV1beta2TimestampedObject {
  /// The attributes of the object in the bounding box.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1beta2DetectedAttribute>? attributes;

  /// The detected landmarks.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1beta2DetectedLandmark>? landmarks;

  /// Normalized Bounding box in a frame, where the object is located.
  GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox?
      normalizedBoundingBox;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this object.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1beta2TimestampedObject();

  GoogleCloudVideointelligenceV1beta2TimestampedObject.fromJson(
      core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = (_json['attributes'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2DetectedAttribute>((value) =>
              GoogleCloudVideointelligenceV1beta2DetectedAttribute.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('landmarks')) {
      landmarks = (_json['landmarks'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2DetectedLandmark>((value) =>
              GoogleCloudVideointelligenceV1beta2DetectedLandmark.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('normalizedBoundingBox')) {
      normalizedBoundingBox =
          GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox.fromJson(
              _json['normalizedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null)
          'attributes': attributes!.map((value) => value.toJson()).toList(),
        if (landmarks != null)
          'landmarks': landmarks!.map((value) => value.toJson()).toList(),
        if (normalizedBoundingBox != null)
          'normalizedBoundingBox': normalizedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// A track of an object instance.
class GoogleCloudVideointelligenceV1beta2Track {
  /// Attributes in the track level.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1beta2DetectedAttribute>? attributes;

  /// The confidence score of the tracked object.
  ///
  /// Optional.
  core.double? confidence;

  /// Video segment of a track.
  GoogleCloudVideointelligenceV1beta2VideoSegment? segment;

  /// The object with timestamp and attributes per frame in the track.
  core.List<GoogleCloudVideointelligenceV1beta2TimestampedObject>?
      timestampedObjects;

  GoogleCloudVideointelligenceV1beta2Track();

  GoogleCloudVideointelligenceV1beta2Track.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = (_json['attributes'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2DetectedAttribute>((value) =>
              GoogleCloudVideointelligenceV1beta2DetectedAttribute.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1beta2VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timestampedObjects')) {
      timestampedObjects = (_json['timestampedObjects'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2TimestampedObject>((value) =>
              GoogleCloudVideointelligenceV1beta2TimestampedObject.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null)
          'attributes': attributes!.map((value) => value.toJson()).toList(),
        if (confidence != null) 'confidence': confidence!,
        if (segment != null) 'segment': segment!.toJson(),
        if (timestampedObjects != null)
          'timestampedObjects':
              timestampedObjects!.map((value) => value.toJson()).toList(),
      };
}

/// Annotation progress for a single video.
class GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress {
  /// Specifies which feature is being tracked if the request contains more than
  /// one feature.
  /// Possible string values are:
  /// - "FEATURE_UNSPECIFIED" : Unspecified.
  /// - "LABEL_DETECTION" : Label detection. Detect objects, such as dog or
  /// flower.
  /// - "SHOT_CHANGE_DETECTION" : Shot change detection.
  /// - "EXPLICIT_CONTENT_DETECTION" : Explicit content detection.
  /// - "FACE_DETECTION" : Human face detection.
  /// - "SPEECH_TRANSCRIPTION" : Speech transcription.
  /// - "TEXT_DETECTION" : OCR text detection and tracking.
  /// - "OBJECT_TRACKING" : Object detection and tracking.
  /// - "LOGO_RECOGNITION" : Logo detection, tracking, and recognition.
  /// - "PERSON_DETECTION" : Person detection.
  core.String? feature;

  /// Video file location in [Cloud Storage](https://cloud.google.com/storage/).
  core.String? inputUri;

  /// Approximate percentage processed thus far.
  ///
  /// Guaranteed to be 100 when fully processed.
  core.int? progressPercent;

  /// Specifies which segment is being tracked if the request contains more than
  /// one segment.
  GoogleCloudVideointelligenceV1beta2VideoSegment? segment;

  /// Time when the request was received.
  core.String? startTime;

  /// Time of the most recent update.
  core.String? updateTime;

  GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress();

  GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress.fromJson(
      core.Map _json) {
    if (_json.containsKey('feature')) {
      feature = _json['feature'] as core.String;
    }
    if (_json.containsKey('inputUri')) {
      inputUri = _json['inputUri'] as core.String;
    }
    if (_json.containsKey('progressPercent')) {
      progressPercent = _json['progressPercent'] as core.int;
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1beta2VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (feature != null) 'feature': feature!,
        if (inputUri != null) 'inputUri': inputUri!,
        if (progressPercent != null) 'progressPercent': progressPercent!,
        if (segment != null) 'segment': segment!.toJson(),
        if (startTime != null) 'startTime': startTime!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Annotation results for a single video.
class GoogleCloudVideointelligenceV1beta2VideoAnnotationResults {
  /// If set, indicates an error.
  ///
  /// Note that for a single `AnnotateVideoRequest` some videos may succeed and
  /// some may fail.
  GoogleRpcStatus? error;

  /// Explicit content annotation.
  GoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation?
      explicitAnnotation;

  /// Please use `face_detection_annotations` instead.
  ///
  /// Deprecated.
  core.List<GoogleCloudVideointelligenceV1beta2FaceAnnotation>? faceAnnotations;

  /// Face detection annotations.
  core.List<GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation>?
      faceDetectionAnnotations;

  /// Label annotations on frame level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1beta2LabelAnnotation>?
      frameLabelAnnotations;

  /// Video file location in [Cloud Storage](https://cloud.google.com/storage/).
  core.String? inputUri;

  /// Annotations for list of logos detected, tracked and recognized in video.
  core.List<GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation>?
      logoRecognitionAnnotations;

  /// Annotations for list of objects detected and tracked in video.
  core.List<GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation>?
      objectAnnotations;

  /// Person detection annotations.
  core.List<GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation>?
      personDetectionAnnotations;

  /// Video segment on which the annotation is run.
  GoogleCloudVideointelligenceV1beta2VideoSegment? segment;

  /// Topical label annotations on video level or user-specified segment level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1beta2LabelAnnotation>?
      segmentLabelAnnotations;

  /// Presence label annotations on video level or user-specified segment level.
  ///
  /// There is exactly one element for each unique label. Compared to the
  /// existing topical `segment_label_annotations`, this field presents more
  /// fine-grained, segment-level labels detected in video content and is made
  /// available only when the client sets `LabelDetectionConfig.model` to
  /// "builtin/latest" in the request.
  core.List<GoogleCloudVideointelligenceV1beta2LabelAnnotation>?
      segmentPresenceLabelAnnotations;

  /// Shot annotations.
  ///
  /// Each shot is represented as a video segment.
  core.List<GoogleCloudVideointelligenceV1beta2VideoSegment>? shotAnnotations;

  /// Topical label annotations on shot level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1beta2LabelAnnotation>?
      shotLabelAnnotations;

  /// Presence label annotations on shot level.
  ///
  /// There is exactly one element for each unique label. Compared to the
  /// existing topical `shot_label_annotations`, this field presents more
  /// fine-grained, shot-level labels detected in video content and is made
  /// available only when the client sets `LabelDetectionConfig.model` to
  /// "builtin/latest" in the request.
  core.List<GoogleCloudVideointelligenceV1beta2LabelAnnotation>?
      shotPresenceLabelAnnotations;

  /// Speech transcription.
  core.List<GoogleCloudVideointelligenceV1beta2SpeechTranscription>?
      speechTranscriptions;

  /// OCR text detection and tracking.
  ///
  /// Annotations for list of detected text snippets. Each will have list of
  /// frame information associated with it.
  core.List<GoogleCloudVideointelligenceV1beta2TextAnnotation>? textAnnotations;

  GoogleCloudVideointelligenceV1beta2VideoAnnotationResults();

  GoogleCloudVideointelligenceV1beta2VideoAnnotationResults.fromJson(
      core.Map _json) {
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('explicitAnnotation')) {
      explicitAnnotation =
          GoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation.fromJson(
              _json['explicitAnnotation']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('faceAnnotations')) {
      faceAnnotations = (_json['faceAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2FaceAnnotation>((value) =>
              GoogleCloudVideointelligenceV1beta2FaceAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('faceDetectionAnnotations')) {
      faceDetectionAnnotations = (_json['faceDetectionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('frameLabelAnnotations')) {
      frameLabelAnnotations = (_json['frameLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1beta2LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('inputUri')) {
      inputUri = _json['inputUri'] as core.String;
    }
    if (_json.containsKey('logoRecognitionAnnotations')) {
      logoRecognitionAnnotations = (_json['logoRecognitionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('objectAnnotations')) {
      objectAnnotations = (_json['objectAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('personDetectionAnnotations')) {
      personDetectionAnnotations = (_json['personDetectionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1beta2VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('segmentLabelAnnotations')) {
      segmentLabelAnnotations = (_json['segmentLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1beta2LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segmentPresenceLabelAnnotations')) {
      segmentPresenceLabelAnnotations =
          (_json['segmentPresenceLabelAnnotations'] as core.List)
              .map<GoogleCloudVideointelligenceV1beta2LabelAnnotation>(
                  (value) => GoogleCloudVideointelligenceV1beta2LabelAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
              .toList();
    }
    if (_json.containsKey('shotAnnotations')) {
      shotAnnotations = (_json['shotAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2VideoSegment>((value) =>
              GoogleCloudVideointelligenceV1beta2VideoSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotLabelAnnotations')) {
      shotLabelAnnotations = (_json['shotLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1beta2LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotPresenceLabelAnnotations')) {
      shotPresenceLabelAnnotations = (_json['shotPresenceLabelAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1beta2LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1beta2LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('speechTranscriptions')) {
      speechTranscriptions = (_json['speechTranscriptions'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2SpeechTranscription>(
              (value) => GoogleCloudVideointelligenceV1beta2SpeechTranscription
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('textAnnotations')) {
      textAnnotations = (_json['textAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1beta2TextAnnotation>((value) =>
              GoogleCloudVideointelligenceV1beta2TextAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (error != null) 'error': error!.toJson(),
        if (explicitAnnotation != null)
          'explicitAnnotation': explicitAnnotation!.toJson(),
        if (faceAnnotations != null)
          'faceAnnotations':
              faceAnnotations!.map((value) => value.toJson()).toList(),
        if (faceDetectionAnnotations != null)
          'faceDetectionAnnotations':
              faceDetectionAnnotations!.map((value) => value.toJson()).toList(),
        if (frameLabelAnnotations != null)
          'frameLabelAnnotations':
              frameLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (inputUri != null) 'inputUri': inputUri!,
        if (logoRecognitionAnnotations != null)
          'logoRecognitionAnnotations': logoRecognitionAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (objectAnnotations != null)
          'objectAnnotations':
              objectAnnotations!.map((value) => value.toJson()).toList(),
        if (personDetectionAnnotations != null)
          'personDetectionAnnotations': personDetectionAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (segment != null) 'segment': segment!.toJson(),
        if (segmentLabelAnnotations != null)
          'segmentLabelAnnotations':
              segmentLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (segmentPresenceLabelAnnotations != null)
          'segmentPresenceLabelAnnotations': segmentPresenceLabelAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (shotAnnotations != null)
          'shotAnnotations':
              shotAnnotations!.map((value) => value.toJson()).toList(),
        if (shotLabelAnnotations != null)
          'shotLabelAnnotations':
              shotLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (shotPresenceLabelAnnotations != null)
          'shotPresenceLabelAnnotations': shotPresenceLabelAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (speechTranscriptions != null)
          'speechTranscriptions':
              speechTranscriptions!.map((value) => value.toJson()).toList(),
        if (textAnnotations != null)
          'textAnnotations':
              textAnnotations!.map((value) => value.toJson()).toList(),
      };
}

/// Video segment.
class GoogleCloudVideointelligenceV1beta2VideoSegment {
  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// end of the segment (inclusive).
  core.String? endTimeOffset;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// start of the segment (inclusive).
  core.String? startTimeOffset;

  GoogleCloudVideointelligenceV1beta2VideoSegment();

  GoogleCloudVideointelligenceV1beta2VideoSegment.fromJson(core.Map _json) {
    if (_json.containsKey('endTimeOffset')) {
      endTimeOffset = _json['endTimeOffset'] as core.String;
    }
    if (_json.containsKey('startTimeOffset')) {
      startTimeOffset = _json['startTimeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTimeOffset != null) 'endTimeOffset': endTimeOffset!,
        if (startTimeOffset != null) 'startTimeOffset': startTimeOffset!,
      };
}

/// Word-specific information for recognized words.
///
/// Word information is only included in the response when certain request
/// parameters are set, such as `enable_word_time_offsets`.
class GoogleCloudVideointelligenceV1beta2WordInfo {
  /// The confidence estimate between 0.0 and 1.0.
  ///
  /// A higher number indicates an estimated greater likelihood that the
  /// recognized words are correct. This field is set only for the top
  /// alternative. This field is not guaranteed to be accurate and users should
  /// not rely on it to be always provided. The default of 0.0 is a sentinel
  /// value indicating `confidence` was not set.
  ///
  /// Output only.
  core.double? confidence;

  /// Time offset relative to the beginning of the audio, and corresponding to
  /// the end of the spoken word.
  ///
  /// This field is only set if `enable_word_time_offsets=true` and only in the
  /// top hypothesis. This is an experimental feature and the accuracy of the
  /// time offset can vary.
  core.String? endTime;

  /// A distinct integer value is assigned for every speaker within the audio.
  ///
  /// This field specifies which one of those speakers was detected to have
  /// spoken this word. Value ranges from 1 up to diarization_speaker_count, and
  /// is only set if speaker diarization is enabled.
  ///
  /// Output only.
  core.int? speakerTag;

  /// Time offset relative to the beginning of the audio, and corresponding to
  /// the start of the spoken word.
  ///
  /// This field is only set if `enable_word_time_offsets=true` and only in the
  /// top hypothesis. This is an experimental feature and the accuracy of the
  /// time offset can vary.
  core.String? startTime;

  /// The word corresponding to this set of information.
  core.String? word;

  GoogleCloudVideointelligenceV1beta2WordInfo();

  GoogleCloudVideointelligenceV1beta2WordInfo.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('speakerTag')) {
      speakerTag = _json['speakerTag'] as core.int;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('word')) {
      word = _json['word'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (endTime != null) 'endTime': endTime!,
        if (speakerTag != null) 'speakerTag': speakerTag!,
        if (startTime != null) 'startTime': startTime!,
        if (word != null) 'word': word!,
      };
}

/// Video annotation progress.
///
/// Included in the `metadata` field of the `Operation` returned by the
/// `GetOperation` call of the `google::longrunning::Operations` service.
class GoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress {
  /// Progress metadata for all videos specified in `AnnotateVideoRequest`.
  core.List<GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress>?
      annotationProgress;

  GoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress();

  GoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress.fromJson(
      core.Map _json) {
    if (_json.containsKey('annotationProgress')) {
      annotationProgress = (_json['annotationProgress'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress>(
              (value) =>
                  GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationProgress != null)
          'annotationProgress':
              annotationProgress!.map((value) => value.toJson()).toList(),
      };
}

/// Video annotation response.
///
/// Included in the `response` field of the `Operation` returned by the
/// `GetOperation` call of the `google::longrunning::Operations` service.
class GoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse {
  /// Annotation results for all videos specified in `AnnotateVideoRequest`.
  core.List<GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults>?
      annotationResults;

  GoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse();

  GoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('annotationResults')) {
      annotationResults = (_json['annotationResults'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults>(
              (value) =>
                  GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationResults != null)
          'annotationResults':
              annotationResults!.map((value) => value.toJson()).toList(),
      };
}

/// A generic detected attribute represented by name in string format.
class GoogleCloudVideointelligenceV1p1beta1DetectedAttribute {
  /// Detected attribute confidence.
  ///
  /// Range \[0, 1\].
  core.double? confidence;

  /// The name of the attribute, for example, glasses, dark_glasses, mouth_open.
  ///
  /// A full list of supported type names will be provided in the document.
  core.String? name;

  /// Text value of the detection result.
  ///
  /// For example, the value for "HairColor" can be "black", "blonde", etc.
  core.String? value;

  GoogleCloudVideointelligenceV1p1beta1DetectedAttribute();

  GoogleCloudVideointelligenceV1p1beta1DetectedAttribute.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (name != null) 'name': name!,
        if (value != null) 'value': value!,
      };
}

/// A generic detected landmark represented by name in string format and a 2D
/// location.
class GoogleCloudVideointelligenceV1p1beta1DetectedLandmark {
  /// The confidence score of the detected landmark.
  ///
  /// Range \[0, 1\].
  core.double? confidence;

  /// The name of this landmark, for example, left_hand, right_shoulder.
  core.String? name;

  /// The 2D point of the detected landmark using the normalized image
  /// coordindate system.
  ///
  /// The normalized coordinates have the range from 0 to 1.
  GoogleCloudVideointelligenceV1p1beta1NormalizedVertex? point;

  GoogleCloudVideointelligenceV1p1beta1DetectedLandmark();

  GoogleCloudVideointelligenceV1p1beta1DetectedLandmark.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('point')) {
      point = GoogleCloudVideointelligenceV1p1beta1NormalizedVertex.fromJson(
          _json['point'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (name != null) 'name': name!,
        if (point != null) 'point': point!.toJson(),
      };
}

/// Detected entity from video analysis.
class GoogleCloudVideointelligenceV1p1beta1Entity {
  /// Textual description, e.g., `Fixed-gear bicycle`.
  core.String? description;

  /// Opaque entity ID.
  ///
  /// Some IDs may be available in
  /// [Google Knowledge Graph Search API](https://developers.google.com/knowledge-graph/).
  core.String? entityId;

  /// Language code for `description` in BCP-47 format.
  core.String? languageCode;

  GoogleCloudVideointelligenceV1p1beta1Entity();

  GoogleCloudVideointelligenceV1p1beta1Entity.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('entityId')) {
      entityId = _json['entityId'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (entityId != null) 'entityId': entityId!,
        if (languageCode != null) 'languageCode': languageCode!,
      };
}

/// Explicit content annotation (based on per-frame visual signals only).
///
/// If no explicit content has been detected in a frame, no annotations are
/// present for that frame.
class GoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation {
  /// All video frames where explicit content was detected.
  core.List<GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame>? frames;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation();

  GoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame>(
              (value) =>
                  GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotation results for explicit content.
class GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame {
  /// Likelihood of the pornography content..
  /// Possible string values are:
  /// - "LIKELIHOOD_UNSPECIFIED" : Unspecified likelihood.
  /// - "VERY_UNLIKELY" : Very unlikely.
  /// - "UNLIKELY" : Unlikely.
  /// - "POSSIBLE" : Possible.
  /// - "LIKELY" : Likely.
  /// - "VERY_LIKELY" : Very likely.
  core.String? pornographyLikelihood;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame();

  GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame.fromJson(
      core.Map _json) {
    if (_json.containsKey('pornographyLikelihood')) {
      pornographyLikelihood = _json['pornographyLikelihood'] as core.String;
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pornographyLikelihood != null)
          'pornographyLikelihood': pornographyLikelihood!,
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// No effect.
///
/// Deprecated.
class GoogleCloudVideointelligenceV1p1beta1FaceAnnotation {
  /// All video frames where a face was detected.
  core.List<GoogleCloudVideointelligenceV1p1beta1FaceFrame>? frames;

  /// All video segments where a face was detected.
  core.List<GoogleCloudVideointelligenceV1p1beta1FaceSegment>? segments;

  /// Thumbnail of a representative face view (in JPEG format).
  core.String? thumbnail;
  core.List<core.int> get thumbnailAsBytes => convert.base64.decode(thumbnail!);

  set thumbnailAsBytes(core.List<core.int> _bytes) {
    thumbnail =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  GoogleCloudVideointelligenceV1p1beta1FaceAnnotation();

  GoogleCloudVideointelligenceV1p1beta1FaceAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1FaceFrame>((value) =>
              GoogleCloudVideointelligenceV1p1beta1FaceFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1FaceSegment>((value) =>
              GoogleCloudVideointelligenceV1p1beta1FaceSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('thumbnail')) {
      thumbnail = _json['thumbnail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (thumbnail != null) 'thumbnail': thumbnail!,
      };
}

/// Face detection annotation.
class GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation {
  /// The thumbnail of a person's face.
  core.String? thumbnail;
  core.List<core.int> get thumbnailAsBytes => convert.base64.decode(thumbnail!);

  set thumbnailAsBytes(core.List<core.int> _bytes) {
    thumbnail =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The face tracks with attributes.
  core.List<GoogleCloudVideointelligenceV1p1beta1Track>? tracks;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation();

  GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('thumbnail')) {
      thumbnail = _json['thumbnail'] as core.String;
    }
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1Track>((value) =>
              GoogleCloudVideointelligenceV1p1beta1Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (thumbnail != null) 'thumbnail': thumbnail!,
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// No effect.
///
/// Deprecated.
class GoogleCloudVideointelligenceV1p1beta1FaceFrame {
  /// Normalized Bounding boxes in a frame.
  ///
  /// There can be more than one boxes if the same face is detected in multiple
  /// locations within the current frame.
  core.List<GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox>?
      normalizedBoundingBoxes;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p1beta1FaceFrame();

  GoogleCloudVideointelligenceV1p1beta1FaceFrame.fromJson(core.Map _json) {
    if (_json.containsKey('normalizedBoundingBoxes')) {
      normalizedBoundingBoxes = (_json['normalizedBoundingBoxes'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox>(
              (value) =>
                  GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (normalizedBoundingBoxes != null)
          'normalizedBoundingBoxes':
              normalizedBoundingBoxes!.map((value) => value.toJson()).toList(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for face detection.
class GoogleCloudVideointelligenceV1p1beta1FaceSegment {
  /// Video segment where a face was detected.
  GoogleCloudVideointelligenceV1p1beta1VideoSegment? segment;

  GoogleCloudVideointelligenceV1p1beta1FaceSegment();

  GoogleCloudVideointelligenceV1p1beta1FaceSegment.fromJson(core.Map _json) {
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p1beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// Label annotation.
class GoogleCloudVideointelligenceV1p1beta1LabelAnnotation {
  /// Common categories for the detected entity.
  ///
  /// For example, when the label is `Terrier`, the category is likely `dog`.
  /// And in some cases there might be more than one categories e.g., `Terrier`
  /// could also be a `pet`.
  core.List<GoogleCloudVideointelligenceV1p1beta1Entity>? categoryEntities;

  /// Detected entity.
  GoogleCloudVideointelligenceV1p1beta1Entity? entity;

  /// All video frames where a label was detected.
  core.List<GoogleCloudVideointelligenceV1p1beta1LabelFrame>? frames;

  /// All video segments where a label was detected.
  core.List<GoogleCloudVideointelligenceV1p1beta1LabelSegment>? segments;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p1beta1LabelAnnotation();

  GoogleCloudVideointelligenceV1p1beta1LabelAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('categoryEntities')) {
      categoryEntities = (_json['categoryEntities'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1Entity>((value) =>
              GoogleCloudVideointelligenceV1p1beta1Entity.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1p1beta1Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1LabelFrame>((value) =>
              GoogleCloudVideointelligenceV1p1beta1LabelFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1LabelSegment>((value) =>
              GoogleCloudVideointelligenceV1p1beta1LabelSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (categoryEntities != null)
          'categoryEntities':
              categoryEntities!.map((value) => value.toJson()).toList(),
        if (entity != null) 'entity': entity!.toJson(),
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotation results for label detection.
class GoogleCloudVideointelligenceV1p1beta1LabelFrame {
  /// Confidence that the label is accurate.
  ///
  /// Range: \[0, 1\].
  core.double? confidence;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p1beta1LabelFrame();

  GoogleCloudVideointelligenceV1p1beta1LabelFrame.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for label detection.
class GoogleCloudVideointelligenceV1p1beta1LabelSegment {
  /// Confidence that the label is accurate.
  ///
  /// Range: \[0, 1\].
  core.double? confidence;

  /// Video segment where a label was detected.
  GoogleCloudVideointelligenceV1p1beta1VideoSegment? segment;

  GoogleCloudVideointelligenceV1p1beta1LabelSegment();

  GoogleCloudVideointelligenceV1p1beta1LabelSegment.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p1beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// Annotation corresponding to one detected, tracked and recognized logo class.
class GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation {
  /// Entity category information to specify the logo class that all the logo
  /// tracks within this LogoRecognitionAnnotation are recognized as.
  GoogleCloudVideointelligenceV1p1beta1Entity? entity;

  /// All video segments where the recognized logo appears.
  ///
  /// There might be multiple instances of the same logo class appearing in one
  /// VideoSegment.
  core.List<GoogleCloudVideointelligenceV1p1beta1VideoSegment>? segments;

  /// All logo tracks where the recognized logo appears.
  ///
  /// Each track corresponds to one logo instance appearing in consecutive
  /// frames.
  core.List<GoogleCloudVideointelligenceV1p1beta1Track>? tracks;

  GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation();

  GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1p1beta1Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1VideoSegment>((value) =>
              GoogleCloudVideointelligenceV1p1beta1VideoSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1Track>((value) =>
              GoogleCloudVideointelligenceV1p1beta1Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entity != null) 'entity': entity!.toJson(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
      };
}

/// Normalized bounding box.
///
/// The normalized vertex coordinates are relative to the original image. Range:
/// \[0, 1\].
class GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox {
  /// Bottom Y coordinate.
  core.double? bottom;

  /// Left X coordinate.
  core.double? left;

  /// Right X coordinate.
  core.double? right;

  /// Top Y coordinate.
  core.double? top;

  GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox();

  GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox.fromJson(
      core.Map _json) {
    if (_json.containsKey('bottom')) {
      bottom = (_json['bottom'] as core.num).toDouble();
    }
    if (_json.containsKey('left')) {
      left = (_json['left'] as core.num).toDouble();
    }
    if (_json.containsKey('right')) {
      right = (_json['right'] as core.num).toDouble();
    }
    if (_json.containsKey('top')) {
      top = (_json['top'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bottom != null) 'bottom': bottom!,
        if (left != null) 'left': left!,
        if (right != null) 'right': right!,
        if (top != null) 'top': top!,
      };
}

/// Normalized bounding polygon for text (that might not be aligned with axis).
///
/// Contains list of the corner points in clockwise order starting from top-left
/// corner. For example, for a rectangular bounding box: When the text is
/// horizontal it might look like: 0----1 | | 3----2 When it's clockwise rotated
/// 180 degrees around the top-left corner it becomes: 2----3 | | 1----0 and the
/// vertex order will still be (0, 1, 2, 3). Note that values can be less than
/// 0, or greater than 1 due to trignometric calculations for location of the
/// box.
class GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly {
  /// Normalized vertices of the bounding polygon.
  core.List<GoogleCloudVideointelligenceV1p1beta1NormalizedVertex>? vertices;

  GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly();

  GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly.fromJson(
      core.Map _json) {
    if (_json.containsKey('vertices')) {
      vertices = (_json['vertices'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1NormalizedVertex>((value) =>
              GoogleCloudVideointelligenceV1p1beta1NormalizedVertex.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (vertices != null)
          'vertices': vertices!.map((value) => value.toJson()).toList(),
      };
}

/// A vertex represents a 2D point in the image.
///
/// NOTE: the normalized vertex coordinates are relative to the original image
/// and range from 0 to 1.
class GoogleCloudVideointelligenceV1p1beta1NormalizedVertex {
  /// X coordinate.
  core.double? x;

  /// Y coordinate.
  core.double? y;

  GoogleCloudVideointelligenceV1p1beta1NormalizedVertex();

  GoogleCloudVideointelligenceV1p1beta1NormalizedVertex.fromJson(
      core.Map _json) {
    if (_json.containsKey('x')) {
      x = (_json['x'] as core.num).toDouble();
    }
    if (_json.containsKey('y')) {
      y = (_json['y'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (x != null) 'x': x!,
        if (y != null) 'y': y!,
      };
}

/// Annotations corresponding to one tracked object.
class GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation {
  /// Object category's labeling confidence of this track.
  core.double? confidence;

  /// Entity to specify the object category that this track is labeled as.
  GoogleCloudVideointelligenceV1p1beta1Entity? entity;

  /// Information corresponding to all frames where this object track appears.
  ///
  /// Non-streaming batch mode: it may be one or multiple ObjectTrackingFrame
  /// messages in frames. Streaming mode: it can only be one ObjectTrackingFrame
  /// message in frames.
  core.List<GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame>? frames;

  /// Non-streaming batch mode ONLY.
  ///
  /// Each object track corresponds to one video segment where it appears.
  GoogleCloudVideointelligenceV1p1beta1VideoSegment? segment;

  /// Streaming mode ONLY.
  ///
  /// In streaming mode, we do not know the end time of a tracked object before
  /// it is completed. Hence, there is no VideoSegment info returned. Instead,
  /// we provide a unique identifiable integer track_id so that the customers
  /// can correlate the results of the ongoing ObjectTrackAnnotation of the same
  /// track_id over time.
  core.String? trackId;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation();

  GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1p1beta1Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame>(
              (value) =>
                  GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p1beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('trackId')) {
      trackId = _json['trackId'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (entity != null) 'entity': entity!.toJson(),
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segment != null) 'segment': segment!.toJson(),
        if (trackId != null) 'trackId': trackId!,
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotations for object detection and tracking.
///
/// This field stores per frame location, time offset, and confidence.
class GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame {
  /// The normalized bounding box location of this object track for the frame.
  GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox?
      normalizedBoundingBox;

  /// The timestamp of the frame in microseconds.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame();

  GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame.fromJson(
      core.Map _json) {
    if (_json.containsKey('normalizedBoundingBox')) {
      normalizedBoundingBox =
          GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox.fromJson(
              _json['normalizedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (normalizedBoundingBox != null)
          'normalizedBoundingBox': normalizedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Person detection annotation per video.
class GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation {
  /// The detected tracks of a person.
  core.List<GoogleCloudVideointelligenceV1p1beta1Track>? tracks;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation();

  GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1Track>((value) =>
              GoogleCloudVideointelligenceV1p1beta1Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Alternative hypotheses (a.k.a. n-best list).
class GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative {
  /// The confidence estimate between 0.0 and 1.0.
  ///
  /// A higher number indicates an estimated greater likelihood that the
  /// recognized words are correct. This field is set only for the top
  /// alternative. This field is not guaranteed to be accurate and users should
  /// not rely on it to be always provided. The default of 0.0 is a sentinel
  /// value indicating `confidence` was not set.
  ///
  /// Output only.
  core.double? confidence;

  /// Transcript text representing the words that the user spoke.
  core.String? transcript;

  /// A list of word-specific information for each recognized word.
  ///
  /// Note: When `enable_speaker_diarization` is set to true, you will see all
  /// the words from the beginning of the audio.
  ///
  /// Output only.
  core.List<GoogleCloudVideointelligenceV1p1beta1WordInfo>? words;

  GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative();

  GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('transcript')) {
      transcript = _json['transcript'] as core.String;
    }
    if (_json.containsKey('words')) {
      words = (_json['words'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1WordInfo>((value) =>
              GoogleCloudVideointelligenceV1p1beta1WordInfo.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (transcript != null) 'transcript': transcript!,
        if (words != null)
          'words': words!.map((value) => value.toJson()).toList(),
      };
}

/// A speech recognition result corresponding to a portion of the audio.
class GoogleCloudVideointelligenceV1p1beta1SpeechTranscription {
  /// May contain one or more recognition hypotheses (up to the maximum
  /// specified in `max_alternatives`).
  ///
  /// These alternatives are ordered in terms of accuracy, with the top (first)
  /// alternative being the most probable, as ranked by the recognizer.
  core.List<GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative>?
      alternatives;

  /// The \[BCP-47\](https://www.rfc-editor.org/rfc/bcp/bcp47.txt) language tag
  /// of the language in this result.
  ///
  /// This language code was detected to have the most likelihood of being
  /// spoken in the audio.
  ///
  /// Output only.
  core.String? languageCode;

  GoogleCloudVideointelligenceV1p1beta1SpeechTranscription();

  GoogleCloudVideointelligenceV1p1beta1SpeechTranscription.fromJson(
      core.Map _json) {
    if (_json.containsKey('alternatives')) {
      alternatives = (_json['alternatives'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative>(
              (value) =>
                  GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alternatives != null)
          'alternatives': alternatives!.map((value) => value.toJson()).toList(),
        if (languageCode != null) 'languageCode': languageCode!,
      };
}

/// Annotations related to one detected OCR text snippet.
///
/// This will contain the corresponding text, confidence value, and frame level
/// information for each detection.
class GoogleCloudVideointelligenceV1p1beta1TextAnnotation {
  /// All video segments where OCR detected text appears.
  core.List<GoogleCloudVideointelligenceV1p1beta1TextSegment>? segments;

  /// The detected text.
  core.String? text;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p1beta1TextAnnotation();

  GoogleCloudVideointelligenceV1p1beta1TextAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1TextSegment>((value) =>
              GoogleCloudVideointelligenceV1p1beta1TextSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (text != null) 'text': text!,
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotation results for text annotation (OCR).
///
/// Contains information regarding timestamp and bounding box locations for the
/// frames containing detected OCR text snippets.
class GoogleCloudVideointelligenceV1p1beta1TextFrame {
  /// Bounding polygon of the detected text for this frame.
  GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly?
      rotatedBoundingBox;

  /// Timestamp of this frame.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p1beta1TextFrame();

  GoogleCloudVideointelligenceV1p1beta1TextFrame.fromJson(core.Map _json) {
    if (_json.containsKey('rotatedBoundingBox')) {
      rotatedBoundingBox =
          GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly.fromJson(
              _json['rotatedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rotatedBoundingBox != null)
          'rotatedBoundingBox': rotatedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for text detection.
class GoogleCloudVideointelligenceV1p1beta1TextSegment {
  /// Confidence for the track of detected text.
  ///
  /// It is calculated as the highest over all frames where OCR detected text
  /// appears.
  core.double? confidence;

  /// Information related to the frames where OCR detected text appears.
  core.List<GoogleCloudVideointelligenceV1p1beta1TextFrame>? frames;

  /// Video segment where a text snippet was detected.
  GoogleCloudVideointelligenceV1p1beta1VideoSegment? segment;

  GoogleCloudVideointelligenceV1p1beta1TextSegment();

  GoogleCloudVideointelligenceV1p1beta1TextSegment.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1TextFrame>((value) =>
              GoogleCloudVideointelligenceV1p1beta1TextFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p1beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// For tracking related features.
///
/// An object at time_offset with attributes, and located with
/// normalized_bounding_box.
class GoogleCloudVideointelligenceV1p1beta1TimestampedObject {
  /// The attributes of the object in the bounding box.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1p1beta1DetectedAttribute>? attributes;

  /// The detected landmarks.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1p1beta1DetectedLandmark>? landmarks;

  /// Normalized Bounding box in a frame, where the object is located.
  GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox?
      normalizedBoundingBox;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this object.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p1beta1TimestampedObject();

  GoogleCloudVideointelligenceV1p1beta1TimestampedObject.fromJson(
      core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = (_json['attributes'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1DetectedAttribute>(
              (value) => GoogleCloudVideointelligenceV1p1beta1DetectedAttribute
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('landmarks')) {
      landmarks = (_json['landmarks'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1DetectedLandmark>((value) =>
              GoogleCloudVideointelligenceV1p1beta1DetectedLandmark.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('normalizedBoundingBox')) {
      normalizedBoundingBox =
          GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox.fromJson(
              _json['normalizedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null)
          'attributes': attributes!.map((value) => value.toJson()).toList(),
        if (landmarks != null)
          'landmarks': landmarks!.map((value) => value.toJson()).toList(),
        if (normalizedBoundingBox != null)
          'normalizedBoundingBox': normalizedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// A track of an object instance.
class GoogleCloudVideointelligenceV1p1beta1Track {
  /// Attributes in the track level.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1p1beta1DetectedAttribute>? attributes;

  /// The confidence score of the tracked object.
  ///
  /// Optional.
  core.double? confidence;

  /// Video segment of a track.
  GoogleCloudVideointelligenceV1p1beta1VideoSegment? segment;

  /// The object with timestamp and attributes per frame in the track.
  core.List<GoogleCloudVideointelligenceV1p1beta1TimestampedObject>?
      timestampedObjects;

  GoogleCloudVideointelligenceV1p1beta1Track();

  GoogleCloudVideointelligenceV1p1beta1Track.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = (_json['attributes'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1DetectedAttribute>(
              (value) => GoogleCloudVideointelligenceV1p1beta1DetectedAttribute
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p1beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timestampedObjects')) {
      timestampedObjects = (_json['timestampedObjects'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1TimestampedObject>(
              (value) => GoogleCloudVideointelligenceV1p1beta1TimestampedObject
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null)
          'attributes': attributes!.map((value) => value.toJson()).toList(),
        if (confidence != null) 'confidence': confidence!,
        if (segment != null) 'segment': segment!.toJson(),
        if (timestampedObjects != null)
          'timestampedObjects':
              timestampedObjects!.map((value) => value.toJson()).toList(),
      };
}

/// Annotation progress for a single video.
class GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress {
  /// Specifies which feature is being tracked if the request contains more than
  /// one feature.
  /// Possible string values are:
  /// - "FEATURE_UNSPECIFIED" : Unspecified.
  /// - "LABEL_DETECTION" : Label detection. Detect objects, such as dog or
  /// flower.
  /// - "SHOT_CHANGE_DETECTION" : Shot change detection.
  /// - "EXPLICIT_CONTENT_DETECTION" : Explicit content detection.
  /// - "FACE_DETECTION" : Human face detection.
  /// - "SPEECH_TRANSCRIPTION" : Speech transcription.
  /// - "TEXT_DETECTION" : OCR text detection and tracking.
  /// - "OBJECT_TRACKING" : Object detection and tracking.
  /// - "LOGO_RECOGNITION" : Logo detection, tracking, and recognition.
  /// - "PERSON_DETECTION" : Person detection.
  core.String? feature;

  /// Video file location in [Cloud Storage](https://cloud.google.com/storage/).
  core.String? inputUri;

  /// Approximate percentage processed thus far.
  ///
  /// Guaranteed to be 100 when fully processed.
  core.int? progressPercent;

  /// Specifies which segment is being tracked if the request contains more than
  /// one segment.
  GoogleCloudVideointelligenceV1p1beta1VideoSegment? segment;

  /// Time when the request was received.
  core.String? startTime;

  /// Time of the most recent update.
  core.String? updateTime;

  GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress();

  GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress.fromJson(
      core.Map _json) {
    if (_json.containsKey('feature')) {
      feature = _json['feature'] as core.String;
    }
    if (_json.containsKey('inputUri')) {
      inputUri = _json['inputUri'] as core.String;
    }
    if (_json.containsKey('progressPercent')) {
      progressPercent = _json['progressPercent'] as core.int;
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p1beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (feature != null) 'feature': feature!,
        if (inputUri != null) 'inputUri': inputUri!,
        if (progressPercent != null) 'progressPercent': progressPercent!,
        if (segment != null) 'segment': segment!.toJson(),
        if (startTime != null) 'startTime': startTime!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Annotation results for a single video.
class GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults {
  /// If set, indicates an error.
  ///
  /// Note that for a single `AnnotateVideoRequest` some videos may succeed and
  /// some may fail.
  GoogleRpcStatus? error;

  /// Explicit content annotation.
  GoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation?
      explicitAnnotation;

  /// Please use `face_detection_annotations` instead.
  ///
  /// Deprecated.
  core.List<GoogleCloudVideointelligenceV1p1beta1FaceAnnotation>?
      faceAnnotations;

  /// Face detection annotations.
  core.List<GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation>?
      faceDetectionAnnotations;

  /// Label annotations on frame level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>?
      frameLabelAnnotations;

  /// Video file location in [Cloud Storage](https://cloud.google.com/storage/).
  core.String? inputUri;

  /// Annotations for list of logos detected, tracked and recognized in video.
  core.List<GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation>?
      logoRecognitionAnnotations;

  /// Annotations for list of objects detected and tracked in video.
  core.List<GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation>?
      objectAnnotations;

  /// Person detection annotations.
  core.List<GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation>?
      personDetectionAnnotations;

  /// Video segment on which the annotation is run.
  GoogleCloudVideointelligenceV1p1beta1VideoSegment? segment;

  /// Topical label annotations on video level or user-specified segment level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>?
      segmentLabelAnnotations;

  /// Presence label annotations on video level or user-specified segment level.
  ///
  /// There is exactly one element for each unique label. Compared to the
  /// existing topical `segment_label_annotations`, this field presents more
  /// fine-grained, segment-level labels detected in video content and is made
  /// available only when the client sets `LabelDetectionConfig.model` to
  /// "builtin/latest" in the request.
  core.List<GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>?
      segmentPresenceLabelAnnotations;

  /// Shot annotations.
  ///
  /// Each shot is represented as a video segment.
  core.List<GoogleCloudVideointelligenceV1p1beta1VideoSegment>? shotAnnotations;

  /// Topical label annotations on shot level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>?
      shotLabelAnnotations;

  /// Presence label annotations on shot level.
  ///
  /// There is exactly one element for each unique label. Compared to the
  /// existing topical `shot_label_annotations`, this field presents more
  /// fine-grained, shot-level labels detected in video content and is made
  /// available only when the client sets `LabelDetectionConfig.model` to
  /// "builtin/latest" in the request.
  core.List<GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>?
      shotPresenceLabelAnnotations;

  /// Speech transcription.
  core.List<GoogleCloudVideointelligenceV1p1beta1SpeechTranscription>?
      speechTranscriptions;

  /// OCR text detection and tracking.
  ///
  /// Annotations for list of detected text snippets. Each will have list of
  /// frame information associated with it.
  core.List<GoogleCloudVideointelligenceV1p1beta1TextAnnotation>?
      textAnnotations;

  GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults();

  GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults.fromJson(
      core.Map _json) {
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('explicitAnnotation')) {
      explicitAnnotation =
          GoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation
              .fromJson(_json['explicitAnnotation']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('faceAnnotations')) {
      faceAnnotations = (_json['faceAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1FaceAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p1beta1FaceAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('faceDetectionAnnotations')) {
      faceDetectionAnnotations = (_json['faceDetectionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('frameLabelAnnotations')) {
      frameLabelAnnotations = (_json['frameLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p1beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('inputUri')) {
      inputUri = _json['inputUri'] as core.String;
    }
    if (_json.containsKey('logoRecognitionAnnotations')) {
      logoRecognitionAnnotations = (_json['logoRecognitionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('objectAnnotations')) {
      objectAnnotations = (_json['objectAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('personDetectionAnnotations')) {
      personDetectionAnnotations = (_json['personDetectionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p1beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('segmentLabelAnnotations')) {
      segmentLabelAnnotations = (_json['segmentLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p1beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segmentPresenceLabelAnnotations')) {
      segmentPresenceLabelAnnotations = (_json[
              'segmentPresenceLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p1beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotAnnotations')) {
      shotAnnotations = (_json['shotAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1VideoSegment>((value) =>
              GoogleCloudVideointelligenceV1p1beta1VideoSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotLabelAnnotations')) {
      shotLabelAnnotations = (_json['shotLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p1beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotPresenceLabelAnnotations')) {
      shotPresenceLabelAnnotations = (_json['shotPresenceLabelAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p1beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('speechTranscriptions')) {
      speechTranscriptions = (_json['speechTranscriptions'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1SpeechTranscription>(
              (value) =>
                  GoogleCloudVideointelligenceV1p1beta1SpeechTranscription
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('textAnnotations')) {
      textAnnotations = (_json['textAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p1beta1TextAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p1beta1TextAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (error != null) 'error': error!.toJson(),
        if (explicitAnnotation != null)
          'explicitAnnotation': explicitAnnotation!.toJson(),
        if (faceAnnotations != null)
          'faceAnnotations':
              faceAnnotations!.map((value) => value.toJson()).toList(),
        if (faceDetectionAnnotations != null)
          'faceDetectionAnnotations':
              faceDetectionAnnotations!.map((value) => value.toJson()).toList(),
        if (frameLabelAnnotations != null)
          'frameLabelAnnotations':
              frameLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (inputUri != null) 'inputUri': inputUri!,
        if (logoRecognitionAnnotations != null)
          'logoRecognitionAnnotations': logoRecognitionAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (objectAnnotations != null)
          'objectAnnotations':
              objectAnnotations!.map((value) => value.toJson()).toList(),
        if (personDetectionAnnotations != null)
          'personDetectionAnnotations': personDetectionAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (segment != null) 'segment': segment!.toJson(),
        if (segmentLabelAnnotations != null)
          'segmentLabelAnnotations':
              segmentLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (segmentPresenceLabelAnnotations != null)
          'segmentPresenceLabelAnnotations': segmentPresenceLabelAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (shotAnnotations != null)
          'shotAnnotations':
              shotAnnotations!.map((value) => value.toJson()).toList(),
        if (shotLabelAnnotations != null)
          'shotLabelAnnotations':
              shotLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (shotPresenceLabelAnnotations != null)
          'shotPresenceLabelAnnotations': shotPresenceLabelAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (speechTranscriptions != null)
          'speechTranscriptions':
              speechTranscriptions!.map((value) => value.toJson()).toList(),
        if (textAnnotations != null)
          'textAnnotations':
              textAnnotations!.map((value) => value.toJson()).toList(),
      };
}

/// Video segment.
class GoogleCloudVideointelligenceV1p1beta1VideoSegment {
  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// end of the segment (inclusive).
  core.String? endTimeOffset;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// start of the segment (inclusive).
  core.String? startTimeOffset;

  GoogleCloudVideointelligenceV1p1beta1VideoSegment();

  GoogleCloudVideointelligenceV1p1beta1VideoSegment.fromJson(core.Map _json) {
    if (_json.containsKey('endTimeOffset')) {
      endTimeOffset = _json['endTimeOffset'] as core.String;
    }
    if (_json.containsKey('startTimeOffset')) {
      startTimeOffset = _json['startTimeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTimeOffset != null) 'endTimeOffset': endTimeOffset!,
        if (startTimeOffset != null) 'startTimeOffset': startTimeOffset!,
      };
}

/// Word-specific information for recognized words.
///
/// Word information is only included in the response when certain request
/// parameters are set, such as `enable_word_time_offsets`.
class GoogleCloudVideointelligenceV1p1beta1WordInfo {
  /// The confidence estimate between 0.0 and 1.0.
  ///
  /// A higher number indicates an estimated greater likelihood that the
  /// recognized words are correct. This field is set only for the top
  /// alternative. This field is not guaranteed to be accurate and users should
  /// not rely on it to be always provided. The default of 0.0 is a sentinel
  /// value indicating `confidence` was not set.
  ///
  /// Output only.
  core.double? confidence;

  /// Time offset relative to the beginning of the audio, and corresponding to
  /// the end of the spoken word.
  ///
  /// This field is only set if `enable_word_time_offsets=true` and only in the
  /// top hypothesis. This is an experimental feature and the accuracy of the
  /// time offset can vary.
  core.String? endTime;

  /// A distinct integer value is assigned for every speaker within the audio.
  ///
  /// This field specifies which one of those speakers was detected to have
  /// spoken this word. Value ranges from 1 up to diarization_speaker_count, and
  /// is only set if speaker diarization is enabled.
  ///
  /// Output only.
  core.int? speakerTag;

  /// Time offset relative to the beginning of the audio, and corresponding to
  /// the start of the spoken word.
  ///
  /// This field is only set if `enable_word_time_offsets=true` and only in the
  /// top hypothesis. This is an experimental feature and the accuracy of the
  /// time offset can vary.
  core.String? startTime;

  /// The word corresponding to this set of information.
  core.String? word;

  GoogleCloudVideointelligenceV1p1beta1WordInfo();

  GoogleCloudVideointelligenceV1p1beta1WordInfo.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('speakerTag')) {
      speakerTag = _json['speakerTag'] as core.int;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('word')) {
      word = _json['word'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (endTime != null) 'endTime': endTime!,
        if (speakerTag != null) 'speakerTag': speakerTag!,
        if (startTime != null) 'startTime': startTime!,
        if (word != null) 'word': word!,
      };
}

/// Video annotation progress.
///
/// Included in the `metadata` field of the `Operation` returned by the
/// `GetOperation` call of the `google::longrunning::Operations` service.
class GoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress {
  /// Progress metadata for all videos specified in `AnnotateVideoRequest`.
  core.List<GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress>?
      annotationProgress;

  GoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress();

  GoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress.fromJson(
      core.Map _json) {
    if (_json.containsKey('annotationProgress')) {
      annotationProgress = (_json['annotationProgress'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress>(
              (value) =>
                  GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationProgress != null)
          'annotationProgress':
              annotationProgress!.map((value) => value.toJson()).toList(),
      };
}

/// Video annotation response.
///
/// Included in the `response` field of the `Operation` returned by the
/// `GetOperation` call of the `google::longrunning::Operations` service.
class GoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse {
  /// Annotation results for all videos specified in `AnnotateVideoRequest`.
  core.List<GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults>?
      annotationResults;

  GoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse();

  GoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('annotationResults')) {
      annotationResults = (_json['annotationResults'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults>(
              (value) =>
                  GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationResults != null)
          'annotationResults':
              annotationResults!.map((value) => value.toJson()).toList(),
      };
}

/// A generic detected attribute represented by name in string format.
class GoogleCloudVideointelligenceV1p2beta1DetectedAttribute {
  /// Detected attribute confidence.
  ///
  /// Range \[0, 1\].
  core.double? confidence;

  /// The name of the attribute, for example, glasses, dark_glasses, mouth_open.
  ///
  /// A full list of supported type names will be provided in the document.
  core.String? name;

  /// Text value of the detection result.
  ///
  /// For example, the value for "HairColor" can be "black", "blonde", etc.
  core.String? value;

  GoogleCloudVideointelligenceV1p2beta1DetectedAttribute();

  GoogleCloudVideointelligenceV1p2beta1DetectedAttribute.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (name != null) 'name': name!,
        if (value != null) 'value': value!,
      };
}

/// A generic detected landmark represented by name in string format and a 2D
/// location.
class GoogleCloudVideointelligenceV1p2beta1DetectedLandmark {
  /// The confidence score of the detected landmark.
  ///
  /// Range \[0, 1\].
  core.double? confidence;

  /// The name of this landmark, for example, left_hand, right_shoulder.
  core.String? name;

  /// The 2D point of the detected landmark using the normalized image
  /// coordindate system.
  ///
  /// The normalized coordinates have the range from 0 to 1.
  GoogleCloudVideointelligenceV1p2beta1NormalizedVertex? point;

  GoogleCloudVideointelligenceV1p2beta1DetectedLandmark();

  GoogleCloudVideointelligenceV1p2beta1DetectedLandmark.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('point')) {
      point = GoogleCloudVideointelligenceV1p2beta1NormalizedVertex.fromJson(
          _json['point'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (name != null) 'name': name!,
        if (point != null) 'point': point!.toJson(),
      };
}

/// Detected entity from video analysis.
class GoogleCloudVideointelligenceV1p2beta1Entity {
  /// Textual description, e.g., `Fixed-gear bicycle`.
  core.String? description;

  /// Opaque entity ID.
  ///
  /// Some IDs may be available in
  /// [Google Knowledge Graph Search API](https://developers.google.com/knowledge-graph/).
  core.String? entityId;

  /// Language code for `description` in BCP-47 format.
  core.String? languageCode;

  GoogleCloudVideointelligenceV1p2beta1Entity();

  GoogleCloudVideointelligenceV1p2beta1Entity.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('entityId')) {
      entityId = _json['entityId'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (entityId != null) 'entityId': entityId!,
        if (languageCode != null) 'languageCode': languageCode!,
      };
}

/// Explicit content annotation (based on per-frame visual signals only).
///
/// If no explicit content has been detected in a frame, no annotations are
/// present for that frame.
class GoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation {
  /// All video frames where explicit content was detected.
  core.List<GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame>? frames;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation();

  GoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame>(
              (value) =>
                  GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotation results for explicit content.
class GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame {
  /// Likelihood of the pornography content..
  /// Possible string values are:
  /// - "LIKELIHOOD_UNSPECIFIED" : Unspecified likelihood.
  /// - "VERY_UNLIKELY" : Very unlikely.
  /// - "UNLIKELY" : Unlikely.
  /// - "POSSIBLE" : Possible.
  /// - "LIKELY" : Likely.
  /// - "VERY_LIKELY" : Very likely.
  core.String? pornographyLikelihood;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame();

  GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame.fromJson(
      core.Map _json) {
    if (_json.containsKey('pornographyLikelihood')) {
      pornographyLikelihood = _json['pornographyLikelihood'] as core.String;
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pornographyLikelihood != null)
          'pornographyLikelihood': pornographyLikelihood!,
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// No effect.
///
/// Deprecated.
class GoogleCloudVideointelligenceV1p2beta1FaceAnnotation {
  /// All video frames where a face was detected.
  core.List<GoogleCloudVideointelligenceV1p2beta1FaceFrame>? frames;

  /// All video segments where a face was detected.
  core.List<GoogleCloudVideointelligenceV1p2beta1FaceSegment>? segments;

  /// Thumbnail of a representative face view (in JPEG format).
  core.String? thumbnail;
  core.List<core.int> get thumbnailAsBytes => convert.base64.decode(thumbnail!);

  set thumbnailAsBytes(core.List<core.int> _bytes) {
    thumbnail =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  GoogleCloudVideointelligenceV1p2beta1FaceAnnotation();

  GoogleCloudVideointelligenceV1p2beta1FaceAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1FaceFrame>((value) =>
              GoogleCloudVideointelligenceV1p2beta1FaceFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1FaceSegment>((value) =>
              GoogleCloudVideointelligenceV1p2beta1FaceSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('thumbnail')) {
      thumbnail = _json['thumbnail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (thumbnail != null) 'thumbnail': thumbnail!,
      };
}

/// Face detection annotation.
class GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation {
  /// The thumbnail of a person's face.
  core.String? thumbnail;
  core.List<core.int> get thumbnailAsBytes => convert.base64.decode(thumbnail!);

  set thumbnailAsBytes(core.List<core.int> _bytes) {
    thumbnail =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The face tracks with attributes.
  core.List<GoogleCloudVideointelligenceV1p2beta1Track>? tracks;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation();

  GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('thumbnail')) {
      thumbnail = _json['thumbnail'] as core.String;
    }
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1Track>((value) =>
              GoogleCloudVideointelligenceV1p2beta1Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (thumbnail != null) 'thumbnail': thumbnail!,
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// No effect.
///
/// Deprecated.
class GoogleCloudVideointelligenceV1p2beta1FaceFrame {
  /// Normalized Bounding boxes in a frame.
  ///
  /// There can be more than one boxes if the same face is detected in multiple
  /// locations within the current frame.
  core.List<GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox>?
      normalizedBoundingBoxes;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p2beta1FaceFrame();

  GoogleCloudVideointelligenceV1p2beta1FaceFrame.fromJson(core.Map _json) {
    if (_json.containsKey('normalizedBoundingBoxes')) {
      normalizedBoundingBoxes = (_json['normalizedBoundingBoxes'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox>(
              (value) =>
                  GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (normalizedBoundingBoxes != null)
          'normalizedBoundingBoxes':
              normalizedBoundingBoxes!.map((value) => value.toJson()).toList(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for face detection.
class GoogleCloudVideointelligenceV1p2beta1FaceSegment {
  /// Video segment where a face was detected.
  GoogleCloudVideointelligenceV1p2beta1VideoSegment? segment;

  GoogleCloudVideointelligenceV1p2beta1FaceSegment();

  GoogleCloudVideointelligenceV1p2beta1FaceSegment.fromJson(core.Map _json) {
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p2beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// Label annotation.
class GoogleCloudVideointelligenceV1p2beta1LabelAnnotation {
  /// Common categories for the detected entity.
  ///
  /// For example, when the label is `Terrier`, the category is likely `dog`.
  /// And in some cases there might be more than one categories e.g., `Terrier`
  /// could also be a `pet`.
  core.List<GoogleCloudVideointelligenceV1p2beta1Entity>? categoryEntities;

  /// Detected entity.
  GoogleCloudVideointelligenceV1p2beta1Entity? entity;

  /// All video frames where a label was detected.
  core.List<GoogleCloudVideointelligenceV1p2beta1LabelFrame>? frames;

  /// All video segments where a label was detected.
  core.List<GoogleCloudVideointelligenceV1p2beta1LabelSegment>? segments;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p2beta1LabelAnnotation();

  GoogleCloudVideointelligenceV1p2beta1LabelAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('categoryEntities')) {
      categoryEntities = (_json['categoryEntities'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1Entity>((value) =>
              GoogleCloudVideointelligenceV1p2beta1Entity.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1p2beta1Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1LabelFrame>((value) =>
              GoogleCloudVideointelligenceV1p2beta1LabelFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1LabelSegment>((value) =>
              GoogleCloudVideointelligenceV1p2beta1LabelSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (categoryEntities != null)
          'categoryEntities':
              categoryEntities!.map((value) => value.toJson()).toList(),
        if (entity != null) 'entity': entity!.toJson(),
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotation results for label detection.
class GoogleCloudVideointelligenceV1p2beta1LabelFrame {
  /// Confidence that the label is accurate.
  ///
  /// Range: \[0, 1\].
  core.double? confidence;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p2beta1LabelFrame();

  GoogleCloudVideointelligenceV1p2beta1LabelFrame.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for label detection.
class GoogleCloudVideointelligenceV1p2beta1LabelSegment {
  /// Confidence that the label is accurate.
  ///
  /// Range: \[0, 1\].
  core.double? confidence;

  /// Video segment where a label was detected.
  GoogleCloudVideointelligenceV1p2beta1VideoSegment? segment;

  GoogleCloudVideointelligenceV1p2beta1LabelSegment();

  GoogleCloudVideointelligenceV1p2beta1LabelSegment.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p2beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// Annotation corresponding to one detected, tracked and recognized logo class.
class GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation {
  /// Entity category information to specify the logo class that all the logo
  /// tracks within this LogoRecognitionAnnotation are recognized as.
  GoogleCloudVideointelligenceV1p2beta1Entity? entity;

  /// All video segments where the recognized logo appears.
  ///
  /// There might be multiple instances of the same logo class appearing in one
  /// VideoSegment.
  core.List<GoogleCloudVideointelligenceV1p2beta1VideoSegment>? segments;

  /// All logo tracks where the recognized logo appears.
  ///
  /// Each track corresponds to one logo instance appearing in consecutive
  /// frames.
  core.List<GoogleCloudVideointelligenceV1p2beta1Track>? tracks;

  GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation();

  GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1p2beta1Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1VideoSegment>((value) =>
              GoogleCloudVideointelligenceV1p2beta1VideoSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1Track>((value) =>
              GoogleCloudVideointelligenceV1p2beta1Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entity != null) 'entity': entity!.toJson(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
      };
}

/// Normalized bounding box.
///
/// The normalized vertex coordinates are relative to the original image. Range:
/// \[0, 1\].
class GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox {
  /// Bottom Y coordinate.
  core.double? bottom;

  /// Left X coordinate.
  core.double? left;

  /// Right X coordinate.
  core.double? right;

  /// Top Y coordinate.
  core.double? top;

  GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox();

  GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox.fromJson(
      core.Map _json) {
    if (_json.containsKey('bottom')) {
      bottom = (_json['bottom'] as core.num).toDouble();
    }
    if (_json.containsKey('left')) {
      left = (_json['left'] as core.num).toDouble();
    }
    if (_json.containsKey('right')) {
      right = (_json['right'] as core.num).toDouble();
    }
    if (_json.containsKey('top')) {
      top = (_json['top'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bottom != null) 'bottom': bottom!,
        if (left != null) 'left': left!,
        if (right != null) 'right': right!,
        if (top != null) 'top': top!,
      };
}

/// Normalized bounding polygon for text (that might not be aligned with axis).
///
/// Contains list of the corner points in clockwise order starting from top-left
/// corner. For example, for a rectangular bounding box: When the text is
/// horizontal it might look like: 0----1 | | 3----2 When it's clockwise rotated
/// 180 degrees around the top-left corner it becomes: 2----3 | | 1----0 and the
/// vertex order will still be (0, 1, 2, 3). Note that values can be less than
/// 0, or greater than 1 due to trignometric calculations for location of the
/// box.
class GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly {
  /// Normalized vertices of the bounding polygon.
  core.List<GoogleCloudVideointelligenceV1p2beta1NormalizedVertex>? vertices;

  GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly();

  GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly.fromJson(
      core.Map _json) {
    if (_json.containsKey('vertices')) {
      vertices = (_json['vertices'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1NormalizedVertex>((value) =>
              GoogleCloudVideointelligenceV1p2beta1NormalizedVertex.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (vertices != null)
          'vertices': vertices!.map((value) => value.toJson()).toList(),
      };
}

/// A vertex represents a 2D point in the image.
///
/// NOTE: the normalized vertex coordinates are relative to the original image
/// and range from 0 to 1.
class GoogleCloudVideointelligenceV1p2beta1NormalizedVertex {
  /// X coordinate.
  core.double? x;

  /// Y coordinate.
  core.double? y;

  GoogleCloudVideointelligenceV1p2beta1NormalizedVertex();

  GoogleCloudVideointelligenceV1p2beta1NormalizedVertex.fromJson(
      core.Map _json) {
    if (_json.containsKey('x')) {
      x = (_json['x'] as core.num).toDouble();
    }
    if (_json.containsKey('y')) {
      y = (_json['y'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (x != null) 'x': x!,
        if (y != null) 'y': y!,
      };
}

/// Annotations corresponding to one tracked object.
class GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation {
  /// Object category's labeling confidence of this track.
  core.double? confidence;

  /// Entity to specify the object category that this track is labeled as.
  GoogleCloudVideointelligenceV1p2beta1Entity? entity;

  /// Information corresponding to all frames where this object track appears.
  ///
  /// Non-streaming batch mode: it may be one or multiple ObjectTrackingFrame
  /// messages in frames. Streaming mode: it can only be one ObjectTrackingFrame
  /// message in frames.
  core.List<GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame>? frames;

  /// Non-streaming batch mode ONLY.
  ///
  /// Each object track corresponds to one video segment where it appears.
  GoogleCloudVideointelligenceV1p2beta1VideoSegment? segment;

  /// Streaming mode ONLY.
  ///
  /// In streaming mode, we do not know the end time of a tracked object before
  /// it is completed. Hence, there is no VideoSegment info returned. Instead,
  /// we provide a unique identifiable integer track_id so that the customers
  /// can correlate the results of the ongoing ObjectTrackAnnotation of the same
  /// track_id over time.
  core.String? trackId;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation();

  GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1p2beta1Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame>(
              (value) =>
                  GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p2beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('trackId')) {
      trackId = _json['trackId'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (entity != null) 'entity': entity!.toJson(),
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segment != null) 'segment': segment!.toJson(),
        if (trackId != null) 'trackId': trackId!,
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotations for object detection and tracking.
///
/// This field stores per frame location, time offset, and confidence.
class GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame {
  /// The normalized bounding box location of this object track for the frame.
  GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox?
      normalizedBoundingBox;

  /// The timestamp of the frame in microseconds.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame();

  GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame.fromJson(
      core.Map _json) {
    if (_json.containsKey('normalizedBoundingBox')) {
      normalizedBoundingBox =
          GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox.fromJson(
              _json['normalizedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (normalizedBoundingBox != null)
          'normalizedBoundingBox': normalizedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Person detection annotation per video.
class GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation {
  /// The detected tracks of a person.
  core.List<GoogleCloudVideointelligenceV1p2beta1Track>? tracks;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation();

  GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1Track>((value) =>
              GoogleCloudVideointelligenceV1p2beta1Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Alternative hypotheses (a.k.a. n-best list).
class GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative {
  /// The confidence estimate between 0.0 and 1.0.
  ///
  /// A higher number indicates an estimated greater likelihood that the
  /// recognized words are correct. This field is set only for the top
  /// alternative. This field is not guaranteed to be accurate and users should
  /// not rely on it to be always provided. The default of 0.0 is a sentinel
  /// value indicating `confidence` was not set.
  ///
  /// Output only.
  core.double? confidence;

  /// Transcript text representing the words that the user spoke.
  core.String? transcript;

  /// A list of word-specific information for each recognized word.
  ///
  /// Note: When `enable_speaker_diarization` is set to true, you will see all
  /// the words from the beginning of the audio.
  ///
  /// Output only.
  core.List<GoogleCloudVideointelligenceV1p2beta1WordInfo>? words;

  GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative();

  GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('transcript')) {
      transcript = _json['transcript'] as core.String;
    }
    if (_json.containsKey('words')) {
      words = (_json['words'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1WordInfo>((value) =>
              GoogleCloudVideointelligenceV1p2beta1WordInfo.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (transcript != null) 'transcript': transcript!,
        if (words != null)
          'words': words!.map((value) => value.toJson()).toList(),
      };
}

/// A speech recognition result corresponding to a portion of the audio.
class GoogleCloudVideointelligenceV1p2beta1SpeechTranscription {
  /// May contain one or more recognition hypotheses (up to the maximum
  /// specified in `max_alternatives`).
  ///
  /// These alternatives are ordered in terms of accuracy, with the top (first)
  /// alternative being the most probable, as ranked by the recognizer.
  core.List<GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative>?
      alternatives;

  /// The \[BCP-47\](https://www.rfc-editor.org/rfc/bcp/bcp47.txt) language tag
  /// of the language in this result.
  ///
  /// This language code was detected to have the most likelihood of being
  /// spoken in the audio.
  ///
  /// Output only.
  core.String? languageCode;

  GoogleCloudVideointelligenceV1p2beta1SpeechTranscription();

  GoogleCloudVideointelligenceV1p2beta1SpeechTranscription.fromJson(
      core.Map _json) {
    if (_json.containsKey('alternatives')) {
      alternatives = (_json['alternatives'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative>(
              (value) =>
                  GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alternatives != null)
          'alternatives': alternatives!.map((value) => value.toJson()).toList(),
        if (languageCode != null) 'languageCode': languageCode!,
      };
}

/// Annotations related to one detected OCR text snippet.
///
/// This will contain the corresponding text, confidence value, and frame level
/// information for each detection.
class GoogleCloudVideointelligenceV1p2beta1TextAnnotation {
  /// All video segments where OCR detected text appears.
  core.List<GoogleCloudVideointelligenceV1p2beta1TextSegment>? segments;

  /// The detected text.
  core.String? text;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p2beta1TextAnnotation();

  GoogleCloudVideointelligenceV1p2beta1TextAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1TextSegment>((value) =>
              GoogleCloudVideointelligenceV1p2beta1TextSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (text != null) 'text': text!,
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotation results for text annotation (OCR).
///
/// Contains information regarding timestamp and bounding box locations for the
/// frames containing detected OCR text snippets.
class GoogleCloudVideointelligenceV1p2beta1TextFrame {
  /// Bounding polygon of the detected text for this frame.
  GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly?
      rotatedBoundingBox;

  /// Timestamp of this frame.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p2beta1TextFrame();

  GoogleCloudVideointelligenceV1p2beta1TextFrame.fromJson(core.Map _json) {
    if (_json.containsKey('rotatedBoundingBox')) {
      rotatedBoundingBox =
          GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly.fromJson(
              _json['rotatedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rotatedBoundingBox != null)
          'rotatedBoundingBox': rotatedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for text detection.
class GoogleCloudVideointelligenceV1p2beta1TextSegment {
  /// Confidence for the track of detected text.
  ///
  /// It is calculated as the highest over all frames where OCR detected text
  /// appears.
  core.double? confidence;

  /// Information related to the frames where OCR detected text appears.
  core.List<GoogleCloudVideointelligenceV1p2beta1TextFrame>? frames;

  /// Video segment where a text snippet was detected.
  GoogleCloudVideointelligenceV1p2beta1VideoSegment? segment;

  GoogleCloudVideointelligenceV1p2beta1TextSegment();

  GoogleCloudVideointelligenceV1p2beta1TextSegment.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1TextFrame>((value) =>
              GoogleCloudVideointelligenceV1p2beta1TextFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p2beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// For tracking related features.
///
/// An object at time_offset with attributes, and located with
/// normalized_bounding_box.
class GoogleCloudVideointelligenceV1p2beta1TimestampedObject {
  /// The attributes of the object in the bounding box.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1p2beta1DetectedAttribute>? attributes;

  /// The detected landmarks.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1p2beta1DetectedLandmark>? landmarks;

  /// Normalized Bounding box in a frame, where the object is located.
  GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox?
      normalizedBoundingBox;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this object.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p2beta1TimestampedObject();

  GoogleCloudVideointelligenceV1p2beta1TimestampedObject.fromJson(
      core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = (_json['attributes'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1DetectedAttribute>(
              (value) => GoogleCloudVideointelligenceV1p2beta1DetectedAttribute
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('landmarks')) {
      landmarks = (_json['landmarks'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1DetectedLandmark>((value) =>
              GoogleCloudVideointelligenceV1p2beta1DetectedLandmark.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('normalizedBoundingBox')) {
      normalizedBoundingBox =
          GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox.fromJson(
              _json['normalizedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null)
          'attributes': attributes!.map((value) => value.toJson()).toList(),
        if (landmarks != null)
          'landmarks': landmarks!.map((value) => value.toJson()).toList(),
        if (normalizedBoundingBox != null)
          'normalizedBoundingBox': normalizedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// A track of an object instance.
class GoogleCloudVideointelligenceV1p2beta1Track {
  /// Attributes in the track level.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1p2beta1DetectedAttribute>? attributes;

  /// The confidence score of the tracked object.
  ///
  /// Optional.
  core.double? confidence;

  /// Video segment of a track.
  GoogleCloudVideointelligenceV1p2beta1VideoSegment? segment;

  /// The object with timestamp and attributes per frame in the track.
  core.List<GoogleCloudVideointelligenceV1p2beta1TimestampedObject>?
      timestampedObjects;

  GoogleCloudVideointelligenceV1p2beta1Track();

  GoogleCloudVideointelligenceV1p2beta1Track.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = (_json['attributes'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1DetectedAttribute>(
              (value) => GoogleCloudVideointelligenceV1p2beta1DetectedAttribute
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p2beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timestampedObjects')) {
      timestampedObjects = (_json['timestampedObjects'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1TimestampedObject>(
              (value) => GoogleCloudVideointelligenceV1p2beta1TimestampedObject
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null)
          'attributes': attributes!.map((value) => value.toJson()).toList(),
        if (confidence != null) 'confidence': confidence!,
        if (segment != null) 'segment': segment!.toJson(),
        if (timestampedObjects != null)
          'timestampedObjects':
              timestampedObjects!.map((value) => value.toJson()).toList(),
      };
}

/// Annotation progress for a single video.
class GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress {
  /// Specifies which feature is being tracked if the request contains more than
  /// one feature.
  /// Possible string values are:
  /// - "FEATURE_UNSPECIFIED" : Unspecified.
  /// - "LABEL_DETECTION" : Label detection. Detect objects, such as dog or
  /// flower.
  /// - "SHOT_CHANGE_DETECTION" : Shot change detection.
  /// - "EXPLICIT_CONTENT_DETECTION" : Explicit content detection.
  /// - "FACE_DETECTION" : Human face detection.
  /// - "SPEECH_TRANSCRIPTION" : Speech transcription.
  /// - "TEXT_DETECTION" : OCR text detection and tracking.
  /// - "OBJECT_TRACKING" : Object detection and tracking.
  /// - "LOGO_RECOGNITION" : Logo detection, tracking, and recognition.
  /// - "PERSON_DETECTION" : Person detection.
  core.String? feature;

  /// Video file location in [Cloud Storage](https://cloud.google.com/storage/).
  core.String? inputUri;

  /// Approximate percentage processed thus far.
  ///
  /// Guaranteed to be 100 when fully processed.
  core.int? progressPercent;

  /// Specifies which segment is being tracked if the request contains more than
  /// one segment.
  GoogleCloudVideointelligenceV1p2beta1VideoSegment? segment;

  /// Time when the request was received.
  core.String? startTime;

  /// Time of the most recent update.
  core.String? updateTime;

  GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress();

  GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress.fromJson(
      core.Map _json) {
    if (_json.containsKey('feature')) {
      feature = _json['feature'] as core.String;
    }
    if (_json.containsKey('inputUri')) {
      inputUri = _json['inputUri'] as core.String;
    }
    if (_json.containsKey('progressPercent')) {
      progressPercent = _json['progressPercent'] as core.int;
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p2beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (feature != null) 'feature': feature!,
        if (inputUri != null) 'inputUri': inputUri!,
        if (progressPercent != null) 'progressPercent': progressPercent!,
        if (segment != null) 'segment': segment!.toJson(),
        if (startTime != null) 'startTime': startTime!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Annotation results for a single video.
class GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults {
  /// If set, indicates an error.
  ///
  /// Note that for a single `AnnotateVideoRequest` some videos may succeed and
  /// some may fail.
  GoogleRpcStatus? error;

  /// Explicit content annotation.
  GoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation?
      explicitAnnotation;

  /// Please use `face_detection_annotations` instead.
  ///
  /// Deprecated.
  core.List<GoogleCloudVideointelligenceV1p2beta1FaceAnnotation>?
      faceAnnotations;

  /// Face detection annotations.
  core.List<GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation>?
      faceDetectionAnnotations;

  /// Label annotations on frame level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>?
      frameLabelAnnotations;

  /// Video file location in [Cloud Storage](https://cloud.google.com/storage/).
  core.String? inputUri;

  /// Annotations for list of logos detected, tracked and recognized in video.
  core.List<GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation>?
      logoRecognitionAnnotations;

  /// Annotations for list of objects detected and tracked in video.
  core.List<GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation>?
      objectAnnotations;

  /// Person detection annotations.
  core.List<GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation>?
      personDetectionAnnotations;

  /// Video segment on which the annotation is run.
  GoogleCloudVideointelligenceV1p2beta1VideoSegment? segment;

  /// Topical label annotations on video level or user-specified segment level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>?
      segmentLabelAnnotations;

  /// Presence label annotations on video level or user-specified segment level.
  ///
  /// There is exactly one element for each unique label. Compared to the
  /// existing topical `segment_label_annotations`, this field presents more
  /// fine-grained, segment-level labels detected in video content and is made
  /// available only when the client sets `LabelDetectionConfig.model` to
  /// "builtin/latest" in the request.
  core.List<GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>?
      segmentPresenceLabelAnnotations;

  /// Shot annotations.
  ///
  /// Each shot is represented as a video segment.
  core.List<GoogleCloudVideointelligenceV1p2beta1VideoSegment>? shotAnnotations;

  /// Topical label annotations on shot level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>?
      shotLabelAnnotations;

  /// Presence label annotations on shot level.
  ///
  /// There is exactly one element for each unique label. Compared to the
  /// existing topical `shot_label_annotations`, this field presents more
  /// fine-grained, shot-level labels detected in video content and is made
  /// available only when the client sets `LabelDetectionConfig.model` to
  /// "builtin/latest" in the request.
  core.List<GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>?
      shotPresenceLabelAnnotations;

  /// Speech transcription.
  core.List<GoogleCloudVideointelligenceV1p2beta1SpeechTranscription>?
      speechTranscriptions;

  /// OCR text detection and tracking.
  ///
  /// Annotations for list of detected text snippets. Each will have list of
  /// frame information associated with it.
  core.List<GoogleCloudVideointelligenceV1p2beta1TextAnnotation>?
      textAnnotations;

  GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults();

  GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults.fromJson(
      core.Map _json) {
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('explicitAnnotation')) {
      explicitAnnotation =
          GoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation
              .fromJson(_json['explicitAnnotation']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('faceAnnotations')) {
      faceAnnotations = (_json['faceAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1FaceAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p2beta1FaceAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('faceDetectionAnnotations')) {
      faceDetectionAnnotations = (_json['faceDetectionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('frameLabelAnnotations')) {
      frameLabelAnnotations = (_json['frameLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p2beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('inputUri')) {
      inputUri = _json['inputUri'] as core.String;
    }
    if (_json.containsKey('logoRecognitionAnnotations')) {
      logoRecognitionAnnotations = (_json['logoRecognitionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('objectAnnotations')) {
      objectAnnotations = (_json['objectAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('personDetectionAnnotations')) {
      personDetectionAnnotations = (_json['personDetectionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p2beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('segmentLabelAnnotations')) {
      segmentLabelAnnotations = (_json['segmentLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p2beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segmentPresenceLabelAnnotations')) {
      segmentPresenceLabelAnnotations = (_json[
              'segmentPresenceLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p2beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotAnnotations')) {
      shotAnnotations = (_json['shotAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1VideoSegment>((value) =>
              GoogleCloudVideointelligenceV1p2beta1VideoSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotLabelAnnotations')) {
      shotLabelAnnotations = (_json['shotLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p2beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotPresenceLabelAnnotations')) {
      shotPresenceLabelAnnotations = (_json['shotPresenceLabelAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p2beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('speechTranscriptions')) {
      speechTranscriptions = (_json['speechTranscriptions'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1SpeechTranscription>(
              (value) =>
                  GoogleCloudVideointelligenceV1p2beta1SpeechTranscription
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('textAnnotations')) {
      textAnnotations = (_json['textAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p2beta1TextAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p2beta1TextAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (error != null) 'error': error!.toJson(),
        if (explicitAnnotation != null)
          'explicitAnnotation': explicitAnnotation!.toJson(),
        if (faceAnnotations != null)
          'faceAnnotations':
              faceAnnotations!.map((value) => value.toJson()).toList(),
        if (faceDetectionAnnotations != null)
          'faceDetectionAnnotations':
              faceDetectionAnnotations!.map((value) => value.toJson()).toList(),
        if (frameLabelAnnotations != null)
          'frameLabelAnnotations':
              frameLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (inputUri != null) 'inputUri': inputUri!,
        if (logoRecognitionAnnotations != null)
          'logoRecognitionAnnotations': logoRecognitionAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (objectAnnotations != null)
          'objectAnnotations':
              objectAnnotations!.map((value) => value.toJson()).toList(),
        if (personDetectionAnnotations != null)
          'personDetectionAnnotations': personDetectionAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (segment != null) 'segment': segment!.toJson(),
        if (segmentLabelAnnotations != null)
          'segmentLabelAnnotations':
              segmentLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (segmentPresenceLabelAnnotations != null)
          'segmentPresenceLabelAnnotations': segmentPresenceLabelAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (shotAnnotations != null)
          'shotAnnotations':
              shotAnnotations!.map((value) => value.toJson()).toList(),
        if (shotLabelAnnotations != null)
          'shotLabelAnnotations':
              shotLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (shotPresenceLabelAnnotations != null)
          'shotPresenceLabelAnnotations': shotPresenceLabelAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (speechTranscriptions != null)
          'speechTranscriptions':
              speechTranscriptions!.map((value) => value.toJson()).toList(),
        if (textAnnotations != null)
          'textAnnotations':
              textAnnotations!.map((value) => value.toJson()).toList(),
      };
}

/// Video segment.
class GoogleCloudVideointelligenceV1p2beta1VideoSegment {
  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// end of the segment (inclusive).
  core.String? endTimeOffset;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// start of the segment (inclusive).
  core.String? startTimeOffset;

  GoogleCloudVideointelligenceV1p2beta1VideoSegment();

  GoogleCloudVideointelligenceV1p2beta1VideoSegment.fromJson(core.Map _json) {
    if (_json.containsKey('endTimeOffset')) {
      endTimeOffset = _json['endTimeOffset'] as core.String;
    }
    if (_json.containsKey('startTimeOffset')) {
      startTimeOffset = _json['startTimeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTimeOffset != null) 'endTimeOffset': endTimeOffset!,
        if (startTimeOffset != null) 'startTimeOffset': startTimeOffset!,
      };
}

/// Word-specific information for recognized words.
///
/// Word information is only included in the response when certain request
/// parameters are set, such as `enable_word_time_offsets`.
class GoogleCloudVideointelligenceV1p2beta1WordInfo {
  /// The confidence estimate between 0.0 and 1.0.
  ///
  /// A higher number indicates an estimated greater likelihood that the
  /// recognized words are correct. This field is set only for the top
  /// alternative. This field is not guaranteed to be accurate and users should
  /// not rely on it to be always provided. The default of 0.0 is a sentinel
  /// value indicating `confidence` was not set.
  ///
  /// Output only.
  core.double? confidence;

  /// Time offset relative to the beginning of the audio, and corresponding to
  /// the end of the spoken word.
  ///
  /// This field is only set if `enable_word_time_offsets=true` and only in the
  /// top hypothesis. This is an experimental feature and the accuracy of the
  /// time offset can vary.
  core.String? endTime;

  /// A distinct integer value is assigned for every speaker within the audio.
  ///
  /// This field specifies which one of those speakers was detected to have
  /// spoken this word. Value ranges from 1 up to diarization_speaker_count, and
  /// is only set if speaker diarization is enabled.
  ///
  /// Output only.
  core.int? speakerTag;

  /// Time offset relative to the beginning of the audio, and corresponding to
  /// the start of the spoken word.
  ///
  /// This field is only set if `enable_word_time_offsets=true` and only in the
  /// top hypothesis. This is an experimental feature and the accuracy of the
  /// time offset can vary.
  core.String? startTime;

  /// The word corresponding to this set of information.
  core.String? word;

  GoogleCloudVideointelligenceV1p2beta1WordInfo();

  GoogleCloudVideointelligenceV1p2beta1WordInfo.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('speakerTag')) {
      speakerTag = _json['speakerTag'] as core.int;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('word')) {
      word = _json['word'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (endTime != null) 'endTime': endTime!,
        if (speakerTag != null) 'speakerTag': speakerTag!,
        if (startTime != null) 'startTime': startTime!,
        if (word != null) 'word': word!,
      };
}

/// Video annotation progress.
///
/// Included in the `metadata` field of the `Operation` returned by the
/// `GetOperation` call of the `google::longrunning::Operations` service.
class GoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress {
  /// Progress metadata for all videos specified in `AnnotateVideoRequest`.
  core.List<GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress>?
      annotationProgress;

  GoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress();

  GoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress.fromJson(
      core.Map _json) {
    if (_json.containsKey('annotationProgress')) {
      annotationProgress = (_json['annotationProgress'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress>(
              (value) =>
                  GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationProgress != null)
          'annotationProgress':
              annotationProgress!.map((value) => value.toJson()).toList(),
      };
}

/// Video annotation response.
///
/// Included in the `response` field of the `Operation` returned by the
/// `GetOperation` call of the `google::longrunning::Operations` service.
class GoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse {
  /// Annotation results for all videos specified in `AnnotateVideoRequest`.
  core.List<GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults>?
      annotationResults;

  GoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse();

  GoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('annotationResults')) {
      annotationResults = (_json['annotationResults'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults>(
              (value) =>
                  GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationResults != null)
          'annotationResults':
              annotationResults!.map((value) => value.toJson()).toList(),
      };
}

/// Celebrity definition.
class GoogleCloudVideointelligenceV1p3beta1Celebrity {
  /// Textual description of additional information about the celebrity, if
  /// applicable.
  core.String? description;

  /// The celebrity name.
  core.String? displayName;

  /// The resource name of the celebrity.
  ///
  /// Have the format `video-intelligence/kg-mid` indicates a celebrity from
  /// preloaded gallery. kg-mid is the id in Google knowledge graph, which is
  /// unique for the celebrity.
  core.String? name;

  GoogleCloudVideointelligenceV1p3beta1Celebrity();

  GoogleCloudVideointelligenceV1p3beta1Celebrity.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('displayName')) {
      displayName = _json['displayName'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (displayName != null) 'displayName': displayName!,
        if (name != null) 'name': name!,
      };
}

/// Celebrity recognition annotation per video.
class GoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation {
  /// The tracks detected from the input video, including recognized celebrities
  /// and other detected faces in the video.
  core.List<GoogleCloudVideointelligenceV1p3beta1CelebrityTrack>?
      celebrityTracks;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation();

  GoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('celebrityTracks')) {
      celebrityTracks = (_json['celebrityTracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1CelebrityTrack>((value) =>
              GoogleCloudVideointelligenceV1p3beta1CelebrityTrack.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (celebrityTracks != null)
          'celebrityTracks':
              celebrityTracks!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// The annotation result of a celebrity face track.
///
/// RecognizedCelebrity field could be empty if the face track does not have any
/// matched celebrities.
class GoogleCloudVideointelligenceV1p3beta1CelebrityTrack {
  /// Top N match of the celebrities for the face in this track.
  core.List<GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity>?
      celebrities;

  /// A track of a person's face.
  GoogleCloudVideointelligenceV1p3beta1Track? faceTrack;

  GoogleCloudVideointelligenceV1p3beta1CelebrityTrack();

  GoogleCloudVideointelligenceV1p3beta1CelebrityTrack.fromJson(core.Map _json) {
    if (_json.containsKey('celebrities')) {
      celebrities = (_json['celebrities'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity>(
              (value) =>
                  GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('faceTrack')) {
      faceTrack = GoogleCloudVideointelligenceV1p3beta1Track.fromJson(
          _json['faceTrack'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (celebrities != null)
          'celebrities': celebrities!.map((value) => value.toJson()).toList(),
        if (faceTrack != null) 'faceTrack': faceTrack!.toJson(),
      };
}

/// A generic detected attribute represented by name in string format.
class GoogleCloudVideointelligenceV1p3beta1DetectedAttribute {
  /// Detected attribute confidence.
  ///
  /// Range \[0, 1\].
  core.double? confidence;

  /// The name of the attribute, for example, glasses, dark_glasses, mouth_open.
  ///
  /// A full list of supported type names will be provided in the document.
  core.String? name;

  /// Text value of the detection result.
  ///
  /// For example, the value for "HairColor" can be "black", "blonde", etc.
  core.String? value;

  GoogleCloudVideointelligenceV1p3beta1DetectedAttribute();

  GoogleCloudVideointelligenceV1p3beta1DetectedAttribute.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (name != null) 'name': name!,
        if (value != null) 'value': value!,
      };
}

/// A generic detected landmark represented by name in string format and a 2D
/// location.
class GoogleCloudVideointelligenceV1p3beta1DetectedLandmark {
  /// The confidence score of the detected landmark.
  ///
  /// Range \[0, 1\].
  core.double? confidence;

  /// The name of this landmark, for example, left_hand, right_shoulder.
  core.String? name;

  /// The 2D point of the detected landmark using the normalized image
  /// coordindate system.
  ///
  /// The normalized coordinates have the range from 0 to 1.
  GoogleCloudVideointelligenceV1p3beta1NormalizedVertex? point;

  GoogleCloudVideointelligenceV1p3beta1DetectedLandmark();

  GoogleCloudVideointelligenceV1p3beta1DetectedLandmark.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('point')) {
      point = GoogleCloudVideointelligenceV1p3beta1NormalizedVertex.fromJson(
          _json['point'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (name != null) 'name': name!,
        if (point != null) 'point': point!.toJson(),
      };
}

/// Detected entity from video analysis.
class GoogleCloudVideointelligenceV1p3beta1Entity {
  /// Textual description, e.g., `Fixed-gear bicycle`.
  core.String? description;

  /// Opaque entity ID.
  ///
  /// Some IDs may be available in
  /// [Google Knowledge Graph Search API](https://developers.google.com/knowledge-graph/).
  core.String? entityId;

  /// Language code for `description` in BCP-47 format.
  core.String? languageCode;

  GoogleCloudVideointelligenceV1p3beta1Entity();

  GoogleCloudVideointelligenceV1p3beta1Entity.fromJson(core.Map _json) {
    if (_json.containsKey('description')) {
      description = _json['description'] as core.String;
    }
    if (_json.containsKey('entityId')) {
      entityId = _json['entityId'] as core.String;
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (description != null) 'description': description!,
        if (entityId != null) 'entityId': entityId!,
        if (languageCode != null) 'languageCode': languageCode!,
      };
}

/// Explicit content annotation (based on per-frame visual signals only).
///
/// If no explicit content has been detected in a frame, no annotations are
/// present for that frame.
class GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation {
  /// All video frames where explicit content was detected.
  core.List<GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame>? frames;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation();

  GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame>(
              (value) =>
                  GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotation results for explicit content.
class GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame {
  /// Likelihood of the pornography content..
  /// Possible string values are:
  /// - "LIKELIHOOD_UNSPECIFIED" : Unspecified likelihood.
  /// - "VERY_UNLIKELY" : Very unlikely.
  /// - "UNLIKELY" : Unlikely.
  /// - "POSSIBLE" : Possible.
  /// - "LIKELY" : Likely.
  /// - "VERY_LIKELY" : Very likely.
  core.String? pornographyLikelihood;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame();

  GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame.fromJson(
      core.Map _json) {
    if (_json.containsKey('pornographyLikelihood')) {
      pornographyLikelihood = _json['pornographyLikelihood'] as core.String;
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (pornographyLikelihood != null)
          'pornographyLikelihood': pornographyLikelihood!,
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// No effect.
///
/// Deprecated.
class GoogleCloudVideointelligenceV1p3beta1FaceAnnotation {
  /// All video frames where a face was detected.
  core.List<GoogleCloudVideointelligenceV1p3beta1FaceFrame>? frames;

  /// All video segments where a face was detected.
  core.List<GoogleCloudVideointelligenceV1p3beta1FaceSegment>? segments;

  /// Thumbnail of a representative face view (in JPEG format).
  core.String? thumbnail;
  core.List<core.int> get thumbnailAsBytes => convert.base64.decode(thumbnail!);

  set thumbnailAsBytes(core.List<core.int> _bytes) {
    thumbnail =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  GoogleCloudVideointelligenceV1p3beta1FaceAnnotation();

  GoogleCloudVideointelligenceV1p3beta1FaceAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1FaceFrame>((value) =>
              GoogleCloudVideointelligenceV1p3beta1FaceFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1FaceSegment>((value) =>
              GoogleCloudVideointelligenceV1p3beta1FaceSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('thumbnail')) {
      thumbnail = _json['thumbnail'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (thumbnail != null) 'thumbnail': thumbnail!,
      };
}

/// Face detection annotation.
class GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation {
  /// The thumbnail of a person's face.
  core.String? thumbnail;
  core.List<core.int> get thumbnailAsBytes => convert.base64.decode(thumbnail!);

  set thumbnailAsBytes(core.List<core.int> _bytes) {
    thumbnail =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// The face tracks with attributes.
  core.List<GoogleCloudVideointelligenceV1p3beta1Track>? tracks;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation();

  GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('thumbnail')) {
      thumbnail = _json['thumbnail'] as core.String;
    }
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1Track>((value) =>
              GoogleCloudVideointelligenceV1p3beta1Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (thumbnail != null) 'thumbnail': thumbnail!,
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// No effect.
///
/// Deprecated.
class GoogleCloudVideointelligenceV1p3beta1FaceFrame {
  /// Normalized Bounding boxes in a frame.
  ///
  /// There can be more than one boxes if the same face is detected in multiple
  /// locations within the current frame.
  core.List<GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox>?
      normalizedBoundingBoxes;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p3beta1FaceFrame();

  GoogleCloudVideointelligenceV1p3beta1FaceFrame.fromJson(core.Map _json) {
    if (_json.containsKey('normalizedBoundingBoxes')) {
      normalizedBoundingBoxes = (_json['normalizedBoundingBoxes'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox>(
              (value) =>
                  GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (normalizedBoundingBoxes != null)
          'normalizedBoundingBoxes':
              normalizedBoundingBoxes!.map((value) => value.toJson()).toList(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for face detection.
class GoogleCloudVideointelligenceV1p3beta1FaceSegment {
  /// Video segment where a face was detected.
  GoogleCloudVideointelligenceV1p3beta1VideoSegment? segment;

  GoogleCloudVideointelligenceV1p3beta1FaceSegment();

  GoogleCloudVideointelligenceV1p3beta1FaceSegment.fromJson(core.Map _json) {
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p3beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// Label annotation.
class GoogleCloudVideointelligenceV1p3beta1LabelAnnotation {
  /// Common categories for the detected entity.
  ///
  /// For example, when the label is `Terrier`, the category is likely `dog`.
  /// And in some cases there might be more than one categories e.g., `Terrier`
  /// could also be a `pet`.
  core.List<GoogleCloudVideointelligenceV1p3beta1Entity>? categoryEntities;

  /// Detected entity.
  GoogleCloudVideointelligenceV1p3beta1Entity? entity;

  /// All video frames where a label was detected.
  core.List<GoogleCloudVideointelligenceV1p3beta1LabelFrame>? frames;

  /// All video segments where a label was detected.
  core.List<GoogleCloudVideointelligenceV1p3beta1LabelSegment>? segments;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p3beta1LabelAnnotation();

  GoogleCloudVideointelligenceV1p3beta1LabelAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('categoryEntities')) {
      categoryEntities = (_json['categoryEntities'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1Entity>((value) =>
              GoogleCloudVideointelligenceV1p3beta1Entity.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1p3beta1Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1LabelFrame>((value) =>
              GoogleCloudVideointelligenceV1p3beta1LabelFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1LabelSegment>((value) =>
              GoogleCloudVideointelligenceV1p3beta1LabelSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (categoryEntities != null)
          'categoryEntities':
              categoryEntities!.map((value) => value.toJson()).toList(),
        if (entity != null) 'entity': entity!.toJson(),
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotation results for label detection.
class GoogleCloudVideointelligenceV1p3beta1LabelFrame {
  /// Confidence that the label is accurate.
  ///
  /// Range: \[0, 1\].
  core.double? confidence;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this location.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p3beta1LabelFrame();

  GoogleCloudVideointelligenceV1p3beta1LabelFrame.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for label detection.
class GoogleCloudVideointelligenceV1p3beta1LabelSegment {
  /// Confidence that the label is accurate.
  ///
  /// Range: \[0, 1\].
  core.double? confidence;

  /// Video segment where a label was detected.
  GoogleCloudVideointelligenceV1p3beta1VideoSegment? segment;

  GoogleCloudVideointelligenceV1p3beta1LabelSegment();

  GoogleCloudVideointelligenceV1p3beta1LabelSegment.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p3beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// Annotation corresponding to one detected, tracked and recognized logo class.
class GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation {
  /// Entity category information to specify the logo class that all the logo
  /// tracks within this LogoRecognitionAnnotation are recognized as.
  GoogleCloudVideointelligenceV1p3beta1Entity? entity;

  /// All video segments where the recognized logo appears.
  ///
  /// There might be multiple instances of the same logo class appearing in one
  /// VideoSegment.
  core.List<GoogleCloudVideointelligenceV1p3beta1VideoSegment>? segments;

  /// All logo tracks where the recognized logo appears.
  ///
  /// Each track corresponds to one logo instance appearing in consecutive
  /// frames.
  core.List<GoogleCloudVideointelligenceV1p3beta1Track>? tracks;

  GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation();

  GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1p3beta1Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1VideoSegment>((value) =>
              GoogleCloudVideointelligenceV1p3beta1VideoSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1Track>((value) =>
              GoogleCloudVideointelligenceV1p3beta1Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (entity != null) 'entity': entity!.toJson(),
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
      };
}

/// Normalized bounding box.
///
/// The normalized vertex coordinates are relative to the original image. Range:
/// \[0, 1\].
class GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox {
  /// Bottom Y coordinate.
  core.double? bottom;

  /// Left X coordinate.
  core.double? left;

  /// Right X coordinate.
  core.double? right;

  /// Top Y coordinate.
  core.double? top;

  GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox();

  GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox.fromJson(
      core.Map _json) {
    if (_json.containsKey('bottom')) {
      bottom = (_json['bottom'] as core.num).toDouble();
    }
    if (_json.containsKey('left')) {
      left = (_json['left'] as core.num).toDouble();
    }
    if (_json.containsKey('right')) {
      right = (_json['right'] as core.num).toDouble();
    }
    if (_json.containsKey('top')) {
      top = (_json['top'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bottom != null) 'bottom': bottom!,
        if (left != null) 'left': left!,
        if (right != null) 'right': right!,
        if (top != null) 'top': top!,
      };
}

/// Normalized bounding polygon for text (that might not be aligned with axis).
///
/// Contains list of the corner points in clockwise order starting from top-left
/// corner. For example, for a rectangular bounding box: When the text is
/// horizontal it might look like: 0----1 | | 3----2 When it's clockwise rotated
/// 180 degrees around the top-left corner it becomes: 2----3 | | 1----0 and the
/// vertex order will still be (0, 1, 2, 3). Note that values can be less than
/// 0, or greater than 1 due to trignometric calculations for location of the
/// box.
class GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly {
  /// Normalized vertices of the bounding polygon.
  core.List<GoogleCloudVideointelligenceV1p3beta1NormalizedVertex>? vertices;

  GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly();

  GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly.fromJson(
      core.Map _json) {
    if (_json.containsKey('vertices')) {
      vertices = (_json['vertices'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1NormalizedVertex>((value) =>
              GoogleCloudVideointelligenceV1p3beta1NormalizedVertex.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (vertices != null)
          'vertices': vertices!.map((value) => value.toJson()).toList(),
      };
}

/// A vertex represents a 2D point in the image.
///
/// NOTE: the normalized vertex coordinates are relative to the original image
/// and range from 0 to 1.
class GoogleCloudVideointelligenceV1p3beta1NormalizedVertex {
  /// X coordinate.
  core.double? x;

  /// Y coordinate.
  core.double? y;

  GoogleCloudVideointelligenceV1p3beta1NormalizedVertex();

  GoogleCloudVideointelligenceV1p3beta1NormalizedVertex.fromJson(
      core.Map _json) {
    if (_json.containsKey('x')) {
      x = (_json['x'] as core.num).toDouble();
    }
    if (_json.containsKey('y')) {
      y = (_json['y'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (x != null) 'x': x!,
        if (y != null) 'y': y!,
      };
}

/// Annotations corresponding to one tracked object.
class GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation {
  /// Object category's labeling confidence of this track.
  core.double? confidence;

  /// Entity to specify the object category that this track is labeled as.
  GoogleCloudVideointelligenceV1p3beta1Entity? entity;

  /// Information corresponding to all frames where this object track appears.
  ///
  /// Non-streaming batch mode: it may be one or multiple ObjectTrackingFrame
  /// messages in frames. Streaming mode: it can only be one ObjectTrackingFrame
  /// message in frames.
  core.List<GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame>? frames;

  /// Non-streaming batch mode ONLY.
  ///
  /// Each object track corresponds to one video segment where it appears.
  GoogleCloudVideointelligenceV1p3beta1VideoSegment? segment;

  /// Streaming mode ONLY.
  ///
  /// In streaming mode, we do not know the end time of a tracked object before
  /// it is completed. Hence, there is no VideoSegment info returned. Instead,
  /// we provide a unique identifiable integer track_id so that the customers
  /// can correlate the results of the ongoing ObjectTrackAnnotation of the same
  /// track_id over time.
  core.String? trackId;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation();

  GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('entity')) {
      entity = GoogleCloudVideointelligenceV1p3beta1Entity.fromJson(
          _json['entity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame>(
              (value) =>
                  GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p3beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('trackId')) {
      trackId = _json['trackId'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (entity != null) 'entity': entity!.toJson(),
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segment != null) 'segment': segment!.toJson(),
        if (trackId != null) 'trackId': trackId!,
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotations for object detection and tracking.
///
/// This field stores per frame location, time offset, and confidence.
class GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame {
  /// The normalized bounding box location of this object track for the frame.
  GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox?
      normalizedBoundingBox;

  /// The timestamp of the frame in microseconds.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame();

  GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame.fromJson(
      core.Map _json) {
    if (_json.containsKey('normalizedBoundingBox')) {
      normalizedBoundingBox =
          GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox.fromJson(
              _json['normalizedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (normalizedBoundingBox != null)
          'normalizedBoundingBox': normalizedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Person detection annotation per video.
class GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation {
  /// The detected tracks of a person.
  core.List<GoogleCloudVideointelligenceV1p3beta1Track>? tracks;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation();

  GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation.fromJson(
      core.Map _json) {
    if (_json.containsKey('tracks')) {
      tracks = (_json['tracks'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1Track>((value) =>
              GoogleCloudVideointelligenceV1p3beta1Track.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (tracks != null)
          'tracks': tracks!.map((value) => value.toJson()).toList(),
        if (version != null) 'version': version!,
      };
}

/// The recognized celebrity with confidence score.
class GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity {
  /// The recognized celebrity.
  GoogleCloudVideointelligenceV1p3beta1Celebrity? celebrity;

  /// Recognition confidence.
  ///
  /// Range \[0, 1\].
  core.double? confidence;

  GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity();

  GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity.fromJson(
      core.Map _json) {
    if (_json.containsKey('celebrity')) {
      celebrity = GoogleCloudVideointelligenceV1p3beta1Celebrity.fromJson(
          _json['celebrity'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (celebrity != null) 'celebrity': celebrity!.toJson(),
        if (confidence != null) 'confidence': confidence!,
      };
}

/// Alternative hypotheses (a.k.a. n-best list).
class GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative {
  /// The confidence estimate between 0.0 and 1.0.
  ///
  /// A higher number indicates an estimated greater likelihood that the
  /// recognized words are correct. This field is set only for the top
  /// alternative. This field is not guaranteed to be accurate and users should
  /// not rely on it to be always provided. The default of 0.0 is a sentinel
  /// value indicating `confidence` was not set.
  ///
  /// Output only.
  core.double? confidence;

  /// Transcript text representing the words that the user spoke.
  core.String? transcript;

  /// A list of word-specific information for each recognized word.
  ///
  /// Note: When `enable_speaker_diarization` is set to true, you will see all
  /// the words from the beginning of the audio.
  ///
  /// Output only.
  core.List<GoogleCloudVideointelligenceV1p3beta1WordInfo>? words;

  GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative();

  GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative.fromJson(
      core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('transcript')) {
      transcript = _json['transcript'] as core.String;
    }
    if (_json.containsKey('words')) {
      words = (_json['words'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1WordInfo>((value) =>
              GoogleCloudVideointelligenceV1p3beta1WordInfo.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (transcript != null) 'transcript': transcript!,
        if (words != null)
          'words': words!.map((value) => value.toJson()).toList(),
      };
}

/// A speech recognition result corresponding to a portion of the audio.
class GoogleCloudVideointelligenceV1p3beta1SpeechTranscription {
  /// May contain one or more recognition hypotheses (up to the maximum
  /// specified in `max_alternatives`).
  ///
  /// These alternatives are ordered in terms of accuracy, with the top (first)
  /// alternative being the most probable, as ranked by the recognizer.
  core.List<GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative>?
      alternatives;

  /// The \[BCP-47\](https://www.rfc-editor.org/rfc/bcp/bcp47.txt) language tag
  /// of the language in this result.
  ///
  /// This language code was detected to have the most likelihood of being
  /// spoken in the audio.
  ///
  /// Output only.
  core.String? languageCode;

  GoogleCloudVideointelligenceV1p3beta1SpeechTranscription();

  GoogleCloudVideointelligenceV1p3beta1SpeechTranscription.fromJson(
      core.Map _json) {
    if (_json.containsKey('alternatives')) {
      alternatives = (_json['alternatives'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative>(
              (value) =>
                  GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('languageCode')) {
      languageCode = _json['languageCode'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (alternatives != null)
          'alternatives': alternatives!.map((value) => value.toJson()).toList(),
        if (languageCode != null) 'languageCode': languageCode!,
      };
}

/// `StreamingAnnotateVideoResponse` is the only message returned to the client
/// by `StreamingAnnotateVideo`.
///
/// A series of zero or more `StreamingAnnotateVideoResponse` messages are
/// streamed back to the client.
class GoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse {
  /// Streaming annotation results.
  GoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults?
      annotationResults;

  /// Google Cloud Storage URI that stores annotation results of one streaming
  /// session in JSON format.
  ///
  /// It is the annotation_result_storage_directory from the request followed by
  /// '/cloud_project_number-session_id'.
  core.String? annotationResultsUri;

  /// If set, returns a google.rpc.Status message that specifies the error for
  /// the operation.
  GoogleRpcStatus? error;

  GoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse();

  GoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse.fromJson(
      core.Map _json) {
    if (_json.containsKey('annotationResults')) {
      annotationResults =
          GoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults
              .fromJson(_json['annotationResults']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('annotationResultsUri')) {
      annotationResultsUri = _json['annotationResultsUri'] as core.String;
    }
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotationResults != null)
          'annotationResults': annotationResults!.toJson(),
        if (annotationResultsUri != null)
          'annotationResultsUri': annotationResultsUri!,
        if (error != null) 'error': error!.toJson(),
      };
}

/// Streaming annotation results corresponding to a portion of the video that is
/// currently being processed.
///
/// Only ONE type of annotation will be specified in the response.
class GoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults {
  /// Explicit content annotation results.
  GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation?
      explicitAnnotation;

  /// Timestamp of the processed frame in microseconds.
  core.String? frameTimestamp;

  /// Label annotation results.
  core.List<GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>?
      labelAnnotations;

  /// Object tracking results.
  core.List<GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation>?
      objectAnnotations;

  /// Shot annotation results.
  ///
  /// Each shot is represented as a video segment.
  core.List<GoogleCloudVideointelligenceV1p3beta1VideoSegment>? shotAnnotations;

  GoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults();

  GoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults.fromJson(
      core.Map _json) {
    if (_json.containsKey('explicitAnnotation')) {
      explicitAnnotation =
          GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation
              .fromJson(_json['explicitAnnotation']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('frameTimestamp')) {
      frameTimestamp = _json['frameTimestamp'] as core.String;
    }
    if (_json.containsKey('labelAnnotations')) {
      labelAnnotations = (_json['labelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p3beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('objectAnnotations')) {
      objectAnnotations = (_json['objectAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotAnnotations')) {
      shotAnnotations = (_json['shotAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1VideoSegment>((value) =>
              GoogleCloudVideointelligenceV1p3beta1VideoSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (explicitAnnotation != null)
          'explicitAnnotation': explicitAnnotation!.toJson(),
        if (frameTimestamp != null) 'frameTimestamp': frameTimestamp!,
        if (labelAnnotations != null)
          'labelAnnotations':
              labelAnnotations!.map((value) => value.toJson()).toList(),
        if (objectAnnotations != null)
          'objectAnnotations':
              objectAnnotations!.map((value) => value.toJson()).toList(),
        if (shotAnnotations != null)
          'shotAnnotations':
              shotAnnotations!.map((value) => value.toJson()).toList(),
      };
}

/// Annotations related to one detected OCR text snippet.
///
/// This will contain the corresponding text, confidence value, and frame level
/// information for each detection.
class GoogleCloudVideointelligenceV1p3beta1TextAnnotation {
  /// All video segments where OCR detected text appears.
  core.List<GoogleCloudVideointelligenceV1p3beta1TextSegment>? segments;

  /// The detected text.
  core.String? text;

  /// Feature version.
  core.String? version;

  GoogleCloudVideointelligenceV1p3beta1TextAnnotation();

  GoogleCloudVideointelligenceV1p3beta1TextAnnotation.fromJson(core.Map _json) {
    if (_json.containsKey('segments')) {
      segments = (_json['segments'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1TextSegment>((value) =>
              GoogleCloudVideointelligenceV1p3beta1TextSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('text')) {
      text = _json['text'] as core.String;
    }
    if (_json.containsKey('version')) {
      version = _json['version'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (segments != null)
          'segments': segments!.map((value) => value.toJson()).toList(),
        if (text != null) 'text': text!,
        if (version != null) 'version': version!,
      };
}

/// Video frame level annotation results for text annotation (OCR).
///
/// Contains information regarding timestamp and bounding box locations for the
/// frames containing detected OCR text snippets.
class GoogleCloudVideointelligenceV1p3beta1TextFrame {
  /// Bounding polygon of the detected text for this frame.
  GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly?
      rotatedBoundingBox;

  /// Timestamp of this frame.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p3beta1TextFrame();

  GoogleCloudVideointelligenceV1p3beta1TextFrame.fromJson(core.Map _json) {
    if (_json.containsKey('rotatedBoundingBox')) {
      rotatedBoundingBox =
          GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly.fromJson(
              _json['rotatedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (rotatedBoundingBox != null)
          'rotatedBoundingBox': rotatedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// Video segment level annotation results for text detection.
class GoogleCloudVideointelligenceV1p3beta1TextSegment {
  /// Confidence for the track of detected text.
  ///
  /// It is calculated as the highest over all frames where OCR detected text
  /// appears.
  core.double? confidence;

  /// Information related to the frames where OCR detected text appears.
  core.List<GoogleCloudVideointelligenceV1p3beta1TextFrame>? frames;

  /// Video segment where a text snippet was detected.
  GoogleCloudVideointelligenceV1p3beta1VideoSegment? segment;

  GoogleCloudVideointelligenceV1p3beta1TextSegment();

  GoogleCloudVideointelligenceV1p3beta1TextSegment.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('frames')) {
      frames = (_json['frames'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1TextFrame>((value) =>
              GoogleCloudVideointelligenceV1p3beta1TextFrame.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p3beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (frames != null)
          'frames': frames!.map((value) => value.toJson()).toList(),
        if (segment != null) 'segment': segment!.toJson(),
      };
}

/// For tracking related features.
///
/// An object at time_offset with attributes, and located with
/// normalized_bounding_box.
class GoogleCloudVideointelligenceV1p3beta1TimestampedObject {
  /// The attributes of the object in the bounding box.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1p3beta1DetectedAttribute>? attributes;

  /// The detected landmarks.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1p3beta1DetectedLandmark>? landmarks;

  /// Normalized Bounding box in a frame, where the object is located.
  GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox?
      normalizedBoundingBox;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// video frame for this object.
  core.String? timeOffset;

  GoogleCloudVideointelligenceV1p3beta1TimestampedObject();

  GoogleCloudVideointelligenceV1p3beta1TimestampedObject.fromJson(
      core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = (_json['attributes'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1DetectedAttribute>(
              (value) => GoogleCloudVideointelligenceV1p3beta1DetectedAttribute
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('landmarks')) {
      landmarks = (_json['landmarks'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1DetectedLandmark>((value) =>
              GoogleCloudVideointelligenceV1p3beta1DetectedLandmark.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('normalizedBoundingBox')) {
      normalizedBoundingBox =
          GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox.fromJson(
              _json['normalizedBoundingBox']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeOffset')) {
      timeOffset = _json['timeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null)
          'attributes': attributes!.map((value) => value.toJson()).toList(),
        if (landmarks != null)
          'landmarks': landmarks!.map((value) => value.toJson()).toList(),
        if (normalizedBoundingBox != null)
          'normalizedBoundingBox': normalizedBoundingBox!.toJson(),
        if (timeOffset != null) 'timeOffset': timeOffset!,
      };
}

/// A track of an object instance.
class GoogleCloudVideointelligenceV1p3beta1Track {
  /// Attributes in the track level.
  ///
  /// Optional.
  core.List<GoogleCloudVideointelligenceV1p3beta1DetectedAttribute>? attributes;

  /// The confidence score of the tracked object.
  ///
  /// Optional.
  core.double? confidence;

  /// Video segment of a track.
  GoogleCloudVideointelligenceV1p3beta1VideoSegment? segment;

  /// The object with timestamp and attributes per frame in the track.
  core.List<GoogleCloudVideointelligenceV1p3beta1TimestampedObject>?
      timestampedObjects;

  GoogleCloudVideointelligenceV1p3beta1Track();

  GoogleCloudVideointelligenceV1p3beta1Track.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = (_json['attributes'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1DetectedAttribute>(
              (value) => GoogleCloudVideointelligenceV1p3beta1DetectedAttribute
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p3beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timestampedObjects')) {
      timestampedObjects = (_json['timestampedObjects'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1TimestampedObject>(
              (value) => GoogleCloudVideointelligenceV1p3beta1TimestampedObject
                  .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null)
          'attributes': attributes!.map((value) => value.toJson()).toList(),
        if (confidence != null) 'confidence': confidence!,
        if (segment != null) 'segment': segment!.toJson(),
        if (timestampedObjects != null)
          'timestampedObjects':
              timestampedObjects!.map((value) => value.toJson()).toList(),
      };
}

/// Annotation progress for a single video.
class GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress {
  /// Specifies which feature is being tracked if the request contains more than
  /// one feature.
  /// Possible string values are:
  /// - "FEATURE_UNSPECIFIED" : Unspecified.
  /// - "LABEL_DETECTION" : Label detection. Detect objects, such as dog or
  /// flower.
  /// - "SHOT_CHANGE_DETECTION" : Shot change detection.
  /// - "EXPLICIT_CONTENT_DETECTION" : Explicit content detection.
  /// - "FACE_DETECTION" : Human face detection.
  /// - "SPEECH_TRANSCRIPTION" : Speech transcription.
  /// - "TEXT_DETECTION" : OCR text detection and tracking.
  /// - "OBJECT_TRACKING" : Object detection and tracking.
  /// - "LOGO_RECOGNITION" : Logo detection, tracking, and recognition.
  /// - "CELEBRITY_RECOGNITION" : Celebrity recognition.
  /// - "PERSON_DETECTION" : Person detection.
  core.String? feature;

  /// Video file location in [Cloud Storage](https://cloud.google.com/storage/).
  core.String? inputUri;

  /// Approximate percentage processed thus far.
  ///
  /// Guaranteed to be 100 when fully processed.
  core.int? progressPercent;

  /// Specifies which segment is being tracked if the request contains more than
  /// one segment.
  GoogleCloudVideointelligenceV1p3beta1VideoSegment? segment;

  /// Time when the request was received.
  core.String? startTime;

  /// Time of the most recent update.
  core.String? updateTime;

  GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress();

  GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress.fromJson(
      core.Map _json) {
    if (_json.containsKey('feature')) {
      feature = _json['feature'] as core.String;
    }
    if (_json.containsKey('inputUri')) {
      inputUri = _json['inputUri'] as core.String;
    }
    if (_json.containsKey('progressPercent')) {
      progressPercent = _json['progressPercent'] as core.int;
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p3beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('updateTime')) {
      updateTime = _json['updateTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (feature != null) 'feature': feature!,
        if (inputUri != null) 'inputUri': inputUri!,
        if (progressPercent != null) 'progressPercent': progressPercent!,
        if (segment != null) 'segment': segment!.toJson(),
        if (startTime != null) 'startTime': startTime!,
        if (updateTime != null) 'updateTime': updateTime!,
      };
}

/// Annotation results for a single video.
class GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults {
  /// Celebrity recognition annotations.
  GoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation?
      celebrityRecognitionAnnotations;

  /// If set, indicates an error.
  ///
  /// Note that for a single `AnnotateVideoRequest` some videos may succeed and
  /// some may fail.
  GoogleRpcStatus? error;

  /// Explicit content annotation.
  GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation?
      explicitAnnotation;

  /// Please use `face_detection_annotations` instead.
  ///
  /// Deprecated.
  core.List<GoogleCloudVideointelligenceV1p3beta1FaceAnnotation>?
      faceAnnotations;

  /// Face detection annotations.
  core.List<GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation>?
      faceDetectionAnnotations;

  /// Label annotations on frame level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>?
      frameLabelAnnotations;

  /// Video file location in [Cloud Storage](https://cloud.google.com/storage/).
  core.String? inputUri;

  /// Annotations for list of logos detected, tracked and recognized in video.
  core.List<GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation>?
      logoRecognitionAnnotations;

  /// Annotations for list of objects detected and tracked in video.
  core.List<GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation>?
      objectAnnotations;

  /// Person detection annotations.
  core.List<GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation>?
      personDetectionAnnotations;

  /// Video segment on which the annotation is run.
  GoogleCloudVideointelligenceV1p3beta1VideoSegment? segment;

  /// Topical label annotations on video level or user-specified segment level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>?
      segmentLabelAnnotations;

  /// Presence label annotations on video level or user-specified segment level.
  ///
  /// There is exactly one element for each unique label. Compared to the
  /// existing topical `segment_label_annotations`, this field presents more
  /// fine-grained, segment-level labels detected in video content and is made
  /// available only when the client sets `LabelDetectionConfig.model` to
  /// "builtin/latest" in the request.
  core.List<GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>?
      segmentPresenceLabelAnnotations;

  /// Shot annotations.
  ///
  /// Each shot is represented as a video segment.
  core.List<GoogleCloudVideointelligenceV1p3beta1VideoSegment>? shotAnnotations;

  /// Topical label annotations on shot level.
  ///
  /// There is exactly one element for each unique label.
  core.List<GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>?
      shotLabelAnnotations;

  /// Presence label annotations on shot level.
  ///
  /// There is exactly one element for each unique label. Compared to the
  /// existing topical `shot_label_annotations`, this field presents more
  /// fine-grained, shot-level labels detected in video content and is made
  /// available only when the client sets `LabelDetectionConfig.model` to
  /// "builtin/latest" in the request.
  core.List<GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>?
      shotPresenceLabelAnnotations;

  /// Speech transcription.
  core.List<GoogleCloudVideointelligenceV1p3beta1SpeechTranscription>?
      speechTranscriptions;

  /// OCR text detection and tracking.
  ///
  /// Annotations for list of detected text snippets. Each will have list of
  /// frame information associated with it.
  core.List<GoogleCloudVideointelligenceV1p3beta1TextAnnotation>?
      textAnnotations;

  GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults();

  GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults.fromJson(
      core.Map _json) {
    if (_json.containsKey('celebrityRecognitionAnnotations')) {
      celebrityRecognitionAnnotations =
          GoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation
              .fromJson(_json['celebrityRecognitionAnnotations']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('explicitAnnotation')) {
      explicitAnnotation =
          GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation
              .fromJson(_json['explicitAnnotation']
                  as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('faceAnnotations')) {
      faceAnnotations = (_json['faceAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1FaceAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p3beta1FaceAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('faceDetectionAnnotations')) {
      faceDetectionAnnotations = (_json['faceDetectionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('frameLabelAnnotations')) {
      frameLabelAnnotations = (_json['frameLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p3beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('inputUri')) {
      inputUri = _json['inputUri'] as core.String;
    }
    if (_json.containsKey('logoRecognitionAnnotations')) {
      logoRecognitionAnnotations = (_json['logoRecognitionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('objectAnnotations')) {
      objectAnnotations = (_json['objectAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('personDetectionAnnotations')) {
      personDetectionAnnotations = (_json['personDetectionAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation>(
              (value) =>
                  GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segment')) {
      segment = GoogleCloudVideointelligenceV1p3beta1VideoSegment.fromJson(
          _json['segment'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('segmentLabelAnnotations')) {
      segmentLabelAnnotations = (_json['segmentLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p3beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('segmentPresenceLabelAnnotations')) {
      segmentPresenceLabelAnnotations = (_json[
              'segmentPresenceLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p3beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotAnnotations')) {
      shotAnnotations = (_json['shotAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1VideoSegment>((value) =>
              GoogleCloudVideointelligenceV1p3beta1VideoSegment.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotLabelAnnotations')) {
      shotLabelAnnotations = (_json['shotLabelAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p3beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('shotPresenceLabelAnnotations')) {
      shotPresenceLabelAnnotations = (_json['shotPresenceLabelAnnotations']
              as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p3beta1LabelAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('speechTranscriptions')) {
      speechTranscriptions = (_json['speechTranscriptions'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1SpeechTranscription>(
              (value) =>
                  GoogleCloudVideointelligenceV1p3beta1SpeechTranscription
                      .fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('textAnnotations')) {
      textAnnotations = (_json['textAnnotations'] as core.List)
          .map<GoogleCloudVideointelligenceV1p3beta1TextAnnotation>((value) =>
              GoogleCloudVideointelligenceV1p3beta1TextAnnotation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (celebrityRecognitionAnnotations != null)
          'celebrityRecognitionAnnotations':
              celebrityRecognitionAnnotations!.toJson(),
        if (error != null) 'error': error!.toJson(),
        if (explicitAnnotation != null)
          'explicitAnnotation': explicitAnnotation!.toJson(),
        if (faceAnnotations != null)
          'faceAnnotations':
              faceAnnotations!.map((value) => value.toJson()).toList(),
        if (faceDetectionAnnotations != null)
          'faceDetectionAnnotations':
              faceDetectionAnnotations!.map((value) => value.toJson()).toList(),
        if (frameLabelAnnotations != null)
          'frameLabelAnnotations':
              frameLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (inputUri != null) 'inputUri': inputUri!,
        if (logoRecognitionAnnotations != null)
          'logoRecognitionAnnotations': logoRecognitionAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (objectAnnotations != null)
          'objectAnnotations':
              objectAnnotations!.map((value) => value.toJson()).toList(),
        if (personDetectionAnnotations != null)
          'personDetectionAnnotations': personDetectionAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (segment != null) 'segment': segment!.toJson(),
        if (segmentLabelAnnotations != null)
          'segmentLabelAnnotations':
              segmentLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (segmentPresenceLabelAnnotations != null)
          'segmentPresenceLabelAnnotations': segmentPresenceLabelAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (shotAnnotations != null)
          'shotAnnotations':
              shotAnnotations!.map((value) => value.toJson()).toList(),
        if (shotLabelAnnotations != null)
          'shotLabelAnnotations':
              shotLabelAnnotations!.map((value) => value.toJson()).toList(),
        if (shotPresenceLabelAnnotations != null)
          'shotPresenceLabelAnnotations': shotPresenceLabelAnnotations!
              .map((value) => value.toJson())
              .toList(),
        if (speechTranscriptions != null)
          'speechTranscriptions':
              speechTranscriptions!.map((value) => value.toJson()).toList(),
        if (textAnnotations != null)
          'textAnnotations':
              textAnnotations!.map((value) => value.toJson()).toList(),
      };
}

/// Video segment.
class GoogleCloudVideointelligenceV1p3beta1VideoSegment {
  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// end of the segment (inclusive).
  core.String? endTimeOffset;

  /// Time-offset, relative to the beginning of the video, corresponding to the
  /// start of the segment (inclusive).
  core.String? startTimeOffset;

  GoogleCloudVideointelligenceV1p3beta1VideoSegment();

  GoogleCloudVideointelligenceV1p3beta1VideoSegment.fromJson(core.Map _json) {
    if (_json.containsKey('endTimeOffset')) {
      endTimeOffset = _json['endTimeOffset'] as core.String;
    }
    if (_json.containsKey('startTimeOffset')) {
      startTimeOffset = _json['startTimeOffset'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (endTimeOffset != null) 'endTimeOffset': endTimeOffset!,
        if (startTimeOffset != null) 'startTimeOffset': startTimeOffset!,
      };
}

/// Word-specific information for recognized words.
///
/// Word information is only included in the response when certain request
/// parameters are set, such as `enable_word_time_offsets`.
class GoogleCloudVideointelligenceV1p3beta1WordInfo {
  /// The confidence estimate between 0.0 and 1.0.
  ///
  /// A higher number indicates an estimated greater likelihood that the
  /// recognized words are correct. This field is set only for the top
  /// alternative. This field is not guaranteed to be accurate and users should
  /// not rely on it to be always provided. The default of 0.0 is a sentinel
  /// value indicating `confidence` was not set.
  ///
  /// Output only.
  core.double? confidence;

  /// Time offset relative to the beginning of the audio, and corresponding to
  /// the end of the spoken word.
  ///
  /// This field is only set if `enable_word_time_offsets=true` and only in the
  /// top hypothesis. This is an experimental feature and the accuracy of the
  /// time offset can vary.
  core.String? endTime;

  /// A distinct integer value is assigned for every speaker within the audio.
  ///
  /// This field specifies which one of those speakers was detected to have
  /// spoken this word. Value ranges from 1 up to diarization_speaker_count, and
  /// is only set if speaker diarization is enabled.
  ///
  /// Output only.
  core.int? speakerTag;

  /// Time offset relative to the beginning of the audio, and corresponding to
  /// the start of the spoken word.
  ///
  /// This field is only set if `enable_word_time_offsets=true` and only in the
  /// top hypothesis. This is an experimental feature and the accuracy of the
  /// time offset can vary.
  core.String? startTime;

  /// The word corresponding to this set of information.
  core.String? word;

  GoogleCloudVideointelligenceV1p3beta1WordInfo();

  GoogleCloudVideointelligenceV1p3beta1WordInfo.fromJson(core.Map _json) {
    if (_json.containsKey('confidence')) {
      confidence = (_json['confidence'] as core.num).toDouble();
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('speakerTag')) {
      speakerTag = _json['speakerTag'] as core.int;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('word')) {
      word = _json['word'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (confidence != null) 'confidence': confidence!,
        if (endTime != null) 'endTime': endTime!,
        if (speakerTag != null) 'speakerTag': speakerTag!,
        if (startTime != null) 'startTime': startTime!,
        if (word != null) 'word': word!,
      };
}

/// The request message for Operations.CancelOperation.
class GoogleLongrunningCancelOperationRequest {
  GoogleLongrunningCancelOperationRequest();

  GoogleLongrunningCancelOperationRequest.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// The response message for Operations.ListOperations.
class GoogleLongrunningListOperationsResponse {
  /// The standard List next-page token.
  core.String? nextPageToken;

  /// A list of operations that matches the specified filter in the request.
  core.List<GoogleLongrunningOperation>? operations;

  GoogleLongrunningListOperationsResponse();

  GoogleLongrunningListOperationsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('operations')) {
      operations = (_json['operations'] as core.List)
          .map<GoogleLongrunningOperation>((value) =>
              GoogleLongrunningOperation.fromJson(
                  value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (operations != null)
          'operations': operations!.map((value) => value.toJson()).toList(),
      };
}

/// This resource represents a long-running operation that is the result of a
/// network API call.
class GoogleLongrunningOperation {
  /// If the value is `false`, it means the operation is still in progress.
  ///
  /// If `true`, the operation is completed, and either `error` or `response` is
  /// available.
  core.bool? done;

  /// The error result of the operation in case of failure or cancellation.
  GoogleRpcStatus? error;

  /// Service-specific metadata associated with the operation.
  ///
  /// It typically contains progress information and common metadata such as
  /// create time. Some services might not provide such metadata. Any method
  /// that returns a long-running operation should document the metadata type,
  /// if any.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? metadata;

  /// The server-assigned name, which is only unique within the same service
  /// that originally returns it.
  ///
  /// If you use the default HTTP mapping, the `name` should be a resource name
  /// ending with `operations/{unique_id}`.
  core.String? name;

  /// The normal response of the operation in case of success.
  ///
  /// If the original method returns no data on success, such as `Delete`, the
  /// response is `google.protobuf.Empty`. If the original method is standard
  /// `Get`/`Create`/`Update`, the response should be the resource. For other
  /// methods, the response should have the type `XxxResponse`, where `Xxx` is
  /// the original method name. For example, if the original method name is
  /// `TakeSnapshot()`, the inferred response type is `TakeSnapshotResponse`.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.Map<core.String, core.Object>? response;

  GoogleLongrunningOperation();

  GoogleLongrunningOperation.fromJson(core.Map _json) {
    if (_json.containsKey('done')) {
      done = _json['done'] as core.bool;
    }
    if (_json.containsKey('error')) {
      error = GoogleRpcStatus.fromJson(
          _json['error'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('metadata')) {
      metadata = (_json['metadata'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('response')) {
      response = (_json['response'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          item as core.Object,
        ),
      );
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (done != null) 'done': done!,
        if (error != null) 'error': error!.toJson(),
        if (metadata != null) 'metadata': metadata!,
        if (name != null) 'name': name!,
        if (response != null) 'response': response!,
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

/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs.
///
/// It is used by [gRPC](https://github.com/grpc). Each `Status` message
/// contains three pieces of data: error code, error message, and error details.
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
class GoogleRpcStatus {
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

  GoogleRpcStatus();

  GoogleRpcStatus.fromJson(core.Map _json) {
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
