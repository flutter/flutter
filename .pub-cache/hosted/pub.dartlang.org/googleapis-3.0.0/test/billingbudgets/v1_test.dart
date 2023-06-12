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

import 'package:googleapis/billingbudgets/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.GoogleCloudBillingBudgetsV1ThresholdRule> buildUnnamed1682() {
  var o = <api.GoogleCloudBillingBudgetsV1ThresholdRule>[];
  o.add(buildGoogleCloudBillingBudgetsV1ThresholdRule());
  o.add(buildGoogleCloudBillingBudgetsV1ThresholdRule());
  return o;
}

void checkUnnamed1682(
    core.List<api.GoogleCloudBillingBudgetsV1ThresholdRule> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudBillingBudgetsV1ThresholdRule(
      o[0] as api.GoogleCloudBillingBudgetsV1ThresholdRule);
  checkGoogleCloudBillingBudgetsV1ThresholdRule(
      o[1] as api.GoogleCloudBillingBudgetsV1ThresholdRule);
}

core.int buildCounterGoogleCloudBillingBudgetsV1Budget = 0;
api.GoogleCloudBillingBudgetsV1Budget buildGoogleCloudBillingBudgetsV1Budget() {
  var o = api.GoogleCloudBillingBudgetsV1Budget();
  buildCounterGoogleCloudBillingBudgetsV1Budget++;
  if (buildCounterGoogleCloudBillingBudgetsV1Budget < 3) {
    o.amount = buildGoogleCloudBillingBudgetsV1BudgetAmount();
    o.budgetFilter = buildGoogleCloudBillingBudgetsV1Filter();
    o.displayName = 'foo';
    o.etag = 'foo';
    o.name = 'foo';
    o.notificationsRule = buildGoogleCloudBillingBudgetsV1NotificationsRule();
    o.thresholdRules = buildUnnamed1682();
  }
  buildCounterGoogleCloudBillingBudgetsV1Budget--;
  return o;
}

void checkGoogleCloudBillingBudgetsV1Budget(
    api.GoogleCloudBillingBudgetsV1Budget o) {
  buildCounterGoogleCloudBillingBudgetsV1Budget++;
  if (buildCounterGoogleCloudBillingBudgetsV1Budget < 3) {
    checkGoogleCloudBillingBudgetsV1BudgetAmount(
        o.amount! as api.GoogleCloudBillingBudgetsV1BudgetAmount);
    checkGoogleCloudBillingBudgetsV1Filter(
        o.budgetFilter! as api.GoogleCloudBillingBudgetsV1Filter);
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkGoogleCloudBillingBudgetsV1NotificationsRule(o.notificationsRule!
        as api.GoogleCloudBillingBudgetsV1NotificationsRule);
    checkUnnamed1682(o.thresholdRules!);
  }
  buildCounterGoogleCloudBillingBudgetsV1Budget--;
}

core.int buildCounterGoogleCloudBillingBudgetsV1BudgetAmount = 0;
api.GoogleCloudBillingBudgetsV1BudgetAmount
    buildGoogleCloudBillingBudgetsV1BudgetAmount() {
  var o = api.GoogleCloudBillingBudgetsV1BudgetAmount();
  buildCounterGoogleCloudBillingBudgetsV1BudgetAmount++;
  if (buildCounterGoogleCloudBillingBudgetsV1BudgetAmount < 3) {
    o.lastPeriodAmount = buildGoogleCloudBillingBudgetsV1LastPeriodAmount();
    o.specifiedAmount = buildGoogleTypeMoney();
  }
  buildCounterGoogleCloudBillingBudgetsV1BudgetAmount--;
  return o;
}

void checkGoogleCloudBillingBudgetsV1BudgetAmount(
    api.GoogleCloudBillingBudgetsV1BudgetAmount o) {
  buildCounterGoogleCloudBillingBudgetsV1BudgetAmount++;
  if (buildCounterGoogleCloudBillingBudgetsV1BudgetAmount < 3) {
    checkGoogleCloudBillingBudgetsV1LastPeriodAmount(
        o.lastPeriodAmount! as api.GoogleCloudBillingBudgetsV1LastPeriodAmount);
    checkGoogleTypeMoney(o.specifiedAmount! as api.GoogleTypeMoney);
  }
  buildCounterGoogleCloudBillingBudgetsV1BudgetAmount--;
}

core.int buildCounterGoogleCloudBillingBudgetsV1CustomPeriod = 0;
api.GoogleCloudBillingBudgetsV1CustomPeriod
    buildGoogleCloudBillingBudgetsV1CustomPeriod() {
  var o = api.GoogleCloudBillingBudgetsV1CustomPeriod();
  buildCounterGoogleCloudBillingBudgetsV1CustomPeriod++;
  if (buildCounterGoogleCloudBillingBudgetsV1CustomPeriod < 3) {
    o.endDate = buildGoogleTypeDate();
    o.startDate = buildGoogleTypeDate();
  }
  buildCounterGoogleCloudBillingBudgetsV1CustomPeriod--;
  return o;
}

void checkGoogleCloudBillingBudgetsV1CustomPeriod(
    api.GoogleCloudBillingBudgetsV1CustomPeriod o) {
  buildCounterGoogleCloudBillingBudgetsV1CustomPeriod++;
  if (buildCounterGoogleCloudBillingBudgetsV1CustomPeriod < 3) {
    checkGoogleTypeDate(o.endDate! as api.GoogleTypeDate);
    checkGoogleTypeDate(o.startDate! as api.GoogleTypeDate);
  }
  buildCounterGoogleCloudBillingBudgetsV1CustomPeriod--;
}

core.List<core.String> buildUnnamed1683() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1683(core.List<core.String> o) {
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

core.List<core.Object> buildUnnamed1684() {
  var o = <core.Object>[];
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  o.add({
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  });
  return o;
}

void checkUnnamed1684(core.List<core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted1 = (o[0]) as core.Map;
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
  var casted2 = (o[1]) as core.Map;
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

core.Map<core.String, core.List<core.Object>> buildUnnamed1685() {
  var o = <core.String, core.List<core.Object>>{};
  o['x'] = buildUnnamed1684();
  o['y'] = buildUnnamed1684();
  return o;
}

void checkUnnamed1685(core.Map<core.String, core.List<core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed1684(o['x']!);
  checkUnnamed1684(o['y']!);
}

core.List<core.String> buildUnnamed1686() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1686(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1687() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1687(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1688() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1688(core.List<core.String> o) {
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

core.int buildCounterGoogleCloudBillingBudgetsV1Filter = 0;
api.GoogleCloudBillingBudgetsV1Filter buildGoogleCloudBillingBudgetsV1Filter() {
  var o = api.GoogleCloudBillingBudgetsV1Filter();
  buildCounterGoogleCloudBillingBudgetsV1Filter++;
  if (buildCounterGoogleCloudBillingBudgetsV1Filter < 3) {
    o.calendarPeriod = 'foo';
    o.creditTypes = buildUnnamed1683();
    o.creditTypesTreatment = 'foo';
    o.customPeriod = buildGoogleCloudBillingBudgetsV1CustomPeriod();
    o.labels = buildUnnamed1685();
    o.projects = buildUnnamed1686();
    o.services = buildUnnamed1687();
    o.subaccounts = buildUnnamed1688();
  }
  buildCounterGoogleCloudBillingBudgetsV1Filter--;
  return o;
}

void checkGoogleCloudBillingBudgetsV1Filter(
    api.GoogleCloudBillingBudgetsV1Filter o) {
  buildCounterGoogleCloudBillingBudgetsV1Filter++;
  if (buildCounterGoogleCloudBillingBudgetsV1Filter < 3) {
    unittest.expect(
      o.calendarPeriod!,
      unittest.equals('foo'),
    );
    checkUnnamed1683(o.creditTypes!);
    unittest.expect(
      o.creditTypesTreatment!,
      unittest.equals('foo'),
    );
    checkGoogleCloudBillingBudgetsV1CustomPeriod(
        o.customPeriod! as api.GoogleCloudBillingBudgetsV1CustomPeriod);
    checkUnnamed1685(o.labels!);
    checkUnnamed1686(o.projects!);
    checkUnnamed1687(o.services!);
    checkUnnamed1688(o.subaccounts!);
  }
  buildCounterGoogleCloudBillingBudgetsV1Filter--;
}

core.int buildCounterGoogleCloudBillingBudgetsV1LastPeriodAmount = 0;
api.GoogleCloudBillingBudgetsV1LastPeriodAmount
    buildGoogleCloudBillingBudgetsV1LastPeriodAmount() {
  var o = api.GoogleCloudBillingBudgetsV1LastPeriodAmount();
  buildCounterGoogleCloudBillingBudgetsV1LastPeriodAmount++;
  if (buildCounterGoogleCloudBillingBudgetsV1LastPeriodAmount < 3) {}
  buildCounterGoogleCloudBillingBudgetsV1LastPeriodAmount--;
  return o;
}

void checkGoogleCloudBillingBudgetsV1LastPeriodAmount(
    api.GoogleCloudBillingBudgetsV1LastPeriodAmount o) {
  buildCounterGoogleCloudBillingBudgetsV1LastPeriodAmount++;
  if (buildCounterGoogleCloudBillingBudgetsV1LastPeriodAmount < 3) {}
  buildCounterGoogleCloudBillingBudgetsV1LastPeriodAmount--;
}

core.List<api.GoogleCloudBillingBudgetsV1Budget> buildUnnamed1689() {
  var o = <api.GoogleCloudBillingBudgetsV1Budget>[];
  o.add(buildGoogleCloudBillingBudgetsV1Budget());
  o.add(buildGoogleCloudBillingBudgetsV1Budget());
  return o;
}

void checkUnnamed1689(core.List<api.GoogleCloudBillingBudgetsV1Budget> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGoogleCloudBillingBudgetsV1Budget(
      o[0] as api.GoogleCloudBillingBudgetsV1Budget);
  checkGoogleCloudBillingBudgetsV1Budget(
      o[1] as api.GoogleCloudBillingBudgetsV1Budget);
}

core.int buildCounterGoogleCloudBillingBudgetsV1ListBudgetsResponse = 0;
api.GoogleCloudBillingBudgetsV1ListBudgetsResponse
    buildGoogleCloudBillingBudgetsV1ListBudgetsResponse() {
  var o = api.GoogleCloudBillingBudgetsV1ListBudgetsResponse();
  buildCounterGoogleCloudBillingBudgetsV1ListBudgetsResponse++;
  if (buildCounterGoogleCloudBillingBudgetsV1ListBudgetsResponse < 3) {
    o.budgets = buildUnnamed1689();
    o.nextPageToken = 'foo';
  }
  buildCounterGoogleCloudBillingBudgetsV1ListBudgetsResponse--;
  return o;
}

void checkGoogleCloudBillingBudgetsV1ListBudgetsResponse(
    api.GoogleCloudBillingBudgetsV1ListBudgetsResponse o) {
  buildCounterGoogleCloudBillingBudgetsV1ListBudgetsResponse++;
  if (buildCounterGoogleCloudBillingBudgetsV1ListBudgetsResponse < 3) {
    checkUnnamed1689(o.budgets!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudBillingBudgetsV1ListBudgetsResponse--;
}

core.List<core.String> buildUnnamed1690() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1690(core.List<core.String> o) {
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

core.int buildCounterGoogleCloudBillingBudgetsV1NotificationsRule = 0;
api.GoogleCloudBillingBudgetsV1NotificationsRule
    buildGoogleCloudBillingBudgetsV1NotificationsRule() {
  var o = api.GoogleCloudBillingBudgetsV1NotificationsRule();
  buildCounterGoogleCloudBillingBudgetsV1NotificationsRule++;
  if (buildCounterGoogleCloudBillingBudgetsV1NotificationsRule < 3) {
    o.disableDefaultIamRecipients = true;
    o.monitoringNotificationChannels = buildUnnamed1690();
    o.pubsubTopic = 'foo';
    o.schemaVersion = 'foo';
  }
  buildCounterGoogleCloudBillingBudgetsV1NotificationsRule--;
  return o;
}

void checkGoogleCloudBillingBudgetsV1NotificationsRule(
    api.GoogleCloudBillingBudgetsV1NotificationsRule o) {
  buildCounterGoogleCloudBillingBudgetsV1NotificationsRule++;
  if (buildCounterGoogleCloudBillingBudgetsV1NotificationsRule < 3) {
    unittest.expect(o.disableDefaultIamRecipients!, unittest.isTrue);
    checkUnnamed1690(o.monitoringNotificationChannels!);
    unittest.expect(
      o.pubsubTopic!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.schemaVersion!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleCloudBillingBudgetsV1NotificationsRule--;
}

core.int buildCounterGoogleCloudBillingBudgetsV1ThresholdRule = 0;
api.GoogleCloudBillingBudgetsV1ThresholdRule
    buildGoogleCloudBillingBudgetsV1ThresholdRule() {
  var o = api.GoogleCloudBillingBudgetsV1ThresholdRule();
  buildCounterGoogleCloudBillingBudgetsV1ThresholdRule++;
  if (buildCounterGoogleCloudBillingBudgetsV1ThresholdRule < 3) {
    o.spendBasis = 'foo';
    o.thresholdPercent = 42.0;
  }
  buildCounterGoogleCloudBillingBudgetsV1ThresholdRule--;
  return o;
}

void checkGoogleCloudBillingBudgetsV1ThresholdRule(
    api.GoogleCloudBillingBudgetsV1ThresholdRule o) {
  buildCounterGoogleCloudBillingBudgetsV1ThresholdRule++;
  if (buildCounterGoogleCloudBillingBudgetsV1ThresholdRule < 3) {
    unittest.expect(
      o.spendBasis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.thresholdPercent!,
      unittest.equals(42.0),
    );
  }
  buildCounterGoogleCloudBillingBudgetsV1ThresholdRule--;
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

core.int buildCounterGoogleTypeDate = 0;
api.GoogleTypeDate buildGoogleTypeDate() {
  var o = api.GoogleTypeDate();
  buildCounterGoogleTypeDate++;
  if (buildCounterGoogleTypeDate < 3) {
    o.day = 42;
    o.month = 42;
    o.year = 42;
  }
  buildCounterGoogleTypeDate--;
  return o;
}

void checkGoogleTypeDate(api.GoogleTypeDate o) {
  buildCounterGoogleTypeDate++;
  if (buildCounterGoogleTypeDate < 3) {
    unittest.expect(
      o.day!,
      unittest.equals(42),
    );
    unittest.expect(
      o.month!,
      unittest.equals(42),
    );
    unittest.expect(
      o.year!,
      unittest.equals(42),
    );
  }
  buildCounterGoogleTypeDate--;
}

core.int buildCounterGoogleTypeMoney = 0;
api.GoogleTypeMoney buildGoogleTypeMoney() {
  var o = api.GoogleTypeMoney();
  buildCounterGoogleTypeMoney++;
  if (buildCounterGoogleTypeMoney < 3) {
    o.currencyCode = 'foo';
    o.nanos = 42;
    o.units = 'foo';
  }
  buildCounterGoogleTypeMoney--;
  return o;
}

void checkGoogleTypeMoney(api.GoogleTypeMoney o) {
  buildCounterGoogleTypeMoney++;
  if (buildCounterGoogleTypeMoney < 3) {
    unittest.expect(
      o.currencyCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nanos!,
      unittest.equals(42),
    );
    unittest.expect(
      o.units!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleTypeMoney--;
}

void main() {
  unittest.group('obj-schema-GoogleCloudBillingBudgetsV1Budget', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudBillingBudgetsV1Budget();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudBillingBudgetsV1Budget.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudBillingBudgetsV1Budget(
          od as api.GoogleCloudBillingBudgetsV1Budget);
    });
  });

  unittest.group('obj-schema-GoogleCloudBillingBudgetsV1BudgetAmount', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudBillingBudgetsV1BudgetAmount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudBillingBudgetsV1BudgetAmount.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudBillingBudgetsV1BudgetAmount(
          od as api.GoogleCloudBillingBudgetsV1BudgetAmount);
    });
  });

  unittest.group('obj-schema-GoogleCloudBillingBudgetsV1CustomPeriod', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudBillingBudgetsV1CustomPeriod();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudBillingBudgetsV1CustomPeriod.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudBillingBudgetsV1CustomPeriod(
          od as api.GoogleCloudBillingBudgetsV1CustomPeriod);
    });
  });

  unittest.group('obj-schema-GoogleCloudBillingBudgetsV1Filter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudBillingBudgetsV1Filter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudBillingBudgetsV1Filter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudBillingBudgetsV1Filter(
          od as api.GoogleCloudBillingBudgetsV1Filter);
    });
  });

  unittest.group('obj-schema-GoogleCloudBillingBudgetsV1LastPeriodAmount', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudBillingBudgetsV1LastPeriodAmount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudBillingBudgetsV1LastPeriodAmount.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudBillingBudgetsV1LastPeriodAmount(
          od as api.GoogleCloudBillingBudgetsV1LastPeriodAmount);
    });
  });

  unittest.group('obj-schema-GoogleCloudBillingBudgetsV1ListBudgetsResponse',
      () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudBillingBudgetsV1ListBudgetsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudBillingBudgetsV1ListBudgetsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudBillingBudgetsV1ListBudgetsResponse(
          od as api.GoogleCloudBillingBudgetsV1ListBudgetsResponse);
    });
  });

  unittest.group('obj-schema-GoogleCloudBillingBudgetsV1NotificationsRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudBillingBudgetsV1NotificationsRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudBillingBudgetsV1NotificationsRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudBillingBudgetsV1NotificationsRule(
          od as api.GoogleCloudBillingBudgetsV1NotificationsRule);
    });
  });

  unittest.group('obj-schema-GoogleCloudBillingBudgetsV1ThresholdRule', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleCloudBillingBudgetsV1ThresholdRule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleCloudBillingBudgetsV1ThresholdRule.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleCloudBillingBudgetsV1ThresholdRule(
          od as api.GoogleCloudBillingBudgetsV1ThresholdRule);
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

  unittest.group('obj-schema-GoogleTypeDate', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleTypeDate();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleTypeDate.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleTypeDate(od as api.GoogleTypeDate);
    });
  });

  unittest.group('obj-schema-GoogleTypeMoney', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleTypeMoney();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleTypeMoney.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleTypeMoney(od as api.GoogleTypeMoney);
    });
  });

  unittest.group('resource-BillingAccountsBudgetsResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.CloudBillingBudgetApi(mock).billingAccounts.budgets;
      var arg_request = buildGoogleCloudBillingBudgetsV1Budget();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleCloudBillingBudgetsV1Budget.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudBillingBudgetsV1Budget(
            obj as api.GoogleCloudBillingBudgetsV1Budget);

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
        var resp =
            convert.json.encode(buildGoogleCloudBillingBudgetsV1Budget());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkGoogleCloudBillingBudgetsV1Budget(
          response as api.GoogleCloudBillingBudgetsV1Budget);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.CloudBillingBudgetApi(mock).billingAccounts.budgets;
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
      var res = api.CloudBillingBudgetApi(mock).billingAccounts.budgets;
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
        var resp =
            convert.json.encode(buildGoogleCloudBillingBudgetsV1Budget());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGoogleCloudBillingBudgetsV1Budget(
          response as api.GoogleCloudBillingBudgetsV1Budget);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.CloudBillingBudgetApi(mock).billingAccounts.budgets;
      var arg_parent = 'foo';
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
        var resp = convert.json
            .encode(buildGoogleCloudBillingBudgetsV1ListBudgetsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkGoogleCloudBillingBudgetsV1ListBudgetsResponse(
          response as api.GoogleCloudBillingBudgetsV1ListBudgetsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.CloudBillingBudgetApi(mock).billingAccounts.budgets;
      var arg_request = buildGoogleCloudBillingBudgetsV1Budget();
      var arg_name = 'foo';
      var arg_updateMask = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GoogleCloudBillingBudgetsV1Budget.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGoogleCloudBillingBudgetsV1Budget(
            obj as api.GoogleCloudBillingBudgetsV1Budget);

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
        var resp =
            convert.json.encode(buildGoogleCloudBillingBudgetsV1Budget());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(arg_request, arg_name,
          updateMask: arg_updateMask, $fields: arg_$fields);
      checkGoogleCloudBillingBudgetsV1Budget(
          response as api.GoogleCloudBillingBudgetsV1Budget);
    });
  });
}
