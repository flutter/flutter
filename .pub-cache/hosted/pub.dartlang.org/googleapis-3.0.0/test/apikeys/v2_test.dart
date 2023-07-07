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

import 'package:googleapis/apikeys/v2.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.Map<core.String, core.Object> buildUnnamed5783() {
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

void checkUnnamed5783(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed5784() {
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

void checkUnnamed5784(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed5783();
    o.name = 'foo';
    o.response = buildUnnamed5784();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed5783(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed5784(o.response!);
  }
  buildCounterOperation--;
}

core.Map<core.String, core.Object> buildUnnamed5785() {
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

void checkUnnamed5785(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed5786() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed5785());
  o.add(buildUnnamed5785());
  return o;
}

void checkUnnamed5786(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed5785(o[0]);
  checkUnnamed5785(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed5786();
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
    checkUnnamed5786(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterV2AndroidApplication = 0;
api.V2AndroidApplication buildV2AndroidApplication() {
  var o = api.V2AndroidApplication();
  buildCounterV2AndroidApplication++;
  if (buildCounterV2AndroidApplication < 3) {
    o.packageName = 'foo';
    o.sha1Fingerprint = 'foo';
  }
  buildCounterV2AndroidApplication--;
  return o;
}

void checkV2AndroidApplication(api.V2AndroidApplication o) {
  buildCounterV2AndroidApplication++;
  if (buildCounterV2AndroidApplication < 3) {
    unittest.expect(
      o.packageName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sha1Fingerprint!,
      unittest.equals('foo'),
    );
  }
  buildCounterV2AndroidApplication--;
}

core.List<api.V2AndroidApplication> buildUnnamed5787() {
  var o = <api.V2AndroidApplication>[];
  o.add(buildV2AndroidApplication());
  o.add(buildV2AndroidApplication());
  return o;
}

void checkUnnamed5787(core.List<api.V2AndroidApplication> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkV2AndroidApplication(o[0] as api.V2AndroidApplication);
  checkV2AndroidApplication(o[1] as api.V2AndroidApplication);
}

core.int buildCounterV2AndroidKeyRestrictions = 0;
api.V2AndroidKeyRestrictions buildV2AndroidKeyRestrictions() {
  var o = api.V2AndroidKeyRestrictions();
  buildCounterV2AndroidKeyRestrictions++;
  if (buildCounterV2AndroidKeyRestrictions < 3) {
    o.allowedApplications = buildUnnamed5787();
  }
  buildCounterV2AndroidKeyRestrictions--;
  return o;
}

void checkV2AndroidKeyRestrictions(api.V2AndroidKeyRestrictions o) {
  buildCounterV2AndroidKeyRestrictions++;
  if (buildCounterV2AndroidKeyRestrictions < 3) {
    checkUnnamed5787(o.allowedApplications!);
  }
  buildCounterV2AndroidKeyRestrictions--;
}

core.List<core.String> buildUnnamed5788() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5788(core.List<core.String> o) {
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

core.int buildCounterV2ApiTarget = 0;
api.V2ApiTarget buildV2ApiTarget() {
  var o = api.V2ApiTarget();
  buildCounterV2ApiTarget++;
  if (buildCounterV2ApiTarget < 3) {
    o.methods = buildUnnamed5788();
    o.service = 'foo';
  }
  buildCounterV2ApiTarget--;
  return o;
}

void checkV2ApiTarget(api.V2ApiTarget o) {
  buildCounterV2ApiTarget++;
  if (buildCounterV2ApiTarget < 3) {
    checkUnnamed5788(o.methods!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterV2ApiTarget--;
}

core.List<core.String> buildUnnamed5789() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5789(core.List<core.String> o) {
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

core.int buildCounterV2BrowserKeyRestrictions = 0;
api.V2BrowserKeyRestrictions buildV2BrowserKeyRestrictions() {
  var o = api.V2BrowserKeyRestrictions();
  buildCounterV2BrowserKeyRestrictions++;
  if (buildCounterV2BrowserKeyRestrictions < 3) {
    o.allowedReferrers = buildUnnamed5789();
  }
  buildCounterV2BrowserKeyRestrictions--;
  return o;
}

void checkV2BrowserKeyRestrictions(api.V2BrowserKeyRestrictions o) {
  buildCounterV2BrowserKeyRestrictions++;
  if (buildCounterV2BrowserKeyRestrictions < 3) {
    checkUnnamed5789(o.allowedReferrers!);
  }
  buildCounterV2BrowserKeyRestrictions--;
}

core.int buildCounterV2CloneKeyRequest = 0;
api.V2CloneKeyRequest buildV2CloneKeyRequest() {
  var o = api.V2CloneKeyRequest();
  buildCounterV2CloneKeyRequest++;
  if (buildCounterV2CloneKeyRequest < 3) {
    o.keyId = 'foo';
  }
  buildCounterV2CloneKeyRequest--;
  return o;
}

void checkV2CloneKeyRequest(api.V2CloneKeyRequest o) {
  buildCounterV2CloneKeyRequest++;
  if (buildCounterV2CloneKeyRequest < 3) {
    unittest.expect(
      o.keyId!,
      unittest.equals('foo'),
    );
  }
  buildCounterV2CloneKeyRequest--;
}

core.int buildCounterV2GetKeyStringResponse = 0;
api.V2GetKeyStringResponse buildV2GetKeyStringResponse() {
  var o = api.V2GetKeyStringResponse();
  buildCounterV2GetKeyStringResponse++;
  if (buildCounterV2GetKeyStringResponse < 3) {
    o.keyString = 'foo';
  }
  buildCounterV2GetKeyStringResponse--;
  return o;
}

void checkV2GetKeyStringResponse(api.V2GetKeyStringResponse o) {
  buildCounterV2GetKeyStringResponse++;
  if (buildCounterV2GetKeyStringResponse < 3) {
    unittest.expect(
      o.keyString!,
      unittest.equals('foo'),
    );
  }
  buildCounterV2GetKeyStringResponse--;
}

core.List<core.String> buildUnnamed5790() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5790(core.List<core.String> o) {
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

core.int buildCounterV2IosKeyRestrictions = 0;
api.V2IosKeyRestrictions buildV2IosKeyRestrictions() {
  var o = api.V2IosKeyRestrictions();
  buildCounterV2IosKeyRestrictions++;
  if (buildCounterV2IosKeyRestrictions < 3) {
    o.allowedBundleIds = buildUnnamed5790();
  }
  buildCounterV2IosKeyRestrictions--;
  return o;
}

void checkV2IosKeyRestrictions(api.V2IosKeyRestrictions o) {
  buildCounterV2IosKeyRestrictions++;
  if (buildCounterV2IosKeyRestrictions < 3) {
    checkUnnamed5790(o.allowedBundleIds!);
  }
  buildCounterV2IosKeyRestrictions--;
}

core.int buildCounterV2Key = 0;
api.V2Key buildV2Key() {
  var o = api.V2Key();
  buildCounterV2Key++;
  if (buildCounterV2Key < 3) {
    o.createTime = 'foo';
    o.deleteTime = 'foo';
    o.displayName = 'foo';
    o.etag = 'foo';
    o.keyString = 'foo';
    o.name = 'foo';
    o.restrictions = buildV2Restrictions();
    o.uid = 'foo';
    o.updateTime = 'foo';
  }
  buildCounterV2Key--;
  return o;
}

void checkV2Key(api.V2Key o) {
  buildCounterV2Key++;
  if (buildCounterV2Key < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.deleteTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.keyString!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkV2Restrictions(o.restrictions! as api.V2Restrictions);
    unittest.expect(
      o.uid!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.updateTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterV2Key--;
}

core.List<api.V2Key> buildUnnamed5791() {
  var o = <api.V2Key>[];
  o.add(buildV2Key());
  o.add(buildV2Key());
  return o;
}

void checkUnnamed5791(core.List<api.V2Key> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkV2Key(o[0] as api.V2Key);
  checkV2Key(o[1] as api.V2Key);
}

core.int buildCounterV2ListKeysResponse = 0;
api.V2ListKeysResponse buildV2ListKeysResponse() {
  var o = api.V2ListKeysResponse();
  buildCounterV2ListKeysResponse++;
  if (buildCounterV2ListKeysResponse < 3) {
    o.keys = buildUnnamed5791();
    o.nextPageToken = 'foo';
  }
  buildCounterV2ListKeysResponse--;
  return o;
}

void checkV2ListKeysResponse(api.V2ListKeysResponse o) {
  buildCounterV2ListKeysResponse++;
  if (buildCounterV2ListKeysResponse < 3) {
    checkUnnamed5791(o.keys!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterV2ListKeysResponse--;
}

core.int buildCounterV2LookupKeyResponse = 0;
api.V2LookupKeyResponse buildV2LookupKeyResponse() {
  var o = api.V2LookupKeyResponse();
  buildCounterV2LookupKeyResponse++;
  if (buildCounterV2LookupKeyResponse < 3) {
    o.name = 'foo';
    o.parent = 'foo';
  }
  buildCounterV2LookupKeyResponse--;
  return o;
}

void checkV2LookupKeyResponse(api.V2LookupKeyResponse o) {
  buildCounterV2LookupKeyResponse++;
  if (buildCounterV2LookupKeyResponse < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parent!,
      unittest.equals('foo'),
    );
  }
  buildCounterV2LookupKeyResponse--;
}

core.List<api.V2ApiTarget> buildUnnamed5792() {
  var o = <api.V2ApiTarget>[];
  o.add(buildV2ApiTarget());
  o.add(buildV2ApiTarget());
  return o;
}

void checkUnnamed5792(core.List<api.V2ApiTarget> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkV2ApiTarget(o[0] as api.V2ApiTarget);
  checkV2ApiTarget(o[1] as api.V2ApiTarget);
}

core.int buildCounterV2Restrictions = 0;
api.V2Restrictions buildV2Restrictions() {
  var o = api.V2Restrictions();
  buildCounterV2Restrictions++;
  if (buildCounterV2Restrictions < 3) {
    o.androidKeyRestrictions = buildV2AndroidKeyRestrictions();
    o.apiTargets = buildUnnamed5792();
    o.browserKeyRestrictions = buildV2BrowserKeyRestrictions();
    o.iosKeyRestrictions = buildV2IosKeyRestrictions();
    o.serverKeyRestrictions = buildV2ServerKeyRestrictions();
  }
  buildCounterV2Restrictions--;
  return o;
}

void checkV2Restrictions(api.V2Restrictions o) {
  buildCounterV2Restrictions++;
  if (buildCounterV2Restrictions < 3) {
    checkV2AndroidKeyRestrictions(
        o.androidKeyRestrictions! as api.V2AndroidKeyRestrictions);
    checkUnnamed5792(o.apiTargets!);
    checkV2BrowserKeyRestrictions(
        o.browserKeyRestrictions! as api.V2BrowserKeyRestrictions);
    checkV2IosKeyRestrictions(
        o.iosKeyRestrictions! as api.V2IosKeyRestrictions);
    checkV2ServerKeyRestrictions(
        o.serverKeyRestrictions! as api.V2ServerKeyRestrictions);
  }
  buildCounterV2Restrictions--;
}

core.List<core.String> buildUnnamed5793() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5793(core.List<core.String> o) {
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

core.int buildCounterV2ServerKeyRestrictions = 0;
api.V2ServerKeyRestrictions buildV2ServerKeyRestrictions() {
  var o = api.V2ServerKeyRestrictions();
  buildCounterV2ServerKeyRestrictions++;
  if (buildCounterV2ServerKeyRestrictions < 3) {
    o.allowedIps = buildUnnamed5793();
  }
  buildCounterV2ServerKeyRestrictions--;
  return o;
}

void checkV2ServerKeyRestrictions(api.V2ServerKeyRestrictions o) {
  buildCounterV2ServerKeyRestrictions++;
  if (buildCounterV2ServerKeyRestrictions < 3) {
    checkUnnamed5793(o.allowedIps!);
  }
  buildCounterV2ServerKeyRestrictions--;
}

core.int buildCounterV2UndeleteKeyRequest = 0;
api.V2UndeleteKeyRequest buildV2UndeleteKeyRequest() {
  var o = api.V2UndeleteKeyRequest();
  buildCounterV2UndeleteKeyRequest++;
  if (buildCounterV2UndeleteKeyRequest < 3) {}
  buildCounterV2UndeleteKeyRequest--;
  return o;
}

void checkV2UndeleteKeyRequest(api.V2UndeleteKeyRequest o) {
  buildCounterV2UndeleteKeyRequest++;
  if (buildCounterV2UndeleteKeyRequest < 3) {}
  buildCounterV2UndeleteKeyRequest--;
}

void main() {
  unittest.group('obj-schema-Operation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOperation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Operation.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkOperation(od as api.Operation);
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

  unittest.group('obj-schema-V2AndroidApplication', () {
    unittest.test('to-json--from-json', () async {
      var o = buildV2AndroidApplication();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.V2AndroidApplication.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkV2AndroidApplication(od as api.V2AndroidApplication);
    });
  });

  unittest.group('obj-schema-V2AndroidKeyRestrictions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildV2AndroidKeyRestrictions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.V2AndroidKeyRestrictions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkV2AndroidKeyRestrictions(od as api.V2AndroidKeyRestrictions);
    });
  });

  unittest.group('obj-schema-V2ApiTarget', () {
    unittest.test('to-json--from-json', () async {
      var o = buildV2ApiTarget();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.V2ApiTarget.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkV2ApiTarget(od as api.V2ApiTarget);
    });
  });

  unittest.group('obj-schema-V2BrowserKeyRestrictions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildV2BrowserKeyRestrictions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.V2BrowserKeyRestrictions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkV2BrowserKeyRestrictions(od as api.V2BrowserKeyRestrictions);
    });
  });

  unittest.group('obj-schema-V2CloneKeyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildV2CloneKeyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.V2CloneKeyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkV2CloneKeyRequest(od as api.V2CloneKeyRequest);
    });
  });

  unittest.group('obj-schema-V2GetKeyStringResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildV2GetKeyStringResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.V2GetKeyStringResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkV2GetKeyStringResponse(od as api.V2GetKeyStringResponse);
    });
  });

  unittest.group('obj-schema-V2IosKeyRestrictions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildV2IosKeyRestrictions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.V2IosKeyRestrictions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkV2IosKeyRestrictions(od as api.V2IosKeyRestrictions);
    });
  });

  unittest.group('obj-schema-V2Key', () {
    unittest.test('to-json--from-json', () async {
      var o = buildV2Key();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.V2Key.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkV2Key(od as api.V2Key);
    });
  });

  unittest.group('obj-schema-V2ListKeysResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildV2ListKeysResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.V2ListKeysResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkV2ListKeysResponse(od as api.V2ListKeysResponse);
    });
  });

  unittest.group('obj-schema-V2LookupKeyResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildV2LookupKeyResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.V2LookupKeyResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkV2LookupKeyResponse(od as api.V2LookupKeyResponse);
    });
  });

  unittest.group('obj-schema-V2Restrictions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildV2Restrictions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.V2Restrictions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkV2Restrictions(od as api.V2Restrictions);
    });
  });

  unittest.group('obj-schema-V2ServerKeyRestrictions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildV2ServerKeyRestrictions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.V2ServerKeyRestrictions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkV2ServerKeyRestrictions(od as api.V2ServerKeyRestrictions);
    });
  });

  unittest.group('obj-schema-V2UndeleteKeyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildV2UndeleteKeyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.V2UndeleteKeyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkV2UndeleteKeyRequest(od as api.V2UndeleteKeyRequest);
    });
  });

  unittest.group('resource-KeysResource', () {
    unittest.test('method--lookupKey', () async {
      var mock = HttpServerMock();
      var res = api.ApiKeysServiceApi(mock).keys;
      var arg_keyString = 'foo';
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
          path.substring(pathOffset, pathOffset + 17),
          unittest.equals("v2/keys:lookupKey"),
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
          queryMap["keyString"]!.first,
          unittest.equals(arg_keyString),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildV2LookupKeyResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.lookupKey(keyString: arg_keyString, $fields: arg_$fields);
      checkV2LookupKeyResponse(response as api.V2LookupKeyResponse);
    });
  });

  unittest.group('resource-OperationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ApiKeysServiceApi(mock).operations;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });

  unittest.group('resource-ProjectsLocationsKeysResource', () {
    unittest.test('method--clone', () async {
      var mock = HttpServerMock();
      var res = api.ApiKeysServiceApi(mock).projects.locations.keys;
      var arg_request = buildV2CloneKeyRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.V2CloneKeyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkV2CloneKeyRequest(obj as api.V2CloneKeyRequest);

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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.clone(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.ApiKeysServiceApi(mock).projects.locations.keys;
      var arg_request = buildV2Key();
      var arg_parent = 'foo';
      var arg_keyId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.V2Key.fromJson(json as core.Map<core.String, core.dynamic>);
        checkV2Key(obj as api.V2Key);

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
          unittest.equals("v2/"),
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
          queryMap["keyId"]!.first,
          unittest.equals(arg_keyId),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.create(arg_request, arg_parent,
          keyId: arg_keyId, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.ApiKeysServiceApi(mock).projects.locations.keys;
      var arg_name = 'foo';
      var arg_etag = 'foo';
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
          unittest.equals("v2/"),
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
          queryMap["etag"]!.first,
          unittest.equals(arg_etag),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_name, etag: arg_etag, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ApiKeysServiceApi(mock).projects.locations.keys;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildV2Key());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkV2Key(response as api.V2Key);
    });

    unittest.test('method--getKeyString', () async {
      var mock = HttpServerMock();
      var res = api.ApiKeysServiceApi(mock).projects.locations.keys;
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildV2GetKeyStringResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getKeyString(arg_name, $fields: arg_$fields);
      checkV2GetKeyStringResponse(response as api.V2GetKeyStringResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ApiKeysServiceApi(mock).projects.locations.keys;
      var arg_parent = 'foo';
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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildV2ListKeysResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkV2ListKeysResponse(response as api.V2ListKeysResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.ApiKeysServiceApi(mock).projects.locations.keys;
      var arg_request = buildV2Key();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.V2Key.fromJson(json as core.Map<core.String, core.dynamic>);
        checkV2Key(obj as api.V2Key);

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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--undelete', () async {
      var mock = HttpServerMock();
      var res = api.ApiKeysServiceApi(mock).projects.locations.keys;
      var arg_request = buildV2UndeleteKeyRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.V2UndeleteKeyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkV2UndeleteKeyRequest(obj as api.V2UndeleteKeyRequest);

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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.undelete(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });
}
