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

import 'package:googleapis/gamesconfiguration/v1configuration.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAchievementConfiguration = 0;
api.AchievementConfiguration buildAchievementConfiguration() {
  var o = api.AchievementConfiguration();
  buildCounterAchievementConfiguration++;
  if (buildCounterAchievementConfiguration < 3) {
    o.achievementType = 'foo';
    o.draft = buildAchievementConfigurationDetail();
    o.id = 'foo';
    o.initialState = 'foo';
    o.kind = 'foo';
    o.published = buildAchievementConfigurationDetail();
    o.stepsToUnlock = 42;
    o.token = 'foo';
  }
  buildCounterAchievementConfiguration--;
  return o;
}

void checkAchievementConfiguration(api.AchievementConfiguration o) {
  buildCounterAchievementConfiguration++;
  if (buildCounterAchievementConfiguration < 3) {
    unittest.expect(
      o.achievementType!,
      unittest.equals('foo'),
    );
    checkAchievementConfigurationDetail(
        o.draft! as api.AchievementConfigurationDetail);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.initialState!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkAchievementConfigurationDetail(
        o.published! as api.AchievementConfigurationDetail);
    unittest.expect(
      o.stepsToUnlock!,
      unittest.equals(42),
    );
    unittest.expect(
      o.token!,
      unittest.equals('foo'),
    );
  }
  buildCounterAchievementConfiguration--;
}

core.int buildCounterAchievementConfigurationDetail = 0;
api.AchievementConfigurationDetail buildAchievementConfigurationDetail() {
  var o = api.AchievementConfigurationDetail();
  buildCounterAchievementConfigurationDetail++;
  if (buildCounterAchievementConfigurationDetail < 3) {
    o.description = buildLocalizedStringBundle();
    o.iconUrl = 'foo';
    o.kind = 'foo';
    o.name = buildLocalizedStringBundle();
    o.pointValue = 42;
    o.sortRank = 42;
  }
  buildCounterAchievementConfigurationDetail--;
  return o;
}

void checkAchievementConfigurationDetail(api.AchievementConfigurationDetail o) {
  buildCounterAchievementConfigurationDetail++;
  if (buildCounterAchievementConfigurationDetail < 3) {
    checkLocalizedStringBundle(o.description! as api.LocalizedStringBundle);
    unittest.expect(
      o.iconUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkLocalizedStringBundle(o.name! as api.LocalizedStringBundle);
    unittest.expect(
      o.pointValue!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sortRank!,
      unittest.equals(42),
    );
  }
  buildCounterAchievementConfigurationDetail--;
}

core.List<api.AchievementConfiguration> buildUnnamed3546() {
  var o = <api.AchievementConfiguration>[];
  o.add(buildAchievementConfiguration());
  o.add(buildAchievementConfiguration());
  return o;
}

void checkUnnamed3546(core.List<api.AchievementConfiguration> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAchievementConfiguration(o[0] as api.AchievementConfiguration);
  checkAchievementConfiguration(o[1] as api.AchievementConfiguration);
}

core.int buildCounterAchievementConfigurationListResponse = 0;
api.AchievementConfigurationListResponse
    buildAchievementConfigurationListResponse() {
  var o = api.AchievementConfigurationListResponse();
  buildCounterAchievementConfigurationListResponse++;
  if (buildCounterAchievementConfigurationListResponse < 3) {
    o.items = buildUnnamed3546();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterAchievementConfigurationListResponse--;
  return o;
}

void checkAchievementConfigurationListResponse(
    api.AchievementConfigurationListResponse o) {
  buildCounterAchievementConfigurationListResponse++;
  if (buildCounterAchievementConfigurationListResponse < 3) {
    checkUnnamed3546(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterAchievementConfigurationListResponse--;
}

core.int buildCounterGamesNumberAffixConfiguration = 0;
api.GamesNumberAffixConfiguration buildGamesNumberAffixConfiguration() {
  var o = api.GamesNumberAffixConfiguration();
  buildCounterGamesNumberAffixConfiguration++;
  if (buildCounterGamesNumberAffixConfiguration < 3) {
    o.few = buildLocalizedStringBundle();
    o.many = buildLocalizedStringBundle();
    o.one = buildLocalizedStringBundle();
    o.other = buildLocalizedStringBundle();
    o.two = buildLocalizedStringBundle();
    o.zero = buildLocalizedStringBundle();
  }
  buildCounterGamesNumberAffixConfiguration--;
  return o;
}

void checkGamesNumberAffixConfiguration(api.GamesNumberAffixConfiguration o) {
  buildCounterGamesNumberAffixConfiguration++;
  if (buildCounterGamesNumberAffixConfiguration < 3) {
    checkLocalizedStringBundle(o.few! as api.LocalizedStringBundle);
    checkLocalizedStringBundle(o.many! as api.LocalizedStringBundle);
    checkLocalizedStringBundle(o.one! as api.LocalizedStringBundle);
    checkLocalizedStringBundle(o.other! as api.LocalizedStringBundle);
    checkLocalizedStringBundle(o.two! as api.LocalizedStringBundle);
    checkLocalizedStringBundle(o.zero! as api.LocalizedStringBundle);
  }
  buildCounterGamesNumberAffixConfiguration--;
}

core.int buildCounterGamesNumberFormatConfiguration = 0;
api.GamesNumberFormatConfiguration buildGamesNumberFormatConfiguration() {
  var o = api.GamesNumberFormatConfiguration();
  buildCounterGamesNumberFormatConfiguration++;
  if (buildCounterGamesNumberFormatConfiguration < 3) {
    o.currencyCode = 'foo';
    o.numDecimalPlaces = 42;
    o.numberFormatType = 'foo';
    o.suffix = buildGamesNumberAffixConfiguration();
  }
  buildCounterGamesNumberFormatConfiguration--;
  return o;
}

void checkGamesNumberFormatConfiguration(api.GamesNumberFormatConfiguration o) {
  buildCounterGamesNumberFormatConfiguration++;
  if (buildCounterGamesNumberFormatConfiguration < 3) {
    unittest.expect(
      o.currencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numDecimalPlaces!,
      unittest.equals(42),
    );
    unittest.expect(
      o.numberFormatType!,
      unittest.equals('foo'),
    );
    checkGamesNumberAffixConfiguration(
        o.suffix! as api.GamesNumberAffixConfiguration);
  }
  buildCounterGamesNumberFormatConfiguration--;
}

core.int buildCounterImageConfiguration = 0;
api.ImageConfiguration buildImageConfiguration() {
  var o = api.ImageConfiguration();
  buildCounterImageConfiguration++;
  if (buildCounterImageConfiguration < 3) {
    o.imageType = 'foo';
    o.kind = 'foo';
    o.resourceId = 'foo';
    o.url = 'foo';
  }
  buildCounterImageConfiguration--;
  return o;
}

void checkImageConfiguration(api.ImageConfiguration o) {
  buildCounterImageConfiguration++;
  if (buildCounterImageConfiguration < 3) {
    unittest.expect(
      o.imageType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.url!,
      unittest.equals('foo'),
    );
  }
  buildCounterImageConfiguration--;
}

core.int buildCounterLeaderboardConfiguration = 0;
api.LeaderboardConfiguration buildLeaderboardConfiguration() {
  var o = api.LeaderboardConfiguration();
  buildCounterLeaderboardConfiguration++;
  if (buildCounterLeaderboardConfiguration < 3) {
    o.draft = buildLeaderboardConfigurationDetail();
    o.id = 'foo';
    o.kind = 'foo';
    o.published = buildLeaderboardConfigurationDetail();
    o.scoreMax = 'foo';
    o.scoreMin = 'foo';
    o.scoreOrder = 'foo';
    o.token = 'foo';
  }
  buildCounterLeaderboardConfiguration--;
  return o;
}

void checkLeaderboardConfiguration(api.LeaderboardConfiguration o) {
  buildCounterLeaderboardConfiguration++;
  if (buildCounterLeaderboardConfiguration < 3) {
    checkLeaderboardConfigurationDetail(
        o.draft! as api.LeaderboardConfigurationDetail);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkLeaderboardConfigurationDetail(
        o.published! as api.LeaderboardConfigurationDetail);
    unittest.expect(
      o.scoreMax!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scoreMin!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scoreOrder!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.token!,
      unittest.equals('foo'),
    );
  }
  buildCounterLeaderboardConfiguration--;
}

core.int buildCounterLeaderboardConfigurationDetail = 0;
api.LeaderboardConfigurationDetail buildLeaderboardConfigurationDetail() {
  var o = api.LeaderboardConfigurationDetail();
  buildCounterLeaderboardConfigurationDetail++;
  if (buildCounterLeaderboardConfigurationDetail < 3) {
    o.iconUrl = 'foo';
    o.kind = 'foo';
    o.name = buildLocalizedStringBundle();
    o.scoreFormat = buildGamesNumberFormatConfiguration();
    o.sortRank = 42;
  }
  buildCounterLeaderboardConfigurationDetail--;
  return o;
}

void checkLeaderboardConfigurationDetail(api.LeaderboardConfigurationDetail o) {
  buildCounterLeaderboardConfigurationDetail++;
  if (buildCounterLeaderboardConfigurationDetail < 3) {
    unittest.expect(
      o.iconUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkLocalizedStringBundle(o.name! as api.LocalizedStringBundle);
    checkGamesNumberFormatConfiguration(
        o.scoreFormat! as api.GamesNumberFormatConfiguration);
    unittest.expect(
      o.sortRank!,
      unittest.equals(42),
    );
  }
  buildCounterLeaderboardConfigurationDetail--;
}

core.List<api.LeaderboardConfiguration> buildUnnamed3547() {
  var o = <api.LeaderboardConfiguration>[];
  o.add(buildLeaderboardConfiguration());
  o.add(buildLeaderboardConfiguration());
  return o;
}

void checkUnnamed3547(core.List<api.LeaderboardConfiguration> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLeaderboardConfiguration(o[0] as api.LeaderboardConfiguration);
  checkLeaderboardConfiguration(o[1] as api.LeaderboardConfiguration);
}

core.int buildCounterLeaderboardConfigurationListResponse = 0;
api.LeaderboardConfigurationListResponse
    buildLeaderboardConfigurationListResponse() {
  var o = api.LeaderboardConfigurationListResponse();
  buildCounterLeaderboardConfigurationListResponse++;
  if (buildCounterLeaderboardConfigurationListResponse < 3) {
    o.items = buildUnnamed3547();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterLeaderboardConfigurationListResponse--;
  return o;
}

void checkLeaderboardConfigurationListResponse(
    api.LeaderboardConfigurationListResponse o) {
  buildCounterLeaderboardConfigurationListResponse++;
  if (buildCounterLeaderboardConfigurationListResponse < 3) {
    checkUnnamed3547(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterLeaderboardConfigurationListResponse--;
}

core.int buildCounterLocalizedString = 0;
api.LocalizedString buildLocalizedString() {
  var o = api.LocalizedString();
  buildCounterLocalizedString++;
  if (buildCounterLocalizedString < 3) {
    o.kind = 'foo';
    o.locale = 'foo';
    o.value = 'foo';
  }
  buildCounterLocalizedString--;
  return o;
}

void checkLocalizedString(api.LocalizedString o) {
  buildCounterLocalizedString++;
  if (buildCounterLocalizedString < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.locale!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocalizedString--;
}

core.List<api.LocalizedString> buildUnnamed3548() {
  var o = <api.LocalizedString>[];
  o.add(buildLocalizedString());
  o.add(buildLocalizedString());
  return o;
}

void checkUnnamed3548(core.List<api.LocalizedString> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocalizedString(o[0] as api.LocalizedString);
  checkLocalizedString(o[1] as api.LocalizedString);
}

core.int buildCounterLocalizedStringBundle = 0;
api.LocalizedStringBundle buildLocalizedStringBundle() {
  var o = api.LocalizedStringBundle();
  buildCounterLocalizedStringBundle++;
  if (buildCounterLocalizedStringBundle < 3) {
    o.kind = 'foo';
    o.translations = buildUnnamed3548();
  }
  buildCounterLocalizedStringBundle--;
  return o;
}

void checkLocalizedStringBundle(api.LocalizedStringBundle o) {
  buildCounterLocalizedStringBundle++;
  if (buildCounterLocalizedStringBundle < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed3548(o.translations!);
  }
  buildCounterLocalizedStringBundle--;
}

void main() {
  unittest.group('obj-schema-AchievementConfiguration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAchievementConfiguration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AchievementConfiguration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAchievementConfiguration(od as api.AchievementConfiguration);
    });
  });

  unittest.group('obj-schema-AchievementConfigurationDetail', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAchievementConfigurationDetail();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AchievementConfigurationDetail.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAchievementConfigurationDetail(
          od as api.AchievementConfigurationDetail);
    });
  });

  unittest.group('obj-schema-AchievementConfigurationListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAchievementConfigurationListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AchievementConfigurationListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAchievementConfigurationListResponse(
          od as api.AchievementConfigurationListResponse);
    });
  });

  unittest.group('obj-schema-GamesNumberAffixConfiguration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGamesNumberAffixConfiguration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GamesNumberAffixConfiguration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGamesNumberAffixConfiguration(
          od as api.GamesNumberAffixConfiguration);
    });
  });

  unittest.group('obj-schema-GamesNumberFormatConfiguration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGamesNumberFormatConfiguration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GamesNumberFormatConfiguration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGamesNumberFormatConfiguration(
          od as api.GamesNumberFormatConfiguration);
    });
  });

  unittest.group('obj-schema-ImageConfiguration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildImageConfiguration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ImageConfiguration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkImageConfiguration(od as api.ImageConfiguration);
    });
  });

  unittest.group('obj-schema-LeaderboardConfiguration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLeaderboardConfiguration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LeaderboardConfiguration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLeaderboardConfiguration(od as api.LeaderboardConfiguration);
    });
  });

  unittest.group('obj-schema-LeaderboardConfigurationDetail', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLeaderboardConfigurationDetail();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LeaderboardConfigurationDetail.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLeaderboardConfigurationDetail(
          od as api.LeaderboardConfigurationDetail);
    });
  });

  unittest.group('obj-schema-LeaderboardConfigurationListResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLeaderboardConfigurationListResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LeaderboardConfigurationListResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLeaderboardConfigurationListResponse(
          od as api.LeaderboardConfigurationListResponse);
    });
  });

  unittest.group('obj-schema-LocalizedString', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocalizedString();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LocalizedString.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLocalizedString(od as api.LocalizedString);
    });
  });

  unittest.group('obj-schema-LocalizedStringBundle', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocalizedStringBundle();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LocalizedStringBundle.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLocalizedStringBundle(od as api.LocalizedStringBundle);
    });
  });

  unittest.group('resource-AchievementConfigurationsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.GamesConfigurationApi(mock).achievementConfigurations;
      var arg_achievementId = 'foo';
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
          path.substring(pathOffset, pathOffset + 35),
          unittest.equals("games/v1configuration/achievements/"),
        );
        pathOffset += 35;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_achievementId'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_achievementId, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GamesConfigurationApi(mock).achievementConfigurations;
      var arg_achievementId = 'foo';
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
          path.substring(pathOffset, pathOffset + 35),
          unittest.equals("games/v1configuration/achievements/"),
        );
        pathOffset += 35;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_achievementId'),
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
        var resp = convert.json.encode(buildAchievementConfiguration());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_achievementId, $fields: arg_$fields);
      checkAchievementConfiguration(response as api.AchievementConfiguration);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.GamesConfigurationApi(mock).achievementConfigurations;
      var arg_request = buildAchievementConfiguration();
      var arg_applicationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AchievementConfiguration.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAchievementConfiguration(obj as api.AchievementConfiguration);

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
          path.substring(pathOffset, pathOffset + 35),
          unittest.equals("games/v1configuration/applications/"),
        );
        pathOffset += 35;
        index = path.indexOf('/achievements', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_applicationId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/achievements"),
        );
        pathOffset += 13;

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
        var resp = convert.json.encode(buildAchievementConfiguration());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, arg_applicationId,
          $fields: arg_$fields);
      checkAchievementConfiguration(response as api.AchievementConfiguration);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GamesConfigurationApi(mock).achievementConfigurations;
      var arg_applicationId = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 35),
          unittest.equals("games/v1configuration/applications/"),
        );
        pathOffset += 35;
        index = path.indexOf('/achievements', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_applicationId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/achievements"),
        );
        pathOffset += 13;

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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
            convert.json.encode(buildAchievementConfigurationListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_applicationId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkAchievementConfigurationListResponse(
          response as api.AchievementConfigurationListResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.GamesConfigurationApi(mock).achievementConfigurations;
      var arg_request = buildAchievementConfiguration();
      var arg_achievementId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AchievementConfiguration.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAchievementConfiguration(obj as api.AchievementConfiguration);

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
          path.substring(pathOffset, pathOffset + 35),
          unittest.equals("games/v1configuration/achievements/"),
        );
        pathOffset += 35;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_achievementId'),
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
        var resp = convert.json.encode(buildAchievementConfiguration());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_achievementId,
          $fields: arg_$fields);
      checkAchievementConfiguration(response as api.AchievementConfiguration);
    });
  });

  unittest.group('resource-ImageConfigurationsResource', () {
    unittest.test('method--upload', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.GamesConfigurationApi(mock).imageConfigurations;
      var arg_resourceId = 'foo';
      var arg_imageType = 'foo';
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
          path.substring(pathOffset, pathOffset + 29),
          unittest.equals("games/v1configuration/images/"),
        );
        pathOffset += 29;
        index = path.indexOf('/imageType/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_resourceId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 11),
          unittest.equals("/imageType/"),
        );
        pathOffset += 11;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_imageType'),
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
        var resp = convert.json.encode(buildImageConfiguration());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.upload(arg_resourceId, arg_imageType, $fields: arg_$fields);
      checkImageConfiguration(response as api.ImageConfiguration);
    });
  });

  unittest.group('resource-LeaderboardConfigurationsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.GamesConfigurationApi(mock).leaderboardConfigurations;
      var arg_leaderboardId = 'foo';
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
          path.substring(pathOffset, pathOffset + 35),
          unittest.equals("games/v1configuration/leaderboards/"),
        );
        pathOffset += 35;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_leaderboardId'),
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_leaderboardId, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.GamesConfigurationApi(mock).leaderboardConfigurations;
      var arg_leaderboardId = 'foo';
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
          path.substring(pathOffset, pathOffset + 35),
          unittest.equals("games/v1configuration/leaderboards/"),
        );
        pathOffset += 35;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_leaderboardId'),
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
        var resp = convert.json.encode(buildLeaderboardConfiguration());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_leaderboardId, $fields: arg_$fields);
      checkLeaderboardConfiguration(response as api.LeaderboardConfiguration);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.GamesConfigurationApi(mock).leaderboardConfigurations;
      var arg_request = buildLeaderboardConfiguration();
      var arg_applicationId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LeaderboardConfiguration.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLeaderboardConfiguration(obj as api.LeaderboardConfiguration);

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
          path.substring(pathOffset, pathOffset + 35),
          unittest.equals("games/v1configuration/applications/"),
        );
        pathOffset += 35;
        index = path.indexOf('/leaderboards', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_applicationId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/leaderboards"),
        );
        pathOffset += 13;

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
        var resp = convert.json.encode(buildLeaderboardConfiguration());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(arg_request, arg_applicationId,
          $fields: arg_$fields);
      checkLeaderboardConfiguration(response as api.LeaderboardConfiguration);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.GamesConfigurationApi(mock).leaderboardConfigurations;
      var arg_applicationId = 'foo';
      var arg_maxResults = 42;
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
          path.substring(pathOffset, pathOffset + 35),
          unittest.equals("games/v1configuration/applications/"),
        );
        pathOffset += 35;
        index = path.indexOf('/leaderboards', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_applicationId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("/leaderboards"),
        );
        pathOffset += 13;

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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
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
            convert.json.encode(buildLeaderboardConfigurationListResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_applicationId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkLeaderboardConfigurationListResponse(
          response as api.LeaderboardConfigurationListResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.GamesConfigurationApi(mock).leaderboardConfigurations;
      var arg_request = buildLeaderboardConfiguration();
      var arg_leaderboardId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LeaderboardConfiguration.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLeaderboardConfiguration(obj as api.LeaderboardConfiguration);

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
          path.substring(pathOffset, pathOffset + 35),
          unittest.equals("games/v1configuration/leaderboards/"),
        );
        pathOffset += 35;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_leaderboardId'),
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
        var resp = convert.json.encode(buildLeaderboardConfiguration());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_leaderboardId,
          $fields: arg_$fields);
      checkLeaderboardConfiguration(response as api.LeaderboardConfiguration);
    });
  });
}
