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

import 'package:googleapis/adexperiencereport/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<core.String> buildUnnamed3331() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed3331(core.List<core.String> o) {
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

core.int buildCounterPlatformSummary = 0;
api.PlatformSummary buildPlatformSummary() {
  var o = api.PlatformSummary();
  buildCounterPlatformSummary++;
  if (buildCounterPlatformSummary < 3) {
    o.betterAdsStatus = 'foo';
    o.enforcementTime = 'foo';
    o.filterStatus = 'foo';
    o.lastChangeTime = 'foo';
    o.region = buildUnnamed3331();
    o.reportUrl = 'foo';
    o.underReview = true;
  }
  buildCounterPlatformSummary--;
  return o;
}

void checkPlatformSummary(api.PlatformSummary o) {
  buildCounterPlatformSummary++;
  if (buildCounterPlatformSummary < 3) {
    unittest.expect(
      o.betterAdsStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.enforcementTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.filterStatus!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastChangeTime!,
      unittest.equals('foo'),
    );
    checkUnnamed3331(o.region!);
    unittest.expect(
      o.reportUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(o.underReview!, unittest.isTrue);
  }
  buildCounterPlatformSummary--;
}

core.int buildCounterSiteSummaryResponse = 0;
api.SiteSummaryResponse buildSiteSummaryResponse() {
  var o = api.SiteSummaryResponse();
  buildCounterSiteSummaryResponse++;
  if (buildCounterSiteSummaryResponse < 3) {
    o.desktopSummary = buildPlatformSummary();
    o.mobileSummary = buildPlatformSummary();
    o.reviewedSite = 'foo';
  }
  buildCounterSiteSummaryResponse--;
  return o;
}

void checkSiteSummaryResponse(api.SiteSummaryResponse o) {
  buildCounterSiteSummaryResponse++;
  if (buildCounterSiteSummaryResponse < 3) {
    checkPlatformSummary(o.desktopSummary! as api.PlatformSummary);
    checkPlatformSummary(o.mobileSummary! as api.PlatformSummary);
    unittest.expect(
      o.reviewedSite!,
      unittest.equals('foo'),
    );
  }
  buildCounterSiteSummaryResponse--;
}

core.List<api.SiteSummaryResponse> buildUnnamed3332() {
  var o = <api.SiteSummaryResponse>[];
  o.add(buildSiteSummaryResponse());
  o.add(buildSiteSummaryResponse());
  return o;
}

void checkUnnamed3332(core.List<api.SiteSummaryResponse> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSiteSummaryResponse(o[0] as api.SiteSummaryResponse);
  checkSiteSummaryResponse(o[1] as api.SiteSummaryResponse);
}

core.int buildCounterViolatingSitesResponse = 0;
api.ViolatingSitesResponse buildViolatingSitesResponse() {
  var o = api.ViolatingSitesResponse();
  buildCounterViolatingSitesResponse++;
  if (buildCounterViolatingSitesResponse < 3) {
    o.violatingSites = buildUnnamed3332();
  }
  buildCounterViolatingSitesResponse--;
  return o;
}

void checkViolatingSitesResponse(api.ViolatingSitesResponse o) {
  buildCounterViolatingSitesResponse++;
  if (buildCounterViolatingSitesResponse < 3) {
    checkUnnamed3332(o.violatingSites!);
  }
  buildCounterViolatingSitesResponse--;
}

void main() {
  unittest.group('obj-schema-PlatformSummary', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPlatformSummary();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.PlatformSummary.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkPlatformSummary(od as api.PlatformSummary);
    });
  });

  unittest.group('obj-schema-SiteSummaryResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSiteSummaryResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SiteSummaryResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSiteSummaryResponse(od as api.SiteSummaryResponse);
    });
  });

  unittest.group('obj-schema-ViolatingSitesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildViolatingSitesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ViolatingSitesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkViolatingSitesResponse(od as api.ViolatingSitesResponse);
    });
  });

  unittest.group('resource-SitesResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.AdExperienceReportApi(mock).sites;
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
        var resp = convert.json.encode(buildSiteSummaryResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkSiteSummaryResponse(response as api.SiteSummaryResponse);
    });
  });

  unittest.group('resource-ViolatingSitesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.AdExperienceReportApi(mock).violatingSites;
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
          unittest.equals("v1/violatingSites"),
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
        var resp = convert.json.encode(buildViolatingSitesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list($fields: arg_$fields);
      checkViolatingSitesResponse(response as api.ViolatingSitesResponse);
    });
  });
}
