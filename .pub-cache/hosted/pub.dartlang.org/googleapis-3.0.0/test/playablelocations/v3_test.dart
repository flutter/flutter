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

import 'package:googleapis/playablelocations/v3.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterGoogleMapsPlayablelocationsV3Impression = 0;
api.GoogleMapsPlayablelocationsV3Impression
    buildGoogleMapsPlayablelocationsV3Impression() {
  var o = api.GoogleMapsPlayablelocationsV3Impression();
  buildCounterGoogleMapsPlayablelocationsV3Impression++;
  if (buildCounterGoogleMapsPlayablelocationsV3Impression < 3) {
    o.gameObjectType = 42;
    o.impressionType = 'foo';
    o.locationName = 'foo';
  }
  buildCounterGoogleMapsPlayablelocationsV3Impression--;
  return o;
}

void checkGoogleMapsPlayablelocationsV3Impression(
    api.GoogleMapsPlayablelocationsV3Impression o) {
  buildCounterGoogleMapsPlayablelocationsV3Impression++;
  if (buildCounterGoogleMapsPlayablelocationsV3Impression < 3) {
    unittest.expect(
      o.gameObjectType!,
      unittest.equals(42),
    );
    unittest.expect(
      o.impressionType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locationName!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleMapsPlayablelocationsV3Impression--;
}

core.List<api.GoogleMapsPlayablelocationsV3Impression> buildUnnamed4378() {
  var o = <api.GoogleMapsPlayablelocationsV3Impression>[];
  o.add(buildGoogleMapsPlayablelocationsV3Impression());
  o.add(buildGoogleMapsPlayablelocationsV3Impression());
  return o;
}

void checkUnnamed4378(
    core.List<api.GoogleMapsPlayablelocationsV3Impression> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleMapsPlayablelocationsV3Impression(
      o[0] as api.GoogleMapsPlayablelocationsV3Impression);
  checkGoogleMapsPlayablelocationsV3Impression(
      o[1] as api.GoogleMapsPlayablelocationsV3Impression);
}

core.int buildCounterGoogleMapsPlayablelocationsV3LogImpressionsRequest = 0;
api.GoogleMapsPlayablelocationsV3LogImpressionsRequest
    buildGoogleMapsPlayablelocationsV3LogImpressionsRequest() {
  var o = api.GoogleMapsPlayablelocationsV3LogImpressionsRequest();
  buildCounterGoogleMapsPlayablelocationsV3LogImpressionsRequest++;
  if (buildCounterGoogleMapsPlayablelocationsV3LogImpressionsRequest < 3) {
    o.clientInfo = buildGoogleMapsUnityClientInfo();
    o.impressions = buildUnnamed4378();
    o.requestId = 'foo';
  }
  buildCounterGoogleMapsPlayablelocationsV3LogImpressionsRequest--;
  return o;
}

void checkGoogleMapsPlayablelocationsV3LogImpressionsRequest(
    api.GoogleMapsPlayablelocationsV3LogImpressionsRequest o) {
  buildCounterGoogleMapsPlayablelocationsV3LogImpressionsRequest++;
  if (buildCounterGoogleMapsPlayablelocationsV3LogImpressionsRequest < 3) {
    checkGoogleMapsUnityClientInfo(
        o.clientInfo! as api.GoogleMapsUnityClientInfo);
    checkUnnamed4378(o.impressions!);
    unittest.expect(
      o.requestId!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleMapsPlayablelocationsV3LogImpressionsRequest--;
}

core.int buildCounterGoogleMapsPlayablelocationsV3LogImpressionsResponse = 0;
api.GoogleMapsPlayablelocationsV3LogImpressionsResponse
    buildGoogleMapsPlayablelocationsV3LogImpressionsResponse() {
  var o = api.GoogleMapsPlayablelocationsV3LogImpressionsResponse();
  buildCounterGoogleMapsPlayablelocationsV3LogImpressionsResponse++;
  if (buildCounterGoogleMapsPlayablelocationsV3LogImpressionsResponse < 3) {}
  buildCounterGoogleMapsPlayablelocationsV3LogImpressionsResponse--;
  return o;
}

void checkGoogleMapsPlayablelocationsV3LogImpressionsResponse(
    api.GoogleMapsPlayablelocationsV3LogImpressionsResponse o) {
  buildCounterGoogleMapsPlayablelocationsV3LogImpressionsResponse++;
  if (buildCounterGoogleMapsPlayablelocationsV3LogImpressionsResponse < 3) {}
  buildCounterGoogleMapsPlayablelocationsV3LogImpressionsResponse--;
}

core.List<api.GoogleMapsPlayablelocationsV3PlayerReport> buildUnnamed4379() {
  var o = <api.GoogleMapsPlayablelocationsV3PlayerReport>[];
  o.add(buildGoogleMapsPlayablelocationsV3PlayerReport());
  o.add(buildGoogleMapsPlayablelocationsV3PlayerReport());
  return o;
}

void checkUnnamed4379(
    core.List<api.GoogleMapsPlayablelocationsV3PlayerReport> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleMapsPlayablelocationsV3PlayerReport(
      o[0] as api.GoogleMapsPlayablelocationsV3PlayerReport);
  checkGoogleMapsPlayablelocationsV3PlayerReport(
      o[1] as api.GoogleMapsPlayablelocationsV3PlayerReport);
}

core.int buildCounterGoogleMapsPlayablelocationsV3LogPlayerReportsRequest = 0;
api.GoogleMapsPlayablelocationsV3LogPlayerReportsRequest
    buildGoogleMapsPlayablelocationsV3LogPlayerReportsRequest() {
  var o = api.GoogleMapsPlayablelocationsV3LogPlayerReportsRequest();
  buildCounterGoogleMapsPlayablelocationsV3LogPlayerReportsRequest++;
  if (buildCounterGoogleMapsPlayablelocationsV3LogPlayerReportsRequest < 3) {
    o.clientInfo = buildGoogleMapsUnityClientInfo();
    o.playerReports = buildUnnamed4379();
    o.requestId = 'foo';
  }
  buildCounterGoogleMapsPlayablelocationsV3LogPlayerReportsRequest--;
  return o;
}

void checkGoogleMapsPlayablelocationsV3LogPlayerReportsRequest(
    api.GoogleMapsPlayablelocationsV3LogPlayerReportsRequest o) {
  buildCounterGoogleMapsPlayablelocationsV3LogPlayerReportsRequest++;
  if (buildCounterGoogleMapsPlayablelocationsV3LogPlayerReportsRequest < 3) {
    checkGoogleMapsUnityClientInfo(
        o.clientInfo! as api.GoogleMapsUnityClientInfo);
    checkUnnamed4379(o.playerReports!);
    unittest.expect(
      o.requestId!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleMapsPlayablelocationsV3LogPlayerReportsRequest--;
}

core.int buildCounterGoogleMapsPlayablelocationsV3LogPlayerReportsResponse = 0;
api.GoogleMapsPlayablelocationsV3LogPlayerReportsResponse
    buildGoogleMapsPlayablelocationsV3LogPlayerReportsResponse() {
  var o = api.GoogleMapsPlayablelocationsV3LogPlayerReportsResponse();
  buildCounterGoogleMapsPlayablelocationsV3LogPlayerReportsResponse++;
  if (buildCounterGoogleMapsPlayablelocationsV3LogPlayerReportsResponse < 3) {}
  buildCounterGoogleMapsPlayablelocationsV3LogPlayerReportsResponse--;
  return o;
}

void checkGoogleMapsPlayablelocationsV3LogPlayerReportsResponse(
    api.GoogleMapsPlayablelocationsV3LogPlayerReportsResponse o) {
  buildCounterGoogleMapsPlayablelocationsV3LogPlayerReportsResponse++;
  if (buildCounterGoogleMapsPlayablelocationsV3LogPlayerReportsResponse < 3) {}
  buildCounterGoogleMapsPlayablelocationsV3LogPlayerReportsResponse--;
}

core.List<core.String> buildUnnamed4380() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4380(core.List<core.String> o) {
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

core.int buildCounterGoogleMapsPlayablelocationsV3PlayerReport = 0;
api.GoogleMapsPlayablelocationsV3PlayerReport
    buildGoogleMapsPlayablelocationsV3PlayerReport() {
  var o = api.GoogleMapsPlayablelocationsV3PlayerReport();
  buildCounterGoogleMapsPlayablelocationsV3PlayerReport++;
  if (buildCounterGoogleMapsPlayablelocationsV3PlayerReport < 3) {
    o.languageCode = 'foo';
    o.locationName = 'foo';
    o.reasonDetails = 'foo';
    o.reasons = buildUnnamed4380();
  }
  buildCounterGoogleMapsPlayablelocationsV3PlayerReport--;
  return o;
}

void checkGoogleMapsPlayablelocationsV3PlayerReport(
    api.GoogleMapsPlayablelocationsV3PlayerReport o) {
  buildCounterGoogleMapsPlayablelocationsV3PlayerReport++;
  if (buildCounterGoogleMapsPlayablelocationsV3PlayerReport < 3) {
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locationName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reasonDetails!,
      unittest.equals('foo'),
    );
    checkUnnamed4380(o.reasons!);
  }
  buildCounterGoogleMapsPlayablelocationsV3PlayerReport--;
}

core.int buildCounterGoogleMapsPlayablelocationsV3SampleAreaFilter = 0;
api.GoogleMapsPlayablelocationsV3SampleAreaFilter
    buildGoogleMapsPlayablelocationsV3SampleAreaFilter() {
  var o = api.GoogleMapsPlayablelocationsV3SampleAreaFilter();
  buildCounterGoogleMapsPlayablelocationsV3SampleAreaFilter++;
  if (buildCounterGoogleMapsPlayablelocationsV3SampleAreaFilter < 3) {
    o.s2CellId = 'foo';
  }
  buildCounterGoogleMapsPlayablelocationsV3SampleAreaFilter--;
  return o;
}

void checkGoogleMapsPlayablelocationsV3SampleAreaFilter(
    api.GoogleMapsPlayablelocationsV3SampleAreaFilter o) {
  buildCounterGoogleMapsPlayablelocationsV3SampleAreaFilter++;
  if (buildCounterGoogleMapsPlayablelocationsV3SampleAreaFilter < 3) {
    unittest.expect(
      o.s2CellId!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleMapsPlayablelocationsV3SampleAreaFilter--;
}

core.int buildCounterGoogleMapsPlayablelocationsV3SampleCriterion = 0;
api.GoogleMapsPlayablelocationsV3SampleCriterion
    buildGoogleMapsPlayablelocationsV3SampleCriterion() {
  var o = api.GoogleMapsPlayablelocationsV3SampleCriterion();
  buildCounterGoogleMapsPlayablelocationsV3SampleCriterion++;
  if (buildCounterGoogleMapsPlayablelocationsV3SampleCriterion < 3) {
    o.fieldsToReturn = 'foo';
    o.filter = buildGoogleMapsPlayablelocationsV3SampleFilter();
    o.gameObjectType = 42;
  }
  buildCounterGoogleMapsPlayablelocationsV3SampleCriterion--;
  return o;
}

void checkGoogleMapsPlayablelocationsV3SampleCriterion(
    api.GoogleMapsPlayablelocationsV3SampleCriterion o) {
  buildCounterGoogleMapsPlayablelocationsV3SampleCriterion++;
  if (buildCounterGoogleMapsPlayablelocationsV3SampleCriterion < 3) {
    unittest.expect(
      o.fieldsToReturn!,
      unittest.equals('foo'),
    );
    checkGoogleMapsPlayablelocationsV3SampleFilter(
        o.filter! as api.GoogleMapsPlayablelocationsV3SampleFilter);
    unittest.expect(
      o.gameObjectType!,
      unittest.equals(42),
    );
  }
  buildCounterGoogleMapsPlayablelocationsV3SampleCriterion--;
}

core.List<core.String> buildUnnamed4381() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4381(core.List<core.String> o) {
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

core.int buildCounterGoogleMapsPlayablelocationsV3SampleFilter = 0;
api.GoogleMapsPlayablelocationsV3SampleFilter
    buildGoogleMapsPlayablelocationsV3SampleFilter() {
  var o = api.GoogleMapsPlayablelocationsV3SampleFilter();
  buildCounterGoogleMapsPlayablelocationsV3SampleFilter++;
  if (buildCounterGoogleMapsPlayablelocationsV3SampleFilter < 3) {
    o.includedTypes = buildUnnamed4381();
    o.maxLocationCount = 42;
    o.spacing = buildGoogleMapsPlayablelocationsV3SampleSpacingOptions();
  }
  buildCounterGoogleMapsPlayablelocationsV3SampleFilter--;
  return o;
}

void checkGoogleMapsPlayablelocationsV3SampleFilter(
    api.GoogleMapsPlayablelocationsV3SampleFilter o) {
  buildCounterGoogleMapsPlayablelocationsV3SampleFilter++;
  if (buildCounterGoogleMapsPlayablelocationsV3SampleFilter < 3) {
    checkUnnamed4381(o.includedTypes!);
    unittest.expect(
      o.maxLocationCount!,
      unittest.equals(42),
    );
    checkGoogleMapsPlayablelocationsV3SampleSpacingOptions(
        o.spacing! as api.GoogleMapsPlayablelocationsV3SampleSpacingOptions);
  }
  buildCounterGoogleMapsPlayablelocationsV3SampleFilter--;
}

core.List<core.String> buildUnnamed4382() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed4382(core.List<core.String> o) {
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

core.int buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocation = 0;
api.GoogleMapsPlayablelocationsV3SamplePlayableLocation
    buildGoogleMapsPlayablelocationsV3SamplePlayableLocation() {
  var o = api.GoogleMapsPlayablelocationsV3SamplePlayableLocation();
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocation++;
  if (buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocation < 3) {
    o.centerPoint = buildGoogleTypeLatLng();
    o.name = 'foo';
    o.placeId = 'foo';
    o.plusCode = 'foo';
    o.snappedPoint = buildGoogleTypeLatLng();
    o.types = buildUnnamed4382();
  }
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocation--;
  return o;
}

void checkGoogleMapsPlayablelocationsV3SamplePlayableLocation(
    api.GoogleMapsPlayablelocationsV3SamplePlayableLocation o) {
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocation++;
  if (buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocation < 3) {
    checkGoogleTypeLatLng(o.centerPoint! as api.GoogleTypeLatLng);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.placeId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.plusCode!,
      unittest.equals('foo'),
    );
    checkGoogleTypeLatLng(o.snappedPoint! as api.GoogleTypeLatLng);
    checkUnnamed4382(o.types!);
  }
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocation--;
}

core.List<api.GoogleMapsPlayablelocationsV3SamplePlayableLocation>
    buildUnnamed4383() {
  var o = <api.GoogleMapsPlayablelocationsV3SamplePlayableLocation>[];
  o.add(buildGoogleMapsPlayablelocationsV3SamplePlayableLocation());
  o.add(buildGoogleMapsPlayablelocationsV3SamplePlayableLocation());
  return o;
}

void checkUnnamed4383(
    core.List<api.GoogleMapsPlayablelocationsV3SamplePlayableLocation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleMapsPlayablelocationsV3SamplePlayableLocation(
      o[0] as api.GoogleMapsPlayablelocationsV3SamplePlayableLocation);
  checkGoogleMapsPlayablelocationsV3SamplePlayableLocation(
      o[1] as api.GoogleMapsPlayablelocationsV3SamplePlayableLocation);
}

core.int buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationList =
    0;
api.GoogleMapsPlayablelocationsV3SamplePlayableLocationList
    buildGoogleMapsPlayablelocationsV3SamplePlayableLocationList() {
  var o = api.GoogleMapsPlayablelocationsV3SamplePlayableLocationList();
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationList++;
  if (buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationList < 3) {
    o.locations = buildUnnamed4383();
  }
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationList--;
  return o;
}

void checkGoogleMapsPlayablelocationsV3SamplePlayableLocationList(
    api.GoogleMapsPlayablelocationsV3SamplePlayableLocationList o) {
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationList++;
  if (buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationList < 3) {
    checkUnnamed4383(o.locations!);
  }
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationList--;
}

core.List<api.GoogleMapsPlayablelocationsV3SampleCriterion> buildUnnamed4384() {
  var o = <api.GoogleMapsPlayablelocationsV3SampleCriterion>[];
  o.add(buildGoogleMapsPlayablelocationsV3SampleCriterion());
  o.add(buildGoogleMapsPlayablelocationsV3SampleCriterion());
  return o;
}

void checkUnnamed4384(
    core.List<api.GoogleMapsPlayablelocationsV3SampleCriterion> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleMapsPlayablelocationsV3SampleCriterion(
      o[0] as api.GoogleMapsPlayablelocationsV3SampleCriterion);
  checkGoogleMapsPlayablelocationsV3SampleCriterion(
      o[1] as api.GoogleMapsPlayablelocationsV3SampleCriterion);
}

core.int
    buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest = 0;
api.GoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest
    buildGoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest() {
  var o = api.GoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest();
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest++;
  if (buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest <
      3) {
    o.areaFilter = buildGoogleMapsPlayablelocationsV3SampleAreaFilter();
    o.criteria = buildUnnamed4384();
  }
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest--;
  return o;
}

void checkGoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest(
    api.GoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest o) {
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest++;
  if (buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest <
      3) {
    checkGoogleMapsPlayablelocationsV3SampleAreaFilter(
        o.areaFilter! as api.GoogleMapsPlayablelocationsV3SampleAreaFilter);
    checkUnnamed4384(o.criteria!);
  }
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest--;
}

core.Map<core.String,
        api.GoogleMapsPlayablelocationsV3SamplePlayableLocationList>
    buildUnnamed4385() {
  var o = <core.String,
      api.GoogleMapsPlayablelocationsV3SamplePlayableLocationList>{};
  o['x'] = buildGoogleMapsPlayablelocationsV3SamplePlayableLocationList();
  o['y'] = buildGoogleMapsPlayablelocationsV3SamplePlayableLocationList();
  return o;
}

void checkUnnamed4385(
    core.Map<core.String,
            api.GoogleMapsPlayablelocationsV3SamplePlayableLocationList>
        o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleMapsPlayablelocationsV3SamplePlayableLocationList(
      o['x']! as api.GoogleMapsPlayablelocationsV3SamplePlayableLocationList);
  checkGoogleMapsPlayablelocationsV3SamplePlayableLocationList(
      o['y']! as api.GoogleMapsPlayablelocationsV3SamplePlayableLocationList);
}

core.int
    buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse =
    0;
api.GoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse
    buildGoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse() {
  var o = api.GoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse();
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse++;
  if (buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse <
      3) {
    o.locationsPerGameObjectType = buildUnnamed4385();
    o.ttl = 'foo';
  }
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse--;
  return o;
}

void checkGoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse(
    api.GoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse o) {
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse++;
  if (buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse <
      3) {
    checkUnnamed4385(o.locationsPerGameObjectType!);
    unittest.expect(
      o.ttl!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse--;
}

core.int buildCounterGoogleMapsPlayablelocationsV3SampleSpacingOptions = 0;
api.GoogleMapsPlayablelocationsV3SampleSpacingOptions
    buildGoogleMapsPlayablelocationsV3SampleSpacingOptions() {
  var o = api.GoogleMapsPlayablelocationsV3SampleSpacingOptions();
  buildCounterGoogleMapsPlayablelocationsV3SampleSpacingOptions++;
  if (buildCounterGoogleMapsPlayablelocationsV3SampleSpacingOptions < 3) {
    o.minSpacingMeters = 42.0;
    o.pointType = 'foo';
  }
  buildCounterGoogleMapsPlayablelocationsV3SampleSpacingOptions--;
  return o;
}

void checkGoogleMapsPlayablelocationsV3SampleSpacingOptions(
    api.GoogleMapsPlayablelocationsV3SampleSpacingOptions o) {
  buildCounterGoogleMapsPlayablelocationsV3SampleSpacingOptions++;
  if (buildCounterGoogleMapsPlayablelocationsV3SampleSpacingOptions < 3) {
    unittest.expect(
      o.minSpacingMeters!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.pointType!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleMapsPlayablelocationsV3SampleSpacingOptions--;
}

core.int buildCounterGoogleMapsUnityClientInfo = 0;
api.GoogleMapsUnityClientInfo buildGoogleMapsUnityClientInfo() {
  var o = api.GoogleMapsUnityClientInfo();
  buildCounterGoogleMapsUnityClientInfo++;
  if (buildCounterGoogleMapsUnityClientInfo < 3) {
    o.apiClient = 'foo';
    o.applicationId = 'foo';
    o.applicationVersion = 'foo';
    o.deviceModel = 'foo';
    o.languageCode = 'foo';
    o.operatingSystem = 'foo';
    o.operatingSystemBuild = 'foo';
    o.platform = 'foo';
  }
  buildCounterGoogleMapsUnityClientInfo--;
  return o;
}

void checkGoogleMapsUnityClientInfo(api.GoogleMapsUnityClientInfo o) {
  buildCounterGoogleMapsUnityClientInfo++;
  if (buildCounterGoogleMapsUnityClientInfo < 3) {
    unittest.expect(
      o.apiClient!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.applicationId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.applicationVersion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deviceModel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operatingSystem!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.operatingSystemBuild!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.platform!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleMapsUnityClientInfo--;
}

core.int buildCounterGoogleTypeLatLng = 0;
api.GoogleTypeLatLng buildGoogleTypeLatLng() {
  var o = api.GoogleTypeLatLng();
  buildCounterGoogleTypeLatLng++;
  if (buildCounterGoogleTypeLatLng < 3) {
    o.latitude = 42.0;
    o.longitude = 42.0;
  }
  buildCounterGoogleTypeLatLng--;
  return o;
}

void checkGoogleTypeLatLng(api.GoogleTypeLatLng o) {
  buildCounterGoogleTypeLatLng++;
  if (buildCounterGoogleTypeLatLng < 3) {
    unittest.expect(
      o.latitude!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.longitude!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleTypeLatLng--;
}

void main() {
  unittest.group('obj-schema-GoogleMapsPlayablelocationsV3Impression', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleMapsPlayablelocationsV3Impression();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleMapsPlayablelocationsV3Impression.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsPlayablelocationsV3Impression(
          od as api.GoogleMapsPlayablelocationsV3Impression);
    });
  });

  unittest.group(
      'obj-schema-GoogleMapsPlayablelocationsV3LogImpressionsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleMapsPlayablelocationsV3LogImpressionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleMapsPlayablelocationsV3LogImpressionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsPlayablelocationsV3LogImpressionsRequest(
          od as api.GoogleMapsPlayablelocationsV3LogImpressionsRequest);
    });
  });

  unittest.group(
      'obj-schema-GoogleMapsPlayablelocationsV3LogImpressionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleMapsPlayablelocationsV3LogImpressionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleMapsPlayablelocationsV3LogImpressionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsPlayablelocationsV3LogImpressionsResponse(
          od as api.GoogleMapsPlayablelocationsV3LogImpressionsResponse);
    });
  });

  unittest.group(
      'obj-schema-GoogleMapsPlayablelocationsV3LogPlayerReportsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleMapsPlayablelocationsV3LogPlayerReportsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleMapsPlayablelocationsV3LogPlayerReportsRequest.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsPlayablelocationsV3LogPlayerReportsRequest(
          od as api.GoogleMapsPlayablelocationsV3LogPlayerReportsRequest);
    });
  });

  unittest.group(
      'obj-schema-GoogleMapsPlayablelocationsV3LogPlayerReportsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleMapsPlayablelocationsV3LogPlayerReportsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleMapsPlayablelocationsV3LogPlayerReportsResponse.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsPlayablelocationsV3LogPlayerReportsResponse(
          od as api.GoogleMapsPlayablelocationsV3LogPlayerReportsResponse);
    });
  });

  unittest.group('obj-schema-GoogleMapsPlayablelocationsV3PlayerReport', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleMapsPlayablelocationsV3PlayerReport();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleMapsPlayablelocationsV3PlayerReport.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsPlayablelocationsV3PlayerReport(
          od as api.GoogleMapsPlayablelocationsV3PlayerReport);
    });
  });

  unittest.group('obj-schema-GoogleMapsPlayablelocationsV3SampleAreaFilter',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleMapsPlayablelocationsV3SampleAreaFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleMapsPlayablelocationsV3SampleAreaFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsPlayablelocationsV3SampleAreaFilter(
          od as api.GoogleMapsPlayablelocationsV3SampleAreaFilter);
    });
  });

  unittest.group('obj-schema-GoogleMapsPlayablelocationsV3SampleCriterion', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleMapsPlayablelocationsV3SampleCriterion();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleMapsPlayablelocationsV3SampleCriterion.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsPlayablelocationsV3SampleCriterion(
          od as api.GoogleMapsPlayablelocationsV3SampleCriterion);
    });
  });

  unittest.group('obj-schema-GoogleMapsPlayablelocationsV3SampleFilter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleMapsPlayablelocationsV3SampleFilter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleMapsPlayablelocationsV3SampleFilter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsPlayablelocationsV3SampleFilter(
          od as api.GoogleMapsPlayablelocationsV3SampleFilter);
    });
  });

  unittest.group(
      'obj-schema-GoogleMapsPlayablelocationsV3SamplePlayableLocation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleMapsPlayablelocationsV3SamplePlayableLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleMapsPlayablelocationsV3SamplePlayableLocation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsPlayablelocationsV3SamplePlayableLocation(
          od as api.GoogleMapsPlayablelocationsV3SamplePlayableLocation);
    });
  });

  unittest.group(
      'obj-schema-GoogleMapsPlayablelocationsV3SamplePlayableLocationList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleMapsPlayablelocationsV3SamplePlayableLocationList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GoogleMapsPlayablelocationsV3SamplePlayableLocationList.fromJson(
              oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsPlayablelocationsV3SamplePlayableLocationList(
          od as api.GoogleMapsPlayablelocationsV3SamplePlayableLocationList);
    });
  });

  unittest.group(
      'obj-schema-GoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest(od
          as api.GoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest);
    });
  });

  unittest.group(
      'obj-schema-GoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o =
          buildGoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse
          .fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse(od
          as api.GoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse);
    });
  });

  unittest.group('obj-schema-GoogleMapsPlayablelocationsV3SampleSpacingOptions',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleMapsPlayablelocationsV3SampleSpacingOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleMapsPlayablelocationsV3SampleSpacingOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsPlayablelocationsV3SampleSpacingOptions(
          od as api.GoogleMapsPlayablelocationsV3SampleSpacingOptions);
    });
  });

  unittest.group('obj-schema-GoogleMapsUnityClientInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleMapsUnityClientInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleMapsUnityClientInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleMapsUnityClientInfo(od as api.GoogleMapsUnityClientInfo);
    });
  });

  unittest.group('obj-schema-GoogleTypeLatLng', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleTypeLatLng();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleTypeLatLng.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleTypeLatLng(od as api.GoogleTypeLatLng);
    });
  });

  unittest.group('resource-V3Resource', () {
    unittest.test('method--logImpressions', () async {
      var mock = HttpServerMock();
      var res = api.PlayableLocationsApi(mock).v3;
      var arg_request =
          buildGoogleMapsPlayablelocationsV3LogImpressionsRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.GoogleMapsPlayablelocationsV3LogImpressionsRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkGoogleMapsPlayablelocationsV3LogImpressionsRequest(
            obj as api.GoogleMapsPlayablelocationsV3LogImpressionsRequest);

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
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("v3:logImpressions"),
        );
        pathOffset += 17;

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
        var resp = convert.json
            .encode(buildGoogleMapsPlayablelocationsV3LogImpressionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.logImpressions(arg_request, $fields: arg_$fields);
      checkGoogleMapsPlayablelocationsV3LogImpressionsResponse(
          response as api.GoogleMapsPlayablelocationsV3LogImpressionsResponse);
    });

    unittest.test('method--logPlayerReports', () async {
      var mock = HttpServerMock();
      var res = api.PlayableLocationsApi(mock).v3;
      var arg_request =
          buildGoogleMapsPlayablelocationsV3LogPlayerReportsRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.GoogleMapsPlayablelocationsV3LogPlayerReportsRequest.fromJson(
                json as core.Map<core.String, core.dynamic>);
        checkGoogleMapsPlayablelocationsV3LogPlayerReportsRequest(
            obj as api.GoogleMapsPlayablelocationsV3LogPlayerReportsRequest);

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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("v3:logPlayerReports"),
        );
        pathOffset += 19;

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
        var resp = convert.json.encode(
            buildGoogleMapsPlayablelocationsV3LogPlayerReportsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.logPlayerReports(arg_request, $fields: arg_$fields);
      checkGoogleMapsPlayablelocationsV3LogPlayerReportsResponse(response
          as api.GoogleMapsPlayablelocationsV3LogPlayerReportsResponse);
    });

    unittest.test('method--samplePlayableLocations', () async {
      var mock = HttpServerMock();
      var res = api.PlayableLocationsApi(mock).v3;
      var arg_request =
          buildGoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.GoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest
                .fromJson(json as core.Map<core.String, core.dynamic>);
        checkGoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest(obj
            as api.GoogleMapsPlayablelocationsV3SamplePlayableLocationsRequest);

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
          path.substring(pathOffset, pathOffset + 26),
          unittest.equals("v3:samplePlayableLocations"),
        );
        pathOffset += 26;

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
        var resp = convert.json.encode(
            buildGoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.samplePlayableLocations(arg_request, $fields: arg_$fields);
      checkGoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse(response
          as api.GoogleMapsPlayablelocationsV3SamplePlayableLocationsResponse);
    });
  });
}
