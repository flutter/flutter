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

import 'package:googleapis/chromeuxreport/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterBin = 0;
api.Bin buildBin() {
  var o = api.Bin();
  buildCounterBin++;
  if (buildCounterBin < 3) {
    o.density = 42.0;
    o.end = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.start = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
  }
  buildCounterBin--;
  return o;
}

void checkBin(api.Bin o) {
  buildCounterBin++;
  if (buildCounterBin < 3) {
    unittest.expect(
      o.density!,
      unittest.equals(42.0),
    );
    var casted1 = (o.end!) as core.Map;
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
    var casted2 = (o.start!) as core.Map;
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
  buildCounterBin--;
}

core.int buildCounterKey = 0;
api.Key buildKey() {
  var o = api.Key();
  buildCounterKey++;
  if (buildCounterKey < 3) {
    o.effectiveConnectionType = 'foo';
    o.formFactor = 'foo';
    o.origin = 'foo';
    o.url = 'foo';
  }
  buildCounterKey--;
  return o;
}

void checkKey(api.Key o) {
  buildCounterKey++;
  if (buildCounterKey < 3) {
    unittest.expect(
      o.effectiveConnectionType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formFactor!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.origin!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterKey--;
}

core.List<api.Bin> buildUnnamed6754() {
  var o = <api.Bin>[];
  o.add(buildBin());
  o.add(buildBin());
  return o;
}

void checkUnnamed6754(core.List<api.Bin> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBin(o[0] as api.Bin);
  checkBin(o[1] as api.Bin);
}

core.int buildCounterMetric = 0;
api.Metric buildMetric() {
  var o = api.Metric();
  buildCounterMetric++;
  if (buildCounterMetric < 3) {
    o.histogram = buildUnnamed6754();
    o.percentiles = buildPercentiles();
  }
  buildCounterMetric--;
  return o;
}

void checkMetric(api.Metric o) {
  buildCounterMetric++;
  if (buildCounterMetric < 3) {
    checkUnnamed6754(o.histogram!);
    checkPercentiles(o.percentiles! as api.Percentiles);
  }
  buildCounterMetric--;
}

core.int buildCounterPercentiles = 0;
api.Percentiles buildPercentiles() {
  var o = api.Percentiles();
  buildCounterPercentiles++;
  if (buildCounterPercentiles < 3) {
    o.p75 = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
  }
  buildCounterPercentiles--;
  return o;
}

void checkPercentiles(api.Percentiles o) {
  buildCounterPercentiles++;
  if (buildCounterPercentiles < 3) {
    var casted3 = (o.p75!) as core.Map;
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
  }
  buildCounterPercentiles--;
}

core.List<core.String> buildUnnamed6755() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed6755(core.List<core.String> o) {
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

core.int buildCounterQueryRequest = 0;
api.QueryRequest buildQueryRequest() {
  var o = api.QueryRequest();
  buildCounterQueryRequest++;
  if (buildCounterQueryRequest < 3) {
    o.effectiveConnectionType = 'foo';
    o.formFactor = 'foo';
    o.metrics = buildUnnamed6755();
    o.origin = 'foo';
    o.url = 'foo';
  }
  buildCounterQueryRequest--;
  return o;
}

void checkQueryRequest(api.QueryRequest o) {
  buildCounterQueryRequest++;
  if (buildCounterQueryRequest < 3) {
    unittest.expect(
      o.effectiveConnectionType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.formFactor!,
      unittest.equals('foo'),
    );
    checkUnnamed6755(o.metrics!);
    unittest.expect(
      o.origin!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterQueryRequest--;
}

core.int buildCounterQueryResponse = 0;
api.QueryResponse buildQueryResponse() {
  var o = api.QueryResponse();
  buildCounterQueryResponse++;
  if (buildCounterQueryResponse < 3) {
    o.record = buildRecord();
    o.urlNormalizationDetails = buildUrlNormalization();
  }
  buildCounterQueryResponse--;
  return o;
}

void checkQueryResponse(api.QueryResponse o) {
  buildCounterQueryResponse++;
  if (buildCounterQueryResponse < 3) {
    checkRecord(o.record! as api.Record);
    checkUrlNormalization(o.urlNormalizationDetails! as api.UrlNormalization);
  }
  buildCounterQueryResponse--;
}

core.Map<core.String, api.Metric> buildUnnamed6756() {
  var o = <core.String, api.Metric>{};
  o['x'] = buildMetric();
  o['y'] = buildMetric();
  return o;
}

void checkUnnamed6756(core.Map<core.String, api.Metric> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkMetric(o['x']! as api.Metric);
  checkMetric(o['y']! as api.Metric);
}

core.int buildCounterRecord = 0;
api.Record buildRecord() {
  var o = api.Record();
  buildCounterRecord++;
  if (buildCounterRecord < 3) {
    o.key = buildKey();
    o.metrics = buildUnnamed6756();
  }
  buildCounterRecord--;
  return o;
}

void checkRecord(api.Record o) {
  buildCounterRecord++;
  if (buildCounterRecord < 3) {
    checkKey(o.key! as api.Key);
    checkUnnamed6756(o.metrics!);
  }
  buildCounterRecord--;
}

core.int buildCounterUrlNormalization = 0;
api.UrlNormalization buildUrlNormalization() {
  var o = api.UrlNormalization();
  buildCounterUrlNormalization++;
  if (buildCounterUrlNormalization < 3) {
    o.normalizedUrl = 'foo';
    o.originalUrl = 'foo';
  }
  buildCounterUrlNormalization--;
  return o;
}

void checkUrlNormalization(api.UrlNormalization o) {
  buildCounterUrlNormalization++;
  if (buildCounterUrlNormalization < 3) {
    unittest.expect(
      o.normalizedUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.originalUrl!,
      unittest.equals('foo'),
    );
  }
  buildCounterUrlNormalization--;
}

void main() {
  unittest.group('obj-schema-Bin', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBin();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Bin.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBin(od as api.Bin);
    });
  });

  unittest.group('obj-schema-Key', () {
    unittest.test('to-json--from-json', () async {
      var o = buildKey();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Key.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkKey(od as api.Key);
    });
  });

  unittest.group('obj-schema-Metric', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMetric();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Metric.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMetric(od as api.Metric);
    });
  });

  unittest.group('obj-schema-Percentiles', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPercentiles();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Percentiles.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPercentiles(od as api.Percentiles);
    });
  });

  unittest.group('obj-schema-QueryRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryRequest(od as api.QueryRequest);
    });
  });

  unittest.group('obj-schema-QueryResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryResponse(od as api.QueryResponse);
    });
  });

  unittest.group('obj-schema-Record', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRecord();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Record.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRecord(od as api.Record);
    });
  });

  unittest.group('obj-schema-UrlNormalization', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUrlNormalization();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UrlNormalization.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUrlNormalization(od as api.UrlNormalization);
    });
  });

  unittest.group('resource-RecordsResource', () {
    unittest.test('method--queryRecord', () async {
      var mock = HttpServerMock();
      var res = api.ChromeUXReportApi(mock).records;
      var arg_request = buildQueryRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.QueryRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkQueryRequest(obj as api.QueryRequest);

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
          path.substring(pathOffset, pathOffset + 22),
          unittest.equals("v1/records:queryRecord"),
        );
        pathOffset += 22;

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
        var resp = convert.json.encode(buildQueryResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.queryRecord(arg_request, $fields: arg_$fields);
      checkQueryResponse(response as api.QueryResponse);
    });
  });
}
