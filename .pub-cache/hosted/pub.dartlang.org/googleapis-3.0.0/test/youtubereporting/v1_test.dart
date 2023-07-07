// ignore_for_file: avoid_returning_null
// ignore_for_file: camel_case_types
// ignore_for_file: cascade_invocations
// ignore_for_file: comment_references
// ignore_for_file: file_names
// ignore_for_file: library_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: prefer_final_locals
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: prefer_single_quotes
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unnecessary_cast
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: unnecessary_string_interpolations
// ignore_for_file: unused_local_variable

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:googleapis/youtubereporting/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterEmpty = 0;
api.Empty buildEmpty() {
  var o = api.Empty();
  buildCounterEmpty++;
  if (buildCounterEmpty < 3) {}
  buildCounterEmpty--;
  return o;
}

void checkEmpty(api.Empty o) {
  buildCounterEmpty++;
  if (buildCounterEmpty < 3) {}
  buildCounterEmpty--;
}

core.int buildCounterGdataBlobstore2Info = 0;
api.GdataBlobstore2Info buildGdataBlobstore2Info() {
  var o = api.GdataBlobstore2Info();
  buildCounterGdataBlobstore2Info++;
  if (buildCounterGdataBlobstore2Info < 3) {
    o.blobGeneration = 'foo';
    o.blobId = 'foo';
    o.downloadReadHandle = 'foo';
    o.readToken = 'foo';
    o.uploadMetadataContainer = 'foo';
  }
  buildCounterGdataBlobstore2Info--;
  return o;
}

void checkGdataBlobstore2Info(api.GdataBlobstore2Info o) {
  buildCounterGdataBlobstore2Info++;
  if (buildCounterGdataBlobstore2Info < 3) {
    unittest.expect(
      o.blobGeneration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.blobId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.downloadReadHandle!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readToken!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uploadMetadataContainer!,
      unittest.equals('foo'),
    );
  }
  buildCounterGdataBlobstore2Info--;
}

core.int buildCounterGdataCompositeMedia = 0;
api.GdataCompositeMedia buildGdataCompositeMedia() {
  var o = api.GdataCompositeMedia();
  buildCounterGdataCompositeMedia++;
  if (buildCounterGdataCompositeMedia < 3) {
    o.blobRef = 'foo';
    o.blobstore2Info = buildGdataBlobstore2Info();
    o.cosmoBinaryReference = 'foo';
    o.crc32cHash = 42;
    o.inline = 'foo';
    o.length = 'foo';
    o.md5Hash = 'foo';
    o.objectId = buildGdataObjectId();
    o.path = 'foo';
    o.referenceType = 'foo';
    o.sha1Hash = 'foo';
  }
  buildCounterGdataCompositeMedia--;
  return o;
}

void checkGdataCompositeMedia(api.GdataCompositeMedia o) {
  buildCounterGdataCompositeMedia++;
  if (buildCounterGdataCompositeMedia < 3) {
    unittest.expect(
      o.blobRef!,
      unittest.equals('foo'),
    );
    checkGdataBlobstore2Info(o.blobstore2Info! as api.GdataBlobstore2Info);
    unittest.expect(
      o.cosmoBinaryReference!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.crc32cHash!,
      unittest.equals(42),
    );
    unittest.expect(
      o.inline!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.length!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.md5Hash!,
      unittest.equals('foo'),
    );
    checkGdataObjectId(o.objectId! as api.GdataObjectId);
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referenceType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sha1Hash!,
      unittest.equals('foo'),
    );
  }
  buildCounterGdataCompositeMedia--;
}

core.int buildCounterGdataContentTypeInfo = 0;
api.GdataContentTypeInfo buildGdataContentTypeInfo() {
  var o = api.GdataContentTypeInfo();
  buildCounterGdataContentTypeInfo++;
  if (buildCounterGdataContentTypeInfo < 3) {
    o.bestGuess = 'foo';
    o.fromBytes = 'foo';
    o.fromFileName = 'foo';
    o.fromHeader = 'foo';
    o.fromUrlPath = 'foo';
  }
  buildCounterGdataContentTypeInfo--;
  return o;
}

void checkGdataContentTypeInfo(api.GdataContentTypeInfo o) {
  buildCounterGdataContentTypeInfo++;
  if (buildCounterGdataContentTypeInfo < 3) {
    unittest.expect(
      o.bestGuess!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fromBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fromFileName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fromHeader!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fromUrlPath!,
      unittest.equals('foo'),
    );
  }
  buildCounterGdataContentTypeInfo--;
}

core.int buildCounterGdataDiffChecksumsResponse = 0;
api.GdataDiffChecksumsResponse buildGdataDiffChecksumsResponse() {
  var o = api.GdataDiffChecksumsResponse();
  buildCounterGdataDiffChecksumsResponse++;
  if (buildCounterGdataDiffChecksumsResponse < 3) {
    o.checksumsLocation = buildGdataCompositeMedia();
    o.chunkSizeBytes = 'foo';
    o.objectLocation = buildGdataCompositeMedia();
    o.objectSizeBytes = 'foo';
    o.objectVersion = 'foo';
  }
  buildCounterGdataDiffChecksumsResponse--;
  return o;
}

void checkGdataDiffChecksumsResponse(api.GdataDiffChecksumsResponse o) {
  buildCounterGdataDiffChecksumsResponse++;
  if (buildCounterGdataDiffChecksumsResponse < 3) {
    checkGdataCompositeMedia(o.checksumsLocation! as api.GdataCompositeMedia);
    unittest.expect(
      o.chunkSizeBytes!,
      unittest.equals('foo'),
    );
    checkGdataCompositeMedia(o.objectLocation! as api.GdataCompositeMedia);
    unittest.expect(
      o.objectSizeBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectVersion!,
      unittest.equals('foo'),
    );
  }
  buildCounterGdataDiffChecksumsResponse--;
}

core.int buildCounterGdataDiffDownloadResponse = 0;
api.GdataDiffDownloadResponse buildGdataDiffDownloadResponse() {
  var o = api.GdataDiffDownloadResponse();
  buildCounterGdataDiffDownloadResponse++;
  if (buildCounterGdataDiffDownloadResponse < 3) {
    o.objectLocation = buildGdataCompositeMedia();
  }
  buildCounterGdataDiffDownloadResponse--;
  return o;
}

void checkGdataDiffDownloadResponse(api.GdataDiffDownloadResponse o) {
  buildCounterGdataDiffDownloadResponse++;
  if (buildCounterGdataDiffDownloadResponse < 3) {
    checkGdataCompositeMedia(o.objectLocation! as api.GdataCompositeMedia);
  }
  buildCounterGdataDiffDownloadResponse--;
}

core.int buildCounterGdataDiffUploadRequest = 0;
api.GdataDiffUploadRequest buildGdataDiffUploadRequest() {
  var o = api.GdataDiffUploadRequest();
  buildCounterGdataDiffUploadRequest++;
  if (buildCounterGdataDiffUploadRequest < 3) {
    o.checksumsInfo = buildGdataCompositeMedia();
    o.objectInfo = buildGdataCompositeMedia();
    o.objectVersion = 'foo';
  }
  buildCounterGdataDiffUploadRequest--;
  return o;
}

void checkGdataDiffUploadRequest(api.GdataDiffUploadRequest o) {
  buildCounterGdataDiffUploadRequest++;
  if (buildCounterGdataDiffUploadRequest < 3) {
    checkGdataCompositeMedia(o.checksumsInfo! as api.GdataCompositeMedia);
    checkGdataCompositeMedia(o.objectInfo! as api.GdataCompositeMedia);
    unittest.expect(
      o.objectVersion!,
      unittest.equals('foo'),
    );
  }
  buildCounterGdataDiffUploadRequest--;
}

core.int buildCounterGdataDiffUploadResponse = 0;
api.GdataDiffUploadResponse buildGdataDiffUploadResponse() {
  var o = api.GdataDiffUploadResponse();
  buildCounterGdataDiffUploadResponse++;
  if (buildCounterGdataDiffUploadResponse < 3) {
    o.objectVersion = 'foo';
    o.originalObject = buildGdataCompositeMedia();
  }
  buildCounterGdataDiffUploadResponse--;
  return o;
}

void checkGdataDiffUploadResponse(api.GdataDiffUploadResponse o) {
  buildCounterGdataDiffUploadResponse++;
  if (buildCounterGdataDiffUploadResponse < 3) {
    unittest.expect(
      o.objectVersion!,
      unittest.equals('foo'),
    );
    checkGdataCompositeMedia(o.originalObject! as api.GdataCompositeMedia);
  }
  buildCounterGdataDiffUploadResponse--;
}

core.int buildCounterGdataDiffVersionResponse = 0;
api.GdataDiffVersionResponse buildGdataDiffVersionResponse() {
  var o = api.GdataDiffVersionResponse();
  buildCounterGdataDiffVersionResponse++;
  if (buildCounterGdataDiffVersionResponse < 3) {
    o.objectSizeBytes = 'foo';
    o.objectVersion = 'foo';
  }
  buildCounterGdataDiffVersionResponse--;
  return o;
}

void checkGdataDiffVersionResponse(api.GdataDiffVersionResponse o) {
  buildCounterGdataDiffVersionResponse++;
  if (buildCounterGdataDiffVersionResponse < 3) {
    unittest.expect(
      o.objectSizeBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectVersion!,
      unittest.equals('foo'),
    );
  }
  buildCounterGdataDiffVersionResponse--;
}

core.int buildCounterGdataDownloadParameters = 0;
api.GdataDownloadParameters buildGdataDownloadParameters() {
  var o = api.GdataDownloadParameters();
  buildCounterGdataDownloadParameters++;
  if (buildCounterGdataDownloadParameters < 3) {
    o.allowGzipCompression = true;
    o.ignoreRange = true;
  }
  buildCounterGdataDownloadParameters--;
  return o;
}

void checkGdataDownloadParameters(api.GdataDownloadParameters o) {
  buildCounterGdataDownloadParameters++;
  if (buildCounterGdataDownloadParameters < 3) {
    unittest.expect(o.allowGzipCompression!, unittest.isTrue);
    unittest.expect(o.ignoreRange!, unittest.isTrue);
  }
  buildCounterGdataDownloadParameters--;
}

core.List<api.GdataCompositeMedia> buildUnnamed4029() {
  var o = <api.GdataCompositeMedia>[];
  o.add(buildGdataCompositeMedia());
  o.add(buildGdataCompositeMedia());
  return o;
}

void checkUnnamed4029(core.List<api.GdataCompositeMedia> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGdataCompositeMedia(o[0] as api.GdataCompositeMedia);
  checkGdataCompositeMedia(o[1] as api.GdataCompositeMedia);
}

core.int buildCounterGdataMedia = 0;
api.GdataMedia buildGdataMedia() {
  var o = api.GdataMedia();
  buildCounterGdataMedia++;
  if (buildCounterGdataMedia < 3) {
    o.algorithm = 'foo';
    o.bigstoreObjectRef = 'foo';
    o.blobRef = 'foo';
    o.blobstore2Info = buildGdataBlobstore2Info();
    o.compositeMedia = buildUnnamed4029();
    o.contentType = 'foo';
    o.contentTypeInfo = buildGdataContentTypeInfo();
    o.cosmoBinaryReference = 'foo';
    o.crc32cHash = 42;
    o.diffChecksumsResponse = buildGdataDiffChecksumsResponse();
    o.diffDownloadResponse = buildGdataDiffDownloadResponse();
    o.diffUploadRequest = buildGdataDiffUploadRequest();
    o.diffUploadResponse = buildGdataDiffUploadResponse();
    o.diffVersionResponse = buildGdataDiffVersionResponse();
    o.downloadParameters = buildGdataDownloadParameters();
    o.filename = 'foo';
    o.hash = 'foo';
    o.hashVerified = true;
    o.inline = 'foo';
    o.isPotentialRetry = true;
    o.length = 'foo';
    o.md5Hash = 'foo';
    o.mediaId = 'foo';
    o.objectId = buildGdataObjectId();
    o.path = 'foo';
    o.referenceType = 'foo';
    o.sha1Hash = 'foo';
    o.sha256Hash = 'foo';
    o.timestamp = 'foo';
    o.token = 'foo';
  }
  buildCounterGdataMedia--;
  return o;
}

void checkGdataMedia(api.GdataMedia o) {
  buildCounterGdataMedia++;
  if (buildCounterGdataMedia < 3) {
    unittest.expect(
      o.algorithm!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.bigstoreObjectRef!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.blobRef!,
      unittest.equals('foo'),
    );
    checkGdataBlobstore2Info(o.blobstore2Info! as api.GdataBlobstore2Info);
    checkUnnamed4029(o.compositeMedia!);
    unittest.expect(
      o.contentType!,
      unittest.equals('foo'),
    );
    checkGdataContentTypeInfo(o.contentTypeInfo! as api.GdataContentTypeInfo);
    unittest.expect(
      o.cosmoBinaryReference!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.crc32cHash!,
      unittest.equals(42),
    );
    checkGdataDiffChecksumsResponse(
        o.diffChecksumsResponse! as api.GdataDiffChecksumsResponse);
    checkGdataDiffDownloadResponse(
        o.diffDownloadResponse! as api.GdataDiffDownloadResponse);
    checkGdataDiffUploadRequest(
        o.diffUploadRequest! as api.GdataDiffUploadRequest);
    checkGdataDiffUploadResponse(
        o.diffUploadResponse! as api.GdataDiffUploadResponse);
    checkGdataDiffVersionResponse(
        o.diffVersionResponse! as api.GdataDiffVersionResponse);
    checkGdataDownloadParameters(
        o.downloadParameters! as api.GdataDownloadParameters);
    unittest.expect(
      o.filename!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.hash!,
      unittest.equals('foo'),
    );
    unittest.expect(o.hashVerified!, unittest.isTrue);
    unittest.expect(
      o.inline!,
      unittest.equals('foo'),
    );
    unittest.expect(o.isPotentialRetry!, unittest.isTrue);
    unittest.expect(
      o.length!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.md5Hash!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mediaId!,
      unittest.equals('foo'),
    );
    checkGdataObjectId(o.objectId! as api.GdataObjectId);
    unittest.expect(
      o.path!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.referenceType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sha1Hash!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sha256Hash!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timestamp!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.token!,
      unittest.equals('foo'),
    );
  }
  buildCounterGdataMedia--;
}

core.int buildCounterGdataObjectId = 0;
api.GdataObjectId buildGdataObjectId() {
  var o = api.GdataObjectId();
  buildCounterGdataObjectId++;
  if (buildCounterGdataObjectId < 3) {
    o.bucketName = 'foo';
    o.generation = 'foo';
    o.objectName = 'foo';
  }
  buildCounterGdataObjectId--;
  return o;
}

void checkGdataObjectId(api.GdataObjectId o) {
  buildCounterGdataObjectId++;
  if (buildCounterGdataObjectId < 3) {
    unittest.expect(
      o.bucketName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.generation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.objectName!,
      unittest.equals('foo'),
    );
  }
  buildCounterGdataObjectId--;
}

core.int buildCounterJob = 0;
api.Job buildJob() {
  var o = api.Job();
  buildCounterJob++;
  if (buildCounterJob < 3) {
    o.createTime = 'foo';
    o.expireTime = 'foo';
    o.id = 'foo';
    o.name = 'foo';
    o.reportTypeId = 'foo';
    o.systemManaged = true;
  }
  buildCounterJob--;
  return o;
}

void checkJob(api.Job o) {
  buildCounterJob++;
  if (buildCounterJob < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expireTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reportTypeId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.systemManaged!, unittest.isTrue);
  }
  buildCounterJob--;
}

core.List<api.Job> buildUnnamed4030() {
  var o = <api.Job>[];
  o.add(buildJob());
  o.add(buildJob());
  return o;
}

void checkUnnamed4030(core.List<api.Job> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkJob(o[0] as api.Job);
  checkJob(o[1] as api.Job);
}

core.int buildCounterListJobsResponse = 0;
api.ListJobsResponse buildListJobsResponse() {
  var o = api.ListJobsResponse();
  buildCounterListJobsResponse++;
  if (buildCounterListJobsResponse < 3) {
    o.jobs = buildUnnamed4030();
    o.nextPageToken = 'foo';
  }
  buildCounterListJobsResponse--;
  return o;
}

void checkListJobsResponse(api.ListJobsResponse o) {
  buildCounterListJobsResponse++;
  if (buildCounterListJobsResponse < 3) {
    checkUnnamed4030(o.jobs!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListJobsResponse--;
}

core.List<api.ReportType> buildUnnamed4031() {
  var o = <api.ReportType>[];
  o.add(buildReportType());
  o.add(buildReportType());
  return o;
}

void checkUnnamed4031(core.List<api.ReportType> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReportType(o[0] as api.ReportType);
  checkReportType(o[1] as api.ReportType);
}

core.int buildCounterListReportTypesResponse = 0;
api.ListReportTypesResponse buildListReportTypesResponse() {
  var o = api.ListReportTypesResponse();
  buildCounterListReportTypesResponse++;
  if (buildCounterListReportTypesResponse < 3) {
    o.nextPageToken = 'foo';
    o.reportTypes = buildUnnamed4031();
  }
  buildCounterListReportTypesResponse--;
  return o;
}

void checkListReportTypesResponse(api.ListReportTypesResponse o) {
  buildCounterListReportTypesResponse++;
  if (buildCounterListReportTypesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed4031(o.reportTypes!);
  }
  buildCounterListReportTypesResponse--;
}

core.List<api.Report> buildUnnamed4032() {
  var o = <api.Report>[];
  o.add(buildReport());
  o.add(buildReport());
  return o;
}

void checkUnnamed4032(core.List<api.Report> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkReport(o[0] as api.Report);
  checkReport(o[1] as api.Report);
}

core.int buildCounterListReportsResponse = 0;
api.ListReportsResponse buildListReportsResponse() {
  var o = api.ListReportsResponse();
  buildCounterListReportsResponse++;
  if (buildCounterListReportsResponse < 3) {
    o.nextPageToken = 'foo';
    o.reports = buildUnnamed4032();
  }
  buildCounterListReportsResponse--;
  return o;
}

void checkListReportsResponse(api.ListReportsResponse o) {
  buildCounterListReportsResponse++;
  if (buildCounterListReportsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed4032(o.reports!);
  }
  buildCounterListReportsResponse--;
}

core.int buildCounterReport = 0;
api.Report buildReport() {
  var o = api.Report();
  buildCounterReport++;
  if (buildCounterReport < 3) {
    o.createTime = 'foo';
    o.downloadUrl = 'foo';
    o.endTime = 'foo';
    o.id = 'foo';
    o.jobExpireTime = 'foo';
    o.jobId = 'foo';
    o.startTime = 'foo';
  }
  buildCounterReport--;
  return o;
}

void checkReport(api.Report o) {
  buildCounterReport++;
  if (buildCounterReport < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.downloadUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.jobExpireTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.jobId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterReport--;
}

core.int buildCounterReportType = 0;
api.ReportType buildReportType() {
  var o = api.ReportType();
  buildCounterReportType++;
  if (buildCounterReportType < 3) {
    o.deprecateTime = 'foo';
    o.id = 'foo';
    o.name = 'foo';
    o.systemManaged = true;
  }
  buildCounterReportType--;
  return o;
}

void checkReportType(api.ReportType o) {
  buildCounterReportType++;
  if (buildCounterReportType < 3) {
    unittest.expect(
      o.deprecateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(o.systemManaged!, unittest.isTrue);
  }
  buildCounterReportType--;
}

void main() {
  unittest.group('obj-schema-Empty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmpty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Empty.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEmpty(od as api.Empty);
    });
  });

  unittest.group('obj-schema-GdataBlobstore2Info', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGdataBlobstore2Info();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GdataBlobstore2Info.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGdataBlobstore2Info(od as api.GdataBlobstore2Info);
    });
  });

  unittest.group('obj-schema-GdataCompositeMedia', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGdataCompositeMedia();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GdataCompositeMedia.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGdataCompositeMedia(od as api.GdataCompositeMedia);
    });
  });

  unittest.group('obj-schema-GdataContentTypeInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGdataContentTypeInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GdataContentTypeInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGdataContentTypeInfo(od as api.GdataContentTypeInfo);
    });
  });

  unittest.group('obj-schema-GdataDiffChecksumsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGdataDiffChecksumsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GdataDiffChecksumsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGdataDiffChecksumsResponse(od as api.GdataDiffChecksumsResponse);
    });
  });

  unittest.group('obj-schema-GdataDiffDownloadResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGdataDiffDownloadResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GdataDiffDownloadResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGdataDiffDownloadResponse(od as api.GdataDiffDownloadResponse);
    });
  });

  unittest.group('obj-schema-GdataDiffUploadRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGdataDiffUploadRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GdataDiffUploadRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGdataDiffUploadRequest(od as api.GdataDiffUploadRequest);
    });
  });

  unittest.group('obj-schema-GdataDiffUploadResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGdataDiffUploadResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GdataDiffUploadResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGdataDiffUploadResponse(od as api.GdataDiffUploadResponse);
    });
  });

  unittest.group('obj-schema-GdataDiffVersionResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGdataDiffVersionResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GdataDiffVersionResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGdataDiffVersionResponse(od as api.GdataDiffVersionResponse);
    });
  });

  unittest.group('obj-schema-GdataDownloadParameters', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGdataDownloadParameters();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GdataDownloadParameters.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGdataDownloadParameters(od as api.GdataDownloadParameters);
    });
  });

  unittest.group('obj-schema-GdataMedia', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGdataMedia();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GdataMedia.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGdataMedia(od as api.GdataMedia);
    });
  });

  unittest.group('obj-schema-GdataObjectId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGdataObjectId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GdataObjectId.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGdataObjectId(od as api.GdataObjectId);
    });
  });

  unittest.group('obj-schema-Job', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJob();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Job.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkJob(od as api.Job);
    });
  });

  unittest.group('obj-schema-ListJobsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListJobsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListJobsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListJobsResponse(od as api.ListJobsResponse);
    });
  });

  unittest.group('obj-schema-ListReportTypesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListReportTypesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListReportTypesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListReportTypesResponse(od as api.ListReportTypesResponse);
    });
  });

  unittest.group('obj-schema-ListReportsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListReportsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListReportsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListReportsResponse(od as api.ListReportsResponse);
    });
  });

  unittest.group('obj-schema-Report', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReport();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Report.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkReport(od as api.Report);
    });
  });

  unittest.group('obj-schema-ReportType', () {
    unittest.test('to-json--from-json', () async {
      var o = buildReportType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ReportType.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkReportType(od as api.ReportType);
    });
  });

  unittest.group('resource-JobsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeReportingApi(mock).jobs;
      var arg_request = buildJob();
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Job.fromJson(json as core.Map<core.String, core.dynamic>);
        checkJob(obj as api.Job);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("v1/jobs"),
        );
        pathOffset += 7;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
      checkJob(response as api.Job);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeReportingApi(mock).jobs;
      var arg_jobId = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/jobs/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_jobId'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_jobId,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeReportingApi(mock).jobs;
      var arg_jobId = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/jobs/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_jobId'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_jobId,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
      checkJob(response as api.Job);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeReportingApi(mock).jobs;
      var arg_includeSystemManaged = true;
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("v1/jobs"),
        );
        pathOffset += 7;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["includeSystemManaged"]!.first,
          unittest.equals("$arg_includeSystemManaged"),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListJobsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          includeSystemManaged: arg_includeSystemManaged,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListJobsResponse(response as api.ListJobsResponse);
    });
  });

  unittest.group('resource-JobsReportsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeReportingApi(mock).jobs.reports;
      var arg_jobId = 'foo';
      var arg_reportId = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/jobs/"),
        );
        pathOffset += 8;
        index = path.indexOf('/reports/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_jobId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/reports/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_reportId'),
        );

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildReport());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_jobId, arg_reportId,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          $fields: arg_$fields);
      checkReport(response as api.Report);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeReportingApi(mock).jobs.reports;
      var arg_jobId = 'foo';
      var arg_createdAfter = 'foo';
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_startTimeAtOrAfter = 'foo';
      var arg_startTimeBefore = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("v1/jobs/"),
        );
        pathOffset += 8;
        index = path.indexOf('/reports', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_jobId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/reports"),
        );
        pathOffset += 8;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["createdAfter"]!.first,
          unittest.equals(arg_createdAfter),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["startTimeAtOrAfter"]!.first,
          unittest.equals(arg_startTimeAtOrAfter),
        );
        unittest.expect(
          queryMap["startTimeBefore"]!.first,
          unittest.equals(arg_startTimeBefore),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListReportsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_jobId,
          createdAfter: arg_createdAfter,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          startTimeAtOrAfter: arg_startTimeAtOrAfter,
          startTimeBefore: arg_startTimeBefore,
          $fields: arg_$fields);
      checkListReportsResponse(response as api.ListReportsResponse);
    });
  });

  unittest.group('resource-MediaResource', () {
    unittest.test('method--download', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.YouTubeReportingApi(mock).media;
      var arg_resourceName = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("v1/media/"),
        );
        pathOffset += 9;
        // NOTE: We cannot test reserved expansions due to the inability to reverse the operation;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGdataMedia());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.download(arg_resourceName, $fields: arg_$fields);
      checkGdataMedia(response as api.GdataMedia);
    });
  });

  unittest.group('resource-ReportTypesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.YouTubeReportingApi(mock).reportTypes;
      var arg_includeSystemManaged = true;
      var arg_onBehalfOfContentOwner = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("v1/reportTypes"),
        );
        pathOffset += 14;

        var query = (req.url).query;
        var queryOffset = 0;
        var queryMap = <core.String, core.List<core.String>>{};
        void addQueryParam(core.String n, core.String v) =>
            queryMap.putIfAbsent(n, () => []).add(v);

        if (query.isNotEmpty) {
          for (var part in query.split('&')) {
            var keyValue = part.split('=');
            addQueryParam(
              core.Uri.decodeQueryComponent(keyValue[0]),
              core.Uri.decodeQueryComponent(keyValue[1]),
            );
          }
        }
        unittest.expect(
          queryMap["includeSystemManaged"]!.first,
          unittest.equals("$arg_includeSystemManaged"),
        );
        unittest.expect(
          queryMap["onBehalfOfContentOwner"]!.first,
          unittest.equals(arg_onBehalfOfContentOwner),
        );
        unittest.expect(
          core.int.parse(queryMap["pageSize"]!.first),
          unittest.equals(arg_pageSize),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListReportTypesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          includeSystemManaged: arg_includeSystemManaged,
          onBehalfOfContentOwner: arg_onBehalfOfContentOwner,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListReportTypesResponse(response as api.ListReportTypesResponse);
    });
  });
}
