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

/// YouTube Reporting API - v1
///
/// Schedules reporting jobs containing your YouTube Analytics data and
/// downloads the resulting bulk data reports in the form of CSV files.
///
/// For more information, see
/// <https://developers.google.com/youtube/reporting/v1/reports/>
///
/// Create an instance of [YouTubeReportingApi] to access these resources:
///
/// - [JobsResource]
///   - [JobsReportsResource]
/// - [MediaResource]
/// - [ReportTypesResource]
library youtubereporting.v1;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show
        ApiRequestError,
        DetailedApiRequestError,
        Media,
        UploadOptions,
        ResumableUploadOptions,
        DownloadOptions,
        PartialDownloadOptions,
        ByteRange;

/// Schedules reporting jobs containing your YouTube Analytics data and
/// downloads the resulting bulk data reports in the form of CSV files.
class YouTubeReportingApi {
  /// View monetary and non-monetary YouTube Analytics reports for your YouTube
  /// content
  static const ytAnalyticsMonetaryReadonlyScope =
      'https://www.googleapis.com/auth/yt-analytics-monetary.readonly';

  /// View YouTube Analytics reports for your YouTube content
  static const ytAnalyticsReadonlyScope =
      'https://www.googleapis.com/auth/yt-analytics.readonly';

  final commons.ApiRequester _requester;

  JobsResource get jobs => JobsResource(_requester);
  MediaResource get media => MediaResource(_requester);
  ReportTypesResource get reportTypes => ReportTypesResource(_requester);

  YouTubeReportingApi(http.Client client,
      {core.String rootUrl = 'https://youtubereporting.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class JobsResource {
  final commons.ApiRequester _requester;

  JobsReportsResource get reports => JobsReportsResource(_requester);

  JobsResource(commons.ApiRequester client) : _requester = client;

  /// Creates a job and returns it.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [onBehalfOfContentOwner] - The content owner's external ID on which behalf
  /// the user is acting on. If not set, the user is acting for himself (his own
  /// channel).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Job].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Job> create(
    Job request, {
    core.String? onBehalfOfContentOwner,
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if (onBehalfOfContentOwner != null)
        'onBehalfOfContentOwner': [onBehalfOfContentOwner],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/jobs';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Job.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Deletes a job.
  ///
  /// Request parameters:
  ///
  /// [jobId] - The ID of the job to delete.
  ///
  /// [onBehalfOfContentOwner] - The content owner's external ID on which behalf
  /// the user is acting on. If not set, the user is acting for himself (his own
  /// channel).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> delete(
    core.String jobId, {
    core.String? onBehalfOfContentOwner,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (onBehalfOfContentOwner != null)
        'onBehalfOfContentOwner': [onBehalfOfContentOwner],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/jobs/' + commons.escapeVariable('$jobId');

    final _response = await _requester.request(
      _url,
      'DELETE',
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Gets a job.
  ///
  /// Request parameters:
  ///
  /// [jobId] - The ID of the job to retrieve.
  ///
  /// [onBehalfOfContentOwner] - The content owner's external ID on which behalf
  /// the user is acting on. If not set, the user is acting for himself (his own
  /// channel).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Job].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Job> get(
    core.String jobId, {
    core.String? onBehalfOfContentOwner,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (onBehalfOfContentOwner != null)
        'onBehalfOfContentOwner': [onBehalfOfContentOwner],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/jobs/' + commons.escapeVariable('$jobId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Job.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists jobs.
  ///
  /// Request parameters:
  ///
  /// [includeSystemManaged] - If set to true, also system-managed jobs will be
  /// returned; otherwise only user-created jobs will be returned.
  /// System-managed jobs can neither be modified nor deleted.
  ///
  /// [onBehalfOfContentOwner] - The content owner's external ID on which behalf
  /// the user is acting on. If not set, the user is acting for himself (his own
  /// channel).
  ///
  /// [pageSize] - Requested page size. Server may return fewer jobs than
  /// requested. If unspecified, server will pick an appropriate default.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of
  /// ListReportTypesResponse.next_page_token returned in response to the
  /// previous call to the `ListJobs` method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListJobsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListJobsResponse> list({
    core.bool? includeSystemManaged,
    core.String? onBehalfOfContentOwner,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeSystemManaged != null)
        'includeSystemManaged': ['${includeSystemManaged}'],
      if (onBehalfOfContentOwner != null)
        'onBehalfOfContentOwner': [onBehalfOfContentOwner],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/jobs';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListJobsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class JobsReportsResource {
  final commons.ApiRequester _requester;

  JobsReportsResource(commons.ApiRequester client) : _requester = client;

  /// Gets the metadata of a specific report.
  ///
  /// Request parameters:
  ///
  /// [jobId] - The ID of the job.
  ///
  /// [reportId] - The ID of the report to retrieve.
  ///
  /// [onBehalfOfContentOwner] - The content owner's external ID on which behalf
  /// the user is acting on. If not set, the user is acting for himself (his own
  /// channel).
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Report].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Report> get(
    core.String jobId,
    core.String reportId, {
    core.String? onBehalfOfContentOwner,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (onBehalfOfContentOwner != null)
        'onBehalfOfContentOwner': [onBehalfOfContentOwner],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/jobs/' +
        commons.escapeVariable('$jobId') +
        '/reports/' +
        commons.escapeVariable('$reportId');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return Report.fromJson(_response as core.Map<core.String, core.dynamic>);
  }

  /// Lists reports created by a specific job.
  ///
  /// Returns NOT_FOUND if the job does not exist.
  ///
  /// Request parameters:
  ///
  /// [jobId] - The ID of the job.
  ///
  /// [createdAfter] - If set, only reports created after the specified
  /// date/time are returned.
  ///
  /// [onBehalfOfContentOwner] - The content owner's external ID on which behalf
  /// the user is acting on. If not set, the user is acting for himself (his own
  /// channel).
  ///
  /// [pageSize] - Requested page size. Server may return fewer report types
  /// than requested. If unspecified, server will pick an appropriate default.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of
  /// ListReportsResponse.next_page_token returned in response to the previous
  /// call to the `ListReports` method.
  ///
  /// [startTimeAtOrAfter] - If set, only reports whose start time is greater
  /// than or equal the specified date/time are returned.
  ///
  /// [startTimeBefore] - If set, only reports whose start time is smaller than
  /// the specified date/time are returned.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListReportsResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListReportsResponse> list(
    core.String jobId, {
    core.String? createdAfter,
    core.String? onBehalfOfContentOwner,
    core.int? pageSize,
    core.String? pageToken,
    core.String? startTimeAtOrAfter,
    core.String? startTimeBefore,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (createdAfter != null) 'createdAfter': [createdAfter],
      if (onBehalfOfContentOwner != null)
        'onBehalfOfContentOwner': [onBehalfOfContentOwner],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if (startTimeAtOrAfter != null)
        'startTimeAtOrAfter': [startTimeAtOrAfter],
      if (startTimeBefore != null) 'startTimeBefore': [startTimeBefore],
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/jobs/' + commons.escapeVariable('$jobId') + '/reports';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListReportsResponse.fromJson(
        _response as core.Map<core.String, core.dynamic>);
  }
}

class MediaResource {
  final commons.ApiRequester _requester;

  MediaResource(commons.ApiRequester client) : _requester = client;

  /// Method for media download.
  ///
  /// Download is supported on the URI `/v1/media/{+name}?alt=media`.
  ///
  /// Request parameters:
  ///
  /// [resourceName] - Name of the media that is being downloaded.
  /// Value must have pattern `^.*$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// [downloadOptions] - Options for downloading. A download can be either a
  /// Metadata (default) or Media download. Partial Media downloads are possible
  /// as well.
  ///
  /// Completes with a
  ///
  /// - [GdataMedia] for Metadata downloads (see [downloadOptions]).
  ///
  /// - [commons.Media] for Media downloads (see [downloadOptions]).
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<core.Object> download(
    core.String resourceName, {
    core.String? $fields,
    commons.DownloadOptions downloadOptions = commons.DownloadOptions.metadata,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v1/media/' + core.Uri.encodeFull('$resourceName');

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
      downloadOptions: downloadOptions,
    );
    if (downloadOptions.isMetadataDownload) {
      return GdataMedia.fromJson(
          _response as core.Map<core.String, core.dynamic>);
    } else {
      return _response as commons.Media;
    }
  }
}

class ReportTypesResource {
  final commons.ApiRequester _requester;

  ReportTypesResource(commons.ApiRequester client) : _requester = client;

  /// Lists report types.
  ///
  /// Request parameters:
  ///
  /// [includeSystemManaged] - If set to true, also system-managed report types
  /// will be returned; otherwise only the report types that can be used to
  /// create new reporting jobs will be returned.
  ///
  /// [onBehalfOfContentOwner] - The content owner's external ID on which behalf
  /// the user is acting on. If not set, the user is acting for himself (his own
  /// channel).
  ///
  /// [pageSize] - Requested page size. Server may return fewer report types
  /// than requested. If unspecified, server will pick an appropriate default.
  ///
  /// [pageToken] - A token identifying a page of results the server should
  /// return. Typically, this is the value of
  /// ListReportTypesResponse.next_page_token returned in response to the
  /// previous call to the `ListReportTypes` method.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [ListReportTypesResponse].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<ListReportTypesResponse> list({
    core.bool? includeSystemManaged,
    core.String? onBehalfOfContentOwner,
    core.int? pageSize,
    core.String? pageToken,
    core.String? $fields,
  }) async {
    final _queryParams = <core.String, core.List<core.String>>{
      if (includeSystemManaged != null)
        'includeSystemManaged': ['${includeSystemManaged}'],
      if (onBehalfOfContentOwner != null)
        'onBehalfOfContentOwner': [onBehalfOfContentOwner],
      if (pageSize != null) 'pageSize': ['${pageSize}'],
      if (pageToken != null) 'pageToken': [pageToken],
      if ($fields != null) 'fields': [$fields],
    };

    const _url = 'v1/reportTypes';

    final _response = await _requester.request(
      _url,
      'GET',
      queryParams: _queryParams,
    );
    return ListReportTypesResponse.fromJson(
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
class Empty {
  Empty();

  Empty.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// gdata
class GdataBlobstore2Info {
  /// gdata
  core.String? blobGeneration;

  /// gdata
  core.String? blobId;

  /// gdata
  core.String? downloadReadHandle;
  core.List<core.int> get downloadReadHandleAsBytes =>
      convert.base64.decode(downloadReadHandle!);

  set downloadReadHandleAsBytes(core.List<core.int> _bytes) {
    downloadReadHandle =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// gdata
  core.String? readToken;

  /// gdata
  core.String? uploadMetadataContainer;
  core.List<core.int> get uploadMetadataContainerAsBytes =>
      convert.base64.decode(uploadMetadataContainer!);

  set uploadMetadataContainerAsBytes(core.List<core.int> _bytes) {
    uploadMetadataContainer =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  GdataBlobstore2Info();

  GdataBlobstore2Info.fromJson(core.Map _json) {
    if (_json.containsKey('blobGeneration')) {
      blobGeneration = _json['blobGeneration'] as core.String;
    }
    if (_json.containsKey('blobId')) {
      blobId = _json['blobId'] as core.String;
    }
    if (_json.containsKey('downloadReadHandle')) {
      downloadReadHandle = _json['downloadReadHandle'] as core.String;
    }
    if (_json.containsKey('readToken')) {
      readToken = _json['readToken'] as core.String;
    }
    if (_json.containsKey('uploadMetadataContainer')) {
      uploadMetadataContainer = _json['uploadMetadataContainer'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (blobGeneration != null) 'blobGeneration': blobGeneration!,
        if (blobId != null) 'blobId': blobId!,
        if (downloadReadHandle != null)
          'downloadReadHandle': downloadReadHandle!,
        if (readToken != null) 'readToken': readToken!,
        if (uploadMetadataContainer != null)
          'uploadMetadataContainer': uploadMetadataContainer!,
      };
}

/// gdata
class GdataCompositeMedia {
  /// gdata
  core.String? blobRef;
  core.List<core.int> get blobRefAsBytes => convert.base64.decode(blobRef!);

  set blobRefAsBytes(core.List<core.int> _bytes) {
    blobRef =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// gdata
  GdataBlobstore2Info? blobstore2Info;

  /// gdata
  core.String? cosmoBinaryReference;
  core.List<core.int> get cosmoBinaryReferenceAsBytes =>
      convert.base64.decode(cosmoBinaryReference!);

  set cosmoBinaryReferenceAsBytes(core.List<core.int> _bytes) {
    cosmoBinaryReference =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// gdata
  core.int? crc32cHash;

  /// gdata
  core.String? inline;
  core.List<core.int> get inlineAsBytes => convert.base64.decode(inline!);

  set inlineAsBytes(core.List<core.int> _bytes) {
    inline =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// gdata
  core.String? length;

  /// gdata
  core.String? md5Hash;
  core.List<core.int> get md5HashAsBytes => convert.base64.decode(md5Hash!);

  set md5HashAsBytes(core.List<core.int> _bytes) {
    md5Hash =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// gdata
  GdataObjectId? objectId;

  /// gdata
  core.String? path;

  /// gdata
  /// Possible string values are:
  /// - "PATH" : gdata
  /// - "BLOB_REF" : gdata
  /// - "INLINE" : gdata
  /// - "BIGSTORE_REF" : gdata
  /// - "COSMO_BINARY_REFERENCE" : gdata
  core.String? referenceType;

  /// gdata
  core.String? sha1Hash;
  core.List<core.int> get sha1HashAsBytes => convert.base64.decode(sha1Hash!);

  set sha1HashAsBytes(core.List<core.int> _bytes) {
    sha1Hash =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  GdataCompositeMedia();

  GdataCompositeMedia.fromJson(core.Map _json) {
    if (_json.containsKey('blobRef')) {
      blobRef = _json['blobRef'] as core.String;
    }
    if (_json.containsKey('blobstore2Info')) {
      blobstore2Info = GdataBlobstore2Info.fromJson(
          _json['blobstore2Info'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('cosmoBinaryReference')) {
      cosmoBinaryReference = _json['cosmoBinaryReference'] as core.String;
    }
    if (_json.containsKey('crc32cHash')) {
      crc32cHash = _json['crc32cHash'] as core.int;
    }
    if (_json.containsKey('inline')) {
      inline = _json['inline'] as core.String;
    }
    if (_json.containsKey('length')) {
      length = _json['length'] as core.String;
    }
    if (_json.containsKey('md5Hash')) {
      md5Hash = _json['md5Hash'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = GdataObjectId.fromJson(
          _json['objectId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('path')) {
      path = _json['path'] as core.String;
    }
    if (_json.containsKey('referenceType')) {
      referenceType = _json['referenceType'] as core.String;
    }
    if (_json.containsKey('sha1Hash')) {
      sha1Hash = _json['sha1Hash'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (blobRef != null) 'blobRef': blobRef!,
        if (blobstore2Info != null) 'blobstore2Info': blobstore2Info!.toJson(),
        if (cosmoBinaryReference != null)
          'cosmoBinaryReference': cosmoBinaryReference!,
        if (crc32cHash != null) 'crc32cHash': crc32cHash!,
        if (inline != null) 'inline': inline!,
        if (length != null) 'length': length!,
        if (md5Hash != null) 'md5Hash': md5Hash!,
        if (objectId != null) 'objectId': objectId!.toJson(),
        if (path != null) 'path': path!,
        if (referenceType != null) 'referenceType': referenceType!,
        if (sha1Hash != null) 'sha1Hash': sha1Hash!,
      };
}

/// gdata
class GdataContentTypeInfo {
  /// gdata
  core.String? bestGuess;

  /// gdata
  core.String? fromBytes;

  /// gdata
  core.String? fromFileName;

  /// gdata
  core.String? fromHeader;

  /// gdata
  core.String? fromUrlPath;

  GdataContentTypeInfo();

  GdataContentTypeInfo.fromJson(core.Map _json) {
    if (_json.containsKey('bestGuess')) {
      bestGuess = _json['bestGuess'] as core.String;
    }
    if (_json.containsKey('fromBytes')) {
      fromBytes = _json['fromBytes'] as core.String;
    }
    if (_json.containsKey('fromFileName')) {
      fromFileName = _json['fromFileName'] as core.String;
    }
    if (_json.containsKey('fromHeader')) {
      fromHeader = _json['fromHeader'] as core.String;
    }
    if (_json.containsKey('fromUrlPath')) {
      fromUrlPath = _json['fromUrlPath'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bestGuess != null) 'bestGuess': bestGuess!,
        if (fromBytes != null) 'fromBytes': fromBytes!,
        if (fromFileName != null) 'fromFileName': fromFileName!,
        if (fromHeader != null) 'fromHeader': fromHeader!,
        if (fromUrlPath != null) 'fromUrlPath': fromUrlPath!,
      };
}

/// gdata
class GdataDiffChecksumsResponse {
  /// gdata
  GdataCompositeMedia? checksumsLocation;

  /// gdata
  core.String? chunkSizeBytes;

  /// gdata
  GdataCompositeMedia? objectLocation;

  /// gdata
  core.String? objectSizeBytes;

  /// gdata
  core.String? objectVersion;

  GdataDiffChecksumsResponse();

  GdataDiffChecksumsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('checksumsLocation')) {
      checksumsLocation = GdataCompositeMedia.fromJson(
          _json['checksumsLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('chunkSizeBytes')) {
      chunkSizeBytes = _json['chunkSizeBytes'] as core.String;
    }
    if (_json.containsKey('objectLocation')) {
      objectLocation = GdataCompositeMedia.fromJson(
          _json['objectLocation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectSizeBytes')) {
      objectSizeBytes = _json['objectSizeBytes'] as core.String;
    }
    if (_json.containsKey('objectVersion')) {
      objectVersion = _json['objectVersion'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (checksumsLocation != null)
          'checksumsLocation': checksumsLocation!.toJson(),
        if (chunkSizeBytes != null) 'chunkSizeBytes': chunkSizeBytes!,
        if (objectLocation != null) 'objectLocation': objectLocation!.toJson(),
        if (objectSizeBytes != null) 'objectSizeBytes': objectSizeBytes!,
        if (objectVersion != null) 'objectVersion': objectVersion!,
      };
}

/// gdata
class GdataDiffDownloadResponse {
  /// gdata
  GdataCompositeMedia? objectLocation;

  GdataDiffDownloadResponse();

  GdataDiffDownloadResponse.fromJson(core.Map _json) {
    if (_json.containsKey('objectLocation')) {
      objectLocation = GdataCompositeMedia.fromJson(
          _json['objectLocation'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectLocation != null) 'objectLocation': objectLocation!.toJson(),
      };
}

/// gdata
class GdataDiffUploadRequest {
  /// gdata
  GdataCompositeMedia? checksumsInfo;

  /// gdata
  GdataCompositeMedia? objectInfo;

  /// gdata
  core.String? objectVersion;

  GdataDiffUploadRequest();

  GdataDiffUploadRequest.fromJson(core.Map _json) {
    if (_json.containsKey('checksumsInfo')) {
      checksumsInfo = GdataCompositeMedia.fromJson(
          _json['checksumsInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectInfo')) {
      objectInfo = GdataCompositeMedia.fromJson(
          _json['objectInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('objectVersion')) {
      objectVersion = _json['objectVersion'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (checksumsInfo != null) 'checksumsInfo': checksumsInfo!.toJson(),
        if (objectInfo != null) 'objectInfo': objectInfo!.toJson(),
        if (objectVersion != null) 'objectVersion': objectVersion!,
      };
}

/// gdata
class GdataDiffUploadResponse {
  /// gdata
  core.String? objectVersion;

  /// gdata
  GdataCompositeMedia? originalObject;

  GdataDiffUploadResponse();

  GdataDiffUploadResponse.fromJson(core.Map _json) {
    if (_json.containsKey('objectVersion')) {
      objectVersion = _json['objectVersion'] as core.String;
    }
    if (_json.containsKey('originalObject')) {
      originalObject = GdataCompositeMedia.fromJson(
          _json['originalObject'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectVersion != null) 'objectVersion': objectVersion!,
        if (originalObject != null) 'originalObject': originalObject!.toJson(),
      };
}

/// gdata
class GdataDiffVersionResponse {
  /// gdata
  core.String? objectSizeBytes;

  /// gdata
  core.String? objectVersion;

  GdataDiffVersionResponse();

  GdataDiffVersionResponse.fromJson(core.Map _json) {
    if (_json.containsKey('objectSizeBytes')) {
      objectSizeBytes = _json['objectSizeBytes'] as core.String;
    }
    if (_json.containsKey('objectVersion')) {
      objectVersion = _json['objectVersion'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (objectSizeBytes != null) 'objectSizeBytes': objectSizeBytes!,
        if (objectVersion != null) 'objectVersion': objectVersion!,
      };
}

/// gdata
class GdataDownloadParameters {
  /// gdata
  core.bool? allowGzipCompression;

  /// gdata
  core.bool? ignoreRange;

  GdataDownloadParameters();

  GdataDownloadParameters.fromJson(core.Map _json) {
    if (_json.containsKey('allowGzipCompression')) {
      allowGzipCompression = _json['allowGzipCompression'] as core.bool;
    }
    if (_json.containsKey('ignoreRange')) {
      ignoreRange = _json['ignoreRange'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (allowGzipCompression != null)
          'allowGzipCompression': allowGzipCompression!,
        if (ignoreRange != null) 'ignoreRange': ignoreRange!,
      };
}

/// gdata
class GdataMedia {
  /// gdata
  core.String? algorithm;

  /// gdata
  core.String? bigstoreObjectRef;
  core.List<core.int> get bigstoreObjectRefAsBytes =>
      convert.base64.decode(bigstoreObjectRef!);

  set bigstoreObjectRefAsBytes(core.List<core.int> _bytes) {
    bigstoreObjectRef =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// gdata
  core.String? blobRef;
  core.List<core.int> get blobRefAsBytes => convert.base64.decode(blobRef!);

  set blobRefAsBytes(core.List<core.int> _bytes) {
    blobRef =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// gdata
  GdataBlobstore2Info? blobstore2Info;

  /// gdata
  core.List<GdataCompositeMedia>? compositeMedia;

  /// gdata
  core.String? contentType;

  /// gdata
  GdataContentTypeInfo? contentTypeInfo;

  /// gdata
  core.String? cosmoBinaryReference;
  core.List<core.int> get cosmoBinaryReferenceAsBytes =>
      convert.base64.decode(cosmoBinaryReference!);

  set cosmoBinaryReferenceAsBytes(core.List<core.int> _bytes) {
    cosmoBinaryReference =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// gdata
  core.int? crc32cHash;

  /// gdata
  GdataDiffChecksumsResponse? diffChecksumsResponse;

  /// gdata
  GdataDiffDownloadResponse? diffDownloadResponse;

  /// gdata
  GdataDiffUploadRequest? diffUploadRequest;

  /// gdata
  GdataDiffUploadResponse? diffUploadResponse;

  /// gdata
  GdataDiffVersionResponse? diffVersionResponse;

  /// gdata
  GdataDownloadParameters? downloadParameters;

  /// gdata
  core.String? filename;

  /// gdata
  core.String? hash;

  /// gdata
  core.bool? hashVerified;

  /// gdata
  core.String? inline;
  core.List<core.int> get inlineAsBytes => convert.base64.decode(inline!);

  set inlineAsBytes(core.List<core.int> _bytes) {
    inline =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// gdata
  core.bool? isPotentialRetry;

  /// gdata
  core.String? length;

  /// gdata
  core.String? md5Hash;
  core.List<core.int> get md5HashAsBytes => convert.base64.decode(md5Hash!);

  set md5HashAsBytes(core.List<core.int> _bytes) {
    md5Hash =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// gdata
  core.String? mediaId;
  core.List<core.int> get mediaIdAsBytes => convert.base64.decode(mediaId!);

  set mediaIdAsBytes(core.List<core.int> _bytes) {
    mediaId =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// gdata
  GdataObjectId? objectId;

  /// gdata
  core.String? path;

  /// gdata
  /// Possible string values are:
  /// - "PATH" : gdata
  /// - "BLOB_REF" : gdata
  /// - "INLINE" : gdata
  /// - "GET_MEDIA" : gdata
  /// - "COMPOSITE_MEDIA" : gdata
  /// - "BIGSTORE_REF" : gdata
  /// - "DIFF_VERSION_RESPONSE" : gdata
  /// - "DIFF_CHECKSUMS_RESPONSE" : gdata
  /// - "DIFF_DOWNLOAD_RESPONSE" : gdata
  /// - "DIFF_UPLOAD_REQUEST" : gdata
  /// - "DIFF_UPLOAD_RESPONSE" : gdata
  /// - "COSMO_BINARY_REFERENCE" : gdata
  /// - "ARBITRARY_BYTES" : gdata
  core.String? referenceType;

  /// gdata
  core.String? sha1Hash;
  core.List<core.int> get sha1HashAsBytes => convert.base64.decode(sha1Hash!);

  set sha1HashAsBytes(core.List<core.int> _bytes) {
    sha1Hash =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// gdata
  core.String? sha256Hash;
  core.List<core.int> get sha256HashAsBytes =>
      convert.base64.decode(sha256Hash!);

  set sha256HashAsBytes(core.List<core.int> _bytes) {
    sha256Hash =
        convert.base64.encode(_bytes).replaceAll('/', '_').replaceAll('+', '-');
  }

  /// gdata
  core.String? timestamp;

  /// gdata
  core.String? token;

  GdataMedia();

  GdataMedia.fromJson(core.Map _json) {
    if (_json.containsKey('algorithm')) {
      algorithm = _json['algorithm'] as core.String;
    }
    if (_json.containsKey('bigstoreObjectRef')) {
      bigstoreObjectRef = _json['bigstoreObjectRef'] as core.String;
    }
    if (_json.containsKey('blobRef')) {
      blobRef = _json['blobRef'] as core.String;
    }
    if (_json.containsKey('blobstore2Info')) {
      blobstore2Info = GdataBlobstore2Info.fromJson(
          _json['blobstore2Info'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('compositeMedia')) {
      compositeMedia = (_json['compositeMedia'] as core.List)
          .map<GdataCompositeMedia>((value) => GdataCompositeMedia.fromJson(
              value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('contentType')) {
      contentType = _json['contentType'] as core.String;
    }
    if (_json.containsKey('contentTypeInfo')) {
      contentTypeInfo = GdataContentTypeInfo.fromJson(
          _json['contentTypeInfo'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('cosmoBinaryReference')) {
      cosmoBinaryReference = _json['cosmoBinaryReference'] as core.String;
    }
    if (_json.containsKey('crc32cHash')) {
      crc32cHash = _json['crc32cHash'] as core.int;
    }
    if (_json.containsKey('diffChecksumsResponse')) {
      diffChecksumsResponse = GdataDiffChecksumsResponse.fromJson(
          _json['diffChecksumsResponse']
              as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('diffDownloadResponse')) {
      diffDownloadResponse = GdataDiffDownloadResponse.fromJson(
          _json['diffDownloadResponse'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('diffUploadRequest')) {
      diffUploadRequest = GdataDiffUploadRequest.fromJson(
          _json['diffUploadRequest'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('diffUploadResponse')) {
      diffUploadResponse = GdataDiffUploadResponse.fromJson(
          _json['diffUploadResponse'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('diffVersionResponse')) {
      diffVersionResponse = GdataDiffVersionResponse.fromJson(
          _json['diffVersionResponse'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('downloadParameters')) {
      downloadParameters = GdataDownloadParameters.fromJson(
          _json['downloadParameters'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('filename')) {
      filename = _json['filename'] as core.String;
    }
    if (_json.containsKey('hash')) {
      hash = _json['hash'] as core.String;
    }
    if (_json.containsKey('hashVerified')) {
      hashVerified = _json['hashVerified'] as core.bool;
    }
    if (_json.containsKey('inline')) {
      inline = _json['inline'] as core.String;
    }
    if (_json.containsKey('isPotentialRetry')) {
      isPotentialRetry = _json['isPotentialRetry'] as core.bool;
    }
    if (_json.containsKey('length')) {
      length = _json['length'] as core.String;
    }
    if (_json.containsKey('md5Hash')) {
      md5Hash = _json['md5Hash'] as core.String;
    }
    if (_json.containsKey('mediaId')) {
      mediaId = _json['mediaId'] as core.String;
    }
    if (_json.containsKey('objectId')) {
      objectId = GdataObjectId.fromJson(
          _json['objectId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('path')) {
      path = _json['path'] as core.String;
    }
    if (_json.containsKey('referenceType')) {
      referenceType = _json['referenceType'] as core.String;
    }
    if (_json.containsKey('sha1Hash')) {
      sha1Hash = _json['sha1Hash'] as core.String;
    }
    if (_json.containsKey('sha256Hash')) {
      sha256Hash = _json['sha256Hash'] as core.String;
    }
    if (_json.containsKey('timestamp')) {
      timestamp = _json['timestamp'] as core.String;
    }
    if (_json.containsKey('token')) {
      token = _json['token'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (algorithm != null) 'algorithm': algorithm!,
        if (bigstoreObjectRef != null) 'bigstoreObjectRef': bigstoreObjectRef!,
        if (blobRef != null) 'blobRef': blobRef!,
        if (blobstore2Info != null) 'blobstore2Info': blobstore2Info!.toJson(),
        if (compositeMedia != null)
          'compositeMedia':
              compositeMedia!.map((value) => value.toJson()).toList(),
        if (contentType != null) 'contentType': contentType!,
        if (contentTypeInfo != null)
          'contentTypeInfo': contentTypeInfo!.toJson(),
        if (cosmoBinaryReference != null)
          'cosmoBinaryReference': cosmoBinaryReference!,
        if (crc32cHash != null) 'crc32cHash': crc32cHash!,
        if (diffChecksumsResponse != null)
          'diffChecksumsResponse': diffChecksumsResponse!.toJson(),
        if (diffDownloadResponse != null)
          'diffDownloadResponse': diffDownloadResponse!.toJson(),
        if (diffUploadRequest != null)
          'diffUploadRequest': diffUploadRequest!.toJson(),
        if (diffUploadResponse != null)
          'diffUploadResponse': diffUploadResponse!.toJson(),
        if (diffVersionResponse != null)
          'diffVersionResponse': diffVersionResponse!.toJson(),
        if (downloadParameters != null)
          'downloadParameters': downloadParameters!.toJson(),
        if (filename != null) 'filename': filename!,
        if (hash != null) 'hash': hash!,
        if (hashVerified != null) 'hashVerified': hashVerified!,
        if (inline != null) 'inline': inline!,
        if (isPotentialRetry != null) 'isPotentialRetry': isPotentialRetry!,
        if (length != null) 'length': length!,
        if (md5Hash != null) 'md5Hash': md5Hash!,
        if (mediaId != null) 'mediaId': mediaId!,
        if (objectId != null) 'objectId': objectId!.toJson(),
        if (path != null) 'path': path!,
        if (referenceType != null) 'referenceType': referenceType!,
        if (sha1Hash != null) 'sha1Hash': sha1Hash!,
        if (sha256Hash != null) 'sha256Hash': sha256Hash!,
        if (timestamp != null) 'timestamp': timestamp!,
        if (token != null) 'token': token!,
      };
}

/// gdata
class GdataObjectId {
  /// gdata
  core.String? bucketName;

  /// gdata
  core.String? generation;

  /// gdata
  core.String? objectName;

  GdataObjectId();

  GdataObjectId.fromJson(core.Map _json) {
    if (_json.containsKey('bucketName')) {
      bucketName = _json['bucketName'] as core.String;
    }
    if (_json.containsKey('generation')) {
      generation = _json['generation'] as core.String;
    }
    if (_json.containsKey('objectName')) {
      objectName = _json['objectName'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (bucketName != null) 'bucketName': bucketName!,
        if (generation != null) 'generation': generation!,
        if (objectName != null) 'objectName': objectName!,
      };
}

/// A job creating reports of a specific type.
class Job {
  /// The creation date/time of the job.
  core.String? createTime;

  /// The date/time when this job will expire/expired.
  ///
  /// After a job expired, no new reports are generated.
  core.String? expireTime;

  /// The server-generated ID of the job (max.
  ///
  /// 40 characters).
  core.String? id;

  /// The name of the job (max.
  ///
  /// 100 characters).
  core.String? name;

  /// The type of reports this job creates.
  ///
  /// Corresponds to the ID of a ReportType.
  core.String? reportTypeId;

  /// True if this a system-managed job that cannot be modified by the user;
  /// otherwise false.
  core.bool? systemManaged;

  Job();

  Job.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('expireTime')) {
      expireTime = _json['expireTime'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('reportTypeId')) {
      reportTypeId = _json['reportTypeId'] as core.String;
    }
    if (_json.containsKey('systemManaged')) {
      systemManaged = _json['systemManaged'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (expireTime != null) 'expireTime': expireTime!,
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
        if (reportTypeId != null) 'reportTypeId': reportTypeId!,
        if (systemManaged != null) 'systemManaged': systemManaged!,
      };
}

/// Response message for ReportingService.ListJobs.
class ListJobsResponse {
  /// The list of jobs.
  core.List<Job>? jobs;

  /// A token to retrieve next page of results.
  ///
  /// Pass this value in the ListJobsRequest.page_token field in the subsequent
  /// call to `ListJobs` method to retrieve the next page of results.
  core.String? nextPageToken;

  ListJobsResponse();

  ListJobsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('jobs')) {
      jobs = (_json['jobs'] as core.List)
          .map<Job>((value) =>
              Job.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (jobs != null) 'jobs': jobs!.map((value) => value.toJson()).toList(),
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
      };
}

/// Response message for ReportingService.ListReportTypes.
class ListReportTypesResponse {
  /// A token to retrieve next page of results.
  ///
  /// Pass this value in the ListReportTypesRequest.page_token field in the
  /// subsequent call to `ListReportTypes` method to retrieve the next page of
  /// results.
  core.String? nextPageToken;

  /// The list of report types.
  core.List<ReportType>? reportTypes;

  ListReportTypesResponse();

  ListReportTypesResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('reportTypes')) {
      reportTypes = (_json['reportTypes'] as core.List)
          .map<ReportType>((value) =>
              ReportType.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (reportTypes != null)
          'reportTypes': reportTypes!.map((value) => value.toJson()).toList(),
      };
}

/// Response message for ReportingService.ListReports.
class ListReportsResponse {
  /// A token to retrieve next page of results.
  ///
  /// Pass this value in the ListReportsRequest.page_token field in the
  /// subsequent call to `ListReports` method to retrieve the next page of
  /// results.
  core.String? nextPageToken;

  /// The list of report types.
  core.List<Report>? reports;

  ListReportsResponse();

  ListReportsResponse.fromJson(core.Map _json) {
    if (_json.containsKey('nextPageToken')) {
      nextPageToken = _json['nextPageToken'] as core.String;
    }
    if (_json.containsKey('reports')) {
      reports = (_json['reports'] as core.List)
          .map<Report>((value) =>
              Report.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (nextPageToken != null) 'nextPageToken': nextPageToken!,
        if (reports != null)
          'reports': reports!.map((value) => value.toJson()).toList(),
      };
}

/// A report's metadata including the URL from which the report itself can be
/// downloaded.
class Report {
  /// The date/time when this report was created.
  core.String? createTime;

  /// The URL from which the report can be downloaded (max.
  ///
  /// 1000 characters).
  core.String? downloadUrl;

  /// The end of the time period that the report instance covers.
  ///
  /// The value is exclusive.
  core.String? endTime;

  /// The server-generated ID of the report.
  core.String? id;

  /// The date/time when the job this report belongs to will expire/expired.
  core.String? jobExpireTime;

  /// The ID of the job that created this report.
  core.String? jobId;

  /// The start of the time period that the report instance covers.
  ///
  /// The value is inclusive.
  core.String? startTime;

  Report();

  Report.fromJson(core.Map _json) {
    if (_json.containsKey('createTime')) {
      createTime = _json['createTime'] as core.String;
    }
    if (_json.containsKey('downloadUrl')) {
      downloadUrl = _json['downloadUrl'] as core.String;
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('jobExpireTime')) {
      jobExpireTime = _json['jobExpireTime'] as core.String;
    }
    if (_json.containsKey('jobId')) {
      jobId = _json['jobId'] as core.String;
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (createTime != null) 'createTime': createTime!,
        if (downloadUrl != null) 'downloadUrl': downloadUrl!,
        if (endTime != null) 'endTime': endTime!,
        if (id != null) 'id': id!,
        if (jobExpireTime != null) 'jobExpireTime': jobExpireTime!,
        if (jobId != null) 'jobId': jobId!,
        if (startTime != null) 'startTime': startTime!,
      };
}

/// A report type.
class ReportType {
  /// The date/time when this report type was/will be deprecated.
  core.String? deprecateTime;

  /// The ID of the report type (max.
  ///
  /// 100 characters).
  core.String? id;

  /// The name of the report type (max.
  ///
  /// 100 characters).
  core.String? name;

  /// True if this a system-managed report type; otherwise false.
  ///
  /// Reporting jobs for system-managed report types are created automatically
  /// and can thus not be used in the `CreateJob` method.
  core.bool? systemManaged;

  ReportType();

  ReportType.fromJson(core.Map _json) {
    if (_json.containsKey('deprecateTime')) {
      deprecateTime = _json['deprecateTime'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('systemManaged')) {
      systemManaged = _json['systemManaged'] as core.bool;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (deprecateTime != null) 'deprecateTime': deprecateTime!,
        if (id != null) 'id': id!,
        if (name != null) 'name': name!,
        if (systemManaged != null) 'systemManaged': systemManaged!,
      };
}
