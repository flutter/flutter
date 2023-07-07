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

import 'package:googleapis/streetviewpublish/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed7181() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7181(core.List<core.String> o) {
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

core.int buildCounterBatchDeletePhotosRequest = 0;
api.BatchDeletePhotosRequest buildBatchDeletePhotosRequest() {
  var o = api.BatchDeletePhotosRequest();
  buildCounterBatchDeletePhotosRequest++;
  if (buildCounterBatchDeletePhotosRequest < 3) {
    o.photoIds = buildUnnamed7181();
  }
  buildCounterBatchDeletePhotosRequest--;
  return o;
}

void checkBatchDeletePhotosRequest(api.BatchDeletePhotosRequest o) {
  buildCounterBatchDeletePhotosRequest++;
  if (buildCounterBatchDeletePhotosRequest < 3) {
    checkUnnamed7181(o.photoIds!);
  }
  buildCounterBatchDeletePhotosRequest--;
}

core.List<api.Status> buildUnnamed7182() {
  var o = <api.Status>[];
  o.add(buildStatus());
  o.add(buildStatus());
  return o;
}

void checkUnnamed7182(core.List<api.Status> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStatus(o[0] as api.Status);
  checkStatus(o[1] as api.Status);
}

core.int buildCounterBatchDeletePhotosResponse = 0;
api.BatchDeletePhotosResponse buildBatchDeletePhotosResponse() {
  var o = api.BatchDeletePhotosResponse();
  buildCounterBatchDeletePhotosResponse++;
  if (buildCounterBatchDeletePhotosResponse < 3) {
    o.status = buildUnnamed7182();
  }
  buildCounterBatchDeletePhotosResponse--;
  return o;
}

void checkBatchDeletePhotosResponse(api.BatchDeletePhotosResponse o) {
  buildCounterBatchDeletePhotosResponse++;
  if (buildCounterBatchDeletePhotosResponse < 3) {
    checkUnnamed7182(o.status!);
  }
  buildCounterBatchDeletePhotosResponse--;
}

core.List<api.PhotoResponse> buildUnnamed7183() {
  var o = <api.PhotoResponse>[];
  o.add(buildPhotoResponse());
  o.add(buildPhotoResponse());
  return o;
}

void checkUnnamed7183(core.List<api.PhotoResponse> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPhotoResponse(o[0] as api.PhotoResponse);
  checkPhotoResponse(o[1] as api.PhotoResponse);
}

core.int buildCounterBatchGetPhotosResponse = 0;
api.BatchGetPhotosResponse buildBatchGetPhotosResponse() {
  var o = api.BatchGetPhotosResponse();
  buildCounterBatchGetPhotosResponse++;
  if (buildCounterBatchGetPhotosResponse < 3) {
    o.results = buildUnnamed7183();
  }
  buildCounterBatchGetPhotosResponse--;
  return o;
}

void checkBatchGetPhotosResponse(api.BatchGetPhotosResponse o) {
  buildCounterBatchGetPhotosResponse++;
  if (buildCounterBatchGetPhotosResponse < 3) {
    checkUnnamed7183(o.results!);
  }
  buildCounterBatchGetPhotosResponse--;
}

core.List<api.UpdatePhotoRequest> buildUnnamed7184() {
  var o = <api.UpdatePhotoRequest>[];
  o.add(buildUpdatePhotoRequest());
  o.add(buildUpdatePhotoRequest());
  return o;
}

void checkUnnamed7184(core.List<api.UpdatePhotoRequest> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUpdatePhotoRequest(o[0] as api.UpdatePhotoRequest);
  checkUpdatePhotoRequest(o[1] as api.UpdatePhotoRequest);
}

core.int buildCounterBatchUpdatePhotosRequest = 0;
api.BatchUpdatePhotosRequest buildBatchUpdatePhotosRequest() {
  var o = api.BatchUpdatePhotosRequest();
  buildCounterBatchUpdatePhotosRequest++;
  if (buildCounterBatchUpdatePhotosRequest < 3) {
    o.updatePhotoRequests = buildUnnamed7184();
  }
  buildCounterBatchUpdatePhotosRequest--;
  return o;
}

void checkBatchUpdatePhotosRequest(api.BatchUpdatePhotosRequest o) {
  buildCounterBatchUpdatePhotosRequest++;
  if (buildCounterBatchUpdatePhotosRequest < 3) {
    checkUnnamed7184(o.updatePhotoRequests!);
  }
  buildCounterBatchUpdatePhotosRequest--;
}

core.List<api.PhotoResponse> buildUnnamed7185() {
  var o = <api.PhotoResponse>[];
  o.add(buildPhotoResponse());
  o.add(buildPhotoResponse());
  return o;
}

void checkUnnamed7185(core.List<api.PhotoResponse> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPhotoResponse(o[0] as api.PhotoResponse);
  checkPhotoResponse(o[1] as api.PhotoResponse);
}

core.int buildCounterBatchUpdatePhotosResponse = 0;
api.BatchUpdatePhotosResponse buildBatchUpdatePhotosResponse() {
  var o = api.BatchUpdatePhotosResponse();
  buildCounterBatchUpdatePhotosResponse++;
  if (buildCounterBatchUpdatePhotosResponse < 3) {
    o.results = buildUnnamed7185();
  }
  buildCounterBatchUpdatePhotosResponse--;
  return o;
}

void checkBatchUpdatePhotosResponse(api.BatchUpdatePhotosResponse o) {
  buildCounterBatchUpdatePhotosResponse++;
  if (buildCounterBatchUpdatePhotosResponse < 3) {
    checkUnnamed7185(o.results!);
  }
  buildCounterBatchUpdatePhotosResponse--;
}

core.int buildCounterConnection = 0;
api.Connection buildConnection() {
  var o = api.Connection();
  buildCounterConnection++;
  if (buildCounterConnection < 3) {
    o.target = buildPhotoId();
  }
  buildCounterConnection--;
  return o;
}

void checkConnection(api.Connection o) {
  buildCounterConnection++;
  if (buildCounterConnection < 3) {
    checkPhotoId(o.target! as api.PhotoId);
  }
  buildCounterConnection--;
}

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

core.int buildCounterLatLng = 0;
api.LatLng buildLatLng() {
  var o = api.LatLng();
  buildCounterLatLng++;
  if (buildCounterLatLng < 3) {
    o.latitude = 42.0;
    o.longitude = 42.0;
  }
  buildCounterLatLng--;
  return o;
}

void checkLatLng(api.LatLng o) {
  buildCounterLatLng++;
  if (buildCounterLatLng < 3) {
    unittest.expect(
      o.latitude!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.longitude!,
      unittest.equals(42.0),
    );
  }
  buildCounterLatLng--;
}

core.int buildCounterLevel = 0;
api.Level buildLevel() {
  var o = api.Level();
  buildCounterLevel++;
  if (buildCounterLevel < 3) {
    o.name = 'foo';
    o.number = 42.0;
  }
  buildCounterLevel--;
  return o;
}

void checkLevel(api.Level o) {
  buildCounterLevel++;
  if (buildCounterLevel < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.number!,
      unittest.equals(42.0),
    );
  }
  buildCounterLevel--;
}

core.List<api.Photo> buildUnnamed7186() {
  var o = <api.Photo>[];
  o.add(buildPhoto());
  o.add(buildPhoto());
  return o;
}

void checkUnnamed7186(core.List<api.Photo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPhoto(o[0] as api.Photo);
  checkPhoto(o[1] as api.Photo);
}

core.int buildCounterListPhotosResponse = 0;
api.ListPhotosResponse buildListPhotosResponse() {
  var o = api.ListPhotosResponse();
  buildCounterListPhotosResponse++;
  if (buildCounterListPhotosResponse < 3) {
    o.nextPageToken = 'foo';
    o.photos = buildUnnamed7186();
  }
  buildCounterListPhotosResponse--;
  return o;
}

void checkListPhotosResponse(api.ListPhotosResponse o) {
  buildCounterListPhotosResponse++;
  if (buildCounterListPhotosResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed7186(o.photos!);
  }
  buildCounterListPhotosResponse--;
}

core.Map<core.String, core.Object> buildUnnamed7187() {
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

void checkUnnamed7187(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed7188() {
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

void checkUnnamed7188(core.Map<core.String, core.Object> o) {
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

core.int buildCounterOperation = 0;
api.Operation buildOperation() {
  var o = api.Operation();
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    o.done = true;
    o.error = buildStatus();
    o.metadata = buildUnnamed7187();
    o.name = 'foo';
    o.response = buildUnnamed7188();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed7187(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed7188(o.response!);
  }
  buildCounterOperation--;
}

core.List<api.Connection> buildUnnamed7189() {
  var o = <api.Connection>[];
  o.add(buildConnection());
  o.add(buildConnection());
  return o;
}

void checkUnnamed7189(core.List<api.Connection> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConnection(o[0] as api.Connection);
  checkConnection(o[1] as api.Connection);
}

core.List<api.Place> buildUnnamed7190() {
  var o = <api.Place>[];
  o.add(buildPlace());
  o.add(buildPlace());
  return o;
}

void checkUnnamed7190(core.List<api.Place> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkPlace(o[0] as api.Place);
  checkPlace(o[1] as api.Place);
}

core.int buildCounterPhoto = 0;
api.Photo buildPhoto() {
  var o = api.Photo();
  buildCounterPhoto++;
  if (buildCounterPhoto < 3) {
    o.captureTime = 'foo';
    o.connections = buildUnnamed7189();
    o.downloadUrl = 'foo';
    o.mapsPublishStatus = 'foo';
    o.photoId = buildPhotoId();
    o.places = buildUnnamed7190();
    o.pose = buildPose();
    o.shareLink = 'foo';
    o.thumbnailUrl = 'foo';
    o.transferStatus = 'foo';
    o.uploadReference = buildUploadRef();
    o.viewCount = 'foo';
  }
  buildCounterPhoto--;
  return o;
}

void checkPhoto(api.Photo o) {
  buildCounterPhoto++;
  if (buildCounterPhoto < 3) {
    unittest.expect(
      o.captureTime!,
      unittest.equals('foo'),
    );
    checkUnnamed7189(o.connections!);
    unittest.expect(
      o.downloadUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mapsPublishStatus!,
      unittest.equals('foo'),
    );
    checkPhotoId(o.photoId! as api.PhotoId);
    checkUnnamed7190(o.places!);
    checkPose(o.pose! as api.Pose);
    unittest.expect(
      o.shareLink!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.thumbnailUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.transferStatus!,
      unittest.equals('foo'),
    );
    checkUploadRef(o.uploadReference! as api.UploadRef);
    unittest.expect(
      o.viewCount!,
      unittest.equals('foo'),
    );
  }
  buildCounterPhoto--;
}

core.int buildCounterPhotoId = 0;
api.PhotoId buildPhotoId() {
  var o = api.PhotoId();
  buildCounterPhotoId++;
  if (buildCounterPhotoId < 3) {
    o.id = 'foo';
  }
  buildCounterPhotoId--;
  return o;
}

void checkPhotoId(api.PhotoId o) {
  buildCounterPhotoId++;
  if (buildCounterPhotoId < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
  }
  buildCounterPhotoId--;
}

core.int buildCounterPhotoResponse = 0;
api.PhotoResponse buildPhotoResponse() {
  var o = api.PhotoResponse();
  buildCounterPhotoResponse++;
  if (buildCounterPhotoResponse < 3) {
    o.photo = buildPhoto();
    o.status = buildStatus();
  }
  buildCounterPhotoResponse--;
  return o;
}

void checkPhotoResponse(api.PhotoResponse o) {
  buildCounterPhotoResponse++;
  if (buildCounterPhotoResponse < 3) {
    checkPhoto(o.photo! as api.Photo);
    checkStatus(o.status! as api.Status);
  }
  buildCounterPhotoResponse--;
}

core.int buildCounterPlace = 0;
api.Place buildPlace() {
  var o = api.Place();
  buildCounterPlace++;
  if (buildCounterPlace < 3) {
    o.languageCode = 'foo';
    o.name = 'foo';
    o.placeId = 'foo';
  }
  buildCounterPlace--;
  return o;
}

void checkPlace(api.Place o) {
  buildCounterPlace++;
  if (buildCounterPlace < 3) {
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.placeId!,
      unittest.equals('foo'),
    );
  }
  buildCounterPlace--;
}

core.int buildCounterPose = 0;
api.Pose buildPose() {
  var o = api.Pose();
  buildCounterPose++;
  if (buildCounterPose < 3) {
    o.accuracyMeters = 42.0;
    o.altitude = 42.0;
    o.heading = 42.0;
    o.latLngPair = buildLatLng();
    o.level = buildLevel();
    o.pitch = 42.0;
    o.roll = 42.0;
  }
  buildCounterPose--;
  return o;
}

void checkPose(api.Pose o) {
  buildCounterPose++;
  if (buildCounterPose < 3) {
    unittest.expect(
      o.accuracyMeters!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.altitude!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.heading!,
      unittest.equals(42.0),
    );
    checkLatLng(o.latLngPair! as api.LatLng);
    checkLevel(o.level! as api.Level);
    unittest.expect(
      o.pitch!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.roll!,
      unittest.equals(42.0),
    );
  }
  buildCounterPose--;
}

core.Map<core.String, core.Object> buildUnnamed7191() {
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

void checkUnnamed7191(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed7192() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed7191());
  o.add(buildUnnamed7191());
  return o;
}

void checkUnnamed7192(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed7191(o[0]);
  checkUnnamed7191(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed7192();
    o.message = 'foo';
  }
  buildCounterStatus--;
  return o;
}

void checkStatus(api.Status o) {
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    unittest.expect(
      o.code!,
      unittest.equals(42),
    );
    checkUnnamed7192(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterUpdatePhotoRequest = 0;
api.UpdatePhotoRequest buildUpdatePhotoRequest() {
  var o = api.UpdatePhotoRequest();
  buildCounterUpdatePhotoRequest++;
  if (buildCounterUpdatePhotoRequest < 3) {
    o.photo = buildPhoto();
    o.updateMask = 'foo';
  }
  buildCounterUpdatePhotoRequest--;
  return o;
}

void checkUpdatePhotoRequest(api.UpdatePhotoRequest o) {
  buildCounterUpdatePhotoRequest++;
  if (buildCounterUpdatePhotoRequest < 3) {
    checkPhoto(o.photo! as api.Photo);
    unittest.expect(
      o.updateMask!,
      unittest.equals('foo'),
    );
  }
  buildCounterUpdatePhotoRequest--;
}

core.int buildCounterUploadRef = 0;
api.UploadRef buildUploadRef() {
  var o = api.UploadRef();
  buildCounterUploadRef++;
  if (buildCounterUploadRef < 3) {
    o.uploadUrl = 'foo';
  }
  buildCounterUploadRef--;
  return o;
}

void checkUploadRef(api.UploadRef o) {
  buildCounterUploadRef++;
  if (buildCounterUploadRef < 3) {
    unittest.expect(
      o.uploadUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterUploadRef--;
}

core.List<core.String> buildUnnamed7193() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed7193(core.List<core.String> o) {
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

void main() {
  unittest.group('obj-schema-BatchDeletePhotosRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchDeletePhotosRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchDeletePhotosRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchDeletePhotosRequest(od as api.BatchDeletePhotosRequest);
    });
  });

  unittest.group('obj-schema-BatchDeletePhotosResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchDeletePhotosResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchDeletePhotosResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchDeletePhotosResponse(od as api.BatchDeletePhotosResponse);
    });
  });

  unittest.group('obj-schema-BatchGetPhotosResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchGetPhotosResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchGetPhotosResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchGetPhotosResponse(od as api.BatchGetPhotosResponse);
    });
  });

  unittest.group('obj-schema-BatchUpdatePhotosRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchUpdatePhotosRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchUpdatePhotosRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchUpdatePhotosRequest(od as api.BatchUpdatePhotosRequest);
    });
  });

  unittest.group('obj-schema-BatchUpdatePhotosResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchUpdatePhotosResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchUpdatePhotosResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchUpdatePhotosResponse(od as api.BatchUpdatePhotosResponse);
    });
  });

  unittest.group('obj-schema-Connection', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConnection();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Connection.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkConnection(od as api.Connection);
    });
  });

  unittest.group('obj-schema-Empty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEmpty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Empty.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEmpty(od as api.Empty);
    });
  });

  unittest.group('obj-schema-LatLng', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLatLng();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.LatLng.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLatLng(od as api.LatLng);
    });
  });

  unittest.group('obj-schema-Level', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLevel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Level.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLevel(od as api.Level);
    });
  });

  unittest.group('obj-schema-ListPhotosResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListPhotosResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListPhotosResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListPhotosResponse(od as api.ListPhotosResponse);
    });
  });

  unittest.group('obj-schema-Operation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Operation.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOperation(od as api.Operation);
    });
  });

  unittest.group('obj-schema-Photo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPhoto();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Photo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPhoto(od as api.Photo);
    });
  });

  unittest.group('obj-schema-PhotoId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPhotoId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.PhotoId.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPhotoId(od as api.PhotoId);
    });
  });

  unittest.group('obj-schema-PhotoResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPhotoResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PhotoResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPhotoResponse(od as api.PhotoResponse);
    });
  });

  unittest.group('obj-schema-Place', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlace();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Place.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPlace(od as api.Place);
    });
  });

  unittest.group('obj-schema-Pose', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPose();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Pose.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPose(od as api.Pose);
    });
  });

  unittest.group('obj-schema-Status', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Status.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStatus(od as api.Status);
    });
  });

  unittest.group('obj-schema-UpdatePhotoRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUpdatePhotoRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UpdatePhotoRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUpdatePhotoRequest(od as api.UpdatePhotoRequest);
    });
  });

  unittest.group('obj-schema-UploadRef', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUploadRef();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.UploadRef.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkUploadRef(od as api.UploadRef);
    });
  });

  unittest.group('resource-PhotoResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.StreetViewPublishApi(mock).photo;
      var arg_request = buildPhoto();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Photo.fromJson(json as core.Map<core.String, core.dynamic>);
        checkPhoto(obj as api.Photo);

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
          unittest.equals("v1/photo"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPhoto());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, $fields: arg_$fields);
      checkPhoto(response as api.Photo);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.StreetViewPublishApi(mock).photo;
      var arg_photoId = 'foo';
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
          unittest.equals("v1/photo/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_photoId'),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_photoId, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.StreetViewPublishApi(mock).photo;
      var arg_photoId = 'foo';
      var arg_languageCode = 'foo';
      var arg_view = 'foo';
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
          unittest.equals("v1/photo/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_photoId'),
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
          queryMap["languageCode"]!.first,
          unittest.equals(arg_languageCode),
        );
        unittest.expect(
          queryMap["view"]!.first,
          unittest.equals(arg_view),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPhoto());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_photoId,
          languageCode: arg_languageCode, view: arg_view, $fields: arg_$fields);
      checkPhoto(response as api.Photo);
    });

    unittest.test('method--startUpload', () async {
      var mock = HttpServerMock();
      var res = api.StreetViewPublishApi(mock).photo;
      var arg_request = buildEmpty();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Empty.fromJson(json as core.Map<core.String, core.dynamic>);
        checkEmpty(obj as api.Empty);

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
          path.substring(pathOffset, pathOffset + 20),
          unittest.equals("v1/photo:startUpload"),
        );
        pathOffset += 20;

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
        var resp = convert.json.encode(buildUploadRef());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.startUpload(arg_request, $fields: arg_$fields);
      checkUploadRef(response as api.UploadRef);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.StreetViewPublishApi(mock).photo;
      var arg_request = buildPhoto();
      var arg_id = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Photo.fromJson(json as core.Map<core.String, core.dynamic>);
        checkPhoto(obj as api.Photo);

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
          unittest.equals("v1/photo/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_id'),
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
          queryMap["updateMask"]!.first,
          unittest.equals(arg_updateMask),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildPhoto());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_id,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkPhoto(response as api.Photo);
    });
  });

  unittest.group('resource-PhotosResource', () {
    unittest.test('method--batchDelete', () async {
      var mock = HttpServerMock();
      var res = api.StreetViewPublishApi(mock).photos;
      var arg_request = buildBatchDeletePhotosRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchDeletePhotosRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchDeletePhotosRequest(obj as api.BatchDeletePhotosRequest);

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
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("v1/photos:batchDelete"),
        );
        pathOffset += 21;

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
        var resp = convert.json.encode(buildBatchDeletePhotosResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchDelete(arg_request, $fields: arg_$fields);
      checkBatchDeletePhotosResponse(response as api.BatchDeletePhotosResponse);
    });

    unittest.test('method--batchGet', () async {
      var mock = HttpServerMock();
      var res = api.StreetViewPublishApi(mock).photos;
      var arg_languageCode = 'foo';
      var arg_photoIds = buildUnnamed7193();
      var arg_view = 'foo';
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
          path.substring(pathOffset, pathOffset + 18),
          unittest.equals("v1/photos:batchGet"),
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
          queryMap["languageCode"]!.first,
          unittest.equals(arg_languageCode),
        );
        unittest.expect(
          queryMap["photoIds"]!,
          unittest.equals(arg_photoIds),
        );
        unittest.expect(
          queryMap["view"]!.first,
          unittest.equals(arg_view),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildBatchGetPhotosResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchGet(
          languageCode: arg_languageCode,
          photoIds: arg_photoIds,
          view: arg_view,
          $fields: arg_$fields);
      checkBatchGetPhotosResponse(response as api.BatchGetPhotosResponse);
    });

    unittest.test('method--batchUpdate', () async {
      var mock = HttpServerMock();
      var res = api.StreetViewPublishApi(mock).photos;
      var arg_request = buildBatchUpdatePhotosRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchUpdatePhotosRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchUpdatePhotosRequest(obj as api.BatchUpdatePhotosRequest);

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
          path.substring(pathOffset, pathOffset + 21),
          unittest.equals("v1/photos:batchUpdate"),
        );
        pathOffset += 21;

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
        var resp = convert.json.encode(buildBatchUpdatePhotosResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.batchUpdate(arg_request, $fields: arg_$fields);
      checkBatchUpdatePhotosResponse(response as api.BatchUpdatePhotosResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.StreetViewPublishApi(mock).photos;
      var arg_filter = 'foo';
      var arg_languageCode = 'foo';
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_view = 'foo';
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
          unittest.equals("v1/photos"),
        );
        pathOffset += 9;

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
          queryMap["languageCode"]!.first,
          unittest.equals(arg_languageCode),
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
          queryMap["view"]!.first,
          unittest.equals(arg_view),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListPhotosResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          filter: arg_filter,
          languageCode: arg_languageCode,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          view: arg_view,
          $fields: arg_$fields);
      checkListPhotosResponse(response as api.ListPhotosResponse);
    });
  });
}
