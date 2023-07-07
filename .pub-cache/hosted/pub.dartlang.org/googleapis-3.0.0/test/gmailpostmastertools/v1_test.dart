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

import 'package:googleapis/gmailpostmastertools/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterDeliveryError = 0;
api.DeliveryError buildDeliveryError() {
  var o = api.DeliveryError();
  buildCounterDeliveryError++;
  if (buildCounterDeliveryError < 3) {
    o.errorClass = 'foo';
    o.errorRatio = 42.0;
    o.errorType = 'foo';
  }
  buildCounterDeliveryError--;
  return o;
}

void checkDeliveryError(api.DeliveryError o) {
  buildCounterDeliveryError++;
  if (buildCounterDeliveryError < 3) {
    unittest.expect(
      o.errorClass!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.errorRatio!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.errorType!,
      unittest.equals('foo'),
    );
  }
  buildCounterDeliveryError--;
}

core.int buildCounterDomain = 0;
api.Domain buildDomain() {
  var o = api.Domain();
  buildCounterDomain++;
  if (buildCounterDomain < 3) {
    o.createTime = 'foo';
    o.name = 'foo';
    o.permission = 'foo';
  }
  buildCounterDomain--;
  return o;
}

void checkDomain(api.Domain o) {
  buildCounterDomain++;
  if (buildCounterDomain < 3) {
    unittest.expect(
      o.createTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.permission!,
      unittest.equals('foo'),
    );
  }
  buildCounterDomain--;
}

core.int buildCounterFeedbackLoop = 0;
api.FeedbackLoop buildFeedbackLoop() {
  var o = api.FeedbackLoop();
  buildCounterFeedbackLoop++;
  if (buildCounterFeedbackLoop < 3) {
    o.id = 'foo';
    o.spamRatio = 42.0;
  }
  buildCounterFeedbackLoop--;
  return o;
}

void checkFeedbackLoop(api.FeedbackLoop o) {
  buildCounterFeedbackLoop++;
  if (buildCounterFeedbackLoop < 3) {
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.spamRatio!,
      unittest.equals(42.0),
    );
  }
  buildCounterFeedbackLoop--;
}

core.List<core.String> buildUnnamed5648() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5648(core.List<core.String> o) {
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

core.int buildCounterIpReputation = 0;
api.IpReputation buildIpReputation() {
  var o = api.IpReputation();
  buildCounterIpReputation++;
  if (buildCounterIpReputation < 3) {
    o.ipCount = 'foo';
    o.reputation = 'foo';
    o.sampleIps = buildUnnamed5648();
  }
  buildCounterIpReputation--;
  return o;
}

void checkIpReputation(api.IpReputation o) {
  buildCounterIpReputation++;
  if (buildCounterIpReputation < 3) {
    unittest.expect(
      o.ipCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reputation!,
      unittest.equals('foo'),
    );
    checkUnnamed5648(o.sampleIps!);
  }
  buildCounterIpReputation--;
}

core.List<api.Domain> buildUnnamed5649() {
  var o = <api.Domain>[];
  o.add(buildDomain());
  o.add(buildDomain());
  return o;
}

void checkUnnamed5649(core.List<api.Domain> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDomain(o[0] as api.Domain);
  checkDomain(o[1] as api.Domain);
}

core.int buildCounterListDomainsResponse = 0;
api.ListDomainsResponse buildListDomainsResponse() {
  var o = api.ListDomainsResponse();
  buildCounterListDomainsResponse++;
  if (buildCounterListDomainsResponse < 3) {
    o.domains = buildUnnamed5649();
    o.nextPageToken = 'foo';
  }
  buildCounterListDomainsResponse--;
  return o;
}

void checkListDomainsResponse(api.ListDomainsResponse o) {
  buildCounterListDomainsResponse++;
  if (buildCounterListDomainsResponse < 3) {
    checkUnnamed5649(o.domains!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListDomainsResponse--;
}

core.List<api.TrafficStats> buildUnnamed5650() {
  var o = <api.TrafficStats>[];
  o.add(buildTrafficStats());
  o.add(buildTrafficStats());
  return o;
}

void checkUnnamed5650(core.List<api.TrafficStats> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTrafficStats(o[0] as api.TrafficStats);
  checkTrafficStats(o[1] as api.TrafficStats);
}

core.int buildCounterListTrafficStatsResponse = 0;
api.ListTrafficStatsResponse buildListTrafficStatsResponse() {
  var o = api.ListTrafficStatsResponse();
  buildCounterListTrafficStatsResponse++;
  if (buildCounterListTrafficStatsResponse < 3) {
    o.nextPageToken = 'foo';
    o.trafficStats = buildUnnamed5650();
  }
  buildCounterListTrafficStatsResponse--;
  return o;
}

void checkListTrafficStatsResponse(api.ListTrafficStatsResponse o) {
  buildCounterListTrafficStatsResponse++;
  if (buildCounterListTrafficStatsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5650(o.trafficStats!);
  }
  buildCounterListTrafficStatsResponse--;
}

core.List<api.DeliveryError> buildUnnamed5651() {
  var o = <api.DeliveryError>[];
  o.add(buildDeliveryError());
  o.add(buildDeliveryError());
  return o;
}

void checkUnnamed5651(core.List<api.DeliveryError> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDeliveryError(o[0] as api.DeliveryError);
  checkDeliveryError(o[1] as api.DeliveryError);
}

core.List<api.IpReputation> buildUnnamed5652() {
  var o = <api.IpReputation>[];
  o.add(buildIpReputation());
  o.add(buildIpReputation());
  return o;
}

void checkUnnamed5652(core.List<api.IpReputation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIpReputation(o[0] as api.IpReputation);
  checkIpReputation(o[1] as api.IpReputation);
}

core.List<api.FeedbackLoop> buildUnnamed5653() {
  var o = <api.FeedbackLoop>[];
  o.add(buildFeedbackLoop());
  o.add(buildFeedbackLoop());
  return o;
}

void checkUnnamed5653(core.List<api.FeedbackLoop> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFeedbackLoop(o[0] as api.FeedbackLoop);
  checkFeedbackLoop(o[1] as api.FeedbackLoop);
}

core.int buildCounterTrafficStats = 0;
api.TrafficStats buildTrafficStats() {
  var o = api.TrafficStats();
  buildCounterTrafficStats++;
  if (buildCounterTrafficStats < 3) {
    o.deliveryErrors = buildUnnamed5651();
    o.dkimSuccessRatio = 42.0;
    o.dmarcSuccessRatio = 42.0;
    o.domainReputation = 'foo';
    o.inboundEncryptionRatio = 42.0;
    o.ipReputations = buildUnnamed5652();
    o.name = 'foo';
    o.outboundEncryptionRatio = 42.0;
    o.spammyFeedbackLoops = buildUnnamed5653();
    o.spfSuccessRatio = 42.0;
    o.userReportedSpamRatio = 42.0;
  }
  buildCounterTrafficStats--;
  return o;
}

void checkTrafficStats(api.TrafficStats o) {
  buildCounterTrafficStats++;
  if (buildCounterTrafficStats < 3) {
    checkUnnamed5651(o.deliveryErrors!);
    unittest.expect(
      o.dkimSuccessRatio!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.dmarcSuccessRatio!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.domainReputation!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inboundEncryptionRatio!,
      unittest.equals(42.0),
    );
    checkUnnamed5652(o.ipReputations!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.outboundEncryptionRatio!,
      unittest.equals(42.0),
    );
    checkUnnamed5653(o.spammyFeedbackLoops!);
    unittest.expect(
      o.spfSuccessRatio!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.userReportedSpamRatio!,
      unittest.equals(42.0),
    );
  }
  buildCounterTrafficStats--;
}

void main() {
  unittest.group('obj-schema-DeliveryError', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDeliveryError();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DeliveryError.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDeliveryError(od as api.DeliveryError);
    });
  });

  unittest.group('obj-schema-Domain', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDomain();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Domain.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDomain(od as api.Domain);
    });
  });

  unittest.group('obj-schema-FeedbackLoop', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFeedbackLoop();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FeedbackLoop.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFeedbackLoop(od as api.FeedbackLoop);
    });
  });

  unittest.group('obj-schema-IpReputation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIpReputation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IpReputation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIpReputation(od as api.IpReputation);
    });
  });

  unittest.group('obj-schema-ListDomainsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDomainsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDomainsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDomainsResponse(od as api.ListDomainsResponse);
    });
  });

  unittest.group('obj-schema-ListTrafficStatsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListTrafficStatsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListTrafficStatsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListTrafficStatsResponse(od as api.ListTrafficStatsResponse);
    });
  });

  unittest.group('obj-schema-TrafficStats', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTrafficStats();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TrafficStats.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTrafficStats(od as api.TrafficStats);
    });
  });

  unittest.group('resource-DomainsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.PostmasterToolsApi(mock).domains;
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
        var resp = convert.json.encode(buildDomain());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkDomain(response as api.Domain);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.PostmasterToolsApi(mock).domains;
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
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("v1/domains"),
        );
        pathOffset += 10;

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
        var resp = convert.json.encode(buildListDomainsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListDomainsResponse(response as api.ListDomainsResponse);
    });
  });

  unittest.group('resource-DomainsTrafficStatsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.PostmasterToolsApi(mock).domains.trafficStats;
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
        var resp = convert.json.encode(buildTrafficStats());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkTrafficStats(response as api.TrafficStats);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.PostmasterToolsApi(mock).domains.trafficStats;
      var arg_parent = 'foo';
      var arg_endDate_day = 42;
      var arg_endDate_month = 42;
      var arg_endDate_year = 42;
      var arg_pageSize = 42;
      var arg_pageToken = 'foo';
      var arg_startDate_day = 42;
      var arg_startDate_month = 42;
      var arg_startDate_year = 42;
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
          core.int.parse(queryMap["endDate.day"]!.first),
          unittest.equals(arg_endDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["endDate.month"]!.first),
          unittest.equals(arg_endDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["endDate.year"]!.first),
          unittest.equals(arg_endDate_year),
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
          core.int.parse(queryMap["startDate.day"]!.first),
          unittest.equals(arg_startDate_day),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate.month"]!.first),
          unittest.equals(arg_startDate_month),
        );
        unittest.expect(
          core.int.parse(queryMap["startDate.year"]!.first),
          unittest.equals(arg_startDate_year),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListTrafficStatsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          endDate_day: arg_endDate_day,
          endDate_month: arg_endDate_month,
          endDate_year: arg_endDate_year,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          startDate_day: arg_startDate_day,
          startDate_month: arg_startDate_month,
          startDate_year: arg_startDate_year,
          $fields: arg_$fields);
      checkListTrafficStatsResponse(response as api.ListTrafficStatsResponse);
    });
  });
}
