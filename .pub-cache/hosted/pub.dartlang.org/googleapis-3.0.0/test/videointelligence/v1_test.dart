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

import 'package:googleapis/videointelligence/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.GoogleCloudVideointelligenceV1VideoAnnotationProgress>
    buildUnnamed358() {
  var o = <api.GoogleCloudVideointelligenceV1VideoAnnotationProgress>[];
  o.add(buildGoogleCloudVideointelligenceV1VideoAnnotationProgress());
  o.add(buildGoogleCloudVideointelligenceV1VideoAnnotationProgress());
  return o;
}

void checkUnnamed358(
    core.List<api.GoogleCloudVideointelligenceV1VideoAnnotationProgress> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1VideoAnnotationProgress(
      o[0] as api.GoogleCloudVideointelligenceV1VideoAnnotationProgress);
  checkGoogleCloudVideointelligenceV1VideoAnnotationProgress(
      o[1] as api.GoogleCloudVideointelligenceV1VideoAnnotationProgress);
}

core.int buildCounterGoogleCloudVideointelligenceV1AnnotateVideoProgress = 0;
api.GoogleCloudVideointelligenceV1AnnotateVideoProgress
    buildGoogleCloudVideointelligenceV1AnnotateVideoProgress() {
  var o = api.GoogleCloudVideointelligenceV1AnnotateVideoProgress();
  buildCounterGoogleCloudVideointelligenceV1AnnotateVideoProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1AnnotateVideoProgress < 3) {
    o.annotationProgress = buildUnnamed358();
  }
  buildCounterGoogleCloudVideointelligenceV1AnnotateVideoProgress--;
  return o;
}

void checkGoogleCloudVideointelligenceV1AnnotateVideoProgress(
    api.GoogleCloudVideointelligenceV1AnnotateVideoProgress o) {
  buildCounterGoogleCloudVideointelligenceV1AnnotateVideoProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1AnnotateVideoProgress < 3) {
    checkUnnamed358(o.annotationProgress!);
  }
  buildCounterGoogleCloudVideointelligenceV1AnnotateVideoProgress--;
}

core.List<core.String> buildUnnamed359() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed359(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterGoogleCloudVideointelligenceV1AnnotateVideoRequest = 0;
api.GoogleCloudVideointelligenceV1AnnotateVideoRequest
    buildGoogleCloudVideointelligenceV1AnnotateVideoRequest() {
  var o = api.GoogleCloudVideointelligenceV1AnnotateVideoRequest();
  buildCounterGoogleCloudVideointelligenceV1AnnotateVideoRequest++;
  if (buildCounterGoogleCloudVideointelligenceV1AnnotateVideoRequest < 3) {
    o.features = buildUnnamed359();
    o.inputContent = 'foo';
    o.inputUri = 'foo';
    o.locationId = 'foo';
    o.outputUri = 'foo';
    o.videoContext = buildGoogleCloudVideointelligenceV1VideoContext();
  }
  buildCounterGoogleCloudVideointelligenceV1AnnotateVideoRequest--;
  return o;
}

void checkGoogleCloudVideointelligenceV1AnnotateVideoRequest(
    api.GoogleCloudVideointelligenceV1AnnotateVideoRequest o) {
  buildCounterGoogleCloudVideointelligenceV1AnnotateVideoRequest++;
  if (buildCounterGoogleCloudVideointelligenceV1AnnotateVideoRequest < 3) {
    checkUnnamed359(o.features!);
    unittest.expect(
      o.inputContent!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inputUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.outputUri!,
      unittest.equals('foo'),
    );
    checkGoogleCloudVideointelligenceV1VideoContext(
        o.videoContext! as api.GoogleCloudVideointelligenceV1VideoContext);
  }
  buildCounterGoogleCloudVideointelligenceV1AnnotateVideoRequest--;
}

core.List<api.GoogleCloudVideointelligenceV1VideoAnnotationResults>
    buildUnnamed360() {
  var o = <api.GoogleCloudVideointelligenceV1VideoAnnotationResults>[];
  o.add(buildGoogleCloudVideointelligenceV1VideoAnnotationResults());
  o.add(buildGoogleCloudVideointelligenceV1VideoAnnotationResults());
  return o;
}

void checkUnnamed360(
    core.List<api.GoogleCloudVideointelligenceV1VideoAnnotationResults> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1VideoAnnotationResults(
      o[0] as api.GoogleCloudVideointelligenceV1VideoAnnotationResults);
  checkGoogleCloudVideointelligenceV1VideoAnnotationResults(
      o[1] as api.GoogleCloudVideointelligenceV1VideoAnnotationResults);
}

core.int buildCounterGoogleCloudVideointelligenceV1AnnotateVideoResponse = 0;
api.GoogleCloudVideointelligenceV1AnnotateVideoResponse
    buildGoogleCloudVideointelligenceV1AnnotateVideoResponse() {
  var o = api.GoogleCloudVideointelligenceV1AnnotateVideoResponse();
  buildCounterGoogleCloudVideointelligenceV1AnnotateVideoResponse++;
  if (buildCounterGoogleCloudVideointelligenceV1AnnotateVideoResponse < 3) {
    o.annotationResults = buildUnnamed360();
  }
  buildCounterGoogleCloudVideointelligenceV1AnnotateVideoResponse--;
  return o;
}

void checkGoogleCloudVideointelligenceV1AnnotateVideoResponse(
    api.GoogleCloudVideointelligenceV1AnnotateVideoResponse o) {
  buildCounterGoogleCloudVideointelligenceV1AnnotateVideoResponse++;
  if (buildCounterGoogleCloudVideointelligenceV1AnnotateVideoResponse < 3) {
    checkUnnamed360(o.annotationResults!);
  }
  buildCounterGoogleCloudVideointelligenceV1AnnotateVideoResponse--;
}

core.int buildCounterGoogleCloudVideointelligenceV1DetectedAttribute = 0;
api.GoogleCloudVideointelligenceV1DetectedAttribute
    buildGoogleCloudVideointelligenceV1DetectedAttribute() {
  var o = api.GoogleCloudVideointelligenceV1DetectedAttribute();
  buildCounterGoogleCloudVideointelligenceV1DetectedAttribute++;
  if (buildCounterGoogleCloudVideointelligenceV1DetectedAttribute < 3) {
    o.confidence = 42.0;
    o.name = 'foo';
    o.value = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1DetectedAttribute--;
  return o;
}

void checkGoogleCloudVideointelligenceV1DetectedAttribute(
    api.GoogleCloudVideointelligenceV1DetectedAttribute o) {
  buildCounterGoogleCloudVideointelligenceV1DetectedAttribute++;
  if (buildCounterGoogleCloudVideointelligenceV1DetectedAttribute < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1DetectedAttribute--;
}

core.int buildCounterGoogleCloudVideointelligenceV1DetectedLandmark = 0;
api.GoogleCloudVideointelligenceV1DetectedLandmark
    buildGoogleCloudVideointelligenceV1DetectedLandmark() {
  var o = api.GoogleCloudVideointelligenceV1DetectedLandmark();
  buildCounterGoogleCloudVideointelligenceV1DetectedLandmark++;
  if (buildCounterGoogleCloudVideointelligenceV1DetectedLandmark < 3) {
    o.confidence = 42.0;
    o.name = 'foo';
    o.point = buildGoogleCloudVideointelligenceV1NormalizedVertex();
  }
  buildCounterGoogleCloudVideointelligenceV1DetectedLandmark--;
  return o;
}

void checkGoogleCloudVideointelligenceV1DetectedLandmark(
    api.GoogleCloudVideointelligenceV1DetectedLandmark o) {
  buildCounterGoogleCloudVideointelligenceV1DetectedLandmark++;
  if (buildCounterGoogleCloudVideointelligenceV1DetectedLandmark < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkGoogleCloudVideointelligenceV1NormalizedVertex(
        o.point! as api.GoogleCloudVideointelligenceV1NormalizedVertex);
  }
  buildCounterGoogleCloudVideointelligenceV1DetectedLandmark--;
}

core.int buildCounterGoogleCloudVideointelligenceV1Entity = 0;
api.GoogleCloudVideointelligenceV1Entity
    buildGoogleCloudVideointelligenceV1Entity() {
  var o = api.GoogleCloudVideointelligenceV1Entity();
  buildCounterGoogleCloudVideointelligenceV1Entity++;
  if (buildCounterGoogleCloudVideointelligenceV1Entity < 3) {
    o.description = 'foo';
    o.entityId = 'foo';
    o.languageCode = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1Entity--;
  return o;
}

void checkGoogleCloudVideointelligenceV1Entity(
    api.GoogleCloudVideointelligenceV1Entity o) {
  buildCounterGoogleCloudVideointelligenceV1Entity++;
  if (buildCounterGoogleCloudVideointelligenceV1Entity < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1Entity--;
}

core.List<api.GoogleCloudVideointelligenceV1ExplicitContentFrame>
    buildUnnamed361() {
  var o = <api.GoogleCloudVideointelligenceV1ExplicitContentFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1ExplicitContentFrame());
  o.add(buildGoogleCloudVideointelligenceV1ExplicitContentFrame());
  return o;
}

void checkUnnamed361(
    core.List<api.GoogleCloudVideointelligenceV1ExplicitContentFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1ExplicitContentFrame(
      o[0] as api.GoogleCloudVideointelligenceV1ExplicitContentFrame);
  checkGoogleCloudVideointelligenceV1ExplicitContentFrame(
      o[1] as api.GoogleCloudVideointelligenceV1ExplicitContentFrame);
}

core.int buildCounterGoogleCloudVideointelligenceV1ExplicitContentAnnotation =
    0;
api.GoogleCloudVideointelligenceV1ExplicitContentAnnotation
    buildGoogleCloudVideointelligenceV1ExplicitContentAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1ExplicitContentAnnotation();
  buildCounterGoogleCloudVideointelligenceV1ExplicitContentAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1ExplicitContentAnnotation < 3) {
    o.frames = buildUnnamed361();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1ExplicitContentAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1ExplicitContentAnnotation(
    api.GoogleCloudVideointelligenceV1ExplicitContentAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1ExplicitContentAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1ExplicitContentAnnotation < 3) {
    checkUnnamed361(o.frames!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1ExplicitContentAnnotation--;
}

core.int
    buildCounterGoogleCloudVideointelligenceV1ExplicitContentDetectionConfig =
    0;
api.GoogleCloudVideointelligenceV1ExplicitContentDetectionConfig
    buildGoogleCloudVideointelligenceV1ExplicitContentDetectionConfig() {
  var o = api.GoogleCloudVideointelligenceV1ExplicitContentDetectionConfig();
  buildCounterGoogleCloudVideointelligenceV1ExplicitContentDetectionConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1ExplicitContentDetectionConfig <
      3) {
    o.model = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1ExplicitContentDetectionConfig--;
  return o;
}

void checkGoogleCloudVideointelligenceV1ExplicitContentDetectionConfig(
    api.GoogleCloudVideointelligenceV1ExplicitContentDetectionConfig o) {
  buildCounterGoogleCloudVideointelligenceV1ExplicitContentDetectionConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1ExplicitContentDetectionConfig <
      3) {
    unittest.expect(
      o.model!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1ExplicitContentDetectionConfig--;
}

core.int buildCounterGoogleCloudVideointelligenceV1ExplicitContentFrame = 0;
api.GoogleCloudVideointelligenceV1ExplicitContentFrame
    buildGoogleCloudVideointelligenceV1ExplicitContentFrame() {
  var o = api.GoogleCloudVideointelligenceV1ExplicitContentFrame();
  buildCounterGoogleCloudVideointelligenceV1ExplicitContentFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1ExplicitContentFrame < 3) {
    o.pornographyLikelihood = 'foo';
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1ExplicitContentFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1ExplicitContentFrame(
    api.GoogleCloudVideointelligenceV1ExplicitContentFrame o) {
  buildCounterGoogleCloudVideointelligenceV1ExplicitContentFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1ExplicitContentFrame < 3) {
    unittest.expect(
      o.pornographyLikelihood!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1ExplicitContentFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1FaceFrame> buildUnnamed362() {
  var o = <api.GoogleCloudVideointelligenceV1FaceFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1FaceFrame());
  o.add(buildGoogleCloudVideointelligenceV1FaceFrame());
  return o;
}

void checkUnnamed362(core.List<api.GoogleCloudVideointelligenceV1FaceFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1FaceFrame(
      o[0] as api.GoogleCloudVideointelligenceV1FaceFrame);
  checkGoogleCloudVideointelligenceV1FaceFrame(
      o[1] as api.GoogleCloudVideointelligenceV1FaceFrame);
}

core.List<api.GoogleCloudVideointelligenceV1FaceSegment> buildUnnamed363() {
  var o = <api.GoogleCloudVideointelligenceV1FaceSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1FaceSegment());
  o.add(buildGoogleCloudVideointelligenceV1FaceSegment());
  return o;
}

void checkUnnamed363(
    core.List<api.GoogleCloudVideointelligenceV1FaceSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1FaceSegment(
      o[0] as api.GoogleCloudVideointelligenceV1FaceSegment);
  checkGoogleCloudVideointelligenceV1FaceSegment(
      o[1] as api.GoogleCloudVideointelligenceV1FaceSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1FaceAnnotation = 0;
api.GoogleCloudVideointelligenceV1FaceAnnotation
    buildGoogleCloudVideointelligenceV1FaceAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1FaceAnnotation();
  buildCounterGoogleCloudVideointelligenceV1FaceAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1FaceAnnotation < 3) {
    o.frames = buildUnnamed362();
    o.segments = buildUnnamed363();
    o.thumbnail = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1FaceAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1FaceAnnotation(
    api.GoogleCloudVideointelligenceV1FaceAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1FaceAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1FaceAnnotation < 3) {
    checkUnnamed362(o.frames!);
    checkUnnamed363(o.segments!);
    unittest.expect(
      o.thumbnail!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1FaceAnnotation--;
}

core.List<api.GoogleCloudVideointelligenceV1Track> buildUnnamed364() {
  var o = <api.GoogleCloudVideointelligenceV1Track>[];
  o.add(buildGoogleCloudVideointelligenceV1Track());
  o.add(buildGoogleCloudVideointelligenceV1Track());
  return o;
}

void checkUnnamed364(core.List<api.GoogleCloudVideointelligenceV1Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1Track(
      o[0] as api.GoogleCloudVideointelligenceV1Track);
  checkGoogleCloudVideointelligenceV1Track(
      o[1] as api.GoogleCloudVideointelligenceV1Track);
}

core.int buildCounterGoogleCloudVideointelligenceV1FaceDetectionAnnotation = 0;
api.GoogleCloudVideointelligenceV1FaceDetectionAnnotation
    buildGoogleCloudVideointelligenceV1FaceDetectionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1FaceDetectionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1FaceDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1FaceDetectionAnnotation < 3) {
    o.thumbnail = 'foo';
    o.tracks = buildUnnamed364();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1FaceDetectionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1FaceDetectionAnnotation(
    api.GoogleCloudVideointelligenceV1FaceDetectionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1FaceDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1FaceDetectionAnnotation < 3) {
    unittest.expect(
      o.thumbnail!,
      unittest.equals('foo'),
    );
    checkUnnamed364(o.tracks!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1FaceDetectionAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1FaceDetectionConfig = 0;
api.GoogleCloudVideointelligenceV1FaceDetectionConfig
    buildGoogleCloudVideointelligenceV1FaceDetectionConfig() {
  var o = api.GoogleCloudVideointelligenceV1FaceDetectionConfig();
  buildCounterGoogleCloudVideointelligenceV1FaceDetectionConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1FaceDetectionConfig < 3) {
    o.includeAttributes = true;
    o.includeBoundingBoxes = true;
    o.model = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1FaceDetectionConfig--;
  return o;
}

void checkGoogleCloudVideointelligenceV1FaceDetectionConfig(
    api.GoogleCloudVideointelligenceV1FaceDetectionConfig o) {
  buildCounterGoogleCloudVideointelligenceV1FaceDetectionConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1FaceDetectionConfig < 3) {
    unittest.expect(o.includeAttributes!, unittest.isTrue);
    unittest.expect(o.includeBoundingBoxes!, unittest.isTrue);
    unittest.expect(
      o.model!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1FaceDetectionConfig--;
}

core.List<api.GoogleCloudVideointelligenceV1NormalizedBoundingBox>
    buildUnnamed365() {
  var o = <api.GoogleCloudVideointelligenceV1NormalizedBoundingBox>[];
  o.add(buildGoogleCloudVideointelligenceV1NormalizedBoundingBox());
  o.add(buildGoogleCloudVideointelligenceV1NormalizedBoundingBox());
  return o;
}

void checkUnnamed365(
    core.List<api.GoogleCloudVideointelligenceV1NormalizedBoundingBox> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1NormalizedBoundingBox(
      o[0] as api.GoogleCloudVideointelligenceV1NormalizedBoundingBox);
  checkGoogleCloudVideointelligenceV1NormalizedBoundingBox(
      o[1] as api.GoogleCloudVideointelligenceV1NormalizedBoundingBox);
}

core.int buildCounterGoogleCloudVideointelligenceV1FaceFrame = 0;
api.GoogleCloudVideointelligenceV1FaceFrame
    buildGoogleCloudVideointelligenceV1FaceFrame() {
  var o = api.GoogleCloudVideointelligenceV1FaceFrame();
  buildCounterGoogleCloudVideointelligenceV1FaceFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1FaceFrame < 3) {
    o.normalizedBoundingBoxes = buildUnnamed365();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1FaceFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1FaceFrame(
    api.GoogleCloudVideointelligenceV1FaceFrame o) {
  buildCounterGoogleCloudVideointelligenceV1FaceFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1FaceFrame < 3) {
    checkUnnamed365(o.normalizedBoundingBoxes!);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1FaceFrame--;
}

core.int buildCounterGoogleCloudVideointelligenceV1FaceSegment = 0;
api.GoogleCloudVideointelligenceV1FaceSegment
    buildGoogleCloudVideointelligenceV1FaceSegment() {
  var o = api.GoogleCloudVideointelligenceV1FaceSegment();
  buildCounterGoogleCloudVideointelligenceV1FaceSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1FaceSegment < 3) {
    o.segment = buildGoogleCloudVideointelligenceV1VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1FaceSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1FaceSegment(
    api.GoogleCloudVideointelligenceV1FaceSegment o) {
  buildCounterGoogleCloudVideointelligenceV1FaceSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1FaceSegment < 3) {
    checkGoogleCloudVideointelligenceV1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1FaceSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1Entity> buildUnnamed366() {
  var o = <api.GoogleCloudVideointelligenceV1Entity>[];
  o.add(buildGoogleCloudVideointelligenceV1Entity());
  o.add(buildGoogleCloudVideointelligenceV1Entity());
  return o;
}

void checkUnnamed366(core.List<api.GoogleCloudVideointelligenceV1Entity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1Entity(
      o[0] as api.GoogleCloudVideointelligenceV1Entity);
  checkGoogleCloudVideointelligenceV1Entity(
      o[1] as api.GoogleCloudVideointelligenceV1Entity);
}

core.List<api.GoogleCloudVideointelligenceV1LabelFrame> buildUnnamed367() {
  var o = <api.GoogleCloudVideointelligenceV1LabelFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1LabelFrame());
  o.add(buildGoogleCloudVideointelligenceV1LabelFrame());
  return o;
}

void checkUnnamed367(
    core.List<api.GoogleCloudVideointelligenceV1LabelFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1LabelFrame(
      o[0] as api.GoogleCloudVideointelligenceV1LabelFrame);
  checkGoogleCloudVideointelligenceV1LabelFrame(
      o[1] as api.GoogleCloudVideointelligenceV1LabelFrame);
}

core.List<api.GoogleCloudVideointelligenceV1LabelSegment> buildUnnamed368() {
  var o = <api.GoogleCloudVideointelligenceV1LabelSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1LabelSegment());
  o.add(buildGoogleCloudVideointelligenceV1LabelSegment());
  return o;
}

void checkUnnamed368(
    core.List<api.GoogleCloudVideointelligenceV1LabelSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1LabelSegment(
      o[0] as api.GoogleCloudVideointelligenceV1LabelSegment);
  checkGoogleCloudVideointelligenceV1LabelSegment(
      o[1] as api.GoogleCloudVideointelligenceV1LabelSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1LabelAnnotation = 0;
api.GoogleCloudVideointelligenceV1LabelAnnotation
    buildGoogleCloudVideointelligenceV1LabelAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1LabelAnnotation();
  buildCounterGoogleCloudVideointelligenceV1LabelAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1LabelAnnotation < 3) {
    o.categoryEntities = buildUnnamed366();
    o.entity = buildGoogleCloudVideointelligenceV1Entity();
    o.frames = buildUnnamed367();
    o.segments = buildUnnamed368();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1LabelAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1LabelAnnotation(
    api.GoogleCloudVideointelligenceV1LabelAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1LabelAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1LabelAnnotation < 3) {
    checkUnnamed366(o.categoryEntities!);
    checkGoogleCloudVideointelligenceV1Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1Entity);
    checkUnnamed367(o.frames!);
    checkUnnamed368(o.segments!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1LabelAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1LabelDetectionConfig = 0;
api.GoogleCloudVideointelligenceV1LabelDetectionConfig
    buildGoogleCloudVideointelligenceV1LabelDetectionConfig() {
  var o = api.GoogleCloudVideointelligenceV1LabelDetectionConfig();
  buildCounterGoogleCloudVideointelligenceV1LabelDetectionConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1LabelDetectionConfig < 3) {
    o.frameConfidenceThreshold = 42.0;
    o.labelDetectionMode = 'foo';
    o.model = 'foo';
    o.stationaryCamera = true;
    o.videoConfidenceThreshold = 42.0;
  }
  buildCounterGoogleCloudVideointelligenceV1LabelDetectionConfig--;
  return o;
}

void checkGoogleCloudVideointelligenceV1LabelDetectionConfig(
    api.GoogleCloudVideointelligenceV1LabelDetectionConfig o) {
  buildCounterGoogleCloudVideointelligenceV1LabelDetectionConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1LabelDetectionConfig < 3) {
    unittest.expect(
      o.frameConfidenceThreshold!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.labelDetectionMode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.model!,
      unittest.equals('foo'),
    );
    unittest.expect(o.stationaryCamera!, unittest.isTrue);
    unittest.expect(
      o.videoConfidenceThreshold!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1LabelDetectionConfig--;
}

core.int buildCounterGoogleCloudVideointelligenceV1LabelFrame = 0;
api.GoogleCloudVideointelligenceV1LabelFrame
    buildGoogleCloudVideointelligenceV1LabelFrame() {
  var o = api.GoogleCloudVideointelligenceV1LabelFrame();
  buildCounterGoogleCloudVideointelligenceV1LabelFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1LabelFrame < 3) {
    o.confidence = 42.0;
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1LabelFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1LabelFrame(
    api.GoogleCloudVideointelligenceV1LabelFrame o) {
  buildCounterGoogleCloudVideointelligenceV1LabelFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1LabelFrame < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1LabelFrame--;
}

core.int buildCounterGoogleCloudVideointelligenceV1LabelSegment = 0;
api.GoogleCloudVideointelligenceV1LabelSegment
    buildGoogleCloudVideointelligenceV1LabelSegment() {
  var o = api.GoogleCloudVideointelligenceV1LabelSegment();
  buildCounterGoogleCloudVideointelligenceV1LabelSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1LabelSegment < 3) {
    o.confidence = 42.0;
    o.segment = buildGoogleCloudVideointelligenceV1VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1LabelSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1LabelSegment(
    api.GoogleCloudVideointelligenceV1LabelSegment o) {
  buildCounterGoogleCloudVideointelligenceV1LabelSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1LabelSegment < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1LabelSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1VideoSegment> buildUnnamed369() {
  var o = <api.GoogleCloudVideointelligenceV1VideoSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1VideoSegment());
  o.add(buildGoogleCloudVideointelligenceV1VideoSegment());
  return o;
}

void checkUnnamed369(
    core.List<api.GoogleCloudVideointelligenceV1VideoSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1VideoSegment(
      o[0] as api.GoogleCloudVideointelligenceV1VideoSegment);
  checkGoogleCloudVideointelligenceV1VideoSegment(
      o[1] as api.GoogleCloudVideointelligenceV1VideoSegment);
}

core.List<api.GoogleCloudVideointelligenceV1Track> buildUnnamed370() {
  var o = <api.GoogleCloudVideointelligenceV1Track>[];
  o.add(buildGoogleCloudVideointelligenceV1Track());
  o.add(buildGoogleCloudVideointelligenceV1Track());
  return o;
}

void checkUnnamed370(core.List<api.GoogleCloudVideointelligenceV1Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1Track(
      o[0] as api.GoogleCloudVideointelligenceV1Track);
  checkGoogleCloudVideointelligenceV1Track(
      o[1] as api.GoogleCloudVideointelligenceV1Track);
}

core.int buildCounterGoogleCloudVideointelligenceV1LogoRecognitionAnnotation =
    0;
api.GoogleCloudVideointelligenceV1LogoRecognitionAnnotation
    buildGoogleCloudVideointelligenceV1LogoRecognitionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1LogoRecognitionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1LogoRecognitionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1LogoRecognitionAnnotation < 3) {
    o.entity = buildGoogleCloudVideointelligenceV1Entity();
    o.segments = buildUnnamed369();
    o.tracks = buildUnnamed370();
  }
  buildCounterGoogleCloudVideointelligenceV1LogoRecognitionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1LogoRecognitionAnnotation(
    api.GoogleCloudVideointelligenceV1LogoRecognitionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1LogoRecognitionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1LogoRecognitionAnnotation < 3) {
    checkGoogleCloudVideointelligenceV1Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1Entity);
    checkUnnamed369(o.segments!);
    checkUnnamed370(o.tracks!);
  }
  buildCounterGoogleCloudVideointelligenceV1LogoRecognitionAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1NormalizedBoundingBox = 0;
api.GoogleCloudVideointelligenceV1NormalizedBoundingBox
    buildGoogleCloudVideointelligenceV1NormalizedBoundingBox() {
  var o = api.GoogleCloudVideointelligenceV1NormalizedBoundingBox();
  buildCounterGoogleCloudVideointelligenceV1NormalizedBoundingBox++;
  if (buildCounterGoogleCloudVideointelligenceV1NormalizedBoundingBox < 3) {
    o.bottom = 42.0;
    o.left = 42.0;
    o.right = 42.0;
    o.top = 42.0;
  }
  buildCounterGoogleCloudVideointelligenceV1NormalizedBoundingBox--;
  return o;
}

void checkGoogleCloudVideointelligenceV1NormalizedBoundingBox(
    api.GoogleCloudVideointelligenceV1NormalizedBoundingBox o) {
  buildCounterGoogleCloudVideointelligenceV1NormalizedBoundingBox++;
  if (buildCounterGoogleCloudVideointelligenceV1NormalizedBoundingBox < 3) {
    unittest.expect(
      o.bottom!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.left!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.right!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.top!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1NormalizedBoundingBox--;
}

core.List<api.GoogleCloudVideointelligenceV1NormalizedVertex>
    buildUnnamed371() {
  var o = <api.GoogleCloudVideointelligenceV1NormalizedVertex>[];
  o.add(buildGoogleCloudVideointelligenceV1NormalizedVertex());
  o.add(buildGoogleCloudVideointelligenceV1NormalizedVertex());
  return o;
}

void checkUnnamed371(
    core.List<api.GoogleCloudVideointelligenceV1NormalizedVertex> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1NormalizedVertex(
      o[0] as api.GoogleCloudVideointelligenceV1NormalizedVertex);
  checkGoogleCloudVideointelligenceV1NormalizedVertex(
      o[1] as api.GoogleCloudVideointelligenceV1NormalizedVertex);
}

core.int buildCounterGoogleCloudVideointelligenceV1NormalizedBoundingPoly = 0;
api.GoogleCloudVideointelligenceV1NormalizedBoundingPoly
    buildGoogleCloudVideointelligenceV1NormalizedBoundingPoly() {
  var o = api.GoogleCloudVideointelligenceV1NormalizedBoundingPoly();
  buildCounterGoogleCloudVideointelligenceV1NormalizedBoundingPoly++;
  if (buildCounterGoogleCloudVideointelligenceV1NormalizedBoundingPoly < 3) {
    o.vertices = buildUnnamed371();
  }
  buildCounterGoogleCloudVideointelligenceV1NormalizedBoundingPoly--;
  return o;
}

void checkGoogleCloudVideointelligenceV1NormalizedBoundingPoly(
    api.GoogleCloudVideointelligenceV1NormalizedBoundingPoly o) {
  buildCounterGoogleCloudVideointelligenceV1NormalizedBoundingPoly++;
  if (buildCounterGoogleCloudVideointelligenceV1NormalizedBoundingPoly < 3) {
    checkUnnamed371(o.vertices!);
  }
  buildCounterGoogleCloudVideointelligenceV1NormalizedBoundingPoly--;
}

core.int buildCounterGoogleCloudVideointelligenceV1NormalizedVertex = 0;
api.GoogleCloudVideointelligenceV1NormalizedVertex
    buildGoogleCloudVideointelligenceV1NormalizedVertex() {
  var o = api.GoogleCloudVideointelligenceV1NormalizedVertex();
  buildCounterGoogleCloudVideointelligenceV1NormalizedVertex++;
  if (buildCounterGoogleCloudVideointelligenceV1NormalizedVertex < 3) {
    o.x = 42.0;
    o.y = 42.0;
  }
  buildCounterGoogleCloudVideointelligenceV1NormalizedVertex--;
  return o;
}

void checkGoogleCloudVideointelligenceV1NormalizedVertex(
    api.GoogleCloudVideointelligenceV1NormalizedVertex o) {
  buildCounterGoogleCloudVideointelligenceV1NormalizedVertex++;
  if (buildCounterGoogleCloudVideointelligenceV1NormalizedVertex < 3) {
    unittest.expect(
      o.x!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.y!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1NormalizedVertex--;
}

core.List<api.GoogleCloudVideointelligenceV1ObjectTrackingFrame>
    buildUnnamed372() {
  var o = <api.GoogleCloudVideointelligenceV1ObjectTrackingFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1ObjectTrackingFrame());
  o.add(buildGoogleCloudVideointelligenceV1ObjectTrackingFrame());
  return o;
}

void checkUnnamed372(
    core.List<api.GoogleCloudVideointelligenceV1ObjectTrackingFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1ObjectTrackingFrame(
      o[0] as api.GoogleCloudVideointelligenceV1ObjectTrackingFrame);
  checkGoogleCloudVideointelligenceV1ObjectTrackingFrame(
      o[1] as api.GoogleCloudVideointelligenceV1ObjectTrackingFrame);
}

core.int buildCounterGoogleCloudVideointelligenceV1ObjectTrackingAnnotation = 0;
api.GoogleCloudVideointelligenceV1ObjectTrackingAnnotation
    buildGoogleCloudVideointelligenceV1ObjectTrackingAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1ObjectTrackingAnnotation();
  buildCounterGoogleCloudVideointelligenceV1ObjectTrackingAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1ObjectTrackingAnnotation < 3) {
    o.confidence = 42.0;
    o.entity = buildGoogleCloudVideointelligenceV1Entity();
    o.frames = buildUnnamed372();
    o.segment = buildGoogleCloudVideointelligenceV1VideoSegment();
    o.trackId = 'foo';
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1ObjectTrackingAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1ObjectTrackingAnnotation(
    api.GoogleCloudVideointelligenceV1ObjectTrackingAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1ObjectTrackingAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1ObjectTrackingAnnotation < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1Entity);
    checkUnnamed372(o.frames!);
    checkGoogleCloudVideointelligenceV1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1VideoSegment);
    unittest.expect(
      o.trackId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1ObjectTrackingAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1ObjectTrackingConfig = 0;
api.GoogleCloudVideointelligenceV1ObjectTrackingConfig
    buildGoogleCloudVideointelligenceV1ObjectTrackingConfig() {
  var o = api.GoogleCloudVideointelligenceV1ObjectTrackingConfig();
  buildCounterGoogleCloudVideointelligenceV1ObjectTrackingConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1ObjectTrackingConfig < 3) {
    o.model = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1ObjectTrackingConfig--;
  return o;
}

void checkGoogleCloudVideointelligenceV1ObjectTrackingConfig(
    api.GoogleCloudVideointelligenceV1ObjectTrackingConfig o) {
  buildCounterGoogleCloudVideointelligenceV1ObjectTrackingConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1ObjectTrackingConfig < 3) {
    unittest.expect(
      o.model!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1ObjectTrackingConfig--;
}

core.int buildCounterGoogleCloudVideointelligenceV1ObjectTrackingFrame = 0;
api.GoogleCloudVideointelligenceV1ObjectTrackingFrame
    buildGoogleCloudVideointelligenceV1ObjectTrackingFrame() {
  var o = api.GoogleCloudVideointelligenceV1ObjectTrackingFrame();
  buildCounterGoogleCloudVideointelligenceV1ObjectTrackingFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1ObjectTrackingFrame < 3) {
    o.normalizedBoundingBox =
        buildGoogleCloudVideointelligenceV1NormalizedBoundingBox();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1ObjectTrackingFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1ObjectTrackingFrame(
    api.GoogleCloudVideointelligenceV1ObjectTrackingFrame o) {
  buildCounterGoogleCloudVideointelligenceV1ObjectTrackingFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1ObjectTrackingFrame < 3) {
    checkGoogleCloudVideointelligenceV1NormalizedBoundingBox(
        o.normalizedBoundingBox!
            as api.GoogleCloudVideointelligenceV1NormalizedBoundingBox);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1ObjectTrackingFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1Track> buildUnnamed373() {
  var o = <api.GoogleCloudVideointelligenceV1Track>[];
  o.add(buildGoogleCloudVideointelligenceV1Track());
  o.add(buildGoogleCloudVideointelligenceV1Track());
  return o;
}

void checkUnnamed373(core.List<api.GoogleCloudVideointelligenceV1Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1Track(
      o[0] as api.GoogleCloudVideointelligenceV1Track);
  checkGoogleCloudVideointelligenceV1Track(
      o[1] as api.GoogleCloudVideointelligenceV1Track);
}

core.int buildCounterGoogleCloudVideointelligenceV1PersonDetectionAnnotation =
    0;
api.GoogleCloudVideointelligenceV1PersonDetectionAnnotation
    buildGoogleCloudVideointelligenceV1PersonDetectionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1PersonDetectionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1PersonDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1PersonDetectionAnnotation < 3) {
    o.tracks = buildUnnamed373();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1PersonDetectionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1PersonDetectionAnnotation(
    api.GoogleCloudVideointelligenceV1PersonDetectionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1PersonDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1PersonDetectionAnnotation < 3) {
    checkUnnamed373(o.tracks!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1PersonDetectionAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1PersonDetectionConfig = 0;
api.GoogleCloudVideointelligenceV1PersonDetectionConfig
    buildGoogleCloudVideointelligenceV1PersonDetectionConfig() {
  var o = api.GoogleCloudVideointelligenceV1PersonDetectionConfig();
  buildCounterGoogleCloudVideointelligenceV1PersonDetectionConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1PersonDetectionConfig < 3) {
    o.includeAttributes = true;
    o.includeBoundingBoxes = true;
    o.includePoseLandmarks = true;
  }
  buildCounterGoogleCloudVideointelligenceV1PersonDetectionConfig--;
  return o;
}

void checkGoogleCloudVideointelligenceV1PersonDetectionConfig(
    api.GoogleCloudVideointelligenceV1PersonDetectionConfig o) {
  buildCounterGoogleCloudVideointelligenceV1PersonDetectionConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1PersonDetectionConfig < 3) {
    unittest.expect(o.includeAttributes!, unittest.isTrue);
    unittest.expect(o.includeBoundingBoxes!, unittest.isTrue);
    unittest.expect(o.includePoseLandmarks!, unittest.isTrue);
  }
  buildCounterGoogleCloudVideointelligenceV1PersonDetectionConfig--;
}

core.int buildCounterGoogleCloudVideointelligenceV1ShotChangeDetectionConfig =
    0;
api.GoogleCloudVideointelligenceV1ShotChangeDetectionConfig
    buildGoogleCloudVideointelligenceV1ShotChangeDetectionConfig() {
  var o = api.GoogleCloudVideointelligenceV1ShotChangeDetectionConfig();
  buildCounterGoogleCloudVideointelligenceV1ShotChangeDetectionConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1ShotChangeDetectionConfig < 3) {
    o.model = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1ShotChangeDetectionConfig--;
  return o;
}

void checkGoogleCloudVideointelligenceV1ShotChangeDetectionConfig(
    api.GoogleCloudVideointelligenceV1ShotChangeDetectionConfig o) {
  buildCounterGoogleCloudVideointelligenceV1ShotChangeDetectionConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1ShotChangeDetectionConfig < 3) {
    unittest.expect(
      o.model!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1ShotChangeDetectionConfig--;
}

core.List<core.String> buildUnnamed374() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed374(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterGoogleCloudVideointelligenceV1SpeechContext = 0;
api.GoogleCloudVideointelligenceV1SpeechContext
    buildGoogleCloudVideointelligenceV1SpeechContext() {
  var o = api.GoogleCloudVideointelligenceV1SpeechContext();
  buildCounterGoogleCloudVideointelligenceV1SpeechContext++;
  if (buildCounterGoogleCloudVideointelligenceV1SpeechContext < 3) {
    o.phrases = buildUnnamed374();
  }
  buildCounterGoogleCloudVideointelligenceV1SpeechContext--;
  return o;
}

void checkGoogleCloudVideointelligenceV1SpeechContext(
    api.GoogleCloudVideointelligenceV1SpeechContext o) {
  buildCounterGoogleCloudVideointelligenceV1SpeechContext++;
  if (buildCounterGoogleCloudVideointelligenceV1SpeechContext < 3) {
    checkUnnamed374(o.phrases!);
  }
  buildCounterGoogleCloudVideointelligenceV1SpeechContext--;
}

core.List<api.GoogleCloudVideointelligenceV1WordInfo> buildUnnamed375() {
  var o = <api.GoogleCloudVideointelligenceV1WordInfo>[];
  o.add(buildGoogleCloudVideointelligenceV1WordInfo());
  o.add(buildGoogleCloudVideointelligenceV1WordInfo());
  return o;
}

void checkUnnamed375(core.List<api.GoogleCloudVideointelligenceV1WordInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1WordInfo(
      o[0] as api.GoogleCloudVideointelligenceV1WordInfo);
  checkGoogleCloudVideointelligenceV1WordInfo(
      o[1] as api.GoogleCloudVideointelligenceV1WordInfo);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1SpeechRecognitionAlternative = 0;
api.GoogleCloudVideointelligenceV1SpeechRecognitionAlternative
    buildGoogleCloudVideointelligenceV1SpeechRecognitionAlternative() {
  var o = api.GoogleCloudVideointelligenceV1SpeechRecognitionAlternative();
  buildCounterGoogleCloudVideointelligenceV1SpeechRecognitionAlternative++;
  if (buildCounterGoogleCloudVideointelligenceV1SpeechRecognitionAlternative <
      3) {
    o.confidence = 42.0;
    o.transcript = 'foo';
    o.words = buildUnnamed375();
  }
  buildCounterGoogleCloudVideointelligenceV1SpeechRecognitionAlternative--;
  return o;
}

void checkGoogleCloudVideointelligenceV1SpeechRecognitionAlternative(
    api.GoogleCloudVideointelligenceV1SpeechRecognitionAlternative o) {
  buildCounterGoogleCloudVideointelligenceV1SpeechRecognitionAlternative++;
  if (buildCounterGoogleCloudVideointelligenceV1SpeechRecognitionAlternative <
      3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.transcript!,
      unittest.equals('foo'),
    );
    checkUnnamed375(o.words!);
  }
  buildCounterGoogleCloudVideointelligenceV1SpeechRecognitionAlternative--;
}

core.List<api.GoogleCloudVideointelligenceV1SpeechRecognitionAlternative>
    buildUnnamed376() {
  var o = <api.GoogleCloudVideointelligenceV1SpeechRecognitionAlternative>[];
  o.add(buildGoogleCloudVideointelligenceV1SpeechRecognitionAlternative());
  o.add(buildGoogleCloudVideointelligenceV1SpeechRecognitionAlternative());
  return o;
}

void checkUnnamed376(
    core.List<api.GoogleCloudVideointelligenceV1SpeechRecognitionAlternative>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1SpeechRecognitionAlternative(
      o[0] as api.GoogleCloudVideointelligenceV1SpeechRecognitionAlternative);
  checkGoogleCloudVideointelligenceV1SpeechRecognitionAlternative(
      o[1] as api.GoogleCloudVideointelligenceV1SpeechRecognitionAlternative);
}

core.int buildCounterGoogleCloudVideointelligenceV1SpeechTranscription = 0;
api.GoogleCloudVideointelligenceV1SpeechTranscription
    buildGoogleCloudVideointelligenceV1SpeechTranscription() {
  var o = api.GoogleCloudVideointelligenceV1SpeechTranscription();
  buildCounterGoogleCloudVideointelligenceV1SpeechTranscription++;
  if (buildCounterGoogleCloudVideointelligenceV1SpeechTranscription < 3) {
    o.alternatives = buildUnnamed376();
    o.languageCode = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1SpeechTranscription--;
  return o;
}

void checkGoogleCloudVideointelligenceV1SpeechTranscription(
    api.GoogleCloudVideointelligenceV1SpeechTranscription o) {
  buildCounterGoogleCloudVideointelligenceV1SpeechTranscription++;
  if (buildCounterGoogleCloudVideointelligenceV1SpeechTranscription < 3) {
    checkUnnamed376(o.alternatives!);
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1SpeechTranscription--;
}

core.List<core.int> buildUnnamed377() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed377(core.List<core.int> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42),
  );
  unittest.expect(
    o[1],
    unittest.equals(42),
  );
}

core.List<api.GoogleCloudVideointelligenceV1SpeechContext> buildUnnamed378() {
  var o = <api.GoogleCloudVideointelligenceV1SpeechContext>[];
  o.add(buildGoogleCloudVideointelligenceV1SpeechContext());
  o.add(buildGoogleCloudVideointelligenceV1SpeechContext());
  return o;
}

void checkUnnamed378(
    core.List<api.GoogleCloudVideointelligenceV1SpeechContext> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1SpeechContext(
      o[0] as api.GoogleCloudVideointelligenceV1SpeechContext);
  checkGoogleCloudVideointelligenceV1SpeechContext(
      o[1] as api.GoogleCloudVideointelligenceV1SpeechContext);
}

core.int buildCounterGoogleCloudVideointelligenceV1SpeechTranscriptionConfig =
    0;
api.GoogleCloudVideointelligenceV1SpeechTranscriptionConfig
    buildGoogleCloudVideointelligenceV1SpeechTranscriptionConfig() {
  var o = api.GoogleCloudVideointelligenceV1SpeechTranscriptionConfig();
  buildCounterGoogleCloudVideointelligenceV1SpeechTranscriptionConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1SpeechTranscriptionConfig < 3) {
    o.audioTracks = buildUnnamed377();
    o.diarizationSpeakerCount = 42;
    o.enableAutomaticPunctuation = true;
    o.enableSpeakerDiarization = true;
    o.enableWordConfidence = true;
    o.filterProfanity = true;
    o.languageCode = 'foo';
    o.maxAlternatives = 42;
    o.speechContexts = buildUnnamed378();
  }
  buildCounterGoogleCloudVideointelligenceV1SpeechTranscriptionConfig--;
  return o;
}

void checkGoogleCloudVideointelligenceV1SpeechTranscriptionConfig(
    api.GoogleCloudVideointelligenceV1SpeechTranscriptionConfig o) {
  buildCounterGoogleCloudVideointelligenceV1SpeechTranscriptionConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1SpeechTranscriptionConfig < 3) {
    checkUnnamed377(o.audioTracks!);
    unittest.expect(
      o.diarizationSpeakerCount!,
      unittest.equals(42),
    );
    unittest.expect(o.enableAutomaticPunctuation!, unittest.isTrue);
    unittest.expect(o.enableSpeakerDiarization!, unittest.isTrue);
    unittest.expect(o.enableWordConfidence!, unittest.isTrue);
    unittest.expect(o.filterProfanity!, unittest.isTrue);
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxAlternatives!,
      unittest.equals(42),
    );
    checkUnnamed378(o.speechContexts!);
  }
  buildCounterGoogleCloudVideointelligenceV1SpeechTranscriptionConfig--;
}

core.List<api.GoogleCloudVideointelligenceV1TextSegment> buildUnnamed379() {
  var o = <api.GoogleCloudVideointelligenceV1TextSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1TextSegment());
  o.add(buildGoogleCloudVideointelligenceV1TextSegment());
  return o;
}

void checkUnnamed379(
    core.List<api.GoogleCloudVideointelligenceV1TextSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1TextSegment(
      o[0] as api.GoogleCloudVideointelligenceV1TextSegment);
  checkGoogleCloudVideointelligenceV1TextSegment(
      o[1] as api.GoogleCloudVideointelligenceV1TextSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1TextAnnotation = 0;
api.GoogleCloudVideointelligenceV1TextAnnotation
    buildGoogleCloudVideointelligenceV1TextAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1TextAnnotation();
  buildCounterGoogleCloudVideointelligenceV1TextAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1TextAnnotation < 3) {
    o.segments = buildUnnamed379();
    o.text = 'foo';
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1TextAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1TextAnnotation(
    api.GoogleCloudVideointelligenceV1TextAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1TextAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1TextAnnotation < 3) {
    checkUnnamed379(o.segments!);
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1TextAnnotation--;
}

core.List<core.String> buildUnnamed380() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed380(core.List<core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals('foo'),
  );
  unittest.expect(
    o[1],
    unittest.equals('foo'),
  );
}

core.int buildCounterGoogleCloudVideointelligenceV1TextDetectionConfig = 0;
api.GoogleCloudVideointelligenceV1TextDetectionConfig
    buildGoogleCloudVideointelligenceV1TextDetectionConfig() {
  var o = api.GoogleCloudVideointelligenceV1TextDetectionConfig();
  buildCounterGoogleCloudVideointelligenceV1TextDetectionConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1TextDetectionConfig < 3) {
    o.languageHints = buildUnnamed380();
    o.model = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1TextDetectionConfig--;
  return o;
}

void checkGoogleCloudVideointelligenceV1TextDetectionConfig(
    api.GoogleCloudVideointelligenceV1TextDetectionConfig o) {
  buildCounterGoogleCloudVideointelligenceV1TextDetectionConfig++;
  if (buildCounterGoogleCloudVideointelligenceV1TextDetectionConfig < 3) {
    checkUnnamed380(o.languageHints!);
    unittest.expect(
      o.model!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1TextDetectionConfig--;
}

core.int buildCounterGoogleCloudVideointelligenceV1TextFrame = 0;
api.GoogleCloudVideointelligenceV1TextFrame
    buildGoogleCloudVideointelligenceV1TextFrame() {
  var o = api.GoogleCloudVideointelligenceV1TextFrame();
  buildCounterGoogleCloudVideointelligenceV1TextFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1TextFrame < 3) {
    o.rotatedBoundingBox =
        buildGoogleCloudVideointelligenceV1NormalizedBoundingPoly();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1TextFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1TextFrame(
    api.GoogleCloudVideointelligenceV1TextFrame o) {
  buildCounterGoogleCloudVideointelligenceV1TextFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1TextFrame < 3) {
    checkGoogleCloudVideointelligenceV1NormalizedBoundingPoly(
        o.rotatedBoundingBox!
            as api.GoogleCloudVideointelligenceV1NormalizedBoundingPoly);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1TextFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1TextFrame> buildUnnamed381() {
  var o = <api.GoogleCloudVideointelligenceV1TextFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1TextFrame());
  o.add(buildGoogleCloudVideointelligenceV1TextFrame());
  return o;
}

void checkUnnamed381(core.List<api.GoogleCloudVideointelligenceV1TextFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1TextFrame(
      o[0] as api.GoogleCloudVideointelligenceV1TextFrame);
  checkGoogleCloudVideointelligenceV1TextFrame(
      o[1] as api.GoogleCloudVideointelligenceV1TextFrame);
}

core.int buildCounterGoogleCloudVideointelligenceV1TextSegment = 0;
api.GoogleCloudVideointelligenceV1TextSegment
    buildGoogleCloudVideointelligenceV1TextSegment() {
  var o = api.GoogleCloudVideointelligenceV1TextSegment();
  buildCounterGoogleCloudVideointelligenceV1TextSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1TextSegment < 3) {
    o.confidence = 42.0;
    o.frames = buildUnnamed381();
    o.segment = buildGoogleCloudVideointelligenceV1VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1TextSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1TextSegment(
    api.GoogleCloudVideointelligenceV1TextSegment o) {
  buildCounterGoogleCloudVideointelligenceV1TextSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1TextSegment < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkUnnamed381(o.frames!);
    checkGoogleCloudVideointelligenceV1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1TextSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1DetectedAttribute>
    buildUnnamed382() {
  var o = <api.GoogleCloudVideointelligenceV1DetectedAttribute>[];
  o.add(buildGoogleCloudVideointelligenceV1DetectedAttribute());
  o.add(buildGoogleCloudVideointelligenceV1DetectedAttribute());
  return o;
}

void checkUnnamed382(
    core.List<api.GoogleCloudVideointelligenceV1DetectedAttribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1DetectedAttribute(
      o[0] as api.GoogleCloudVideointelligenceV1DetectedAttribute);
  checkGoogleCloudVideointelligenceV1DetectedAttribute(
      o[1] as api.GoogleCloudVideointelligenceV1DetectedAttribute);
}

core.List<api.GoogleCloudVideointelligenceV1DetectedLandmark>
    buildUnnamed383() {
  var o = <api.GoogleCloudVideointelligenceV1DetectedLandmark>[];
  o.add(buildGoogleCloudVideointelligenceV1DetectedLandmark());
  o.add(buildGoogleCloudVideointelligenceV1DetectedLandmark());
  return o;
}

void checkUnnamed383(
    core.List<api.GoogleCloudVideointelligenceV1DetectedLandmark> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1DetectedLandmark(
      o[0] as api.GoogleCloudVideointelligenceV1DetectedLandmark);
  checkGoogleCloudVideointelligenceV1DetectedLandmark(
      o[1] as api.GoogleCloudVideointelligenceV1DetectedLandmark);
}

core.int buildCounterGoogleCloudVideointelligenceV1TimestampedObject = 0;
api.GoogleCloudVideointelligenceV1TimestampedObject
    buildGoogleCloudVideointelligenceV1TimestampedObject() {
  var o = api.GoogleCloudVideointelligenceV1TimestampedObject();
  buildCounterGoogleCloudVideointelligenceV1TimestampedObject++;
  if (buildCounterGoogleCloudVideointelligenceV1TimestampedObject < 3) {
    o.attributes = buildUnnamed382();
    o.landmarks = buildUnnamed383();
    o.normalizedBoundingBox =
        buildGoogleCloudVideointelligenceV1NormalizedBoundingBox();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1TimestampedObject--;
  return o;
}

void checkGoogleCloudVideointelligenceV1TimestampedObject(
    api.GoogleCloudVideointelligenceV1TimestampedObject o) {
  buildCounterGoogleCloudVideointelligenceV1TimestampedObject++;
  if (buildCounterGoogleCloudVideointelligenceV1TimestampedObject < 3) {
    checkUnnamed382(o.attributes!);
    checkUnnamed383(o.landmarks!);
    checkGoogleCloudVideointelligenceV1NormalizedBoundingBox(
        o.normalizedBoundingBox!
            as api.GoogleCloudVideointelligenceV1NormalizedBoundingBox);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1TimestampedObject--;
}

core.List<api.GoogleCloudVideointelligenceV1DetectedAttribute>
    buildUnnamed384() {
  var o = <api.GoogleCloudVideointelligenceV1DetectedAttribute>[];
  o.add(buildGoogleCloudVideointelligenceV1DetectedAttribute());
  o.add(buildGoogleCloudVideointelligenceV1DetectedAttribute());
  return o;
}

void checkUnnamed384(
    core.List<api.GoogleCloudVideointelligenceV1DetectedAttribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1DetectedAttribute(
      o[0] as api.GoogleCloudVideointelligenceV1DetectedAttribute);
  checkGoogleCloudVideointelligenceV1DetectedAttribute(
      o[1] as api.GoogleCloudVideointelligenceV1DetectedAttribute);
}

core.List<api.GoogleCloudVideointelligenceV1TimestampedObject>
    buildUnnamed385() {
  var o = <api.GoogleCloudVideointelligenceV1TimestampedObject>[];
  o.add(buildGoogleCloudVideointelligenceV1TimestampedObject());
  o.add(buildGoogleCloudVideointelligenceV1TimestampedObject());
  return o;
}

void checkUnnamed385(
    core.List<api.GoogleCloudVideointelligenceV1TimestampedObject> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1TimestampedObject(
      o[0] as api.GoogleCloudVideointelligenceV1TimestampedObject);
  checkGoogleCloudVideointelligenceV1TimestampedObject(
      o[1] as api.GoogleCloudVideointelligenceV1TimestampedObject);
}

core.int buildCounterGoogleCloudVideointelligenceV1Track = 0;
api.GoogleCloudVideointelligenceV1Track
    buildGoogleCloudVideointelligenceV1Track() {
  var o = api.GoogleCloudVideointelligenceV1Track();
  buildCounterGoogleCloudVideointelligenceV1Track++;
  if (buildCounterGoogleCloudVideointelligenceV1Track < 3) {
    o.attributes = buildUnnamed384();
    o.confidence = 42.0;
    o.segment = buildGoogleCloudVideointelligenceV1VideoSegment();
    o.timestampedObjects = buildUnnamed385();
  }
  buildCounterGoogleCloudVideointelligenceV1Track--;
  return o;
}

void checkGoogleCloudVideointelligenceV1Track(
    api.GoogleCloudVideointelligenceV1Track o) {
  buildCounterGoogleCloudVideointelligenceV1Track++;
  if (buildCounterGoogleCloudVideointelligenceV1Track < 3) {
    checkUnnamed384(o.attributes!);
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1VideoSegment);
    checkUnnamed385(o.timestampedObjects!);
  }
  buildCounterGoogleCloudVideointelligenceV1Track--;
}

core.int buildCounterGoogleCloudVideointelligenceV1VideoAnnotationProgress = 0;
api.GoogleCloudVideointelligenceV1VideoAnnotationProgress
    buildGoogleCloudVideointelligenceV1VideoAnnotationProgress() {
  var o = api.GoogleCloudVideointelligenceV1VideoAnnotationProgress();
  buildCounterGoogleCloudVideointelligenceV1VideoAnnotationProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1VideoAnnotationProgress < 3) {
    o.feature = 'foo';
    o.inputUri = 'foo';
    o.progressPercent = 42;
    o.segment = buildGoogleCloudVideointelligenceV1VideoSegment();
    o.startTime = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1VideoAnnotationProgress--;
  return o;
}

void checkGoogleCloudVideointelligenceV1VideoAnnotationProgress(
    api.GoogleCloudVideointelligenceV1VideoAnnotationProgress o) {
  buildCounterGoogleCloudVideointelligenceV1VideoAnnotationProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1VideoAnnotationProgress < 3) {
    unittest.expect(
      o.feature!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inputUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.progressPercent!,
      unittest.equals(42),
    );
    checkGoogleCloudVideointelligenceV1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1VideoSegment);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1VideoAnnotationProgress--;
}

core.List<api.GoogleCloudVideointelligenceV1FaceAnnotation> buildUnnamed386() {
  var o = <api.GoogleCloudVideointelligenceV1FaceAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1FaceAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1FaceAnnotation());
  return o;
}

void checkUnnamed386(
    core.List<api.GoogleCloudVideointelligenceV1FaceAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1FaceAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1FaceAnnotation);
  checkGoogleCloudVideointelligenceV1FaceAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1FaceAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1FaceDetectionAnnotation>
    buildUnnamed387() {
  var o = <api.GoogleCloudVideointelligenceV1FaceDetectionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1FaceDetectionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1FaceDetectionAnnotation());
  return o;
}

void checkUnnamed387(
    core.List<api.GoogleCloudVideointelligenceV1FaceDetectionAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1FaceDetectionAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1FaceDetectionAnnotation);
  checkGoogleCloudVideointelligenceV1FaceDetectionAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1FaceDetectionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1LabelAnnotation> buildUnnamed388() {
  var o = <api.GoogleCloudVideointelligenceV1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1LabelAnnotation());
  return o;
}

void checkUnnamed388(
    core.List<api.GoogleCloudVideointelligenceV1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1LogoRecognitionAnnotation>
    buildUnnamed389() {
  var o = <api.GoogleCloudVideointelligenceV1LogoRecognitionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1LogoRecognitionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1LogoRecognitionAnnotation());
  return o;
}

void checkUnnamed389(
    core.List<api.GoogleCloudVideointelligenceV1LogoRecognitionAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1LogoRecognitionAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1LogoRecognitionAnnotation);
  checkGoogleCloudVideointelligenceV1LogoRecognitionAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1LogoRecognitionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1ObjectTrackingAnnotation>
    buildUnnamed390() {
  var o = <api.GoogleCloudVideointelligenceV1ObjectTrackingAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1ObjectTrackingAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1ObjectTrackingAnnotation());
  return o;
}

void checkUnnamed390(
    core.List<api.GoogleCloudVideointelligenceV1ObjectTrackingAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1ObjectTrackingAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1ObjectTrackingAnnotation);
  checkGoogleCloudVideointelligenceV1ObjectTrackingAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1ObjectTrackingAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1PersonDetectionAnnotation>
    buildUnnamed391() {
  var o = <api.GoogleCloudVideointelligenceV1PersonDetectionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1PersonDetectionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1PersonDetectionAnnotation());
  return o;
}

void checkUnnamed391(
    core.List<api.GoogleCloudVideointelligenceV1PersonDetectionAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1PersonDetectionAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1PersonDetectionAnnotation);
  checkGoogleCloudVideointelligenceV1PersonDetectionAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1PersonDetectionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1LabelAnnotation> buildUnnamed392() {
  var o = <api.GoogleCloudVideointelligenceV1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1LabelAnnotation());
  return o;
}

void checkUnnamed392(
    core.List<api.GoogleCloudVideointelligenceV1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1LabelAnnotation> buildUnnamed393() {
  var o = <api.GoogleCloudVideointelligenceV1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1LabelAnnotation());
  return o;
}

void checkUnnamed393(
    core.List<api.GoogleCloudVideointelligenceV1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1VideoSegment> buildUnnamed394() {
  var o = <api.GoogleCloudVideointelligenceV1VideoSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1VideoSegment());
  o.add(buildGoogleCloudVideointelligenceV1VideoSegment());
  return o;
}

void checkUnnamed394(
    core.List<api.GoogleCloudVideointelligenceV1VideoSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1VideoSegment(
      o[0] as api.GoogleCloudVideointelligenceV1VideoSegment);
  checkGoogleCloudVideointelligenceV1VideoSegment(
      o[1] as api.GoogleCloudVideointelligenceV1VideoSegment);
}

core.List<api.GoogleCloudVideointelligenceV1LabelAnnotation> buildUnnamed395() {
  var o = <api.GoogleCloudVideointelligenceV1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1LabelAnnotation());
  return o;
}

void checkUnnamed395(
    core.List<api.GoogleCloudVideointelligenceV1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1LabelAnnotation> buildUnnamed396() {
  var o = <api.GoogleCloudVideointelligenceV1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1LabelAnnotation());
  return o;
}

void checkUnnamed396(
    core.List<api.GoogleCloudVideointelligenceV1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1SpeechTranscription>
    buildUnnamed397() {
  var o = <api.GoogleCloudVideointelligenceV1SpeechTranscription>[];
  o.add(buildGoogleCloudVideointelligenceV1SpeechTranscription());
  o.add(buildGoogleCloudVideointelligenceV1SpeechTranscription());
  return o;
}

void checkUnnamed397(
    core.List<api.GoogleCloudVideointelligenceV1SpeechTranscription> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1SpeechTranscription(
      o[0] as api.GoogleCloudVideointelligenceV1SpeechTranscription);
  checkGoogleCloudVideointelligenceV1SpeechTranscription(
      o[1] as api.GoogleCloudVideointelligenceV1SpeechTranscription);
}

core.List<api.GoogleCloudVideointelligenceV1TextAnnotation> buildUnnamed398() {
  var o = <api.GoogleCloudVideointelligenceV1TextAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1TextAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1TextAnnotation());
  return o;
}

void checkUnnamed398(
    core.List<api.GoogleCloudVideointelligenceV1TextAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1TextAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1TextAnnotation);
  checkGoogleCloudVideointelligenceV1TextAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1TextAnnotation);
}

core.int buildCounterGoogleCloudVideointelligenceV1VideoAnnotationResults = 0;
api.GoogleCloudVideointelligenceV1VideoAnnotationResults
    buildGoogleCloudVideointelligenceV1VideoAnnotationResults() {
  var o = api.GoogleCloudVideointelligenceV1VideoAnnotationResults();
  buildCounterGoogleCloudVideointelligenceV1VideoAnnotationResults++;
  if (buildCounterGoogleCloudVideointelligenceV1VideoAnnotationResults < 3) {
    o.error = buildGoogleRpcStatus();
    o.explicitAnnotation =
        buildGoogleCloudVideointelligenceV1ExplicitContentAnnotation();
    o.faceAnnotations = buildUnnamed386();
    o.faceDetectionAnnotations = buildUnnamed387();
    o.frameLabelAnnotations = buildUnnamed388();
    o.inputUri = 'foo';
    o.logoRecognitionAnnotations = buildUnnamed389();
    o.objectAnnotations = buildUnnamed390();
    o.personDetectionAnnotations = buildUnnamed391();
    o.segment = buildGoogleCloudVideointelligenceV1VideoSegment();
    o.segmentLabelAnnotations = buildUnnamed392();
    o.segmentPresenceLabelAnnotations = buildUnnamed393();
    o.shotAnnotations = buildUnnamed394();
    o.shotLabelAnnotations = buildUnnamed395();
    o.shotPresenceLabelAnnotations = buildUnnamed396();
    o.speechTranscriptions = buildUnnamed397();
    o.textAnnotations = buildUnnamed398();
  }
  buildCounterGoogleCloudVideointelligenceV1VideoAnnotationResults--;
  return o;
}

void checkGoogleCloudVideointelligenceV1VideoAnnotationResults(
    api.GoogleCloudVideointelligenceV1VideoAnnotationResults o) {
  buildCounterGoogleCloudVideointelligenceV1VideoAnnotationResults++;
  if (buildCounterGoogleCloudVideointelligenceV1VideoAnnotationResults < 3) {
    checkGoogleRpcStatus(o.error! as api.GoogleRpcStatus);
    checkGoogleCloudVideointelligenceV1ExplicitContentAnnotation(
        o.explicitAnnotation!
            as api.GoogleCloudVideointelligenceV1ExplicitContentAnnotation);
    checkUnnamed386(o.faceAnnotations!);
    checkUnnamed387(o.faceDetectionAnnotations!);
    checkUnnamed388(o.frameLabelAnnotations!);
    unittest.expect(
      o.inputUri!,
      unittest.equals('foo'),
    );
    checkUnnamed389(o.logoRecognitionAnnotations!);
    checkUnnamed390(o.objectAnnotations!);
    checkUnnamed391(o.personDetectionAnnotations!);
    checkGoogleCloudVideointelligenceV1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1VideoSegment);
    checkUnnamed392(o.segmentLabelAnnotations!);
    checkUnnamed393(o.segmentPresenceLabelAnnotations!);
    checkUnnamed394(o.shotAnnotations!);
    checkUnnamed395(o.shotLabelAnnotations!);
    checkUnnamed396(o.shotPresenceLabelAnnotations!);
    checkUnnamed397(o.speechTranscriptions!);
    checkUnnamed398(o.textAnnotations!);
  }
  buildCounterGoogleCloudVideointelligenceV1VideoAnnotationResults--;
}

core.List<api.GoogleCloudVideointelligenceV1VideoSegment> buildUnnamed399() {
  var o = <api.GoogleCloudVideointelligenceV1VideoSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1VideoSegment());
  o.add(buildGoogleCloudVideointelligenceV1VideoSegment());
  return o;
}

void checkUnnamed399(
    core.List<api.GoogleCloudVideointelligenceV1VideoSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1VideoSegment(
      o[0] as api.GoogleCloudVideointelligenceV1VideoSegment);
  checkGoogleCloudVideointelligenceV1VideoSegment(
      o[1] as api.GoogleCloudVideointelligenceV1VideoSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1VideoContext = 0;
api.GoogleCloudVideointelligenceV1VideoContext
    buildGoogleCloudVideointelligenceV1VideoContext() {
  var o = api.GoogleCloudVideointelligenceV1VideoContext();
  buildCounterGoogleCloudVideointelligenceV1VideoContext++;
  if (buildCounterGoogleCloudVideointelligenceV1VideoContext < 3) {
    o.explicitContentDetectionConfig =
        buildGoogleCloudVideointelligenceV1ExplicitContentDetectionConfig();
    o.faceDetectionConfig =
        buildGoogleCloudVideointelligenceV1FaceDetectionConfig();
    o.labelDetectionConfig =
        buildGoogleCloudVideointelligenceV1LabelDetectionConfig();
    o.objectTrackingConfig =
        buildGoogleCloudVideointelligenceV1ObjectTrackingConfig();
    o.personDetectionConfig =
        buildGoogleCloudVideointelligenceV1PersonDetectionConfig();
    o.segments = buildUnnamed399();
    o.shotChangeDetectionConfig =
        buildGoogleCloudVideointelligenceV1ShotChangeDetectionConfig();
    o.speechTranscriptionConfig =
        buildGoogleCloudVideointelligenceV1SpeechTranscriptionConfig();
    o.textDetectionConfig =
        buildGoogleCloudVideointelligenceV1TextDetectionConfig();
  }
  buildCounterGoogleCloudVideointelligenceV1VideoContext--;
  return o;
}

void checkGoogleCloudVideointelligenceV1VideoContext(
    api.GoogleCloudVideointelligenceV1VideoContext o) {
  buildCounterGoogleCloudVideointelligenceV1VideoContext++;
  if (buildCounterGoogleCloudVideointelligenceV1VideoContext < 3) {
    checkGoogleCloudVideointelligenceV1ExplicitContentDetectionConfig(o
            .explicitContentDetectionConfig!
        as api.GoogleCloudVideointelligenceV1ExplicitContentDetectionConfig);
    checkGoogleCloudVideointelligenceV1FaceDetectionConfig(
        o.faceDetectionConfig!
            as api.GoogleCloudVideointelligenceV1FaceDetectionConfig);
    checkGoogleCloudVideointelligenceV1LabelDetectionConfig(
        o.labelDetectionConfig!
            as api.GoogleCloudVideointelligenceV1LabelDetectionConfig);
    checkGoogleCloudVideointelligenceV1ObjectTrackingConfig(
        o.objectTrackingConfig!
            as api.GoogleCloudVideointelligenceV1ObjectTrackingConfig);
    checkGoogleCloudVideointelligenceV1PersonDetectionConfig(
        o.personDetectionConfig!
            as api.GoogleCloudVideointelligenceV1PersonDetectionConfig);
    checkUnnamed399(o.segments!);
    checkGoogleCloudVideointelligenceV1ShotChangeDetectionConfig(
        o.shotChangeDetectionConfig!
            as api.GoogleCloudVideointelligenceV1ShotChangeDetectionConfig);
    checkGoogleCloudVideointelligenceV1SpeechTranscriptionConfig(
        o.speechTranscriptionConfig!
            as api.GoogleCloudVideointelligenceV1SpeechTranscriptionConfig);
    checkGoogleCloudVideointelligenceV1TextDetectionConfig(
        o.textDetectionConfig!
            as api.GoogleCloudVideointelligenceV1TextDetectionConfig);
  }
  buildCounterGoogleCloudVideointelligenceV1VideoContext--;
}

core.int buildCounterGoogleCloudVideointelligenceV1VideoSegment = 0;
api.GoogleCloudVideointelligenceV1VideoSegment
    buildGoogleCloudVideointelligenceV1VideoSegment() {
  var o = api.GoogleCloudVideointelligenceV1VideoSegment();
  buildCounterGoogleCloudVideointelligenceV1VideoSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1VideoSegment < 3) {
    o.endTimeOffset = 'foo';
    o.startTimeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1VideoSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1VideoSegment(
    api.GoogleCloudVideointelligenceV1VideoSegment o) {
  buildCounterGoogleCloudVideointelligenceV1VideoSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1VideoSegment < 3) {
    unittest.expect(
      o.endTimeOffset!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTimeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1VideoSegment--;
}

core.int buildCounterGoogleCloudVideointelligenceV1WordInfo = 0;
api.GoogleCloudVideointelligenceV1WordInfo
    buildGoogleCloudVideointelligenceV1WordInfo() {
  var o = api.GoogleCloudVideointelligenceV1WordInfo();
  buildCounterGoogleCloudVideointelligenceV1WordInfo++;
  if (buildCounterGoogleCloudVideointelligenceV1WordInfo < 3) {
    o.confidence = 42.0;
    o.endTime = 'foo';
    o.speakerTag = 42;
    o.startTime = 'foo';
    o.word = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1WordInfo--;
  return o;
}

void checkGoogleCloudVideointelligenceV1WordInfo(
    api.GoogleCloudVideointelligenceV1WordInfo o) {
  buildCounterGoogleCloudVideointelligenceV1WordInfo++;
  if (buildCounterGoogleCloudVideointelligenceV1WordInfo < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.speakerTag!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.word!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1WordInfo--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress>
    buildUnnamed400() {
  var o = <api.GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress());
  o.add(buildGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress());
  return o;
}

void checkUnnamed400(
    core.List<api.GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress(
      o[0] as api.GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress);
  checkGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress(
      o[1] as api.GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress);
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2AnnotateVideoProgress =
    0;
api.GoogleCloudVideointelligenceV1beta2AnnotateVideoProgress
    buildGoogleCloudVideointelligenceV1beta2AnnotateVideoProgress() {
  var o = api.GoogleCloudVideointelligenceV1beta2AnnotateVideoProgress();
  buildCounterGoogleCloudVideointelligenceV1beta2AnnotateVideoProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2AnnotateVideoProgress <
      3) {
    o.annotationProgress = buildUnnamed400();
  }
  buildCounterGoogleCloudVideointelligenceV1beta2AnnotateVideoProgress--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2AnnotateVideoProgress(
    api.GoogleCloudVideointelligenceV1beta2AnnotateVideoProgress o) {
  buildCounterGoogleCloudVideointelligenceV1beta2AnnotateVideoProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2AnnotateVideoProgress <
      3) {
    checkUnnamed400(o.annotationProgress!);
  }
  buildCounterGoogleCloudVideointelligenceV1beta2AnnotateVideoProgress--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2VideoAnnotationResults>
    buildUnnamed401() {
  var o = <api.GoogleCloudVideointelligenceV1beta2VideoAnnotationResults>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2VideoAnnotationResults());
  o.add(buildGoogleCloudVideointelligenceV1beta2VideoAnnotationResults());
  return o;
}

void checkUnnamed401(
    core.List<api.GoogleCloudVideointelligenceV1beta2VideoAnnotationResults>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2VideoAnnotationResults(
      o[0] as api.GoogleCloudVideointelligenceV1beta2VideoAnnotationResults);
  checkGoogleCloudVideointelligenceV1beta2VideoAnnotationResults(
      o[1] as api.GoogleCloudVideointelligenceV1beta2VideoAnnotationResults);
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2AnnotateVideoResponse =
    0;
api.GoogleCloudVideointelligenceV1beta2AnnotateVideoResponse
    buildGoogleCloudVideointelligenceV1beta2AnnotateVideoResponse() {
  var o = api.GoogleCloudVideointelligenceV1beta2AnnotateVideoResponse();
  buildCounterGoogleCloudVideointelligenceV1beta2AnnotateVideoResponse++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2AnnotateVideoResponse <
      3) {
    o.annotationResults = buildUnnamed401();
  }
  buildCounterGoogleCloudVideointelligenceV1beta2AnnotateVideoResponse--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2AnnotateVideoResponse(
    api.GoogleCloudVideointelligenceV1beta2AnnotateVideoResponse o) {
  buildCounterGoogleCloudVideointelligenceV1beta2AnnotateVideoResponse++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2AnnotateVideoResponse <
      3) {
    checkUnnamed401(o.annotationResults!);
  }
  buildCounterGoogleCloudVideointelligenceV1beta2AnnotateVideoResponse--;
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2DetectedAttribute = 0;
api.GoogleCloudVideointelligenceV1beta2DetectedAttribute
    buildGoogleCloudVideointelligenceV1beta2DetectedAttribute() {
  var o = api.GoogleCloudVideointelligenceV1beta2DetectedAttribute();
  buildCounterGoogleCloudVideointelligenceV1beta2DetectedAttribute++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2DetectedAttribute < 3) {
    o.confidence = 42.0;
    o.name = 'foo';
    o.value = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2DetectedAttribute--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2DetectedAttribute(
    api.GoogleCloudVideointelligenceV1beta2DetectedAttribute o) {
  buildCounterGoogleCloudVideointelligenceV1beta2DetectedAttribute++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2DetectedAttribute < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2DetectedAttribute--;
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2DetectedLandmark = 0;
api.GoogleCloudVideointelligenceV1beta2DetectedLandmark
    buildGoogleCloudVideointelligenceV1beta2DetectedLandmark() {
  var o = api.GoogleCloudVideointelligenceV1beta2DetectedLandmark();
  buildCounterGoogleCloudVideointelligenceV1beta2DetectedLandmark++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2DetectedLandmark < 3) {
    o.confidence = 42.0;
    o.name = 'foo';
    o.point = buildGoogleCloudVideointelligenceV1beta2NormalizedVertex();
  }
  buildCounterGoogleCloudVideointelligenceV1beta2DetectedLandmark--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2DetectedLandmark(
    api.GoogleCloudVideointelligenceV1beta2DetectedLandmark o) {
  buildCounterGoogleCloudVideointelligenceV1beta2DetectedLandmark++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2DetectedLandmark < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkGoogleCloudVideointelligenceV1beta2NormalizedVertex(
        o.point! as api.GoogleCloudVideointelligenceV1beta2NormalizedVertex);
  }
  buildCounterGoogleCloudVideointelligenceV1beta2DetectedLandmark--;
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2Entity = 0;
api.GoogleCloudVideointelligenceV1beta2Entity
    buildGoogleCloudVideointelligenceV1beta2Entity() {
  var o = api.GoogleCloudVideointelligenceV1beta2Entity();
  buildCounterGoogleCloudVideointelligenceV1beta2Entity++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2Entity < 3) {
    o.description = 'foo';
    o.entityId = 'foo';
    o.languageCode = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2Entity--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2Entity(
    api.GoogleCloudVideointelligenceV1beta2Entity o) {
  buildCounterGoogleCloudVideointelligenceV1beta2Entity++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2Entity < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2Entity--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2ExplicitContentFrame>
    buildUnnamed402() {
  var o = <api.GoogleCloudVideointelligenceV1beta2ExplicitContentFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2ExplicitContentFrame());
  o.add(buildGoogleCloudVideointelligenceV1beta2ExplicitContentFrame());
  return o;
}

void checkUnnamed402(
    core.List<api.GoogleCloudVideointelligenceV1beta2ExplicitContentFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2ExplicitContentFrame(
      o[0] as api.GoogleCloudVideointelligenceV1beta2ExplicitContentFrame);
  checkGoogleCloudVideointelligenceV1beta2ExplicitContentFrame(
      o[1] as api.GoogleCloudVideointelligenceV1beta2ExplicitContentFrame);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation =
    0;
api.GoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation
    buildGoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation();
  buildCounterGoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation <
      3) {
    o.frames = buildUnnamed402();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation(
    api.GoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation <
      3) {
    checkUnnamed402(o.frames!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2ExplicitContentFrame =
    0;
api.GoogleCloudVideointelligenceV1beta2ExplicitContentFrame
    buildGoogleCloudVideointelligenceV1beta2ExplicitContentFrame() {
  var o = api.GoogleCloudVideointelligenceV1beta2ExplicitContentFrame();
  buildCounterGoogleCloudVideointelligenceV1beta2ExplicitContentFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2ExplicitContentFrame < 3) {
    o.pornographyLikelihood = 'foo';
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2ExplicitContentFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2ExplicitContentFrame(
    api.GoogleCloudVideointelligenceV1beta2ExplicitContentFrame o) {
  buildCounterGoogleCloudVideointelligenceV1beta2ExplicitContentFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2ExplicitContentFrame < 3) {
    unittest.expect(
      o.pornographyLikelihood!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2ExplicitContentFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2FaceFrame> buildUnnamed403() {
  var o = <api.GoogleCloudVideointelligenceV1beta2FaceFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2FaceFrame());
  o.add(buildGoogleCloudVideointelligenceV1beta2FaceFrame());
  return o;
}

void checkUnnamed403(
    core.List<api.GoogleCloudVideointelligenceV1beta2FaceFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2FaceFrame(
      o[0] as api.GoogleCloudVideointelligenceV1beta2FaceFrame);
  checkGoogleCloudVideointelligenceV1beta2FaceFrame(
      o[1] as api.GoogleCloudVideointelligenceV1beta2FaceFrame);
}

core.List<api.GoogleCloudVideointelligenceV1beta2FaceSegment>
    buildUnnamed404() {
  var o = <api.GoogleCloudVideointelligenceV1beta2FaceSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2FaceSegment());
  o.add(buildGoogleCloudVideointelligenceV1beta2FaceSegment());
  return o;
}

void checkUnnamed404(
    core.List<api.GoogleCloudVideointelligenceV1beta2FaceSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2FaceSegment(
      o[0] as api.GoogleCloudVideointelligenceV1beta2FaceSegment);
  checkGoogleCloudVideointelligenceV1beta2FaceSegment(
      o[1] as api.GoogleCloudVideointelligenceV1beta2FaceSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2FaceAnnotation = 0;
api.GoogleCloudVideointelligenceV1beta2FaceAnnotation
    buildGoogleCloudVideointelligenceV1beta2FaceAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1beta2FaceAnnotation();
  buildCounterGoogleCloudVideointelligenceV1beta2FaceAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2FaceAnnotation < 3) {
    o.frames = buildUnnamed403();
    o.segments = buildUnnamed404();
    o.thumbnail = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2FaceAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2FaceAnnotation(
    api.GoogleCloudVideointelligenceV1beta2FaceAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1beta2FaceAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2FaceAnnotation < 3) {
    checkUnnamed403(o.frames!);
    checkUnnamed404(o.segments!);
    unittest.expect(
      o.thumbnail!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2FaceAnnotation--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2Track> buildUnnamed405() {
  var o = <api.GoogleCloudVideointelligenceV1beta2Track>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2Track());
  o.add(buildGoogleCloudVideointelligenceV1beta2Track());
  return o;
}

void checkUnnamed405(
    core.List<api.GoogleCloudVideointelligenceV1beta2Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2Track(
      o[0] as api.GoogleCloudVideointelligenceV1beta2Track);
  checkGoogleCloudVideointelligenceV1beta2Track(
      o[1] as api.GoogleCloudVideointelligenceV1beta2Track);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation = 0;
api.GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation
    buildGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation <
      3) {
    o.thumbnail = 'foo';
    o.tracks = buildUnnamed405();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation(
    api.GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation <
      3) {
    unittest.expect(
      o.thumbnail!,
      unittest.equals('foo'),
    );
    checkUnnamed405(o.tracks!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox>
    buildUnnamed406() {
  var o = <api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox());
  o.add(buildGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox());
  return o;
}

void checkUnnamed406(
    core.List<api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox(
      o[0] as api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox);
  checkGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox(
      o[1] as api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox);
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2FaceFrame = 0;
api.GoogleCloudVideointelligenceV1beta2FaceFrame
    buildGoogleCloudVideointelligenceV1beta2FaceFrame() {
  var o = api.GoogleCloudVideointelligenceV1beta2FaceFrame();
  buildCounterGoogleCloudVideointelligenceV1beta2FaceFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2FaceFrame < 3) {
    o.normalizedBoundingBoxes = buildUnnamed406();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2FaceFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2FaceFrame(
    api.GoogleCloudVideointelligenceV1beta2FaceFrame o) {
  buildCounterGoogleCloudVideointelligenceV1beta2FaceFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2FaceFrame < 3) {
    checkUnnamed406(o.normalizedBoundingBoxes!);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2FaceFrame--;
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2FaceSegment = 0;
api.GoogleCloudVideointelligenceV1beta2FaceSegment
    buildGoogleCloudVideointelligenceV1beta2FaceSegment() {
  var o = api.GoogleCloudVideointelligenceV1beta2FaceSegment();
  buildCounterGoogleCloudVideointelligenceV1beta2FaceSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2FaceSegment < 3) {
    o.segment = buildGoogleCloudVideointelligenceV1beta2VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1beta2FaceSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2FaceSegment(
    api.GoogleCloudVideointelligenceV1beta2FaceSegment o) {
  buildCounterGoogleCloudVideointelligenceV1beta2FaceSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2FaceSegment < 3) {
    checkGoogleCloudVideointelligenceV1beta2VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1beta2VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1beta2FaceSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2Entity> buildUnnamed407() {
  var o = <api.GoogleCloudVideointelligenceV1beta2Entity>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2Entity());
  o.add(buildGoogleCloudVideointelligenceV1beta2Entity());
  return o;
}

void checkUnnamed407(
    core.List<api.GoogleCloudVideointelligenceV1beta2Entity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2Entity(
      o[0] as api.GoogleCloudVideointelligenceV1beta2Entity);
  checkGoogleCloudVideointelligenceV1beta2Entity(
      o[1] as api.GoogleCloudVideointelligenceV1beta2Entity);
}

core.List<api.GoogleCloudVideointelligenceV1beta2LabelFrame> buildUnnamed408() {
  var o = <api.GoogleCloudVideointelligenceV1beta2LabelFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2LabelFrame());
  o.add(buildGoogleCloudVideointelligenceV1beta2LabelFrame());
  return o;
}

void checkUnnamed408(
    core.List<api.GoogleCloudVideointelligenceV1beta2LabelFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2LabelFrame(
      o[0] as api.GoogleCloudVideointelligenceV1beta2LabelFrame);
  checkGoogleCloudVideointelligenceV1beta2LabelFrame(
      o[1] as api.GoogleCloudVideointelligenceV1beta2LabelFrame);
}

core.List<api.GoogleCloudVideointelligenceV1beta2LabelSegment>
    buildUnnamed409() {
  var o = <api.GoogleCloudVideointelligenceV1beta2LabelSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2LabelSegment());
  o.add(buildGoogleCloudVideointelligenceV1beta2LabelSegment());
  return o;
}

void checkUnnamed409(
    core.List<api.GoogleCloudVideointelligenceV1beta2LabelSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2LabelSegment(
      o[0] as api.GoogleCloudVideointelligenceV1beta2LabelSegment);
  checkGoogleCloudVideointelligenceV1beta2LabelSegment(
      o[1] as api.GoogleCloudVideointelligenceV1beta2LabelSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2LabelAnnotation = 0;
api.GoogleCloudVideointelligenceV1beta2LabelAnnotation
    buildGoogleCloudVideointelligenceV1beta2LabelAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1beta2LabelAnnotation();
  buildCounterGoogleCloudVideointelligenceV1beta2LabelAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2LabelAnnotation < 3) {
    o.categoryEntities = buildUnnamed407();
    o.entity = buildGoogleCloudVideointelligenceV1beta2Entity();
    o.frames = buildUnnamed408();
    o.segments = buildUnnamed409();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2LabelAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2LabelAnnotation(
    api.GoogleCloudVideointelligenceV1beta2LabelAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1beta2LabelAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2LabelAnnotation < 3) {
    checkUnnamed407(o.categoryEntities!);
    checkGoogleCloudVideointelligenceV1beta2Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1beta2Entity);
    checkUnnamed408(o.frames!);
    checkUnnamed409(o.segments!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2LabelAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2LabelFrame = 0;
api.GoogleCloudVideointelligenceV1beta2LabelFrame
    buildGoogleCloudVideointelligenceV1beta2LabelFrame() {
  var o = api.GoogleCloudVideointelligenceV1beta2LabelFrame();
  buildCounterGoogleCloudVideointelligenceV1beta2LabelFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2LabelFrame < 3) {
    o.confidence = 42.0;
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2LabelFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2LabelFrame(
    api.GoogleCloudVideointelligenceV1beta2LabelFrame o) {
  buildCounterGoogleCloudVideointelligenceV1beta2LabelFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2LabelFrame < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2LabelFrame--;
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2LabelSegment = 0;
api.GoogleCloudVideointelligenceV1beta2LabelSegment
    buildGoogleCloudVideointelligenceV1beta2LabelSegment() {
  var o = api.GoogleCloudVideointelligenceV1beta2LabelSegment();
  buildCounterGoogleCloudVideointelligenceV1beta2LabelSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2LabelSegment < 3) {
    o.confidence = 42.0;
    o.segment = buildGoogleCloudVideointelligenceV1beta2VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1beta2LabelSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2LabelSegment(
    api.GoogleCloudVideointelligenceV1beta2LabelSegment o) {
  buildCounterGoogleCloudVideointelligenceV1beta2LabelSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2LabelSegment < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1beta2VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1beta2VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1beta2LabelSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2VideoSegment>
    buildUnnamed410() {
  var o = <api.GoogleCloudVideointelligenceV1beta2VideoSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2VideoSegment());
  o.add(buildGoogleCloudVideointelligenceV1beta2VideoSegment());
  return o;
}

void checkUnnamed410(
    core.List<api.GoogleCloudVideointelligenceV1beta2VideoSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2VideoSegment(
      o[0] as api.GoogleCloudVideointelligenceV1beta2VideoSegment);
  checkGoogleCloudVideointelligenceV1beta2VideoSegment(
      o[1] as api.GoogleCloudVideointelligenceV1beta2VideoSegment);
}

core.List<api.GoogleCloudVideointelligenceV1beta2Track> buildUnnamed411() {
  var o = <api.GoogleCloudVideointelligenceV1beta2Track>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2Track());
  o.add(buildGoogleCloudVideointelligenceV1beta2Track());
  return o;
}

void checkUnnamed411(
    core.List<api.GoogleCloudVideointelligenceV1beta2Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2Track(
      o[0] as api.GoogleCloudVideointelligenceV1beta2Track);
  checkGoogleCloudVideointelligenceV1beta2Track(
      o[1] as api.GoogleCloudVideointelligenceV1beta2Track);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation =
    0;
api.GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation
    buildGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation <
      3) {
    o.entity = buildGoogleCloudVideointelligenceV1beta2Entity();
    o.segments = buildUnnamed410();
    o.tracks = buildUnnamed411();
  }
  buildCounterGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation(
    api.GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation <
      3) {
    checkGoogleCloudVideointelligenceV1beta2Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1beta2Entity);
    checkUnnamed410(o.segments!);
    checkUnnamed411(o.tracks!);
  }
  buildCounterGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox =
    0;
api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox
    buildGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox() {
  var o = api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox();
  buildCounterGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox <
      3) {
    o.bottom = 42.0;
    o.left = 42.0;
    o.right = 42.0;
    o.top = 42.0;
  }
  buildCounterGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox(
    api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox o) {
  buildCounterGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox <
      3) {
    unittest.expect(
      o.bottom!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.left!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.right!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.top!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2NormalizedVertex>
    buildUnnamed412() {
  var o = <api.GoogleCloudVideointelligenceV1beta2NormalizedVertex>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2NormalizedVertex());
  o.add(buildGoogleCloudVideointelligenceV1beta2NormalizedVertex());
  return o;
}

void checkUnnamed412(
    core.List<api.GoogleCloudVideointelligenceV1beta2NormalizedVertex> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2NormalizedVertex(
      o[0] as api.GoogleCloudVideointelligenceV1beta2NormalizedVertex);
  checkGoogleCloudVideointelligenceV1beta2NormalizedVertex(
      o[1] as api.GoogleCloudVideointelligenceV1beta2NormalizedVertex);
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly =
    0;
api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly
    buildGoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly() {
  var o = api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly();
  buildCounterGoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly <
      3) {
    o.vertices = buildUnnamed412();
  }
  buildCounterGoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly(
    api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly o) {
  buildCounterGoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly <
      3) {
    checkUnnamed412(o.vertices!);
  }
  buildCounterGoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly--;
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2NormalizedVertex = 0;
api.GoogleCloudVideointelligenceV1beta2NormalizedVertex
    buildGoogleCloudVideointelligenceV1beta2NormalizedVertex() {
  var o = api.GoogleCloudVideointelligenceV1beta2NormalizedVertex();
  buildCounterGoogleCloudVideointelligenceV1beta2NormalizedVertex++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2NormalizedVertex < 3) {
    o.x = 42.0;
    o.y = 42.0;
  }
  buildCounterGoogleCloudVideointelligenceV1beta2NormalizedVertex--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2NormalizedVertex(
    api.GoogleCloudVideointelligenceV1beta2NormalizedVertex o) {
  buildCounterGoogleCloudVideointelligenceV1beta2NormalizedVertex++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2NormalizedVertex < 3) {
    unittest.expect(
      o.x!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.y!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2NormalizedVertex--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame>
    buildUnnamed413() {
  var o = <api.GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame());
  o.add(buildGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame());
  return o;
}

void checkUnnamed413(
    core.List<api.GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame(
      o[0] as api.GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame);
  checkGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame(
      o[1] as api.GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation = 0;
api.GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation
    buildGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation();
  buildCounterGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation <
      3) {
    o.confidence = 42.0;
    o.entity = buildGoogleCloudVideointelligenceV1beta2Entity();
    o.frames = buildUnnamed413();
    o.segment = buildGoogleCloudVideointelligenceV1beta2VideoSegment();
    o.trackId = 'foo';
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation(
    api.GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation <
      3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1beta2Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1beta2Entity);
    checkUnnamed413(o.frames!);
    checkGoogleCloudVideointelligenceV1beta2VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1beta2VideoSegment);
    unittest.expect(
      o.trackId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame = 0;
api.GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame
    buildGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame() {
  var o = api.GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame();
  buildCounterGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame < 3) {
    o.normalizedBoundingBox =
        buildGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame(
    api.GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame o) {
  buildCounterGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame < 3) {
    checkGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox(
        o.normalizedBoundingBox!
            as api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2Track> buildUnnamed414() {
  var o = <api.GoogleCloudVideointelligenceV1beta2Track>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2Track());
  o.add(buildGoogleCloudVideointelligenceV1beta2Track());
  return o;
}

void checkUnnamed414(
    core.List<api.GoogleCloudVideointelligenceV1beta2Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2Track(
      o[0] as api.GoogleCloudVideointelligenceV1beta2Track);
  checkGoogleCloudVideointelligenceV1beta2Track(
      o[1] as api.GoogleCloudVideointelligenceV1beta2Track);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation =
    0;
api.GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation
    buildGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation <
      3) {
    o.tracks = buildUnnamed414();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation(
    api.GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation <
      3) {
    checkUnnamed414(o.tracks!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2WordInfo> buildUnnamed415() {
  var o = <api.GoogleCloudVideointelligenceV1beta2WordInfo>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2WordInfo());
  o.add(buildGoogleCloudVideointelligenceV1beta2WordInfo());
  return o;
}

void checkUnnamed415(
    core.List<api.GoogleCloudVideointelligenceV1beta2WordInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2WordInfo(
      o[0] as api.GoogleCloudVideointelligenceV1beta2WordInfo);
  checkGoogleCloudVideointelligenceV1beta2WordInfo(
      o[1] as api.GoogleCloudVideointelligenceV1beta2WordInfo);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative =
    0;
api.GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative
    buildGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative() {
  var o = api.GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative();
  buildCounterGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative <
      3) {
    o.confidence = 42.0;
    o.transcript = 'foo';
    o.words = buildUnnamed415();
  }
  buildCounterGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative(
    api.GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative o) {
  buildCounterGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative <
      3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.transcript!,
      unittest.equals('foo'),
    );
    checkUnnamed415(o.words!);
  }
  buildCounterGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative>
    buildUnnamed416() {
  var o =
      <api.GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative());
  o.add(buildGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative());
  return o;
}

void checkUnnamed416(
    core.List<
            api.GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative(o[0]
      as api.GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative);
  checkGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative(o[1]
      as api.GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative);
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2SpeechTranscription = 0;
api.GoogleCloudVideointelligenceV1beta2SpeechTranscription
    buildGoogleCloudVideointelligenceV1beta2SpeechTranscription() {
  var o = api.GoogleCloudVideointelligenceV1beta2SpeechTranscription();
  buildCounterGoogleCloudVideointelligenceV1beta2SpeechTranscription++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2SpeechTranscription < 3) {
    o.alternatives = buildUnnamed416();
    o.languageCode = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2SpeechTranscription--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2SpeechTranscription(
    api.GoogleCloudVideointelligenceV1beta2SpeechTranscription o) {
  buildCounterGoogleCloudVideointelligenceV1beta2SpeechTranscription++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2SpeechTranscription < 3) {
    checkUnnamed416(o.alternatives!);
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2SpeechTranscription--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2TextSegment>
    buildUnnamed417() {
  var o = <api.GoogleCloudVideointelligenceV1beta2TextSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2TextSegment());
  o.add(buildGoogleCloudVideointelligenceV1beta2TextSegment());
  return o;
}

void checkUnnamed417(
    core.List<api.GoogleCloudVideointelligenceV1beta2TextSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2TextSegment(
      o[0] as api.GoogleCloudVideointelligenceV1beta2TextSegment);
  checkGoogleCloudVideointelligenceV1beta2TextSegment(
      o[1] as api.GoogleCloudVideointelligenceV1beta2TextSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2TextAnnotation = 0;
api.GoogleCloudVideointelligenceV1beta2TextAnnotation
    buildGoogleCloudVideointelligenceV1beta2TextAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1beta2TextAnnotation();
  buildCounterGoogleCloudVideointelligenceV1beta2TextAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2TextAnnotation < 3) {
    o.segments = buildUnnamed417();
    o.text = 'foo';
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2TextAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2TextAnnotation(
    api.GoogleCloudVideointelligenceV1beta2TextAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1beta2TextAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2TextAnnotation < 3) {
    checkUnnamed417(o.segments!);
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2TextAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2TextFrame = 0;
api.GoogleCloudVideointelligenceV1beta2TextFrame
    buildGoogleCloudVideointelligenceV1beta2TextFrame() {
  var o = api.GoogleCloudVideointelligenceV1beta2TextFrame();
  buildCounterGoogleCloudVideointelligenceV1beta2TextFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2TextFrame < 3) {
    o.rotatedBoundingBox =
        buildGoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2TextFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2TextFrame(
    api.GoogleCloudVideointelligenceV1beta2TextFrame o) {
  buildCounterGoogleCloudVideointelligenceV1beta2TextFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2TextFrame < 3) {
    checkGoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly(
        o.rotatedBoundingBox!
            as api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2TextFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2TextFrame> buildUnnamed418() {
  var o = <api.GoogleCloudVideointelligenceV1beta2TextFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2TextFrame());
  o.add(buildGoogleCloudVideointelligenceV1beta2TextFrame());
  return o;
}

void checkUnnamed418(
    core.List<api.GoogleCloudVideointelligenceV1beta2TextFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2TextFrame(
      o[0] as api.GoogleCloudVideointelligenceV1beta2TextFrame);
  checkGoogleCloudVideointelligenceV1beta2TextFrame(
      o[1] as api.GoogleCloudVideointelligenceV1beta2TextFrame);
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2TextSegment = 0;
api.GoogleCloudVideointelligenceV1beta2TextSegment
    buildGoogleCloudVideointelligenceV1beta2TextSegment() {
  var o = api.GoogleCloudVideointelligenceV1beta2TextSegment();
  buildCounterGoogleCloudVideointelligenceV1beta2TextSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2TextSegment < 3) {
    o.confidence = 42.0;
    o.frames = buildUnnamed418();
    o.segment = buildGoogleCloudVideointelligenceV1beta2VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1beta2TextSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2TextSegment(
    api.GoogleCloudVideointelligenceV1beta2TextSegment o) {
  buildCounterGoogleCloudVideointelligenceV1beta2TextSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2TextSegment < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkUnnamed418(o.frames!);
    checkGoogleCloudVideointelligenceV1beta2VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1beta2VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1beta2TextSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2DetectedAttribute>
    buildUnnamed419() {
  var o = <api.GoogleCloudVideointelligenceV1beta2DetectedAttribute>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2DetectedAttribute());
  o.add(buildGoogleCloudVideointelligenceV1beta2DetectedAttribute());
  return o;
}

void checkUnnamed419(
    core.List<api.GoogleCloudVideointelligenceV1beta2DetectedAttribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2DetectedAttribute(
      o[0] as api.GoogleCloudVideointelligenceV1beta2DetectedAttribute);
  checkGoogleCloudVideointelligenceV1beta2DetectedAttribute(
      o[1] as api.GoogleCloudVideointelligenceV1beta2DetectedAttribute);
}

core.List<api.GoogleCloudVideointelligenceV1beta2DetectedLandmark>
    buildUnnamed420() {
  var o = <api.GoogleCloudVideointelligenceV1beta2DetectedLandmark>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2DetectedLandmark());
  o.add(buildGoogleCloudVideointelligenceV1beta2DetectedLandmark());
  return o;
}

void checkUnnamed420(
    core.List<api.GoogleCloudVideointelligenceV1beta2DetectedLandmark> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2DetectedLandmark(
      o[0] as api.GoogleCloudVideointelligenceV1beta2DetectedLandmark);
  checkGoogleCloudVideointelligenceV1beta2DetectedLandmark(
      o[1] as api.GoogleCloudVideointelligenceV1beta2DetectedLandmark);
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2TimestampedObject = 0;
api.GoogleCloudVideointelligenceV1beta2TimestampedObject
    buildGoogleCloudVideointelligenceV1beta2TimestampedObject() {
  var o = api.GoogleCloudVideointelligenceV1beta2TimestampedObject();
  buildCounterGoogleCloudVideointelligenceV1beta2TimestampedObject++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2TimestampedObject < 3) {
    o.attributes = buildUnnamed419();
    o.landmarks = buildUnnamed420();
    o.normalizedBoundingBox =
        buildGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2TimestampedObject--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2TimestampedObject(
    api.GoogleCloudVideointelligenceV1beta2TimestampedObject o) {
  buildCounterGoogleCloudVideointelligenceV1beta2TimestampedObject++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2TimestampedObject < 3) {
    checkUnnamed419(o.attributes!);
    checkUnnamed420(o.landmarks!);
    checkGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox(
        o.normalizedBoundingBox!
            as api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2TimestampedObject--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2DetectedAttribute>
    buildUnnamed421() {
  var o = <api.GoogleCloudVideointelligenceV1beta2DetectedAttribute>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2DetectedAttribute());
  o.add(buildGoogleCloudVideointelligenceV1beta2DetectedAttribute());
  return o;
}

void checkUnnamed421(
    core.List<api.GoogleCloudVideointelligenceV1beta2DetectedAttribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2DetectedAttribute(
      o[0] as api.GoogleCloudVideointelligenceV1beta2DetectedAttribute);
  checkGoogleCloudVideointelligenceV1beta2DetectedAttribute(
      o[1] as api.GoogleCloudVideointelligenceV1beta2DetectedAttribute);
}

core.List<api.GoogleCloudVideointelligenceV1beta2TimestampedObject>
    buildUnnamed422() {
  var o = <api.GoogleCloudVideointelligenceV1beta2TimestampedObject>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2TimestampedObject());
  o.add(buildGoogleCloudVideointelligenceV1beta2TimestampedObject());
  return o;
}

void checkUnnamed422(
    core.List<api.GoogleCloudVideointelligenceV1beta2TimestampedObject> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2TimestampedObject(
      o[0] as api.GoogleCloudVideointelligenceV1beta2TimestampedObject);
  checkGoogleCloudVideointelligenceV1beta2TimestampedObject(
      o[1] as api.GoogleCloudVideointelligenceV1beta2TimestampedObject);
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2Track = 0;
api.GoogleCloudVideointelligenceV1beta2Track
    buildGoogleCloudVideointelligenceV1beta2Track() {
  var o = api.GoogleCloudVideointelligenceV1beta2Track();
  buildCounterGoogleCloudVideointelligenceV1beta2Track++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2Track < 3) {
    o.attributes = buildUnnamed421();
    o.confidence = 42.0;
    o.segment = buildGoogleCloudVideointelligenceV1beta2VideoSegment();
    o.timestampedObjects = buildUnnamed422();
  }
  buildCounterGoogleCloudVideointelligenceV1beta2Track--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2Track(
    api.GoogleCloudVideointelligenceV1beta2Track o) {
  buildCounterGoogleCloudVideointelligenceV1beta2Track++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2Track < 3) {
    checkUnnamed421(o.attributes!);
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1beta2VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1beta2VideoSegment);
    checkUnnamed422(o.timestampedObjects!);
  }
  buildCounterGoogleCloudVideointelligenceV1beta2Track--;
}

core.int
    buildCounterGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress = 0;
api.GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress
    buildGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress() {
  var o = api.GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress();
  buildCounterGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress <
      3) {
    o.feature = 'foo';
    o.inputUri = 'foo';
    o.progressPercent = 42;
    o.segment = buildGoogleCloudVideointelligenceV1beta2VideoSegment();
    o.startTime = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress(
    api.GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress o) {
  buildCounterGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress <
      3) {
    unittest.expect(
      o.feature!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inputUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.progressPercent!,
      unittest.equals(42),
    );
    checkGoogleCloudVideointelligenceV1beta2VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1beta2VideoSegment);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress--;
}

core.List<api.GoogleCloudVideointelligenceV1beta2FaceAnnotation>
    buildUnnamed423() {
  var o = <api.GoogleCloudVideointelligenceV1beta2FaceAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2FaceAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1beta2FaceAnnotation());
  return o;
}

void checkUnnamed423(
    core.List<api.GoogleCloudVideointelligenceV1beta2FaceAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2FaceAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1beta2FaceAnnotation);
  checkGoogleCloudVideointelligenceV1beta2FaceAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1beta2FaceAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation>
    buildUnnamed424() {
  var o = <api.GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation());
  return o;
}

void checkUnnamed424(
    core.List<api.GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation);
  checkGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1beta2LabelAnnotation>
    buildUnnamed425() {
  var o = <api.GoogleCloudVideointelligenceV1beta2LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1beta2LabelAnnotation());
  return o;
}

void checkUnnamed425(
    core.List<api.GoogleCloudVideointelligenceV1beta2LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1beta2LabelAnnotation);
  checkGoogleCloudVideointelligenceV1beta2LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1beta2LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation>
    buildUnnamed426() {
  var o = <api.GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation());
  return o;
}

void checkUnnamed426(
    core.List<api.GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation);
  checkGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation>
    buildUnnamed427() {
  var o = <api.GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation());
  return o;
}

void checkUnnamed427(
    core.List<api.GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation);
  checkGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation>
    buildUnnamed428() {
  var o = <api.GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation());
  return o;
}

void checkUnnamed428(
    core.List<api.GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation);
  checkGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1beta2LabelAnnotation>
    buildUnnamed429() {
  var o = <api.GoogleCloudVideointelligenceV1beta2LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1beta2LabelAnnotation());
  return o;
}

void checkUnnamed429(
    core.List<api.GoogleCloudVideointelligenceV1beta2LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1beta2LabelAnnotation);
  checkGoogleCloudVideointelligenceV1beta2LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1beta2LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1beta2LabelAnnotation>
    buildUnnamed430() {
  var o = <api.GoogleCloudVideointelligenceV1beta2LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1beta2LabelAnnotation());
  return o;
}

void checkUnnamed430(
    core.List<api.GoogleCloudVideointelligenceV1beta2LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1beta2LabelAnnotation);
  checkGoogleCloudVideointelligenceV1beta2LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1beta2LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1beta2VideoSegment>
    buildUnnamed431() {
  var o = <api.GoogleCloudVideointelligenceV1beta2VideoSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2VideoSegment());
  o.add(buildGoogleCloudVideointelligenceV1beta2VideoSegment());
  return o;
}

void checkUnnamed431(
    core.List<api.GoogleCloudVideointelligenceV1beta2VideoSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2VideoSegment(
      o[0] as api.GoogleCloudVideointelligenceV1beta2VideoSegment);
  checkGoogleCloudVideointelligenceV1beta2VideoSegment(
      o[1] as api.GoogleCloudVideointelligenceV1beta2VideoSegment);
}

core.List<api.GoogleCloudVideointelligenceV1beta2LabelAnnotation>
    buildUnnamed432() {
  var o = <api.GoogleCloudVideointelligenceV1beta2LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1beta2LabelAnnotation());
  return o;
}

void checkUnnamed432(
    core.List<api.GoogleCloudVideointelligenceV1beta2LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1beta2LabelAnnotation);
  checkGoogleCloudVideointelligenceV1beta2LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1beta2LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1beta2LabelAnnotation>
    buildUnnamed433() {
  var o = <api.GoogleCloudVideointelligenceV1beta2LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1beta2LabelAnnotation());
  return o;
}

void checkUnnamed433(
    core.List<api.GoogleCloudVideointelligenceV1beta2LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1beta2LabelAnnotation);
  checkGoogleCloudVideointelligenceV1beta2LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1beta2LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1beta2SpeechTranscription>
    buildUnnamed434() {
  var o = <api.GoogleCloudVideointelligenceV1beta2SpeechTranscription>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2SpeechTranscription());
  o.add(buildGoogleCloudVideointelligenceV1beta2SpeechTranscription());
  return o;
}

void checkUnnamed434(
    core.List<api.GoogleCloudVideointelligenceV1beta2SpeechTranscription> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2SpeechTranscription(
      o[0] as api.GoogleCloudVideointelligenceV1beta2SpeechTranscription);
  checkGoogleCloudVideointelligenceV1beta2SpeechTranscription(
      o[1] as api.GoogleCloudVideointelligenceV1beta2SpeechTranscription);
}

core.List<api.GoogleCloudVideointelligenceV1beta2TextAnnotation>
    buildUnnamed435() {
  var o = <api.GoogleCloudVideointelligenceV1beta2TextAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1beta2TextAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1beta2TextAnnotation());
  return o;
}

void checkUnnamed435(
    core.List<api.GoogleCloudVideointelligenceV1beta2TextAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1beta2TextAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1beta2TextAnnotation);
  checkGoogleCloudVideointelligenceV1beta2TextAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1beta2TextAnnotation);
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2VideoAnnotationResults =
    0;
api.GoogleCloudVideointelligenceV1beta2VideoAnnotationResults
    buildGoogleCloudVideointelligenceV1beta2VideoAnnotationResults() {
  var o = api.GoogleCloudVideointelligenceV1beta2VideoAnnotationResults();
  buildCounterGoogleCloudVideointelligenceV1beta2VideoAnnotationResults++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2VideoAnnotationResults <
      3) {
    o.error = buildGoogleRpcStatus();
    o.explicitAnnotation =
        buildGoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation();
    o.faceAnnotations = buildUnnamed423();
    o.faceDetectionAnnotations = buildUnnamed424();
    o.frameLabelAnnotations = buildUnnamed425();
    o.inputUri = 'foo';
    o.logoRecognitionAnnotations = buildUnnamed426();
    o.objectAnnotations = buildUnnamed427();
    o.personDetectionAnnotations = buildUnnamed428();
    o.segment = buildGoogleCloudVideointelligenceV1beta2VideoSegment();
    o.segmentLabelAnnotations = buildUnnamed429();
    o.segmentPresenceLabelAnnotations = buildUnnamed430();
    o.shotAnnotations = buildUnnamed431();
    o.shotLabelAnnotations = buildUnnamed432();
    o.shotPresenceLabelAnnotations = buildUnnamed433();
    o.speechTranscriptions = buildUnnamed434();
    o.textAnnotations = buildUnnamed435();
  }
  buildCounterGoogleCloudVideointelligenceV1beta2VideoAnnotationResults--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2VideoAnnotationResults(
    api.GoogleCloudVideointelligenceV1beta2VideoAnnotationResults o) {
  buildCounterGoogleCloudVideointelligenceV1beta2VideoAnnotationResults++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2VideoAnnotationResults <
      3) {
    checkGoogleRpcStatus(o.error! as api.GoogleRpcStatus);
    checkGoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation(o
            .explicitAnnotation!
        as api.GoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation);
    checkUnnamed423(o.faceAnnotations!);
    checkUnnamed424(o.faceDetectionAnnotations!);
    checkUnnamed425(o.frameLabelAnnotations!);
    unittest.expect(
      o.inputUri!,
      unittest.equals('foo'),
    );
    checkUnnamed426(o.logoRecognitionAnnotations!);
    checkUnnamed427(o.objectAnnotations!);
    checkUnnamed428(o.personDetectionAnnotations!);
    checkGoogleCloudVideointelligenceV1beta2VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1beta2VideoSegment);
    checkUnnamed429(o.segmentLabelAnnotations!);
    checkUnnamed430(o.segmentPresenceLabelAnnotations!);
    checkUnnamed431(o.shotAnnotations!);
    checkUnnamed432(o.shotLabelAnnotations!);
    checkUnnamed433(o.shotPresenceLabelAnnotations!);
    checkUnnamed434(o.speechTranscriptions!);
    checkUnnamed435(o.textAnnotations!);
  }
  buildCounterGoogleCloudVideointelligenceV1beta2VideoAnnotationResults--;
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2VideoSegment = 0;
api.GoogleCloudVideointelligenceV1beta2VideoSegment
    buildGoogleCloudVideointelligenceV1beta2VideoSegment() {
  var o = api.GoogleCloudVideointelligenceV1beta2VideoSegment();
  buildCounterGoogleCloudVideointelligenceV1beta2VideoSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2VideoSegment < 3) {
    o.endTimeOffset = 'foo';
    o.startTimeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2VideoSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2VideoSegment(
    api.GoogleCloudVideointelligenceV1beta2VideoSegment o) {
  buildCounterGoogleCloudVideointelligenceV1beta2VideoSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2VideoSegment < 3) {
    unittest.expect(
      o.endTimeOffset!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTimeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2VideoSegment--;
}

core.int buildCounterGoogleCloudVideointelligenceV1beta2WordInfo = 0;
api.GoogleCloudVideointelligenceV1beta2WordInfo
    buildGoogleCloudVideointelligenceV1beta2WordInfo() {
  var o = api.GoogleCloudVideointelligenceV1beta2WordInfo();
  buildCounterGoogleCloudVideointelligenceV1beta2WordInfo++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2WordInfo < 3) {
    o.confidence = 42.0;
    o.endTime = 'foo';
    o.speakerTag = 42;
    o.startTime = 'foo';
    o.word = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1beta2WordInfo--;
  return o;
}

void checkGoogleCloudVideointelligenceV1beta2WordInfo(
    api.GoogleCloudVideointelligenceV1beta2WordInfo o) {
  buildCounterGoogleCloudVideointelligenceV1beta2WordInfo++;
  if (buildCounterGoogleCloudVideointelligenceV1beta2WordInfo < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.speakerTag!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.word!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1beta2WordInfo--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress>
    buildUnnamed436() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress());
  return o;
}

void checkUnnamed436(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress);
  checkGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress = 0;
api.GoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress
    buildGoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress();
  buildCounterGoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress <
      3) {
    o.annotationProgress = buildUnnamed436();
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress(
    api.GoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress <
      3) {
    checkUnnamed436(o.annotationProgress!);
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults>
    buildUnnamed437() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults());
  return o;
}

void checkUnnamed437(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults);
  checkGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse = 0;
api.GoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse
    buildGoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse();
  buildCounterGoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse <
      3) {
    o.annotationResults = buildUnnamed437();
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse(
    api.GoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse <
      3) {
    checkUnnamed437(o.annotationResults!);
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1DetectedAttribute = 0;
api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute
    buildGoogleCloudVideointelligenceV1p1beta1DetectedAttribute() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute();
  buildCounterGoogleCloudVideointelligenceV1p1beta1DetectedAttribute++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1DetectedAttribute < 3) {
    o.confidence = 42.0;
    o.name = 'foo';
    o.value = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1DetectedAttribute--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1DetectedAttribute(
    api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1DetectedAttribute++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1DetectedAttribute < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1DetectedAttribute--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1DetectedLandmark = 0;
api.GoogleCloudVideointelligenceV1p1beta1DetectedLandmark
    buildGoogleCloudVideointelligenceV1p1beta1DetectedLandmark() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1DetectedLandmark();
  buildCounterGoogleCloudVideointelligenceV1p1beta1DetectedLandmark++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1DetectedLandmark < 3) {
    o.confidence = 42.0;
    o.name = 'foo';
    o.point = buildGoogleCloudVideointelligenceV1p1beta1NormalizedVertex();
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1DetectedLandmark--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1DetectedLandmark(
    api.GoogleCloudVideointelligenceV1p1beta1DetectedLandmark o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1DetectedLandmark++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1DetectedLandmark < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkGoogleCloudVideointelligenceV1p1beta1NormalizedVertex(
        o.point! as api.GoogleCloudVideointelligenceV1p1beta1NormalizedVertex);
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1DetectedLandmark--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1Entity = 0;
api.GoogleCloudVideointelligenceV1p1beta1Entity
    buildGoogleCloudVideointelligenceV1p1beta1Entity() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1Entity();
  buildCounterGoogleCloudVideointelligenceV1p1beta1Entity++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1Entity < 3) {
    o.description = 'foo';
    o.entityId = 'foo';
    o.languageCode = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1Entity--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1Entity(
    api.GoogleCloudVideointelligenceV1p1beta1Entity o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1Entity++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1Entity < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1Entity--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame>
    buildUnnamed438() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame());
  return o;
}

void checkUnnamed438(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame);
  checkGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation
    buildGoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation <
      3) {
    o.frames = buildUnnamed438();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation(
    api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation <
      3) {
    checkUnnamed438(o.frames!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame =
    0;
api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame
    buildGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame();
  buildCounterGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame <
      3) {
    o.pornographyLikelihood = 'foo';
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame(
    api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame <
      3) {
    unittest.expect(
      o.pornographyLikelihood!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1FaceFrame>
    buildUnnamed439() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1FaceFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1FaceFrame());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1FaceFrame());
  return o;
}

void checkUnnamed439(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1FaceFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1FaceFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1FaceFrame);
  checkGoogleCloudVideointelligenceV1p1beta1FaceFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1FaceFrame);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1FaceSegment>
    buildUnnamed440() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1FaceSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1FaceSegment());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1FaceSegment());
  return o;
}

void checkUnnamed440(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1FaceSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1FaceSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1FaceSegment);
  checkGoogleCloudVideointelligenceV1p1beta1FaceSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1FaceSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1FaceAnnotation = 0;
api.GoogleCloudVideointelligenceV1p1beta1FaceAnnotation
    buildGoogleCloudVideointelligenceV1p1beta1FaceAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1FaceAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1FaceAnnotation < 3) {
    o.frames = buildUnnamed439();
    o.segments = buildUnnamed440();
    o.thumbnail = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1FaceAnnotation(
    api.GoogleCloudVideointelligenceV1p1beta1FaceAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1FaceAnnotation < 3) {
    checkUnnamed439(o.frames!);
    checkUnnamed440(o.segments!);
    unittest.expect(
      o.thumbnail!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceAnnotation--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1Track> buildUnnamed441() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1Track>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1Track());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1Track());
  return o;
}

void checkUnnamed441(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1Track(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1Track);
  checkGoogleCloudVideointelligenceV1p1beta1Track(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1Track);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation
    buildGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation <
      3) {
    o.thumbnail = 'foo';
    o.tracks = buildUnnamed441();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation(
    api.GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation <
      3) {
    unittest.expect(
      o.thumbnail!,
      unittest.equals('foo'),
    );
    checkUnnamed441(o.tracks!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox>
    buildUnnamed442() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox());
  return o;
}

void checkUnnamed442(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox);
  checkGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox);
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1FaceFrame = 0;
api.GoogleCloudVideointelligenceV1p1beta1FaceFrame
    buildGoogleCloudVideointelligenceV1p1beta1FaceFrame() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1FaceFrame();
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1FaceFrame < 3) {
    o.normalizedBoundingBoxes = buildUnnamed442();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1FaceFrame(
    api.GoogleCloudVideointelligenceV1p1beta1FaceFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1FaceFrame < 3) {
    checkUnnamed442(o.normalizedBoundingBoxes!);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceFrame--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1FaceSegment = 0;
api.GoogleCloudVideointelligenceV1p1beta1FaceSegment
    buildGoogleCloudVideointelligenceV1p1beta1FaceSegment() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1FaceSegment();
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1FaceSegment < 3) {
    o.segment = buildGoogleCloudVideointelligenceV1p1beta1VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1FaceSegment(
    api.GoogleCloudVideointelligenceV1p1beta1FaceSegment o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1FaceSegment < 3) {
    checkGoogleCloudVideointelligenceV1p1beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p1beta1VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1FaceSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1Entity> buildUnnamed443() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1Entity>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1Entity());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1Entity());
  return o;
}

void checkUnnamed443(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1Entity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1Entity(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1Entity);
  checkGoogleCloudVideointelligenceV1p1beta1Entity(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1Entity);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1LabelFrame>
    buildUnnamed444() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1LabelFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LabelFrame());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LabelFrame());
  return o;
}

void checkUnnamed444(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1LabelFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1LabelFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1LabelFrame);
  checkGoogleCloudVideointelligenceV1p1beta1LabelFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1LabelFrame);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1LabelSegment>
    buildUnnamed445() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1LabelSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LabelSegment());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LabelSegment());
  return o;
}

void checkUnnamed445(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1LabelSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1LabelSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1LabelSegment);
  checkGoogleCloudVideointelligenceV1p1beta1LabelSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1LabelSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1LabelAnnotation = 0;
api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation
    buildGoogleCloudVideointelligenceV1p1beta1LabelAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p1beta1LabelAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1LabelAnnotation < 3) {
    o.categoryEntities = buildUnnamed443();
    o.entity = buildGoogleCloudVideointelligenceV1p1beta1Entity();
    o.frames = buildUnnamed444();
    o.segments = buildUnnamed445();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1LabelAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1LabelAnnotation(
    api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1LabelAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1LabelAnnotation < 3) {
    checkUnnamed443(o.categoryEntities!);
    checkGoogleCloudVideointelligenceV1p1beta1Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1p1beta1Entity);
    checkUnnamed444(o.frames!);
    checkUnnamed445(o.segments!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1LabelAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1LabelFrame = 0;
api.GoogleCloudVideointelligenceV1p1beta1LabelFrame
    buildGoogleCloudVideointelligenceV1p1beta1LabelFrame() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1LabelFrame();
  buildCounterGoogleCloudVideointelligenceV1p1beta1LabelFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1LabelFrame < 3) {
    o.confidence = 42.0;
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1LabelFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1LabelFrame(
    api.GoogleCloudVideointelligenceV1p1beta1LabelFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1LabelFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1LabelFrame < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1LabelFrame--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1LabelSegment = 0;
api.GoogleCloudVideointelligenceV1p1beta1LabelSegment
    buildGoogleCloudVideointelligenceV1p1beta1LabelSegment() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1LabelSegment();
  buildCounterGoogleCloudVideointelligenceV1p1beta1LabelSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1LabelSegment < 3) {
    o.confidence = 42.0;
    o.segment = buildGoogleCloudVideointelligenceV1p1beta1VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1LabelSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1LabelSegment(
    api.GoogleCloudVideointelligenceV1p1beta1LabelSegment o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1LabelSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1LabelSegment < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1p1beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p1beta1VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1LabelSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1VideoSegment>
    buildUnnamed446() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1VideoSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1VideoSegment());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1VideoSegment());
  return o;
}

void checkUnnamed446(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1VideoSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1VideoSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1VideoSegment);
  checkGoogleCloudVideointelligenceV1p1beta1VideoSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1VideoSegment);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1Track> buildUnnamed447() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1Track>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1Track());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1Track());
  return o;
}

void checkUnnamed447(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1Track(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1Track);
  checkGoogleCloudVideointelligenceV1p1beta1Track(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1Track);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation
    buildGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation <
      3) {
    o.entity = buildGoogleCloudVideointelligenceV1p1beta1Entity();
    o.segments = buildUnnamed446();
    o.tracks = buildUnnamed447();
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation(
    api.GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation <
      3) {
    checkGoogleCloudVideointelligenceV1p1beta1Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1p1beta1Entity);
    checkUnnamed446(o.segments!);
    checkUnnamed447(o.tracks!);
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation--;
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox = 0;
api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox
    buildGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox();
  buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox <
      3) {
    o.bottom = 42.0;
    o.left = 42.0;
    o.right = 42.0;
    o.top = 42.0;
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox(
    api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox <
      3) {
    unittest.expect(
      o.bottom!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.left!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.right!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.top!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1NormalizedVertex>
    buildUnnamed448() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1NormalizedVertex>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1NormalizedVertex());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1NormalizedVertex());
  return o;
}

void checkUnnamed448(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1NormalizedVertex> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1NormalizedVertex(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1NormalizedVertex);
  checkGoogleCloudVideointelligenceV1p1beta1NormalizedVertex(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1NormalizedVertex);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly = 0;
api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly
    buildGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly();
  buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly <
      3) {
    o.vertices = buildUnnamed448();
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly(
    api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly <
      3) {
    checkUnnamed448(o.vertices!);
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedVertex = 0;
api.GoogleCloudVideointelligenceV1p1beta1NormalizedVertex
    buildGoogleCloudVideointelligenceV1p1beta1NormalizedVertex() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1NormalizedVertex();
  buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedVertex++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedVertex < 3) {
    o.x = 42.0;
    o.y = 42.0;
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedVertex--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1NormalizedVertex(
    api.GoogleCloudVideointelligenceV1p1beta1NormalizedVertex o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedVertex++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedVertex < 3) {
    unittest.expect(
      o.x!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.y!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1NormalizedVertex--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame>
    buildUnnamed449() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame());
  return o;
}

void checkUnnamed449(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame);
  checkGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation
    buildGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation <
      3) {
    o.confidence = 42.0;
    o.entity = buildGoogleCloudVideointelligenceV1p1beta1Entity();
    o.frames = buildUnnamed449();
    o.segment = buildGoogleCloudVideointelligenceV1p1beta1VideoSegment();
    o.trackId = 'foo';
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation(
    api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation <
      3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1p1beta1Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1p1beta1Entity);
    checkUnnamed449(o.frames!);
    checkGoogleCloudVideointelligenceV1p1beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p1beta1VideoSegment);
    unittest.expect(
      o.trackId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame =
    0;
api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame
    buildGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame();
  buildCounterGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame <
      3) {
    o.normalizedBoundingBox =
        buildGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame(
    api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame <
      3) {
    checkGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox(
        o.normalizedBoundingBox!
            as api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1Track> buildUnnamed450() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1Track>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1Track());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1Track());
  return o;
}

void checkUnnamed450(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1Track(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1Track);
  checkGoogleCloudVideointelligenceV1p1beta1Track(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1Track);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation
    buildGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation <
      3) {
    o.tracks = buildUnnamed450();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation(
    api.GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation <
      3) {
    checkUnnamed450(o.tracks!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1WordInfo> buildUnnamed451() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1WordInfo>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1WordInfo());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1WordInfo());
  return o;
}

void checkUnnamed451(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1WordInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1WordInfo(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1WordInfo);
  checkGoogleCloudVideointelligenceV1p1beta1WordInfo(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1WordInfo);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative =
    0;
api.GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative
    buildGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative() {
  var o =
      api.GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative();
  buildCounterGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative <
      3) {
    o.confidence = 42.0;
    o.transcript = 'foo';
    o.words = buildUnnamed451();
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative(
    api.GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative <
      3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.transcript!,
      unittest.equals('foo'),
    );
    checkUnnamed451(o.words!);
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative>
    buildUnnamed452() {
  var o =
      <api.GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative>[];
  o.add(
      buildGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative());
  o.add(
      buildGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative());
  return o;
}

void checkUnnamed452(
    core.List<
            api.GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative(o[0]
      as api.GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative);
  checkGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative(o[1]
      as api.GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative);
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1SpeechTranscription =
    0;
api.GoogleCloudVideointelligenceV1p1beta1SpeechTranscription
    buildGoogleCloudVideointelligenceV1p1beta1SpeechTranscription() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1SpeechTranscription();
  buildCounterGoogleCloudVideointelligenceV1p1beta1SpeechTranscription++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1SpeechTranscription <
      3) {
    o.alternatives = buildUnnamed452();
    o.languageCode = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1SpeechTranscription--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1SpeechTranscription(
    api.GoogleCloudVideointelligenceV1p1beta1SpeechTranscription o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1SpeechTranscription++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1SpeechTranscription <
      3) {
    checkUnnamed452(o.alternatives!);
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1SpeechTranscription--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1TextSegment>
    buildUnnamed453() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1TextSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1TextSegment());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1TextSegment());
  return o;
}

void checkUnnamed453(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1TextSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1TextSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1TextSegment);
  checkGoogleCloudVideointelligenceV1p1beta1TextSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1TextSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1TextAnnotation = 0;
api.GoogleCloudVideointelligenceV1p1beta1TextAnnotation
    buildGoogleCloudVideointelligenceV1p1beta1TextAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1TextAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p1beta1TextAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1TextAnnotation < 3) {
    o.segments = buildUnnamed453();
    o.text = 'foo';
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1TextAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1TextAnnotation(
    api.GoogleCloudVideointelligenceV1p1beta1TextAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1TextAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1TextAnnotation < 3) {
    checkUnnamed453(o.segments!);
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1TextAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1TextFrame = 0;
api.GoogleCloudVideointelligenceV1p1beta1TextFrame
    buildGoogleCloudVideointelligenceV1p1beta1TextFrame() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1TextFrame();
  buildCounterGoogleCloudVideointelligenceV1p1beta1TextFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1TextFrame < 3) {
    o.rotatedBoundingBox =
        buildGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1TextFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1TextFrame(
    api.GoogleCloudVideointelligenceV1p1beta1TextFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1TextFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1TextFrame < 3) {
    checkGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly(
        o.rotatedBoundingBox!
            as api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1TextFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1TextFrame>
    buildUnnamed454() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1TextFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1TextFrame());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1TextFrame());
  return o;
}

void checkUnnamed454(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1TextFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1TextFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1TextFrame);
  checkGoogleCloudVideointelligenceV1p1beta1TextFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1TextFrame);
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1TextSegment = 0;
api.GoogleCloudVideointelligenceV1p1beta1TextSegment
    buildGoogleCloudVideointelligenceV1p1beta1TextSegment() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1TextSegment();
  buildCounterGoogleCloudVideointelligenceV1p1beta1TextSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1TextSegment < 3) {
    o.confidence = 42.0;
    o.frames = buildUnnamed454();
    o.segment = buildGoogleCloudVideointelligenceV1p1beta1VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1TextSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1TextSegment(
    api.GoogleCloudVideointelligenceV1p1beta1TextSegment o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1TextSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1TextSegment < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkUnnamed454(o.frames!);
    checkGoogleCloudVideointelligenceV1p1beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p1beta1VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1TextSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute>
    buildUnnamed455() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1DetectedAttribute());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1DetectedAttribute());
  return o;
}

void checkUnnamed455(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1DetectedAttribute(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute);
  checkGoogleCloudVideointelligenceV1p1beta1DetectedAttribute(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1DetectedLandmark>
    buildUnnamed456() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1DetectedLandmark>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1DetectedLandmark());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1DetectedLandmark());
  return o;
}

void checkUnnamed456(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1DetectedLandmark> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1DetectedLandmark(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1DetectedLandmark);
  checkGoogleCloudVideointelligenceV1p1beta1DetectedLandmark(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1DetectedLandmark);
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1TimestampedObject = 0;
api.GoogleCloudVideointelligenceV1p1beta1TimestampedObject
    buildGoogleCloudVideointelligenceV1p1beta1TimestampedObject() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1TimestampedObject();
  buildCounterGoogleCloudVideointelligenceV1p1beta1TimestampedObject++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1TimestampedObject < 3) {
    o.attributes = buildUnnamed455();
    o.landmarks = buildUnnamed456();
    o.normalizedBoundingBox =
        buildGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1TimestampedObject--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1TimestampedObject(
    api.GoogleCloudVideointelligenceV1p1beta1TimestampedObject o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1TimestampedObject++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1TimestampedObject < 3) {
    checkUnnamed455(o.attributes!);
    checkUnnamed456(o.landmarks!);
    checkGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox(
        o.normalizedBoundingBox!
            as api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1TimestampedObject--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute>
    buildUnnamed457() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1DetectedAttribute());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1DetectedAttribute());
  return o;
}

void checkUnnamed457(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1DetectedAttribute(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute);
  checkGoogleCloudVideointelligenceV1p1beta1DetectedAttribute(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1TimestampedObject>
    buildUnnamed458() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1TimestampedObject>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1TimestampedObject());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1TimestampedObject());
  return o;
}

void checkUnnamed458(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1TimestampedObject> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1TimestampedObject(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1TimestampedObject);
  checkGoogleCloudVideointelligenceV1p1beta1TimestampedObject(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1TimestampedObject);
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1Track = 0;
api.GoogleCloudVideointelligenceV1p1beta1Track
    buildGoogleCloudVideointelligenceV1p1beta1Track() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1Track();
  buildCounterGoogleCloudVideointelligenceV1p1beta1Track++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1Track < 3) {
    o.attributes = buildUnnamed457();
    o.confidence = 42.0;
    o.segment = buildGoogleCloudVideointelligenceV1p1beta1VideoSegment();
    o.timestampedObjects = buildUnnamed458();
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1Track--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1Track(
    api.GoogleCloudVideointelligenceV1p1beta1Track o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1Track++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1Track < 3) {
    checkUnnamed457(o.attributes!);
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1p1beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p1beta1VideoSegment);
    checkUnnamed458(o.timestampedObjects!);
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1Track--;
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress =
    0;
api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress
    buildGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress();
  buildCounterGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress <
      3) {
    o.feature = 'foo';
    o.inputUri = 'foo';
    o.progressPercent = 42;
    o.segment = buildGoogleCloudVideointelligenceV1p1beta1VideoSegment();
    o.startTime = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress(
    api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress <
      3) {
    unittest.expect(
      o.feature!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inputUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.progressPercent!,
      unittest.equals(42),
    );
    checkGoogleCloudVideointelligenceV1p1beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p1beta1VideoSegment);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress--;
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1FaceAnnotation>
    buildUnnamed459() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1FaceAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1FaceAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1FaceAnnotation());
  return o;
}

void checkUnnamed459(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1FaceAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1FaceAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1FaceAnnotation);
  checkGoogleCloudVideointelligenceV1p1beta1FaceAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1FaceAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation>
    buildUnnamed460() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation());
  return o;
}

void checkUnnamed460(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation);
  checkGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>
    buildUnnamed461() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LabelAnnotation());
  return o;
}

void checkUnnamed461(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p1beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation>
    buildUnnamed462() {
  var o =
      <api.GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation());
  return o;
}

void checkUnnamed462(
    core.List<
            api.GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation(o[0]
      as api.GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation);
  checkGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation(o[1]
      as api.GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation>
    buildUnnamed463() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation());
  return o;
}

void checkUnnamed463(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation(o[0]
      as api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation);
  checkGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation(o[1]
      as api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation>
    buildUnnamed464() {
  var o =
      <api.GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation());
  return o;
}

void checkUnnamed464(
    core.List<
            api.GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation(o[0]
      as api.GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation);
  checkGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation(o[1]
      as api.GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>
    buildUnnamed465() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LabelAnnotation());
  return o;
}

void checkUnnamed465(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p1beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>
    buildUnnamed466() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LabelAnnotation());
  return o;
}

void checkUnnamed466(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p1beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1VideoSegment>
    buildUnnamed467() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1VideoSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1VideoSegment());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1VideoSegment());
  return o;
}

void checkUnnamed467(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1VideoSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1VideoSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1VideoSegment);
  checkGoogleCloudVideointelligenceV1p1beta1VideoSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1VideoSegment);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>
    buildUnnamed468() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LabelAnnotation());
  return o;
}

void checkUnnamed468(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p1beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>
    buildUnnamed469() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1LabelAnnotation());
  return o;
}

void checkUnnamed469(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p1beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1SpeechTranscription>
    buildUnnamed470() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1SpeechTranscription>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1SpeechTranscription());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1SpeechTranscription());
  return o;
}

void checkUnnamed470(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1SpeechTranscription> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1SpeechTranscription(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1SpeechTranscription);
  checkGoogleCloudVideointelligenceV1p1beta1SpeechTranscription(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1SpeechTranscription);
}

core.List<api.GoogleCloudVideointelligenceV1p1beta1TextAnnotation>
    buildUnnamed471() {
  var o = <api.GoogleCloudVideointelligenceV1p1beta1TextAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p1beta1TextAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p1beta1TextAnnotation());
  return o;
}

void checkUnnamed471(
    core.List<api.GoogleCloudVideointelligenceV1p1beta1TextAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p1beta1TextAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p1beta1TextAnnotation);
  checkGoogleCloudVideointelligenceV1p1beta1TextAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p1beta1TextAnnotation);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults = 0;
api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults
    buildGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults();
  buildCounterGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults <
      3) {
    o.error = buildGoogleRpcStatus();
    o.explicitAnnotation =
        buildGoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation();
    o.faceAnnotations = buildUnnamed459();
    o.faceDetectionAnnotations = buildUnnamed460();
    o.frameLabelAnnotations = buildUnnamed461();
    o.inputUri = 'foo';
    o.logoRecognitionAnnotations = buildUnnamed462();
    o.objectAnnotations = buildUnnamed463();
    o.personDetectionAnnotations = buildUnnamed464();
    o.segment = buildGoogleCloudVideointelligenceV1p1beta1VideoSegment();
    o.segmentLabelAnnotations = buildUnnamed465();
    o.segmentPresenceLabelAnnotations = buildUnnamed466();
    o.shotAnnotations = buildUnnamed467();
    o.shotLabelAnnotations = buildUnnamed468();
    o.shotPresenceLabelAnnotations = buildUnnamed469();
    o.speechTranscriptions = buildUnnamed470();
    o.textAnnotations = buildUnnamed471();
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults(
    api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults <
      3) {
    checkGoogleRpcStatus(o.error! as api.GoogleRpcStatus);
    checkGoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation(o
            .explicitAnnotation!
        as api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation);
    checkUnnamed459(o.faceAnnotations!);
    checkUnnamed460(o.faceDetectionAnnotations!);
    checkUnnamed461(o.frameLabelAnnotations!);
    unittest.expect(
      o.inputUri!,
      unittest.equals('foo'),
    );
    checkUnnamed462(o.logoRecognitionAnnotations!);
    checkUnnamed463(o.objectAnnotations!);
    checkUnnamed464(o.personDetectionAnnotations!);
    checkGoogleCloudVideointelligenceV1p1beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p1beta1VideoSegment);
    checkUnnamed465(o.segmentLabelAnnotations!);
    checkUnnamed466(o.segmentPresenceLabelAnnotations!);
    checkUnnamed467(o.shotAnnotations!);
    checkUnnamed468(o.shotLabelAnnotations!);
    checkUnnamed469(o.shotPresenceLabelAnnotations!);
    checkUnnamed470(o.speechTranscriptions!);
    checkUnnamed471(o.textAnnotations!);
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1VideoSegment = 0;
api.GoogleCloudVideointelligenceV1p1beta1VideoSegment
    buildGoogleCloudVideointelligenceV1p1beta1VideoSegment() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1VideoSegment();
  buildCounterGoogleCloudVideointelligenceV1p1beta1VideoSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1VideoSegment < 3) {
    o.endTimeOffset = 'foo';
    o.startTimeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1VideoSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1VideoSegment(
    api.GoogleCloudVideointelligenceV1p1beta1VideoSegment o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1VideoSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1VideoSegment < 3) {
    unittest.expect(
      o.endTimeOffset!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTimeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1VideoSegment--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p1beta1WordInfo = 0;
api.GoogleCloudVideointelligenceV1p1beta1WordInfo
    buildGoogleCloudVideointelligenceV1p1beta1WordInfo() {
  var o = api.GoogleCloudVideointelligenceV1p1beta1WordInfo();
  buildCounterGoogleCloudVideointelligenceV1p1beta1WordInfo++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1WordInfo < 3) {
    o.confidence = 42.0;
    o.endTime = 'foo';
    o.speakerTag = 42;
    o.startTime = 'foo';
    o.word = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1WordInfo--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p1beta1WordInfo(
    api.GoogleCloudVideointelligenceV1p1beta1WordInfo o) {
  buildCounterGoogleCloudVideointelligenceV1p1beta1WordInfo++;
  if (buildCounterGoogleCloudVideointelligenceV1p1beta1WordInfo < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.speakerTag!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.word!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p1beta1WordInfo--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress>
    buildUnnamed472() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress());
  return o;
}

void checkUnnamed472(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress);
  checkGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress = 0;
api.GoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress
    buildGoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress();
  buildCounterGoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress <
      3) {
    o.annotationProgress = buildUnnamed472();
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress(
    api.GoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress <
      3) {
    checkUnnamed472(o.annotationProgress!);
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults>
    buildUnnamed473() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults());
  return o;
}

void checkUnnamed473(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults);
  checkGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse = 0;
api.GoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse
    buildGoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse();
  buildCounterGoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse <
      3) {
    o.annotationResults = buildUnnamed473();
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse(
    api.GoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse <
      3) {
    checkUnnamed473(o.annotationResults!);
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1DetectedAttribute = 0;
api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute
    buildGoogleCloudVideointelligenceV1p2beta1DetectedAttribute() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute();
  buildCounterGoogleCloudVideointelligenceV1p2beta1DetectedAttribute++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1DetectedAttribute < 3) {
    o.confidence = 42.0;
    o.name = 'foo';
    o.value = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1DetectedAttribute--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1DetectedAttribute(
    api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1DetectedAttribute++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1DetectedAttribute < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1DetectedAttribute--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1DetectedLandmark = 0;
api.GoogleCloudVideointelligenceV1p2beta1DetectedLandmark
    buildGoogleCloudVideointelligenceV1p2beta1DetectedLandmark() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1DetectedLandmark();
  buildCounterGoogleCloudVideointelligenceV1p2beta1DetectedLandmark++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1DetectedLandmark < 3) {
    o.confidence = 42.0;
    o.name = 'foo';
    o.point = buildGoogleCloudVideointelligenceV1p2beta1NormalizedVertex();
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1DetectedLandmark--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1DetectedLandmark(
    api.GoogleCloudVideointelligenceV1p2beta1DetectedLandmark o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1DetectedLandmark++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1DetectedLandmark < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkGoogleCloudVideointelligenceV1p2beta1NormalizedVertex(
        o.point! as api.GoogleCloudVideointelligenceV1p2beta1NormalizedVertex);
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1DetectedLandmark--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1Entity = 0;
api.GoogleCloudVideointelligenceV1p2beta1Entity
    buildGoogleCloudVideointelligenceV1p2beta1Entity() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1Entity();
  buildCounterGoogleCloudVideointelligenceV1p2beta1Entity++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1Entity < 3) {
    o.description = 'foo';
    o.entityId = 'foo';
    o.languageCode = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1Entity--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1Entity(
    api.GoogleCloudVideointelligenceV1p2beta1Entity o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1Entity++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1Entity < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1Entity--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame>
    buildUnnamed474() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame());
  return o;
}

void checkUnnamed474(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame);
  checkGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation
    buildGoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation <
      3) {
    o.frames = buildUnnamed474();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation(
    api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation <
      3) {
    checkUnnamed474(o.frames!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame =
    0;
api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame
    buildGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame();
  buildCounterGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame <
      3) {
    o.pornographyLikelihood = 'foo';
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame(
    api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame <
      3) {
    unittest.expect(
      o.pornographyLikelihood!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1FaceFrame>
    buildUnnamed475() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1FaceFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1FaceFrame());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1FaceFrame());
  return o;
}

void checkUnnamed475(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1FaceFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1FaceFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1FaceFrame);
  checkGoogleCloudVideointelligenceV1p2beta1FaceFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1FaceFrame);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1FaceSegment>
    buildUnnamed476() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1FaceSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1FaceSegment());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1FaceSegment());
  return o;
}

void checkUnnamed476(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1FaceSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1FaceSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1FaceSegment);
  checkGoogleCloudVideointelligenceV1p2beta1FaceSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1FaceSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1FaceAnnotation = 0;
api.GoogleCloudVideointelligenceV1p2beta1FaceAnnotation
    buildGoogleCloudVideointelligenceV1p2beta1FaceAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1FaceAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1FaceAnnotation < 3) {
    o.frames = buildUnnamed475();
    o.segments = buildUnnamed476();
    o.thumbnail = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1FaceAnnotation(
    api.GoogleCloudVideointelligenceV1p2beta1FaceAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1FaceAnnotation < 3) {
    checkUnnamed475(o.frames!);
    checkUnnamed476(o.segments!);
    unittest.expect(
      o.thumbnail!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceAnnotation--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1Track> buildUnnamed477() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1Track>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1Track());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1Track());
  return o;
}

void checkUnnamed477(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1Track(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1Track);
  checkGoogleCloudVideointelligenceV1p2beta1Track(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1Track);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation
    buildGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation <
      3) {
    o.thumbnail = 'foo';
    o.tracks = buildUnnamed477();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation(
    api.GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation <
      3) {
    unittest.expect(
      o.thumbnail!,
      unittest.equals('foo'),
    );
    checkUnnamed477(o.tracks!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox>
    buildUnnamed478() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox());
  return o;
}

void checkUnnamed478(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox);
  checkGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox);
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1FaceFrame = 0;
api.GoogleCloudVideointelligenceV1p2beta1FaceFrame
    buildGoogleCloudVideointelligenceV1p2beta1FaceFrame() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1FaceFrame();
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1FaceFrame < 3) {
    o.normalizedBoundingBoxes = buildUnnamed478();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1FaceFrame(
    api.GoogleCloudVideointelligenceV1p2beta1FaceFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1FaceFrame < 3) {
    checkUnnamed478(o.normalizedBoundingBoxes!);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceFrame--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1FaceSegment = 0;
api.GoogleCloudVideointelligenceV1p2beta1FaceSegment
    buildGoogleCloudVideointelligenceV1p2beta1FaceSegment() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1FaceSegment();
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1FaceSegment < 3) {
    o.segment = buildGoogleCloudVideointelligenceV1p2beta1VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1FaceSegment(
    api.GoogleCloudVideointelligenceV1p2beta1FaceSegment o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1FaceSegment < 3) {
    checkGoogleCloudVideointelligenceV1p2beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p2beta1VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1FaceSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1Entity> buildUnnamed479() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1Entity>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1Entity());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1Entity());
  return o;
}

void checkUnnamed479(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1Entity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1Entity(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1Entity);
  checkGoogleCloudVideointelligenceV1p2beta1Entity(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1Entity);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1LabelFrame>
    buildUnnamed480() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1LabelFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LabelFrame());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LabelFrame());
  return o;
}

void checkUnnamed480(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1LabelFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1LabelFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1LabelFrame);
  checkGoogleCloudVideointelligenceV1p2beta1LabelFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1LabelFrame);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1LabelSegment>
    buildUnnamed481() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1LabelSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LabelSegment());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LabelSegment());
  return o;
}

void checkUnnamed481(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1LabelSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1LabelSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1LabelSegment);
  checkGoogleCloudVideointelligenceV1p2beta1LabelSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1LabelSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1LabelAnnotation = 0;
api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation
    buildGoogleCloudVideointelligenceV1p2beta1LabelAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p2beta1LabelAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1LabelAnnotation < 3) {
    o.categoryEntities = buildUnnamed479();
    o.entity = buildGoogleCloudVideointelligenceV1p2beta1Entity();
    o.frames = buildUnnamed480();
    o.segments = buildUnnamed481();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1LabelAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1LabelAnnotation(
    api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1LabelAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1LabelAnnotation < 3) {
    checkUnnamed479(o.categoryEntities!);
    checkGoogleCloudVideointelligenceV1p2beta1Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1p2beta1Entity);
    checkUnnamed480(o.frames!);
    checkUnnamed481(o.segments!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1LabelAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1LabelFrame = 0;
api.GoogleCloudVideointelligenceV1p2beta1LabelFrame
    buildGoogleCloudVideointelligenceV1p2beta1LabelFrame() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1LabelFrame();
  buildCounterGoogleCloudVideointelligenceV1p2beta1LabelFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1LabelFrame < 3) {
    o.confidence = 42.0;
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1LabelFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1LabelFrame(
    api.GoogleCloudVideointelligenceV1p2beta1LabelFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1LabelFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1LabelFrame < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1LabelFrame--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1LabelSegment = 0;
api.GoogleCloudVideointelligenceV1p2beta1LabelSegment
    buildGoogleCloudVideointelligenceV1p2beta1LabelSegment() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1LabelSegment();
  buildCounterGoogleCloudVideointelligenceV1p2beta1LabelSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1LabelSegment < 3) {
    o.confidence = 42.0;
    o.segment = buildGoogleCloudVideointelligenceV1p2beta1VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1LabelSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1LabelSegment(
    api.GoogleCloudVideointelligenceV1p2beta1LabelSegment o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1LabelSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1LabelSegment < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1p2beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p2beta1VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1LabelSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1VideoSegment>
    buildUnnamed482() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1VideoSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1VideoSegment());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1VideoSegment());
  return o;
}

void checkUnnamed482(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1VideoSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1VideoSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1VideoSegment);
  checkGoogleCloudVideointelligenceV1p2beta1VideoSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1VideoSegment);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1Track> buildUnnamed483() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1Track>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1Track());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1Track());
  return o;
}

void checkUnnamed483(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1Track(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1Track);
  checkGoogleCloudVideointelligenceV1p2beta1Track(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1Track);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation
    buildGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation <
      3) {
    o.entity = buildGoogleCloudVideointelligenceV1p2beta1Entity();
    o.segments = buildUnnamed482();
    o.tracks = buildUnnamed483();
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation(
    api.GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation <
      3) {
    checkGoogleCloudVideointelligenceV1p2beta1Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1p2beta1Entity);
    checkUnnamed482(o.segments!);
    checkUnnamed483(o.tracks!);
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation--;
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox = 0;
api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox
    buildGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox();
  buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox <
      3) {
    o.bottom = 42.0;
    o.left = 42.0;
    o.right = 42.0;
    o.top = 42.0;
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox(
    api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox <
      3) {
    unittest.expect(
      o.bottom!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.left!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.right!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.top!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1NormalizedVertex>
    buildUnnamed484() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1NormalizedVertex>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1NormalizedVertex());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1NormalizedVertex());
  return o;
}

void checkUnnamed484(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1NormalizedVertex> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1NormalizedVertex(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1NormalizedVertex);
  checkGoogleCloudVideointelligenceV1p2beta1NormalizedVertex(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1NormalizedVertex);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly = 0;
api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly
    buildGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly();
  buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly <
      3) {
    o.vertices = buildUnnamed484();
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly(
    api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly <
      3) {
    checkUnnamed484(o.vertices!);
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedVertex = 0;
api.GoogleCloudVideointelligenceV1p2beta1NormalizedVertex
    buildGoogleCloudVideointelligenceV1p2beta1NormalizedVertex() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1NormalizedVertex();
  buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedVertex++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedVertex < 3) {
    o.x = 42.0;
    o.y = 42.0;
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedVertex--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1NormalizedVertex(
    api.GoogleCloudVideointelligenceV1p2beta1NormalizedVertex o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedVertex++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedVertex < 3) {
    unittest.expect(
      o.x!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.y!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1NormalizedVertex--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame>
    buildUnnamed485() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame());
  return o;
}

void checkUnnamed485(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame);
  checkGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation
    buildGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation <
      3) {
    o.confidence = 42.0;
    o.entity = buildGoogleCloudVideointelligenceV1p2beta1Entity();
    o.frames = buildUnnamed485();
    o.segment = buildGoogleCloudVideointelligenceV1p2beta1VideoSegment();
    o.trackId = 'foo';
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation(
    api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation <
      3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1p2beta1Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1p2beta1Entity);
    checkUnnamed485(o.frames!);
    checkGoogleCloudVideointelligenceV1p2beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p2beta1VideoSegment);
    unittest.expect(
      o.trackId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame =
    0;
api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame
    buildGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame();
  buildCounterGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame <
      3) {
    o.normalizedBoundingBox =
        buildGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame(
    api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame <
      3) {
    checkGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox(
        o.normalizedBoundingBox!
            as api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1Track> buildUnnamed486() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1Track>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1Track());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1Track());
  return o;
}

void checkUnnamed486(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1Track(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1Track);
  checkGoogleCloudVideointelligenceV1p2beta1Track(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1Track);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation
    buildGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation <
      3) {
    o.tracks = buildUnnamed486();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation(
    api.GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation <
      3) {
    checkUnnamed486(o.tracks!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1WordInfo> buildUnnamed487() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1WordInfo>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1WordInfo());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1WordInfo());
  return o;
}

void checkUnnamed487(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1WordInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1WordInfo(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1WordInfo);
  checkGoogleCloudVideointelligenceV1p2beta1WordInfo(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1WordInfo);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative =
    0;
api.GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative
    buildGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative() {
  var o =
      api.GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative();
  buildCounterGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative <
      3) {
    o.confidence = 42.0;
    o.transcript = 'foo';
    o.words = buildUnnamed487();
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative(
    api.GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative <
      3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.transcript!,
      unittest.equals('foo'),
    );
    checkUnnamed487(o.words!);
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative>
    buildUnnamed488() {
  var o =
      <api.GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative>[];
  o.add(
      buildGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative());
  o.add(
      buildGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative());
  return o;
}

void checkUnnamed488(
    core.List<
            api.GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative(o[0]
      as api.GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative);
  checkGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative(o[1]
      as api.GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative);
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1SpeechTranscription =
    0;
api.GoogleCloudVideointelligenceV1p2beta1SpeechTranscription
    buildGoogleCloudVideointelligenceV1p2beta1SpeechTranscription() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1SpeechTranscription();
  buildCounterGoogleCloudVideointelligenceV1p2beta1SpeechTranscription++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1SpeechTranscription <
      3) {
    o.alternatives = buildUnnamed488();
    o.languageCode = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1SpeechTranscription--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1SpeechTranscription(
    api.GoogleCloudVideointelligenceV1p2beta1SpeechTranscription o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1SpeechTranscription++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1SpeechTranscription <
      3) {
    checkUnnamed488(o.alternatives!);
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1SpeechTranscription--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1TextSegment>
    buildUnnamed489() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1TextSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1TextSegment());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1TextSegment());
  return o;
}

void checkUnnamed489(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1TextSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1TextSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1TextSegment);
  checkGoogleCloudVideointelligenceV1p2beta1TextSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1TextSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1TextAnnotation = 0;
api.GoogleCloudVideointelligenceV1p2beta1TextAnnotation
    buildGoogleCloudVideointelligenceV1p2beta1TextAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1TextAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p2beta1TextAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1TextAnnotation < 3) {
    o.segments = buildUnnamed489();
    o.text = 'foo';
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1TextAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1TextAnnotation(
    api.GoogleCloudVideointelligenceV1p2beta1TextAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1TextAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1TextAnnotation < 3) {
    checkUnnamed489(o.segments!);
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1TextAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1TextFrame = 0;
api.GoogleCloudVideointelligenceV1p2beta1TextFrame
    buildGoogleCloudVideointelligenceV1p2beta1TextFrame() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1TextFrame();
  buildCounterGoogleCloudVideointelligenceV1p2beta1TextFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1TextFrame < 3) {
    o.rotatedBoundingBox =
        buildGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1TextFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1TextFrame(
    api.GoogleCloudVideointelligenceV1p2beta1TextFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1TextFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1TextFrame < 3) {
    checkGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly(
        o.rotatedBoundingBox!
            as api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1TextFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1TextFrame>
    buildUnnamed490() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1TextFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1TextFrame());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1TextFrame());
  return o;
}

void checkUnnamed490(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1TextFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1TextFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1TextFrame);
  checkGoogleCloudVideointelligenceV1p2beta1TextFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1TextFrame);
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1TextSegment = 0;
api.GoogleCloudVideointelligenceV1p2beta1TextSegment
    buildGoogleCloudVideointelligenceV1p2beta1TextSegment() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1TextSegment();
  buildCounterGoogleCloudVideointelligenceV1p2beta1TextSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1TextSegment < 3) {
    o.confidence = 42.0;
    o.frames = buildUnnamed490();
    o.segment = buildGoogleCloudVideointelligenceV1p2beta1VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1TextSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1TextSegment(
    api.GoogleCloudVideointelligenceV1p2beta1TextSegment o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1TextSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1TextSegment < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkUnnamed490(o.frames!);
    checkGoogleCloudVideointelligenceV1p2beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p2beta1VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1TextSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute>
    buildUnnamed491() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1DetectedAttribute());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1DetectedAttribute());
  return o;
}

void checkUnnamed491(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1DetectedAttribute(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute);
  checkGoogleCloudVideointelligenceV1p2beta1DetectedAttribute(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1DetectedLandmark>
    buildUnnamed492() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1DetectedLandmark>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1DetectedLandmark());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1DetectedLandmark());
  return o;
}

void checkUnnamed492(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1DetectedLandmark> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1DetectedLandmark(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1DetectedLandmark);
  checkGoogleCloudVideointelligenceV1p2beta1DetectedLandmark(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1DetectedLandmark);
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1TimestampedObject = 0;
api.GoogleCloudVideointelligenceV1p2beta1TimestampedObject
    buildGoogleCloudVideointelligenceV1p2beta1TimestampedObject() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1TimestampedObject();
  buildCounterGoogleCloudVideointelligenceV1p2beta1TimestampedObject++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1TimestampedObject < 3) {
    o.attributes = buildUnnamed491();
    o.landmarks = buildUnnamed492();
    o.normalizedBoundingBox =
        buildGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1TimestampedObject--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1TimestampedObject(
    api.GoogleCloudVideointelligenceV1p2beta1TimestampedObject o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1TimestampedObject++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1TimestampedObject < 3) {
    checkUnnamed491(o.attributes!);
    checkUnnamed492(o.landmarks!);
    checkGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox(
        o.normalizedBoundingBox!
            as api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1TimestampedObject--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute>
    buildUnnamed493() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1DetectedAttribute());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1DetectedAttribute());
  return o;
}

void checkUnnamed493(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1DetectedAttribute(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute);
  checkGoogleCloudVideointelligenceV1p2beta1DetectedAttribute(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1TimestampedObject>
    buildUnnamed494() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1TimestampedObject>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1TimestampedObject());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1TimestampedObject());
  return o;
}

void checkUnnamed494(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1TimestampedObject> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1TimestampedObject(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1TimestampedObject);
  checkGoogleCloudVideointelligenceV1p2beta1TimestampedObject(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1TimestampedObject);
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1Track = 0;
api.GoogleCloudVideointelligenceV1p2beta1Track
    buildGoogleCloudVideointelligenceV1p2beta1Track() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1Track();
  buildCounterGoogleCloudVideointelligenceV1p2beta1Track++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1Track < 3) {
    o.attributes = buildUnnamed493();
    o.confidence = 42.0;
    o.segment = buildGoogleCloudVideointelligenceV1p2beta1VideoSegment();
    o.timestampedObjects = buildUnnamed494();
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1Track--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1Track(
    api.GoogleCloudVideointelligenceV1p2beta1Track o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1Track++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1Track < 3) {
    checkUnnamed493(o.attributes!);
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1p2beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p2beta1VideoSegment);
    checkUnnamed494(o.timestampedObjects!);
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1Track--;
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress =
    0;
api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress
    buildGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress();
  buildCounterGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress <
      3) {
    o.feature = 'foo';
    o.inputUri = 'foo';
    o.progressPercent = 42;
    o.segment = buildGoogleCloudVideointelligenceV1p2beta1VideoSegment();
    o.startTime = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress(
    api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress <
      3) {
    unittest.expect(
      o.feature!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inputUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.progressPercent!,
      unittest.equals(42),
    );
    checkGoogleCloudVideointelligenceV1p2beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p2beta1VideoSegment);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress--;
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1FaceAnnotation>
    buildUnnamed495() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1FaceAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1FaceAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1FaceAnnotation());
  return o;
}

void checkUnnamed495(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1FaceAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1FaceAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1FaceAnnotation);
  checkGoogleCloudVideointelligenceV1p2beta1FaceAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1FaceAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation>
    buildUnnamed496() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation());
  return o;
}

void checkUnnamed496(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation);
  checkGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>
    buildUnnamed497() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LabelAnnotation());
  return o;
}

void checkUnnamed497(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p2beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation>
    buildUnnamed498() {
  var o =
      <api.GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation());
  return o;
}

void checkUnnamed498(
    core.List<
            api.GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation(o[0]
      as api.GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation);
  checkGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation(o[1]
      as api.GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation>
    buildUnnamed499() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation());
  return o;
}

void checkUnnamed499(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation(o[0]
      as api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation);
  checkGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation(o[1]
      as api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation>
    buildUnnamed500() {
  var o =
      <api.GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation());
  return o;
}

void checkUnnamed500(
    core.List<
            api.GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation(o[0]
      as api.GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation);
  checkGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation(o[1]
      as api.GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>
    buildUnnamed501() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LabelAnnotation());
  return o;
}

void checkUnnamed501(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p2beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>
    buildUnnamed502() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LabelAnnotation());
  return o;
}

void checkUnnamed502(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p2beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1VideoSegment>
    buildUnnamed503() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1VideoSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1VideoSegment());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1VideoSegment());
  return o;
}

void checkUnnamed503(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1VideoSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1VideoSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1VideoSegment);
  checkGoogleCloudVideointelligenceV1p2beta1VideoSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1VideoSegment);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>
    buildUnnamed504() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LabelAnnotation());
  return o;
}

void checkUnnamed504(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p2beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>
    buildUnnamed505() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1LabelAnnotation());
  return o;
}

void checkUnnamed505(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p2beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1SpeechTranscription>
    buildUnnamed506() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1SpeechTranscription>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1SpeechTranscription());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1SpeechTranscription());
  return o;
}

void checkUnnamed506(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1SpeechTranscription> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1SpeechTranscription(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1SpeechTranscription);
  checkGoogleCloudVideointelligenceV1p2beta1SpeechTranscription(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1SpeechTranscription);
}

core.List<api.GoogleCloudVideointelligenceV1p2beta1TextAnnotation>
    buildUnnamed507() {
  var o = <api.GoogleCloudVideointelligenceV1p2beta1TextAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p2beta1TextAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p2beta1TextAnnotation());
  return o;
}

void checkUnnamed507(
    core.List<api.GoogleCloudVideointelligenceV1p2beta1TextAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p2beta1TextAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p2beta1TextAnnotation);
  checkGoogleCloudVideointelligenceV1p2beta1TextAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p2beta1TextAnnotation);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults = 0;
api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults
    buildGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults();
  buildCounterGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults <
      3) {
    o.error = buildGoogleRpcStatus();
    o.explicitAnnotation =
        buildGoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation();
    o.faceAnnotations = buildUnnamed495();
    o.faceDetectionAnnotations = buildUnnamed496();
    o.frameLabelAnnotations = buildUnnamed497();
    o.inputUri = 'foo';
    o.logoRecognitionAnnotations = buildUnnamed498();
    o.objectAnnotations = buildUnnamed499();
    o.personDetectionAnnotations = buildUnnamed500();
    o.segment = buildGoogleCloudVideointelligenceV1p2beta1VideoSegment();
    o.segmentLabelAnnotations = buildUnnamed501();
    o.segmentPresenceLabelAnnotations = buildUnnamed502();
    o.shotAnnotations = buildUnnamed503();
    o.shotLabelAnnotations = buildUnnamed504();
    o.shotPresenceLabelAnnotations = buildUnnamed505();
    o.speechTranscriptions = buildUnnamed506();
    o.textAnnotations = buildUnnamed507();
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults(
    api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults <
      3) {
    checkGoogleRpcStatus(o.error! as api.GoogleRpcStatus);
    checkGoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation(o
            .explicitAnnotation!
        as api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation);
    checkUnnamed495(o.faceAnnotations!);
    checkUnnamed496(o.faceDetectionAnnotations!);
    checkUnnamed497(o.frameLabelAnnotations!);
    unittest.expect(
      o.inputUri!,
      unittest.equals('foo'),
    );
    checkUnnamed498(o.logoRecognitionAnnotations!);
    checkUnnamed499(o.objectAnnotations!);
    checkUnnamed500(o.personDetectionAnnotations!);
    checkGoogleCloudVideointelligenceV1p2beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p2beta1VideoSegment);
    checkUnnamed501(o.segmentLabelAnnotations!);
    checkUnnamed502(o.segmentPresenceLabelAnnotations!);
    checkUnnamed503(o.shotAnnotations!);
    checkUnnamed504(o.shotLabelAnnotations!);
    checkUnnamed505(o.shotPresenceLabelAnnotations!);
    checkUnnamed506(o.speechTranscriptions!);
    checkUnnamed507(o.textAnnotations!);
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1VideoSegment = 0;
api.GoogleCloudVideointelligenceV1p2beta1VideoSegment
    buildGoogleCloudVideointelligenceV1p2beta1VideoSegment() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1VideoSegment();
  buildCounterGoogleCloudVideointelligenceV1p2beta1VideoSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1VideoSegment < 3) {
    o.endTimeOffset = 'foo';
    o.startTimeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1VideoSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1VideoSegment(
    api.GoogleCloudVideointelligenceV1p2beta1VideoSegment o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1VideoSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1VideoSegment < 3) {
    unittest.expect(
      o.endTimeOffset!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTimeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1VideoSegment--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p2beta1WordInfo = 0;
api.GoogleCloudVideointelligenceV1p2beta1WordInfo
    buildGoogleCloudVideointelligenceV1p2beta1WordInfo() {
  var o = api.GoogleCloudVideointelligenceV1p2beta1WordInfo();
  buildCounterGoogleCloudVideointelligenceV1p2beta1WordInfo++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1WordInfo < 3) {
    o.confidence = 42.0;
    o.endTime = 'foo';
    o.speakerTag = 42;
    o.startTime = 'foo';
    o.word = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1WordInfo--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p2beta1WordInfo(
    api.GoogleCloudVideointelligenceV1p2beta1WordInfo o) {
  buildCounterGoogleCloudVideointelligenceV1p2beta1WordInfo++;
  if (buildCounterGoogleCloudVideointelligenceV1p2beta1WordInfo < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.speakerTag!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.word!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p2beta1WordInfo--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress>
    buildUnnamed508() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress());
  return o;
}

void checkUnnamed508(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress);
  checkGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress = 0;
api.GoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress
    buildGoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress();
  buildCounterGoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress <
      3) {
    o.annotationProgress = buildUnnamed508();
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress(
    api.GoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress <
      3) {
    checkUnnamed508(o.annotationProgress!);
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults>
    buildUnnamed509() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults());
  return o;
}

void checkUnnamed509(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults);
  checkGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse = 0;
api.GoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse
    buildGoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse();
  buildCounterGoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse <
      3) {
    o.annotationResults = buildUnnamed509();
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse(
    api.GoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse <
      3) {
    checkUnnamed509(o.annotationResults!);
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1Celebrity = 0;
api.GoogleCloudVideointelligenceV1p3beta1Celebrity
    buildGoogleCloudVideointelligenceV1p3beta1Celebrity() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1Celebrity();
  buildCounterGoogleCloudVideointelligenceV1p3beta1Celebrity++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1Celebrity < 3) {
    o.description = 'foo';
    o.displayName = 'foo';
    o.name = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1Celebrity--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1Celebrity(
    api.GoogleCloudVideointelligenceV1p3beta1Celebrity o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1Celebrity++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1Celebrity < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1Celebrity--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1CelebrityTrack>
    buildUnnamed510() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1CelebrityTrack>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1CelebrityTrack());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1CelebrityTrack());
  return o;
}

void checkUnnamed510(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1CelebrityTrack> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1CelebrityTrack(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1CelebrityTrack);
  checkGoogleCloudVideointelligenceV1p3beta1CelebrityTrack(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1CelebrityTrack);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation
    buildGoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation() {
  var o =
      api.GoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation <
      3) {
    o.celebrityTracks = buildUnnamed510();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation(
    api.GoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation <
      3) {
    checkUnnamed510(o.celebrityTracks!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity>
    buildUnnamed511() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity());
  return o;
}

void checkUnnamed511(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity);
  checkGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity);
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1CelebrityTrack = 0;
api.GoogleCloudVideointelligenceV1p3beta1CelebrityTrack
    buildGoogleCloudVideointelligenceV1p3beta1CelebrityTrack() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1CelebrityTrack();
  buildCounterGoogleCloudVideointelligenceV1p3beta1CelebrityTrack++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1CelebrityTrack < 3) {
    o.celebrities = buildUnnamed511();
    o.faceTrack = buildGoogleCloudVideointelligenceV1p3beta1Track();
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1CelebrityTrack--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1CelebrityTrack(
    api.GoogleCloudVideointelligenceV1p3beta1CelebrityTrack o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1CelebrityTrack++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1CelebrityTrack < 3) {
    checkUnnamed511(o.celebrities!);
    checkGoogleCloudVideointelligenceV1p3beta1Track(
        o.faceTrack! as api.GoogleCloudVideointelligenceV1p3beta1Track);
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1CelebrityTrack--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1DetectedAttribute = 0;
api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute
    buildGoogleCloudVideointelligenceV1p3beta1DetectedAttribute() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute();
  buildCounterGoogleCloudVideointelligenceV1p3beta1DetectedAttribute++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1DetectedAttribute < 3) {
    o.confidence = 42.0;
    o.name = 'foo';
    o.value = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1DetectedAttribute--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1DetectedAttribute(
    api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1DetectedAttribute++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1DetectedAttribute < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1DetectedAttribute--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1DetectedLandmark = 0;
api.GoogleCloudVideointelligenceV1p3beta1DetectedLandmark
    buildGoogleCloudVideointelligenceV1p3beta1DetectedLandmark() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1DetectedLandmark();
  buildCounterGoogleCloudVideointelligenceV1p3beta1DetectedLandmark++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1DetectedLandmark < 3) {
    o.confidence = 42.0;
    o.name = 'foo';
    o.point = buildGoogleCloudVideointelligenceV1p3beta1NormalizedVertex();
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1DetectedLandmark--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1DetectedLandmark(
    api.GoogleCloudVideointelligenceV1p3beta1DetectedLandmark o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1DetectedLandmark++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1DetectedLandmark < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkGoogleCloudVideointelligenceV1p3beta1NormalizedVertex(
        o.point! as api.GoogleCloudVideointelligenceV1p3beta1NormalizedVertex);
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1DetectedLandmark--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1Entity = 0;
api.GoogleCloudVideointelligenceV1p3beta1Entity
    buildGoogleCloudVideointelligenceV1p3beta1Entity() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1Entity();
  buildCounterGoogleCloudVideointelligenceV1p3beta1Entity++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1Entity < 3) {
    o.description = 'foo';
    o.entityId = 'foo';
    o.languageCode = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1Entity--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1Entity(
    api.GoogleCloudVideointelligenceV1p3beta1Entity o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1Entity++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1Entity < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1Entity--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame>
    buildUnnamed512() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame());
  return o;
}

void checkUnnamed512(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame);
  checkGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation
    buildGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation <
      3) {
    o.frames = buildUnnamed512();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation(
    api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation <
      3) {
    checkUnnamed512(o.frames!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame =
    0;
api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame
    buildGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame();
  buildCounterGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame <
      3) {
    o.pornographyLikelihood = 'foo';
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame(
    api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame <
      3) {
    unittest.expect(
      o.pornographyLikelihood!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1FaceFrame>
    buildUnnamed513() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1FaceFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1FaceFrame());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1FaceFrame());
  return o;
}

void checkUnnamed513(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1FaceFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1FaceFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1FaceFrame);
  checkGoogleCloudVideointelligenceV1p3beta1FaceFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1FaceFrame);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1FaceSegment>
    buildUnnamed514() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1FaceSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1FaceSegment());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1FaceSegment());
  return o;
}

void checkUnnamed514(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1FaceSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1FaceSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1FaceSegment);
  checkGoogleCloudVideointelligenceV1p3beta1FaceSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1FaceSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1FaceAnnotation = 0;
api.GoogleCloudVideointelligenceV1p3beta1FaceAnnotation
    buildGoogleCloudVideointelligenceV1p3beta1FaceAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1FaceAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1FaceAnnotation < 3) {
    o.frames = buildUnnamed513();
    o.segments = buildUnnamed514();
    o.thumbnail = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1FaceAnnotation(
    api.GoogleCloudVideointelligenceV1p3beta1FaceAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1FaceAnnotation < 3) {
    checkUnnamed513(o.frames!);
    checkUnnamed514(o.segments!);
    unittest.expect(
      o.thumbnail!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceAnnotation--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1Track> buildUnnamed515() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1Track>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1Track());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1Track());
  return o;
}

void checkUnnamed515(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1Track(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1Track);
  checkGoogleCloudVideointelligenceV1p3beta1Track(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1Track);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation
    buildGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation <
      3) {
    o.thumbnail = 'foo';
    o.tracks = buildUnnamed515();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation(
    api.GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation <
      3) {
    unittest.expect(
      o.thumbnail!,
      unittest.equals('foo'),
    );
    checkUnnamed515(o.tracks!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox>
    buildUnnamed516() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox());
  return o;
}

void checkUnnamed516(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox);
  checkGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox);
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1FaceFrame = 0;
api.GoogleCloudVideointelligenceV1p3beta1FaceFrame
    buildGoogleCloudVideointelligenceV1p3beta1FaceFrame() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1FaceFrame();
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1FaceFrame < 3) {
    o.normalizedBoundingBoxes = buildUnnamed516();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1FaceFrame(
    api.GoogleCloudVideointelligenceV1p3beta1FaceFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1FaceFrame < 3) {
    checkUnnamed516(o.normalizedBoundingBoxes!);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceFrame--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1FaceSegment = 0;
api.GoogleCloudVideointelligenceV1p3beta1FaceSegment
    buildGoogleCloudVideointelligenceV1p3beta1FaceSegment() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1FaceSegment();
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1FaceSegment < 3) {
    o.segment = buildGoogleCloudVideointelligenceV1p3beta1VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1FaceSegment(
    api.GoogleCloudVideointelligenceV1p3beta1FaceSegment o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1FaceSegment < 3) {
    checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p3beta1VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1FaceSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1Entity> buildUnnamed517() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1Entity>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1Entity());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1Entity());
  return o;
}

void checkUnnamed517(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1Entity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1Entity(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1Entity);
  checkGoogleCloudVideointelligenceV1p3beta1Entity(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1Entity);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelFrame>
    buildUnnamed518() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1LabelFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelFrame());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelFrame());
  return o;
}

void checkUnnamed518(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1LabelFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1LabelFrame);
  checkGoogleCloudVideointelligenceV1p3beta1LabelFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1LabelFrame);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelSegment>
    buildUnnamed519() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1LabelSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelSegment());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelSegment());
  return o;
}

void checkUnnamed519(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1LabelSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1LabelSegment);
  checkGoogleCloudVideointelligenceV1p3beta1LabelSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1LabelSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1LabelAnnotation = 0;
api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation
    buildGoogleCloudVideointelligenceV1p3beta1LabelAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p3beta1LabelAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1LabelAnnotation < 3) {
    o.categoryEntities = buildUnnamed517();
    o.entity = buildGoogleCloudVideointelligenceV1p3beta1Entity();
    o.frames = buildUnnamed518();
    o.segments = buildUnnamed519();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1LabelAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1LabelAnnotation(
    api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1LabelAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1LabelAnnotation < 3) {
    checkUnnamed517(o.categoryEntities!);
    checkGoogleCloudVideointelligenceV1p3beta1Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1p3beta1Entity);
    checkUnnamed518(o.frames!);
    checkUnnamed519(o.segments!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1LabelAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1LabelFrame = 0;
api.GoogleCloudVideointelligenceV1p3beta1LabelFrame
    buildGoogleCloudVideointelligenceV1p3beta1LabelFrame() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1LabelFrame();
  buildCounterGoogleCloudVideointelligenceV1p3beta1LabelFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1LabelFrame < 3) {
    o.confidence = 42.0;
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1LabelFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1LabelFrame(
    api.GoogleCloudVideointelligenceV1p3beta1LabelFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1LabelFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1LabelFrame < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1LabelFrame--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1LabelSegment = 0;
api.GoogleCloudVideointelligenceV1p3beta1LabelSegment
    buildGoogleCloudVideointelligenceV1p3beta1LabelSegment() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1LabelSegment();
  buildCounterGoogleCloudVideointelligenceV1p3beta1LabelSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1LabelSegment < 3) {
    o.confidence = 42.0;
    o.segment = buildGoogleCloudVideointelligenceV1p3beta1VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1LabelSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1LabelSegment(
    api.GoogleCloudVideointelligenceV1p3beta1LabelSegment o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1LabelSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1LabelSegment < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p3beta1VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1LabelSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1VideoSegment>
    buildUnnamed520() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1VideoSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1VideoSegment());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1VideoSegment());
  return o;
}

void checkUnnamed520(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1VideoSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1VideoSegment);
  checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1VideoSegment);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1Track> buildUnnamed521() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1Track>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1Track());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1Track());
  return o;
}

void checkUnnamed521(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1Track(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1Track);
  checkGoogleCloudVideointelligenceV1p3beta1Track(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1Track);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation
    buildGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation <
      3) {
    o.entity = buildGoogleCloudVideointelligenceV1p3beta1Entity();
    o.segments = buildUnnamed520();
    o.tracks = buildUnnamed521();
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation(
    api.GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation <
      3) {
    checkGoogleCloudVideointelligenceV1p3beta1Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1p3beta1Entity);
    checkUnnamed520(o.segments!);
    checkUnnamed521(o.tracks!);
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation--;
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox = 0;
api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox
    buildGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox();
  buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox <
      3) {
    o.bottom = 42.0;
    o.left = 42.0;
    o.right = 42.0;
    o.top = 42.0;
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox(
    api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox <
      3) {
    unittest.expect(
      o.bottom!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.left!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.right!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.top!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1NormalizedVertex>
    buildUnnamed522() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1NormalizedVertex>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1NormalizedVertex());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1NormalizedVertex());
  return o;
}

void checkUnnamed522(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1NormalizedVertex> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1NormalizedVertex(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1NormalizedVertex);
  checkGoogleCloudVideointelligenceV1p3beta1NormalizedVertex(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1NormalizedVertex);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly = 0;
api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly
    buildGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly();
  buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly <
      3) {
    o.vertices = buildUnnamed522();
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly(
    api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly <
      3) {
    checkUnnamed522(o.vertices!);
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedVertex = 0;
api.GoogleCloudVideointelligenceV1p3beta1NormalizedVertex
    buildGoogleCloudVideointelligenceV1p3beta1NormalizedVertex() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1NormalizedVertex();
  buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedVertex++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedVertex < 3) {
    o.x = 42.0;
    o.y = 42.0;
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedVertex--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1NormalizedVertex(
    api.GoogleCloudVideointelligenceV1p3beta1NormalizedVertex o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedVertex++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedVertex < 3) {
    unittest.expect(
      o.x!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.y!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1NormalizedVertex--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame>
    buildUnnamed523() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame());
  return o;
}

void checkUnnamed523(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame);
  checkGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation
    buildGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation <
      3) {
    o.confidence = 42.0;
    o.entity = buildGoogleCloudVideointelligenceV1p3beta1Entity();
    o.frames = buildUnnamed523();
    o.segment = buildGoogleCloudVideointelligenceV1p3beta1VideoSegment();
    o.trackId = 'foo';
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation(
    api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation <
      3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1p3beta1Entity(
        o.entity! as api.GoogleCloudVideointelligenceV1p3beta1Entity);
    checkUnnamed523(o.frames!);
    checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p3beta1VideoSegment);
    unittest.expect(
      o.trackId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame =
    0;
api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame
    buildGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame();
  buildCounterGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame <
      3) {
    o.normalizedBoundingBox =
        buildGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame(
    api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame <
      3) {
    checkGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox(
        o.normalizedBoundingBox!
            as api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1Track> buildUnnamed524() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1Track>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1Track());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1Track());
  return o;
}

void checkUnnamed524(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1Track> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1Track(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1Track);
  checkGoogleCloudVideointelligenceV1p3beta1Track(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1Track);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation =
    0;
api.GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation
    buildGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation <
      3) {
    o.tracks = buildUnnamed524();
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation(
    api.GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation <
      3) {
    checkUnnamed524(o.tracks!);
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity =
    0;
api.GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity
    buildGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity();
  buildCounterGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity <
      3) {
    o.celebrity = buildGoogleCloudVideointelligenceV1p3beta1Celebrity();
    o.confidence = 42.0;
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity(
    api.GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity <
      3) {
    checkGoogleCloudVideointelligenceV1p3beta1Celebrity(
        o.celebrity! as api.GoogleCloudVideointelligenceV1p3beta1Celebrity);
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1WordInfo> buildUnnamed525() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1WordInfo>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1WordInfo());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1WordInfo());
  return o;
}

void checkUnnamed525(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1WordInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1WordInfo(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1WordInfo);
  checkGoogleCloudVideointelligenceV1p3beta1WordInfo(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1WordInfo);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative =
    0;
api.GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative
    buildGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative() {
  var o =
      api.GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative();
  buildCounterGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative <
      3) {
    o.confidence = 42.0;
    o.transcript = 'foo';
    o.words = buildUnnamed525();
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative(
    api.GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative <
      3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.transcript!,
      unittest.equals('foo'),
    );
    checkUnnamed525(o.words!);
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative>
    buildUnnamed526() {
  var o =
      <api.GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative>[];
  o.add(
      buildGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative());
  o.add(
      buildGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative());
  return o;
}

void checkUnnamed526(
    core.List<
            api.GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative(o[0]
      as api.GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative);
  checkGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative(o[1]
      as api.GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative);
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1SpeechTranscription =
    0;
api.GoogleCloudVideointelligenceV1p3beta1SpeechTranscription
    buildGoogleCloudVideointelligenceV1p3beta1SpeechTranscription() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1SpeechTranscription();
  buildCounterGoogleCloudVideointelligenceV1p3beta1SpeechTranscription++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1SpeechTranscription <
      3) {
    o.alternatives = buildUnnamed526();
    o.languageCode = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1SpeechTranscription--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1SpeechTranscription(
    api.GoogleCloudVideointelligenceV1p3beta1SpeechTranscription o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1SpeechTranscription++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1SpeechTranscription <
      3) {
    checkUnnamed526(o.alternatives!);
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1SpeechTranscription--;
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse =
    0;
api.GoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse
    buildGoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse() {
  var o =
      api.GoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse();
  buildCounterGoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse <
      3) {
    o.annotationResults =
        buildGoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults();
    o.annotationResultsUri = 'foo';
    o.error = buildGoogleRpcStatus();
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse(
    api.GoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse <
      3) {
    checkGoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults(
        o.annotationResults! as api
            .GoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults);
    unittest.expect(
      o.annotationResultsUri!,
      unittest.equals('foo'),
    );
    checkGoogleRpcStatus(o.error! as api.GoogleRpcStatus);
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>
    buildUnnamed527() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelAnnotation());
  return o;
}

void checkUnnamed527(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p3beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation>
    buildUnnamed528() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation());
  return o;
}

void checkUnnamed528(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation(o[0]
      as api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation);
  checkGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation(o[1]
      as api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1VideoSegment>
    buildUnnamed529() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1VideoSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1VideoSegment());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1VideoSegment());
  return o;
}

void checkUnnamed529(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1VideoSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1VideoSegment);
  checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1VideoSegment);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults =
    0;
api.GoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults
    buildGoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults() {
  var o = api
      .GoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults();
  buildCounterGoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults <
      3) {
    o.explicitAnnotation =
        buildGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation();
    o.frameTimestamp = 'foo';
    o.labelAnnotations = buildUnnamed527();
    o.objectAnnotations = buildUnnamed528();
    o.shotAnnotations = buildUnnamed529();
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults(
    api.GoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults
        o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults <
      3) {
    checkGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation(o
            .explicitAnnotation!
        as api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation);
    unittest.expect(
      o.frameTimestamp!,
      unittest.equals('foo'),
    );
    checkUnnamed527(o.labelAnnotations!);
    checkUnnamed528(o.objectAnnotations!);
    checkUnnamed529(o.shotAnnotations!);
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1TextSegment>
    buildUnnamed530() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1TextSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1TextSegment());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1TextSegment());
  return o;
}

void checkUnnamed530(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1TextSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1TextSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1TextSegment);
  checkGoogleCloudVideointelligenceV1p3beta1TextSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1TextSegment);
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1TextAnnotation = 0;
api.GoogleCloudVideointelligenceV1p3beta1TextAnnotation
    buildGoogleCloudVideointelligenceV1p3beta1TextAnnotation() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1TextAnnotation();
  buildCounterGoogleCloudVideointelligenceV1p3beta1TextAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1TextAnnotation < 3) {
    o.segments = buildUnnamed530();
    o.text = 'foo';
    o.version = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1TextAnnotation--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1TextAnnotation(
    api.GoogleCloudVideointelligenceV1p3beta1TextAnnotation o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1TextAnnotation++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1TextAnnotation < 3) {
    checkUnnamed530(o.segments!);
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1TextAnnotation--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1TextFrame = 0;
api.GoogleCloudVideointelligenceV1p3beta1TextFrame
    buildGoogleCloudVideointelligenceV1p3beta1TextFrame() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1TextFrame();
  buildCounterGoogleCloudVideointelligenceV1p3beta1TextFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1TextFrame < 3) {
    o.rotatedBoundingBox =
        buildGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1TextFrame--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1TextFrame(
    api.GoogleCloudVideointelligenceV1p3beta1TextFrame o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1TextFrame++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1TextFrame < 3) {
    checkGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly(
        o.rotatedBoundingBox!
            as api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1TextFrame--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1TextFrame>
    buildUnnamed531() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1TextFrame>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1TextFrame());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1TextFrame());
  return o;
}

void checkUnnamed531(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1TextFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1TextFrame(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1TextFrame);
  checkGoogleCloudVideointelligenceV1p3beta1TextFrame(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1TextFrame);
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1TextSegment = 0;
api.GoogleCloudVideointelligenceV1p3beta1TextSegment
    buildGoogleCloudVideointelligenceV1p3beta1TextSegment() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1TextSegment();
  buildCounterGoogleCloudVideointelligenceV1p3beta1TextSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1TextSegment < 3) {
    o.confidence = 42.0;
    o.frames = buildUnnamed531();
    o.segment = buildGoogleCloudVideointelligenceV1p3beta1VideoSegment();
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1TextSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1TextSegment(
    api.GoogleCloudVideointelligenceV1p3beta1TextSegment o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1TextSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1TextSegment < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkUnnamed531(o.frames!);
    checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p3beta1VideoSegment);
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1TextSegment--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute>
    buildUnnamed532() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1DetectedAttribute());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1DetectedAttribute());
  return o;
}

void checkUnnamed532(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1DetectedAttribute(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute);
  checkGoogleCloudVideointelligenceV1p3beta1DetectedAttribute(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1DetectedLandmark>
    buildUnnamed533() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1DetectedLandmark>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1DetectedLandmark());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1DetectedLandmark());
  return o;
}

void checkUnnamed533(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1DetectedLandmark> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1DetectedLandmark(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1DetectedLandmark);
  checkGoogleCloudVideointelligenceV1p3beta1DetectedLandmark(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1DetectedLandmark);
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1TimestampedObject = 0;
api.GoogleCloudVideointelligenceV1p3beta1TimestampedObject
    buildGoogleCloudVideointelligenceV1p3beta1TimestampedObject() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1TimestampedObject();
  buildCounterGoogleCloudVideointelligenceV1p3beta1TimestampedObject++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1TimestampedObject < 3) {
    o.attributes = buildUnnamed532();
    o.landmarks = buildUnnamed533();
    o.normalizedBoundingBox =
        buildGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox();
    o.timeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1TimestampedObject--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1TimestampedObject(
    api.GoogleCloudVideointelligenceV1p3beta1TimestampedObject o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1TimestampedObject++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1TimestampedObject < 3) {
    checkUnnamed532(o.attributes!);
    checkUnnamed533(o.landmarks!);
    checkGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox(
        o.normalizedBoundingBox!
            as api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox);
    unittest.expect(
      o.timeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1TimestampedObject--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute>
    buildUnnamed534() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1DetectedAttribute());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1DetectedAttribute());
  return o;
}

void checkUnnamed534(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1DetectedAttribute(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute);
  checkGoogleCloudVideointelligenceV1p3beta1DetectedAttribute(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1TimestampedObject>
    buildUnnamed535() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1TimestampedObject>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1TimestampedObject());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1TimestampedObject());
  return o;
}

void checkUnnamed535(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1TimestampedObject> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1TimestampedObject(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1TimestampedObject);
  checkGoogleCloudVideointelligenceV1p3beta1TimestampedObject(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1TimestampedObject);
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1Track = 0;
api.GoogleCloudVideointelligenceV1p3beta1Track
    buildGoogleCloudVideointelligenceV1p3beta1Track() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1Track();
  buildCounterGoogleCloudVideointelligenceV1p3beta1Track++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1Track < 3) {
    o.attributes = buildUnnamed534();
    o.confidence = 42.0;
    o.segment = buildGoogleCloudVideointelligenceV1p3beta1VideoSegment();
    o.timestampedObjects = buildUnnamed535();
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1Track--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1Track(
    api.GoogleCloudVideointelligenceV1p3beta1Track o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1Track++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1Track < 3) {
    checkUnnamed534(o.attributes!);
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p3beta1VideoSegment);
    checkUnnamed535(o.timestampedObjects!);
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1Track--;
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress =
    0;
api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress
    buildGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress();
  buildCounterGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress <
      3) {
    o.feature = 'foo';
    o.inputUri = 'foo';
    o.progressPercent = 42;
    o.segment = buildGoogleCloudVideointelligenceV1p3beta1VideoSegment();
    o.startTime = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress(
    api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress <
      3) {
    unittest.expect(
      o.feature!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inputUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.progressPercent!,
      unittest.equals(42),
    );
    checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p3beta1VideoSegment);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress--;
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1FaceAnnotation>
    buildUnnamed536() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1FaceAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1FaceAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1FaceAnnotation());
  return o;
}

void checkUnnamed536(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1FaceAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1FaceAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1FaceAnnotation);
  checkGoogleCloudVideointelligenceV1p3beta1FaceAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1FaceAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation>
    buildUnnamed537() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation());
  return o;
}

void checkUnnamed537(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation);
  checkGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>
    buildUnnamed538() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelAnnotation());
  return o;
}

void checkUnnamed538(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p3beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation>
    buildUnnamed539() {
  var o =
      <api.GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation());
  return o;
}

void checkUnnamed539(
    core.List<
            api.GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation(o[0]
      as api.GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation);
  checkGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation(o[1]
      as api.GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation>
    buildUnnamed540() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation());
  return o;
}

void checkUnnamed540(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation(o[0]
      as api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation);
  checkGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation(o[1]
      as api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation>
    buildUnnamed541() {
  var o =
      <api.GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation());
  return o;
}

void checkUnnamed541(
    core.List<
            api.GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation(o[0]
      as api.GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation);
  checkGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation(o[1]
      as api.GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>
    buildUnnamed542() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelAnnotation());
  return o;
}

void checkUnnamed542(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p3beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>
    buildUnnamed543() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelAnnotation());
  return o;
}

void checkUnnamed543(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p3beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1VideoSegment>
    buildUnnamed544() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1VideoSegment>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1VideoSegment());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1VideoSegment());
  return o;
}

void checkUnnamed544(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1VideoSegment> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1VideoSegment);
  checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1VideoSegment);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>
    buildUnnamed545() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelAnnotation());
  return o;
}

void checkUnnamed545(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p3beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>
    buildUnnamed546() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1LabelAnnotation());
  return o;
}

void checkUnnamed546(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1LabelAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation);
  checkGoogleCloudVideointelligenceV1p3beta1LabelAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1SpeechTranscription>
    buildUnnamed547() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1SpeechTranscription>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1SpeechTranscription());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1SpeechTranscription());
  return o;
}

void checkUnnamed547(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1SpeechTranscription> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1SpeechTranscription(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1SpeechTranscription);
  checkGoogleCloudVideointelligenceV1p3beta1SpeechTranscription(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1SpeechTranscription);
}

core.List<api.GoogleCloudVideointelligenceV1p3beta1TextAnnotation>
    buildUnnamed548() {
  var o = <api.GoogleCloudVideointelligenceV1p3beta1TextAnnotation>[];
  o.add(buildGoogleCloudVideointelligenceV1p3beta1TextAnnotation());
  o.add(buildGoogleCloudVideointelligenceV1p3beta1TextAnnotation());
  return o;
}

void checkUnnamed548(
    core.List<api.GoogleCloudVideointelligenceV1p3beta1TextAnnotation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudVideointelligenceV1p3beta1TextAnnotation(
      o[0] as api.GoogleCloudVideointelligenceV1p3beta1TextAnnotation);
  checkGoogleCloudVideointelligenceV1p3beta1TextAnnotation(
      o[1] as api.GoogleCloudVideointelligenceV1p3beta1TextAnnotation);
}

core.int
    buildCounterGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults = 0;
api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults
    buildGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults();
  buildCounterGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults <
      3) {
    o.celebrityRecognitionAnnotations =
        buildGoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation();
    o.error = buildGoogleRpcStatus();
    o.explicitAnnotation =
        buildGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation();
    o.faceAnnotations = buildUnnamed536();
    o.faceDetectionAnnotations = buildUnnamed537();
    o.frameLabelAnnotations = buildUnnamed538();
    o.inputUri = 'foo';
    o.logoRecognitionAnnotations = buildUnnamed539();
    o.objectAnnotations = buildUnnamed540();
    o.personDetectionAnnotations = buildUnnamed541();
    o.segment = buildGoogleCloudVideointelligenceV1p3beta1VideoSegment();
    o.segmentLabelAnnotations = buildUnnamed542();
    o.segmentPresenceLabelAnnotations = buildUnnamed543();
    o.shotAnnotations = buildUnnamed544();
    o.shotLabelAnnotations = buildUnnamed545();
    o.shotPresenceLabelAnnotations = buildUnnamed546();
    o.speechTranscriptions = buildUnnamed547();
    o.textAnnotations = buildUnnamed548();
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults(
    api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults <
      3) {
    checkGoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation(
        o.celebrityRecognitionAnnotations! as api
            .GoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation);
    checkGoogleRpcStatus(o.error! as api.GoogleRpcStatus);
    checkGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation(o
            .explicitAnnotation!
        as api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation);
    checkUnnamed536(o.faceAnnotations!);
    checkUnnamed537(o.faceDetectionAnnotations!);
    checkUnnamed538(o.frameLabelAnnotations!);
    unittest.expect(
      o.inputUri!,
      unittest.equals('foo'),
    );
    checkUnnamed539(o.logoRecognitionAnnotations!);
    checkUnnamed540(o.objectAnnotations!);
    checkUnnamed541(o.personDetectionAnnotations!);
    checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
        o.segment! as api.GoogleCloudVideointelligenceV1p3beta1VideoSegment);
    checkUnnamed542(o.segmentLabelAnnotations!);
    checkUnnamed543(o.segmentPresenceLabelAnnotations!);
    checkUnnamed544(o.shotAnnotations!);
    checkUnnamed545(o.shotLabelAnnotations!);
    checkUnnamed546(o.shotPresenceLabelAnnotations!);
    checkUnnamed547(o.speechTranscriptions!);
    checkUnnamed548(o.textAnnotations!);
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1VideoSegment = 0;
api.GoogleCloudVideointelligenceV1p3beta1VideoSegment
    buildGoogleCloudVideointelligenceV1p3beta1VideoSegment() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1VideoSegment();
  buildCounterGoogleCloudVideointelligenceV1p3beta1VideoSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1VideoSegment < 3) {
    o.endTimeOffset = 'foo';
    o.startTimeOffset = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1VideoSegment--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
    api.GoogleCloudVideointelligenceV1p3beta1VideoSegment o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1VideoSegment++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1VideoSegment < 3) {
    unittest.expect(
      o.endTimeOffset!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTimeOffset!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1VideoSegment--;
}

core.int buildCounterGoogleCloudVideointelligenceV1p3beta1WordInfo = 0;
api.GoogleCloudVideointelligenceV1p3beta1WordInfo
    buildGoogleCloudVideointelligenceV1p3beta1WordInfo() {
  var o = api.GoogleCloudVideointelligenceV1p3beta1WordInfo();
  buildCounterGoogleCloudVideointelligenceV1p3beta1WordInfo++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1WordInfo < 3) {
    o.confidence = 42.0;
    o.endTime = 'foo';
    o.speakerTag = 42;
    o.startTime = 'foo';
    o.word = 'foo';
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1WordInfo--;
  return o;
}

void checkGoogleCloudVideointelligenceV1p3beta1WordInfo(
    api.GoogleCloudVideointelligenceV1p3beta1WordInfo o) {
  buildCounterGoogleCloudVideointelligenceV1p3beta1WordInfo++;
  if (buildCounterGoogleCloudVideointelligenceV1p3beta1WordInfo < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.speakerTag!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.word!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudVideointelligenceV1p3beta1WordInfo--;
}

core.int buildCounterGoogleLongrunningCancelOperationRequest = 0;
api.GoogleLongrunningCancelOperationRequest
    buildGoogleLongrunningCancelOperationRequest() {
  var o = api.GoogleLongrunningCancelOperationRequest();
  buildCounterGoogleLongrunningCancelOperationRequest++;
  if (buildCounterGoogleLongrunningCancelOperationRequest < 3) {}
  buildCounterGoogleLongrunningCancelOperationRequest--;
  return o;
}

void checkGoogleLongrunningCancelOperationRequest(
    api.GoogleLongrunningCancelOperationRequest o) {
  buildCounterGoogleLongrunningCancelOperationRequest++;
  if (buildCounterGoogleLongrunningCancelOperationRequest < 3) {}
  buildCounterGoogleLongrunningCancelOperationRequest--;
}

core.List<api.GoogleLongrunningOperation> buildUnnamed549() {
  var o = <api.GoogleLongrunningOperation>[];
  o.add(buildGoogleLongrunningOperation());
  o.add(buildGoogleLongrunningOperation());
  return o;
}

void checkUnnamed549(core.List<api.GoogleLongrunningOperation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleLongrunningOperation(o[0] as api.GoogleLongrunningOperation);
  checkGoogleLongrunningOperation(o[1] as api.GoogleLongrunningOperation);
}

core.int buildCounterGoogleLongrunningListOperationsResponse = 0;
api.GoogleLongrunningListOperationsResponse
    buildGoogleLongrunningListOperationsResponse() {
  var o = api.GoogleLongrunningListOperationsResponse();
  buildCounterGoogleLongrunningListOperationsResponse++;
  if (buildCounterGoogleLongrunningListOperationsResponse < 3) {
    o.nextPageToken = 'foo';
    o.operations = buildUnnamed549();
  }
  buildCounterGoogleLongrunningListOperationsResponse--;
  return o;
}

void checkGoogleLongrunningListOperationsResponse(
    api.GoogleLongrunningListOperationsResponse o) {
  buildCounterGoogleLongrunningListOperationsResponse++;
  if (buildCounterGoogleLongrunningListOperationsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed549(o.operations!);
  }
  buildCounterGoogleLongrunningListOperationsResponse--;
}

core.Map<core.String, core.Object> buildUnnamed550() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed550(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted1 = (o['x']!) as core.Map;
  unittest.expect(casted1, unittest.hasLength(3));
  unittest.expect(
    casted1['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted1['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted1['string'],
    unittest.equals('foo'),
  );
  var casted2 = (o['y']!) as core.Map;
  unittest.expect(casted2, unittest.hasLength(3));
  unittest.expect(
    casted2['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted2['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted2['string'],
    unittest.equals('foo'),
  );
}

core.Map<core.String, core.Object> buildUnnamed551() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed551(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted3 = (o['x']!) as core.Map;
  unittest.expect(casted3, unittest.hasLength(3));
  unittest.expect(
    casted3['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted3['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted3['string'],
    unittest.equals('foo'),
  );
  var casted4 = (o['y']!) as core.Map;
  unittest.expect(casted4, unittest.hasLength(3));
  unittest.expect(
    casted4['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted4['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted4['string'],
    unittest.equals('foo'),
  );
}

core.int buildCounterGoogleLongrunningOperation = 0;
api.GoogleLongrunningOperation buildGoogleLongrunningOperation() {
  var o = api.GoogleLongrunningOperation();
  buildCounterGoogleLongrunningOperation++;
  if (buildCounterGoogleLongrunningOperation < 3) {
    o.done = true;
    o.error = buildGoogleRpcStatus();
    o.metadata = buildUnnamed550();
    o.name = 'foo';
    o.response = buildUnnamed551();
  }
  buildCounterGoogleLongrunningOperation--;
  return o;
}

void checkGoogleLongrunningOperation(api.GoogleLongrunningOperation o) {
  buildCounterGoogleLongrunningOperation++;
  if (buildCounterGoogleLongrunningOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkGoogleRpcStatus(o.error! as api.GoogleRpcStatus);
    checkUnnamed550(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed551(o.response!);
  }
  buildCounterGoogleLongrunningOperation--;
}

core.int buildCounterGoogleProtobufEmpty = 0;
api.GoogleProtobufEmpty buildGoogleProtobufEmpty() {
  var o = api.GoogleProtobufEmpty();
  buildCounterGoogleProtobufEmpty++;
  if (buildCounterGoogleProtobufEmpty < 3) {}
  buildCounterGoogleProtobufEmpty--;
  return o;
}

void checkGoogleProtobufEmpty(api.GoogleProtobufEmpty o) {
  buildCounterGoogleProtobufEmpty++;
  if (buildCounterGoogleProtobufEmpty < 3) {}
  buildCounterGoogleProtobufEmpty--;
}

core.Map<core.String, core.Object> buildUnnamed552() {
  var o = <core.String, core.Object>{};
  o['x'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o['y'] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkUnnamed552(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted5 = (o['x']!) as core.Map;
  unittest.expect(casted5, unittest.hasLength(3));
  unittest.expect(
    casted5['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted5['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted5['string'],
    unittest.equals('foo'),
  );
  var casted6 = (o['y']!) as core.Map;
  unittest.expect(casted6, unittest.hasLength(3));
  unittest.expect(
    casted6['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted6['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted6['string'],
    unittest.equals('foo'),
  );
}

core.List<core.Map<core.String, core.Object>> buildUnnamed553() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed552());
  o.add(buildUnnamed552());
  return o;
}

void checkUnnamed553(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed552(o[0]);
  checkUnnamed552(o[1]);
}

core.int buildCounterGoogleRpcStatus = 0;
api.GoogleRpcStatus buildGoogleRpcStatus() {
  var o = api.GoogleRpcStatus();
  buildCounterGoogleRpcStatus++;
  if (buildCounterGoogleRpcStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed553();
    o.message = 'foo';
  }
  buildCounterGoogleRpcStatus--;
  return o;
}

void checkGoogleRpcStatus(api.GoogleRpcStatus o) {
  buildCounterGoogleRpcStatus++;
  if (buildCounterGoogleRpcStatus < 3) {
    unittest.expect(
      o.code!,
      unittest.equals(42),
    );
    checkUnnamed553(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleRpcStatus--;
}

void main() {
  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1AnnotateVideoProgress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1AnnotateVideoProgress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1AnnotateVideoProgress.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1AnnotateVideoProgress(
          od as api.GoogleCloudVideointelligenceV1AnnotateVideoProgress);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1AnnotateVideoRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1AnnotateVideoRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1AnnotateVideoRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1AnnotateVideoRequest(
          od as api.GoogleCloudVideointelligenceV1AnnotateVideoRequest);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1AnnotateVideoResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1AnnotateVideoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1AnnotateVideoResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1AnnotateVideoResponse(
          od as api.GoogleCloudVideointelligenceV1AnnotateVideoResponse);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1DetectedAttribute',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1DetectedAttribute();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1DetectedAttribute.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1DetectedAttribute(
          od as api.GoogleCloudVideointelligenceV1DetectedAttribute);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1DetectedLandmark',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1DetectedLandmark();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1DetectedLandmark.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1DetectedLandmark(
          od as api.GoogleCloudVideointelligenceV1DetectedLandmark);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1Entity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1Entity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1Entity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1Entity(
          od as api.GoogleCloudVideointelligenceV1Entity);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1ExplicitContentAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1ExplicitContentAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1ExplicitContentAnnotation.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1ExplicitContentAnnotation(
          od as api.GoogleCloudVideointelligenceV1ExplicitContentAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1ExplicitContentDetectionConfig',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1ExplicitContentDetectionConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1ExplicitContentDetectionConfig
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1ExplicitContentDetectionConfig(od
          as api.GoogleCloudVideointelligenceV1ExplicitContentDetectionConfig);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1ExplicitContentFrame', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1ExplicitContentFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1ExplicitContentFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1ExplicitContentFrame(
          od as api.GoogleCloudVideointelligenceV1ExplicitContentFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1FaceAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1FaceAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1FaceAnnotation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1FaceAnnotation(
          od as api.GoogleCloudVideointelligenceV1FaceAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1FaceDetectionAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1FaceDetectionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1FaceDetectionAnnotation.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1FaceDetectionAnnotation(
          od as api.GoogleCloudVideointelligenceV1FaceDetectionAnnotation);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1FaceDetectionConfig',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1FaceDetectionConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1FaceDetectionConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1FaceDetectionConfig(
          od as api.GoogleCloudVideointelligenceV1FaceDetectionConfig);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1FaceFrame', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1FaceFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1FaceFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1FaceFrame(
          od as api.GoogleCloudVideointelligenceV1FaceFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1FaceSegment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1FaceSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1FaceSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1FaceSegment(
          od as api.GoogleCloudVideointelligenceV1FaceSegment);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1LabelAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1LabelAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1LabelAnnotation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1LabelAnnotation(
          od as api.GoogleCloudVideointelligenceV1LabelAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1LabelDetectionConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1LabelDetectionConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1LabelDetectionConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1LabelDetectionConfig(
          od as api.GoogleCloudVideointelligenceV1LabelDetectionConfig);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1LabelFrame', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1LabelFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1LabelFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1LabelFrame(
          od as api.GoogleCloudVideointelligenceV1LabelFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1LabelSegment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1LabelSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1LabelSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1LabelSegment(
          od as api.GoogleCloudVideointelligenceV1LabelSegment);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1LogoRecognitionAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1LogoRecognitionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1LogoRecognitionAnnotation.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1LogoRecognitionAnnotation(
          od as api.GoogleCloudVideointelligenceV1LogoRecognitionAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1NormalizedBoundingBox', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1NormalizedBoundingBox();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1NormalizedBoundingBox.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1NormalizedBoundingBox(
          od as api.GoogleCloudVideointelligenceV1NormalizedBoundingBox);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1NormalizedBoundingPoly', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1NormalizedBoundingPoly();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1NormalizedBoundingPoly.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1NormalizedBoundingPoly(
          od as api.GoogleCloudVideointelligenceV1NormalizedBoundingPoly);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1NormalizedVertex',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1NormalizedVertex();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1NormalizedVertex.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1NormalizedVertex(
          od as api.GoogleCloudVideointelligenceV1NormalizedVertex);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1ObjectTrackingAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1ObjectTrackingAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1ObjectTrackingAnnotation.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1ObjectTrackingAnnotation(
          od as api.GoogleCloudVideointelligenceV1ObjectTrackingAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1ObjectTrackingConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1ObjectTrackingConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1ObjectTrackingConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1ObjectTrackingConfig(
          od as api.GoogleCloudVideointelligenceV1ObjectTrackingConfig);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1ObjectTrackingFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1ObjectTrackingFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1ObjectTrackingFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1ObjectTrackingFrame(
          od as api.GoogleCloudVideointelligenceV1ObjectTrackingFrame);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1PersonDetectionAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1PersonDetectionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1PersonDetectionAnnotation.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1PersonDetectionAnnotation(
          od as api.GoogleCloudVideointelligenceV1PersonDetectionAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1PersonDetectionConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1PersonDetectionConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1PersonDetectionConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1PersonDetectionConfig(
          od as api.GoogleCloudVideointelligenceV1PersonDetectionConfig);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1ShotChangeDetectionConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1ShotChangeDetectionConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1ShotChangeDetectionConfig.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1ShotChangeDetectionConfig(
          od as api.GoogleCloudVideointelligenceV1ShotChangeDetectionConfig);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1SpeechContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1SpeechContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1SpeechContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1SpeechContext(
          od as api.GoogleCloudVideointelligenceV1SpeechContext);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1SpeechRecognitionAlternative',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1SpeechRecognitionAlternative();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1SpeechRecognitionAlternative
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1SpeechRecognitionAlternative(
          od as api.GoogleCloudVideointelligenceV1SpeechRecognitionAlternative);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1SpeechTranscription',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1SpeechTranscription();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1SpeechTranscription.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1SpeechTranscription(
          od as api.GoogleCloudVideointelligenceV1SpeechTranscription);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1SpeechTranscriptionConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1SpeechTranscriptionConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1SpeechTranscriptionConfig.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1SpeechTranscriptionConfig(
          od as api.GoogleCloudVideointelligenceV1SpeechTranscriptionConfig);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1TextAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1TextAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1TextAnnotation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1TextAnnotation(
          od as api.GoogleCloudVideointelligenceV1TextAnnotation);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1TextDetectionConfig',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1TextDetectionConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1TextDetectionConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1TextDetectionConfig(
          od as api.GoogleCloudVideointelligenceV1TextDetectionConfig);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1TextFrame', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1TextFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1TextFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1TextFrame(
          od as api.GoogleCloudVideointelligenceV1TextFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1TextSegment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1TextSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1TextSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1TextSegment(
          od as api.GoogleCloudVideointelligenceV1TextSegment);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1TimestampedObject',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1TimestampedObject();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1TimestampedObject.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1TimestampedObject(
          od as api.GoogleCloudVideointelligenceV1TimestampedObject);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1Track', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1Track();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1Track.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1Track(
          od as api.GoogleCloudVideointelligenceV1Track);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1VideoAnnotationProgress', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1VideoAnnotationProgress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1VideoAnnotationProgress.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1VideoAnnotationProgress(
          od as api.GoogleCloudVideointelligenceV1VideoAnnotationProgress);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1VideoAnnotationResults', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1VideoAnnotationResults();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1VideoAnnotationResults.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1VideoAnnotationResults(
          od as api.GoogleCloudVideointelligenceV1VideoAnnotationResults);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1VideoContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1VideoContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1VideoContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1VideoContext(
          od as api.GoogleCloudVideointelligenceV1VideoContext);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1VideoSegment', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1VideoSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1VideoSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1VideoSegment(
          od as api.GoogleCloudVideointelligenceV1VideoSegment);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1WordInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1WordInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1WordInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1WordInfo(
          od as api.GoogleCloudVideointelligenceV1WordInfo);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2AnnotateVideoProgress',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2AnnotateVideoProgress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1beta2AnnotateVideoProgress.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2AnnotateVideoProgress(
          od as api.GoogleCloudVideointelligenceV1beta2AnnotateVideoProgress);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2AnnotateVideoResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2AnnotateVideoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1beta2AnnotateVideoResponse.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2AnnotateVideoResponse(
          od as api.GoogleCloudVideointelligenceV1beta2AnnotateVideoResponse);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2DetectedAttribute', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2DetectedAttribute();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1beta2DetectedAttribute.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2DetectedAttribute(
          od as api.GoogleCloudVideointelligenceV1beta2DetectedAttribute);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2DetectedLandmark', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2DetectedLandmark();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2DetectedLandmark.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2DetectedLandmark(
          od as api.GoogleCloudVideointelligenceV1beta2DetectedLandmark);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1beta2Entity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2Entity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2Entity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2Entity(
          od as api.GoogleCloudVideointelligenceV1beta2Entity);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation(od
          as api.GoogleCloudVideointelligenceV1beta2ExplicitContentAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2ExplicitContentFrame', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2ExplicitContentFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1beta2ExplicitContentFrame.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2ExplicitContentFrame(
          od as api.GoogleCloudVideointelligenceV1beta2ExplicitContentFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1beta2FaceAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2FaceAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2FaceAnnotation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2FaceAnnotation(
          od as api.GoogleCloudVideointelligenceV1beta2FaceAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation(
          od as api.GoogleCloudVideointelligenceV1beta2FaceDetectionAnnotation);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1beta2FaceFrame', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2FaceFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2FaceFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2FaceFrame(
          od as api.GoogleCloudVideointelligenceV1beta2FaceFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1beta2FaceSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2FaceSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2FaceSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2FaceSegment(
          od as api.GoogleCloudVideointelligenceV1beta2FaceSegment);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2LabelAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2LabelAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2LabelAnnotation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2LabelAnnotation(
          od as api.GoogleCloudVideointelligenceV1beta2LabelAnnotation);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1beta2LabelFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2LabelFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2LabelFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2LabelFrame(
          od as api.GoogleCloudVideointelligenceV1beta2LabelFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1beta2LabelSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2LabelSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2LabelSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2LabelSegment(
          od as api.GoogleCloudVideointelligenceV1beta2LabelSegment);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation(od
          as api.GoogleCloudVideointelligenceV1beta2LogoRecognitionAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2NormalizedBoundingBox(
          od as api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingBox);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly(
          od as api.GoogleCloudVideointelligenceV1beta2NormalizedBoundingPoly);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2NormalizedVertex', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2NormalizedVertex();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2NormalizedVertex.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2NormalizedVertex(
          od as api.GoogleCloudVideointelligenceV1beta2NormalizedVertex);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation(od
          as api.GoogleCloudVideointelligenceV1beta2ObjectTrackingAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2ObjectTrackingFrame(
          od as api.GoogleCloudVideointelligenceV1beta2ObjectTrackingFrame);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation(od
          as api.GoogleCloudVideointelligenceV1beta2PersonDetectionAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative(od
          as api
              .GoogleCloudVideointelligenceV1beta2SpeechRecognitionAlternative);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2SpeechTranscription', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2SpeechTranscription();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1beta2SpeechTranscription.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2SpeechTranscription(
          od as api.GoogleCloudVideointelligenceV1beta2SpeechTranscription);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1beta2TextAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2TextAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2TextAnnotation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2TextAnnotation(
          od as api.GoogleCloudVideointelligenceV1beta2TextAnnotation);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1beta2TextFrame', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2TextFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2TextFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2TextFrame(
          od as api.GoogleCloudVideointelligenceV1beta2TextFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1beta2TextSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2TextSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2TextSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2TextSegment(
          od as api.GoogleCloudVideointelligenceV1beta2TextSegment);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2TimestampedObject', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2TimestampedObject();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1beta2TimestampedObject.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2TimestampedObject(
          od as api.GoogleCloudVideointelligenceV1beta2TimestampedObject);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1beta2Track', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2Track();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2Track.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2Track(
          od as api.GoogleCloudVideointelligenceV1beta2Track);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2VideoAnnotationProgress(
          od as api.GoogleCloudVideointelligenceV1beta2VideoAnnotationProgress);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1beta2VideoAnnotationResults',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2VideoAnnotationResults();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2VideoAnnotationResults
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2VideoAnnotationResults(
          od as api.GoogleCloudVideointelligenceV1beta2VideoAnnotationResults);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1beta2VideoSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2VideoSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2VideoSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2VideoSegment(
          od as api.GoogleCloudVideointelligenceV1beta2VideoSegment);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1beta2WordInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1beta2WordInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1beta2WordInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1beta2WordInfo(
          od as api.GoogleCloudVideointelligenceV1beta2WordInfo);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress(
          od as api.GoogleCloudVideointelligenceV1p1beta1AnnotateVideoProgress);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse(
          od as api.GoogleCloudVideointelligenceV1p1beta1AnnotateVideoResponse);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1DetectedAttribute', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1DetectedAttribute();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1DetectedAttribute(
          od as api.GoogleCloudVideointelligenceV1p1beta1DetectedAttribute);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1DetectedLandmark', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1DetectedLandmark();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p1beta1DetectedLandmark.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1DetectedLandmark(
          od as api.GoogleCloudVideointelligenceV1p1beta1DetectedLandmark);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p1beta1Entity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1Entity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1Entity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1Entity(
          od as api.GoogleCloudVideointelligenceV1p1beta1Entity);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation(od
          as api
              .GoogleCloudVideointelligenceV1p1beta1ExplicitContentAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame(
          od as api.GoogleCloudVideointelligenceV1p1beta1ExplicitContentFrame);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1FaceAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1FaceAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1FaceAnnotation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1FaceAnnotation(
          od as api.GoogleCloudVideointelligenceV1p1beta1FaceAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation(od
          as api.GoogleCloudVideointelligenceV1p1beta1FaceDetectionAnnotation);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p1beta1FaceFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1FaceFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1FaceFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1FaceFrame(
          od as api.GoogleCloudVideointelligenceV1p1beta1FaceFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p1beta1FaceSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1FaceSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1FaceSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1FaceSegment(
          od as api.GoogleCloudVideointelligenceV1p1beta1FaceSegment);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1LabelAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1LabelAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1LabelAnnotation(
          od as api.GoogleCloudVideointelligenceV1p1beta1LabelAnnotation);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p1beta1LabelFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1LabelFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1LabelFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1LabelFrame(
          od as api.GoogleCloudVideointelligenceV1p1beta1LabelFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p1beta1LabelSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1LabelSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1LabelSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1LabelSegment(
          od as api.GoogleCloudVideointelligenceV1p1beta1LabelSegment);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation(od
          as api
              .GoogleCloudVideointelligenceV1p1beta1LogoRecognitionAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox(
          od as api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingBox);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly(od
          as api.GoogleCloudVideointelligenceV1p1beta1NormalizedBoundingPoly);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1NormalizedVertex', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1NormalizedVertex();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p1beta1NormalizedVertex.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1NormalizedVertex(
          od as api.GoogleCloudVideointelligenceV1p1beta1NormalizedVertex);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation(od
          as api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame(
          od as api.GoogleCloudVideointelligenceV1p1beta1ObjectTrackingFrame);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation(od
          as api
              .GoogleCloudVideointelligenceV1p1beta1PersonDetectionAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative(od
          as api
              .GoogleCloudVideointelligenceV1p1beta1SpeechRecognitionAlternative);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1SpeechTranscription',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1SpeechTranscription();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p1beta1SpeechTranscription.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1SpeechTranscription(
          od as api.GoogleCloudVideointelligenceV1p1beta1SpeechTranscription);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1TextAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1TextAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1TextAnnotation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1TextAnnotation(
          od as api.GoogleCloudVideointelligenceV1p1beta1TextAnnotation);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p1beta1TextFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1TextFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1TextFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1TextFrame(
          od as api.GoogleCloudVideointelligenceV1p1beta1TextFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p1beta1TextSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1TextSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1TextSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1TextSegment(
          od as api.GoogleCloudVideointelligenceV1p1beta1TextSegment);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1TimestampedObject', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1TimestampedObject();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p1beta1TimestampedObject.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1TimestampedObject(
          od as api.GoogleCloudVideointelligenceV1p1beta1TimestampedObject);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p1beta1Track', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1Track();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1Track.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1Track(
          od as api.GoogleCloudVideointelligenceV1p1beta1Track);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress(od
          as api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationProgress);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults(od
          as api.GoogleCloudVideointelligenceV1p1beta1VideoAnnotationResults);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p1beta1VideoSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1VideoSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1VideoSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1VideoSegment(
          od as api.GoogleCloudVideointelligenceV1p1beta1VideoSegment);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p1beta1WordInfo',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p1beta1WordInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p1beta1WordInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p1beta1WordInfo(
          od as api.GoogleCloudVideointelligenceV1p1beta1WordInfo);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress(
          od as api.GoogleCloudVideointelligenceV1p2beta1AnnotateVideoProgress);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse(
          od as api.GoogleCloudVideointelligenceV1p2beta1AnnotateVideoResponse);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1DetectedAttribute', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1DetectedAttribute();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1DetectedAttribute(
          od as api.GoogleCloudVideointelligenceV1p2beta1DetectedAttribute);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1DetectedLandmark', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1DetectedLandmark();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p2beta1DetectedLandmark.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1DetectedLandmark(
          od as api.GoogleCloudVideointelligenceV1p2beta1DetectedLandmark);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p2beta1Entity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1Entity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1Entity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1Entity(
          od as api.GoogleCloudVideointelligenceV1p2beta1Entity);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation(od
          as api
              .GoogleCloudVideointelligenceV1p2beta1ExplicitContentAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame(
          od as api.GoogleCloudVideointelligenceV1p2beta1ExplicitContentFrame);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1FaceAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1FaceAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1FaceAnnotation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1FaceAnnotation(
          od as api.GoogleCloudVideointelligenceV1p2beta1FaceAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation(od
          as api.GoogleCloudVideointelligenceV1p2beta1FaceDetectionAnnotation);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p2beta1FaceFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1FaceFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1FaceFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1FaceFrame(
          od as api.GoogleCloudVideointelligenceV1p2beta1FaceFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p2beta1FaceSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1FaceSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1FaceSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1FaceSegment(
          od as api.GoogleCloudVideointelligenceV1p2beta1FaceSegment);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1LabelAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1LabelAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1LabelAnnotation(
          od as api.GoogleCloudVideointelligenceV1p2beta1LabelAnnotation);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p2beta1LabelFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1LabelFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1LabelFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1LabelFrame(
          od as api.GoogleCloudVideointelligenceV1p2beta1LabelFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p2beta1LabelSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1LabelSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1LabelSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1LabelSegment(
          od as api.GoogleCloudVideointelligenceV1p2beta1LabelSegment);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation(od
          as api
              .GoogleCloudVideointelligenceV1p2beta1LogoRecognitionAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox(
          od as api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingBox);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly(od
          as api.GoogleCloudVideointelligenceV1p2beta1NormalizedBoundingPoly);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1NormalizedVertex', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1NormalizedVertex();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p2beta1NormalizedVertex.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1NormalizedVertex(
          od as api.GoogleCloudVideointelligenceV1p2beta1NormalizedVertex);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation(od
          as api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame(
          od as api.GoogleCloudVideointelligenceV1p2beta1ObjectTrackingFrame);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation(od
          as api
              .GoogleCloudVideointelligenceV1p2beta1PersonDetectionAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative(od
          as api
              .GoogleCloudVideointelligenceV1p2beta1SpeechRecognitionAlternative);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1SpeechTranscription',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1SpeechTranscription();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p2beta1SpeechTranscription.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1SpeechTranscription(
          od as api.GoogleCloudVideointelligenceV1p2beta1SpeechTranscription);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1TextAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1TextAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1TextAnnotation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1TextAnnotation(
          od as api.GoogleCloudVideointelligenceV1p2beta1TextAnnotation);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p2beta1TextFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1TextFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1TextFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1TextFrame(
          od as api.GoogleCloudVideointelligenceV1p2beta1TextFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p2beta1TextSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1TextSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1TextSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1TextSegment(
          od as api.GoogleCloudVideointelligenceV1p2beta1TextSegment);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1TimestampedObject', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1TimestampedObject();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p2beta1TimestampedObject.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1TimestampedObject(
          od as api.GoogleCloudVideointelligenceV1p2beta1TimestampedObject);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p2beta1Track', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1Track();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1Track.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1Track(
          od as api.GoogleCloudVideointelligenceV1p2beta1Track);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress(od
          as api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationProgress);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults(od
          as api.GoogleCloudVideointelligenceV1p2beta1VideoAnnotationResults);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p2beta1VideoSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1VideoSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1VideoSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1VideoSegment(
          od as api.GoogleCloudVideointelligenceV1p2beta1VideoSegment);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p2beta1WordInfo',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p2beta1WordInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p2beta1WordInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p2beta1WordInfo(
          od as api.GoogleCloudVideointelligenceV1p2beta1WordInfo);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress(
          od as api.GoogleCloudVideointelligenceV1p3beta1AnnotateVideoProgress);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse(
          od as api.GoogleCloudVideointelligenceV1p3beta1AnnotateVideoResponse);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p3beta1Celebrity',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1Celebrity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1Celebrity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1Celebrity(
          od as api.GoogleCloudVideointelligenceV1p3beta1Celebrity);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation(
          od as api
              .GoogleCloudVideointelligenceV1p3beta1CelebrityRecognitionAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1CelebrityTrack', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1CelebrityTrack();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1CelebrityTrack.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1CelebrityTrack(
          od as api.GoogleCloudVideointelligenceV1p3beta1CelebrityTrack);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1DetectedAttribute', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1DetectedAttribute();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1DetectedAttribute(
          od as api.GoogleCloudVideointelligenceV1p3beta1DetectedAttribute);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1DetectedLandmark', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1DetectedLandmark();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1DetectedLandmark.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1DetectedLandmark(
          od as api.GoogleCloudVideointelligenceV1p3beta1DetectedLandmark);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p3beta1Entity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1Entity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1Entity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1Entity(
          od as api.GoogleCloudVideointelligenceV1p3beta1Entity);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation(od
          as api
              .GoogleCloudVideointelligenceV1p3beta1ExplicitContentAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame(
          od as api.GoogleCloudVideointelligenceV1p3beta1ExplicitContentFrame);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1FaceAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1FaceAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1FaceAnnotation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1FaceAnnotation(
          od as api.GoogleCloudVideointelligenceV1p3beta1FaceAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation(od
          as api.GoogleCloudVideointelligenceV1p3beta1FaceDetectionAnnotation);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p3beta1FaceFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1FaceFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1FaceFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1FaceFrame(
          od as api.GoogleCloudVideointelligenceV1p3beta1FaceFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p3beta1FaceSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1FaceSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1FaceSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1FaceSegment(
          od as api.GoogleCloudVideointelligenceV1p3beta1FaceSegment);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1LabelAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1LabelAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1LabelAnnotation(
          od as api.GoogleCloudVideointelligenceV1p3beta1LabelAnnotation);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p3beta1LabelFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1LabelFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1LabelFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1LabelFrame(
          od as api.GoogleCloudVideointelligenceV1p3beta1LabelFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p3beta1LabelSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1LabelSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1LabelSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1LabelSegment(
          od as api.GoogleCloudVideointelligenceV1p3beta1LabelSegment);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation(od
          as api
              .GoogleCloudVideointelligenceV1p3beta1LogoRecognitionAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox(
          od as api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingBox);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly(od
          as api.GoogleCloudVideointelligenceV1p3beta1NormalizedBoundingPoly);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1NormalizedVertex', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1NormalizedVertex();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1NormalizedVertex.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1NormalizedVertex(
          od as api.GoogleCloudVideointelligenceV1p3beta1NormalizedVertex);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation(od
          as api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame(
          od as api.GoogleCloudVideointelligenceV1p3beta1ObjectTrackingFrame);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation(od
          as api
              .GoogleCloudVideointelligenceV1p3beta1PersonDetectionAnnotation);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity(
          od as api.GoogleCloudVideointelligenceV1p3beta1RecognizedCelebrity);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative(od
          as api
              .GoogleCloudVideointelligenceV1p3beta1SpeechRecognitionAlternative);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1SpeechTranscription',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1SpeechTranscription();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1SpeechTranscription.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1SpeechTranscription(
          od as api.GoogleCloudVideointelligenceV1p3beta1SpeechTranscription);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse(
          od as api
              .GoogleCloudVideointelligenceV1p3beta1StreamingAnnotateVideoResponse);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults
              .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults(
          od as api
              .GoogleCloudVideointelligenceV1p3beta1StreamingVideoAnnotationResults);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1TextAnnotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1TextAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1TextAnnotation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1TextAnnotation(
          od as api.GoogleCloudVideointelligenceV1p3beta1TextAnnotation);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p3beta1TextFrame',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1TextFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1TextFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1TextFrame(
          od as api.GoogleCloudVideointelligenceV1p3beta1TextFrame);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p3beta1TextSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1TextSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1TextSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1TextSegment(
          od as api.GoogleCloudVideointelligenceV1p3beta1TextSegment);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1TimestampedObject', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1TimestampedObject();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleCloudVideointelligenceV1p3beta1TimestampedObject.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1TimestampedObject(
          od as api.GoogleCloudVideointelligenceV1p3beta1TimestampedObject);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p3beta1Track', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1Track();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1Track.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1Track(
          od as api.GoogleCloudVideointelligenceV1p3beta1Track);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress(od
          as api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationProgress);
    });
  });

  unittest.group(
      'obj-schema-GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults(od
          as api.GoogleCloudVideointelligenceV1p3beta1VideoAnnotationResults);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p3beta1VideoSegment',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1VideoSegment();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1VideoSegment.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1VideoSegment(
          od as api.GoogleCloudVideointelligenceV1p3beta1VideoSegment);
    });
  });

  unittest.group('obj-schema-GoogleCloudVideointelligenceV1p3beta1WordInfo',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudVideointelligenceV1p3beta1WordInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudVideointelligenceV1p3beta1WordInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudVideointelligenceV1p3beta1WordInfo(
          od as api.GoogleCloudVideointelligenceV1p3beta1WordInfo);
    });
  });

  unittest.group('obj-schema-GoogleLongrunningCancelOperationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleLongrunningCancelOperationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleLongrunningCancelOperationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleLongrunningCancelOperationRequest(
          od as api.GoogleLongrunningCancelOperationRequest);
    });
  });

  unittest.group('obj-schema-GoogleLongrunningListOperationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleLongrunningListOperationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleLongrunningListOperationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleLongrunningListOperationsResponse(
          od as api.GoogleLongrunningListOperationsResponse);
    });
  });

  unittest.group('obj-schema-GoogleLongrunningOperation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleLongrunningOperation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleLongrunningOperation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleLongrunningOperation(od as api.GoogleLongrunningOperation);
    });
  });

  unittest.group('obj-schema-GoogleProtobufEmpty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleProtobufEmpty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleProtobufEmpty.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleProtobufEmpty(od as api.GoogleProtobufEmpty);
    });
  });

  unittest.group('obj-schema-GoogleRpcStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleRpcStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleRpcStatus.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleRpcStatus(od as api.GoogleRpcStatus);
    });
  });

  unittest.group('resource-OperationsProjectsLocationsOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.CloudVideoIntelligenceApi(mock)
          .operations
          .projects
          .locations
          .operations;
      var arg_name = 'foo';
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
          unittest.equals("v1/operations/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildGoogleProtobufEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.cancel(arg_name, $fields: arg_$fields);
      checkGoogleProtobufEmpty(response as api.GoogleProtobufEmpty);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudVideoIntelligenceApi(mock)
          .operations
          .projects
          .locations
          .operations;
      var arg_name = 'foo';
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
          unittest.equals("v1/operations/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildGoogleProtobufEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkGoogleProtobufEmpty(response as api.GoogleProtobufEmpty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.CloudVideoIntelligenceApi(mock)
          .operations
          .projects
          .locations
          .operations;
      var arg_name = 'foo';
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
          unittest.equals("v1/operations/"),
        );
        pathOffset += 14;
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
        var resp = convert.json.encode(buildGoogleLongrunningOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGoogleLongrunningOperation(
          response as api.GoogleLongrunningOperation);
    });
  });

  unittest.group('resource-ProjectsLocationsOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudVideoIntelligenceApi(mock).projects.locations.operations;
      var arg_request = buildGoogleLongrunningCancelOperationRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleLongrunningCancelOperationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleLongrunningCancelOperationRequest(
            obj as api.GoogleLongrunningCancelOperationRequest);

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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
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
        var resp = convert.json.encode(buildGoogleProtobufEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.cancel(arg_request, arg_name, $fields: arg_$fields);
      checkGoogleProtobufEmpty(response as api.GoogleProtobufEmpty);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudVideoIntelligenceApi(mock).projects.locations.operations;
      var arg_name = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
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
        var resp = convert.json.encode(buildGoogleProtobufEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkGoogleProtobufEmpty(response as api.GoogleProtobufEmpty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudVideoIntelligenceApi(mock).projects.locations.operations;
      var arg_name = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
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
        var resp = convert.json.encode(buildGoogleLongrunningOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGoogleLongrunningOperation(
          response as api.GoogleLongrunningOperation);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res =
          api.CloudVideoIntelligenceApi(mock).projects.locations.operations;
      var arg_name = 'foo';
      var arg_filter = 'foo';
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
          path.substring(pathOffset, pathOffset + 3),
          unittest.equals("v1/"),
        );
        pathOffset += 3;
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
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
        var resp =
            convert.json.encode(buildGoogleLongrunningListOperationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleLongrunningListOperationsResponse(
          response as api.GoogleLongrunningListOperationsResponse);
    });
  });

  unittest.group('resource-VideosResource', () {
    unittest.test('method--annotate', () async {
      var mock = HttpServerMock();
      var res = api.CloudVideoIntelligenceApi(mock).videos;
      var arg_request =
          buildGoogleCloudVideointelligenceV1AnnotateVideoRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.GoogleCloudVideointelligenceV1AnnotateVideoRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudVideointelligenceV1AnnotateVideoRequest(
            obj as api.GoogleCloudVideointelligenceV1AnnotateVideoRequest);

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
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("v1/videos:annotate"),
        );
        pathOffset += 18;

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
        var resp = convert.json.encode(buildGoogleLongrunningOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.annotate(arg_request, $fields: arg_$fields);
      checkGoogleLongrunningOperation(
          response as api.GoogleLongrunningOperation);
    });
  });
}
