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

import 'package:googleapis/admin/reports_v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.Activity> buildUnnamed5794() {
  var o = <api.Activity>[];
  o.add(buildActivity());
  o.add(buildActivity());
  return o;
}

void checkUnnamed5794(core.List<api.Activity> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkActivity(o[0] as api.Activity);
  checkActivity(o[1] as api.Activity);
}

core.int buildCounterActivities = 0;
api.Activities buildActivities() {
  var o = api.Activities();
  buildCounterActivities++;
  if (buildCounterActivities < 3) {
    o.etag = 'foo';
    o.items = buildUnnamed5794();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterActivities--;
  return o;
}

void checkActivities(api.Activities o) {
  buildCounterActivities++;
  if (buildCounterActivities < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed5794(o.items!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterActivities--;
}

core.int buildCounterActivityActor = 0;
api.ActivityActor buildActivityActor() {
  var o = api.ActivityActor();
  buildCounterActivityActor++;
  if (buildCounterActivityActor < 3) {
    o.callerType = 'foo';
    o.email = 'foo';
    o.key = 'foo';
    o.profileId = 'foo';
  }
  buildCounterActivityActor--;
  return o;
}

void checkActivityActor(api.ActivityActor o) {
  buildCounterActivityActor++;
  if (buildCounterActivityActor < 3) {
    unittest.expect(
      o.callerType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileId!,
      unittest.equals('foo'),
    );
  }
  buildCounterActivityActor--;
}

core.List<api.NestedParameter> buildUnnamed5795() {
  var o = <api.NestedParameter>[];
  o.add(buildNestedParameter());
  o.add(buildNestedParameter());
  return o;
}

void checkUnnamed5795(core.List<api.NestedParameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNestedParameter(o[0] as api.NestedParameter);
  checkNestedParameter(o[1] as api.NestedParameter);
}

core.int buildCounterActivityEventsParametersMessageValue = 0;
api.ActivityEventsParametersMessageValue
    buildActivityEventsParametersMessageValue() {
  var o = api.ActivityEventsParametersMessageValue();
  buildCounterActivityEventsParametersMessageValue++;
  if (buildCounterActivityEventsParametersMessageValue < 3) {
    o.parameter = buildUnnamed5795();
  }
  buildCounterActivityEventsParametersMessageValue--;
  return o;
}

void checkActivityEventsParametersMessageValue(
    api.ActivityEventsParametersMessageValue o) {
  buildCounterActivityEventsParametersMessageValue++;
  if (buildCounterActivityEventsParametersMessageValue < 3) {
    checkUnnamed5795(o.parameter!);
  }
  buildCounterActivityEventsParametersMessageValue--;
}

core.List<core.String> buildUnnamed5796() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5796(core.List<core.String> o) {
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

core.List<api.NestedParameter> buildUnnamed5797() {
  var o = <api.NestedParameter>[];
  o.add(buildNestedParameter());
  o.add(buildNestedParameter());
  return o;
}

void checkUnnamed5797(core.List<api.NestedParameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkNestedParameter(o[0] as api.NestedParameter);
  checkNestedParameter(o[1] as api.NestedParameter);
}

core.int buildCounterActivityEventsParametersMultiMessageValue = 0;
api.ActivityEventsParametersMultiMessageValue
    buildActivityEventsParametersMultiMessageValue() {
  var o = api.ActivityEventsParametersMultiMessageValue();
  buildCounterActivityEventsParametersMultiMessageValue++;
  if (buildCounterActivityEventsParametersMultiMessageValue < 3) {
    o.parameter = buildUnnamed5797();
  }
  buildCounterActivityEventsParametersMultiMessageValue--;
  return o;
}

void checkActivityEventsParametersMultiMessageValue(
    api.ActivityEventsParametersMultiMessageValue o) {
  buildCounterActivityEventsParametersMultiMessageValue++;
  if (buildCounterActivityEventsParametersMultiMessageValue < 3) {
    checkUnnamed5797(o.parameter!);
  }
  buildCounterActivityEventsParametersMultiMessageValue--;
}

core.List<api.ActivityEventsParametersMultiMessageValue> buildUnnamed5798() {
  var o = <api.ActivityEventsParametersMultiMessageValue>[];
  o.add(buildActivityEventsParametersMultiMessageValue());
  o.add(buildActivityEventsParametersMultiMessageValue());
  return o;
}

void checkUnnamed5798(
    core.List<api.ActivityEventsParametersMultiMessageValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkActivityEventsParametersMultiMessageValue(
      o[0] as api.ActivityEventsParametersMultiMessageValue);
  checkActivityEventsParametersMultiMessageValue(
      o[1] as api.ActivityEventsParametersMultiMessageValue);
}

core.List<core.String> buildUnnamed5799() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5799(core.List<core.String> o) {
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

core.int buildCounterActivityEventsParameters = 0;
api.ActivityEventsParameters buildActivityEventsParameters() {
  var o = api.ActivityEventsParameters();
  buildCounterActivityEventsParameters++;
  if (buildCounterActivityEventsParameters < 3) {
    o.boolValue = true;
    o.intValue = 'foo';
    o.messageValue = buildActivityEventsParametersMessageValue();
    o.multiIntValue = buildUnnamed5796();
    o.multiMessageValue = buildUnnamed5798();
    o.multiValue = buildUnnamed5799();
    o.name = 'foo';
    o.value = 'foo';
  }
  buildCounterActivityEventsParameters--;
  return o;
}

void checkActivityEventsParameters(api.ActivityEventsParameters o) {
  buildCounterActivityEventsParameters++;
  if (buildCounterActivityEventsParameters < 3) {
    unittest.expect(o.boolValue!, unittest.isTrue);
    unittest.expect(
      o.intValue!,
      unittest.equals('foo'),
    );
    checkActivityEventsParametersMessageValue(
        o.messageValue! as api.ActivityEventsParametersMessageValue);
    checkUnnamed5796(o.multiIntValue!);
    checkUnnamed5798(o.multiMessageValue!);
    checkUnnamed5799(o.multiValue!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterActivityEventsParameters--;
}

core.List<api.ActivityEventsParameters> buildUnnamed5800() {
  var o = <api.ActivityEventsParameters>[];
  o.add(buildActivityEventsParameters());
  o.add(buildActivityEventsParameters());
  return o;
}

void checkUnnamed5800(core.List<api.ActivityEventsParameters> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkActivityEventsParameters(o[0] as api.ActivityEventsParameters);
  checkActivityEventsParameters(o[1] as api.ActivityEventsParameters);
}

core.int buildCounterActivityEvents = 0;
api.ActivityEvents buildActivityEvents() {
  var o = api.ActivityEvents();
  buildCounterActivityEvents++;
  if (buildCounterActivityEvents < 3) {
    o.name = 'foo';
    o.parameters = buildUnnamed5800();
    o.type = 'foo';
  }
  buildCounterActivityEvents--;
  return o;
}

void checkActivityEvents(api.ActivityEvents o) {
  buildCounterActivityEvents++;
  if (buildCounterActivityEvents < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed5800(o.parameters!);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterActivityEvents--;
}

core.List<api.ActivityEvents> buildUnnamed5801() {
  var o = <api.ActivityEvents>[];
  o.add(buildActivityEvents());
  o.add(buildActivityEvents());
  return o;
}

void checkUnnamed5801(core.List<api.ActivityEvents> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkActivityEvents(o[0] as api.ActivityEvents);
  checkActivityEvents(o[1] as api.ActivityEvents);
}

core.int buildCounterActivityId = 0;
api.ActivityId buildActivityId() {
  var o = api.ActivityId();
  buildCounterActivityId++;
  if (buildCounterActivityId < 3) {
    o.applicationName = 'foo';
    o.customerId = 'foo';
    o.time = core.DateTime.parse("2002-02-27T14:01:02");
    o.uniqueQualifier = 'foo';
  }
  buildCounterActivityId--;
  return o;
}

void checkActivityId(api.ActivityId o) {
  buildCounterActivityId++;
  if (buildCounterActivityId < 3) {
    unittest.expect(
      o.applicationName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.customerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.time!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.uniqueQualifier!,
      unittest.equals('foo'),
    );
  }
  buildCounterActivityId--;
}

core.int buildCounterActivity = 0;
api.Activity buildActivity() {
  var o = api.Activity();
  buildCounterActivity++;
  if (buildCounterActivity < 3) {
    o.actor = buildActivityActor();
    o.etag = 'foo';
    o.events = buildUnnamed5801();
    o.id = buildActivityId();
    o.ipAddress = 'foo';
    o.kind = 'foo';
    o.ownerDomain = 'foo';
  }
  buildCounterActivity--;
  return o;
}

void checkActivity(api.Activity o) {
  buildCounterActivity++;
  if (buildCounterActivity < 3) {
    checkActivityActor(o.actor! as api.ActivityActor);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed5801(o.events!);
    checkActivityId(o.id! as api.ActivityId);
    unittest.expect(
      o.ipAddress!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.ownerDomain!,
      unittest.equals('foo'),
    );
  }
  buildCounterActivity--;
}

core.Map<core.String, core.String> buildUnnamed5802() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed5802(core.Map<core.String, core.String> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals('foo'),
  );
  unittest.expect(
    o['y']!,
    unittest.equals('foo'),
  );
}

core.int buildCounterChannel = 0;
api.Channel buildChannel() {
  var o = api.Channel();
  buildCounterChannel++;
  if (buildCounterChannel < 3) {
    o.address = 'foo';
    o.expiration = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.params = buildUnnamed5802();
    o.payload = true;
    o.resourceId = 'foo';
    o.resourceUri = 'foo';
    o.token = 'foo';
    o.type = 'foo';
  }
  buildCounterChannel--;
  return o;
}

void checkChannel(api.Channel o) {
  buildCounterChannel++;
  if (buildCounterChannel < 3) {
    unittest.expect(
      o.address!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expiration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed5802(o.params!);
    unittest.expect(o.payload!, unittest.isTrue);
    unittest.expect(
      o.resourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceUri!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.token!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterChannel--;
}

core.List<core.bool> buildUnnamed5803() {
  var o = <core.bool>[];
  o.add(true);
  o.add(true);
  return o;
}

void checkUnnamed5803(core.List<core.bool> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(o[0], unittest.isTrue);
  unittest.expect(o[1], unittest.isTrue);
}

core.List<core.String> buildUnnamed5804() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5804(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed5805() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5805(core.List<core.String> o) {
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

core.int buildCounterNestedParameter = 0;
api.NestedParameter buildNestedParameter() {
  var o = api.NestedParameter();
  buildCounterNestedParameter++;
  if (buildCounterNestedParameter < 3) {
    o.boolValue = true;
    o.intValue = 'foo';
    o.multiBoolValue = buildUnnamed5803();
    o.multiIntValue = buildUnnamed5804();
    o.multiValue = buildUnnamed5805();
    o.name = 'foo';
    o.value = 'foo';
  }
  buildCounterNestedParameter--;
  return o;
}

void checkNestedParameter(api.NestedParameter o) {
  buildCounterNestedParameter++;
  if (buildCounterNestedParameter < 3) {
    unittest.expect(o.boolValue!, unittest.isTrue);
    unittest.expect(
      o.intValue!,
      unittest.equals('foo'),
    );
    checkUnnamed5803(o.multiBoolValue!);
    checkUnnamed5804(o.multiIntValue!);
    checkUnnamed5805(o.multiValue!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterNestedParameter--;
}

core.int buildCounterUsageReportEntity = 0;
api.UsageReportEntity buildUsageReportEntity() {
  var o = api.UsageReportEntity();
  buildCounterUsageReportEntity++;
  if (buildCounterUsageReportEntity < 3) {
    o.customerId = 'foo';
    o.entityId = 'foo';
    o.profileId = 'foo';
    o.type = 'foo';
    o.userEmail = 'foo';
  }
  buildCounterUsageReportEntity--;
  return o;
}

void checkUsageReportEntity(api.UsageReportEntity o) {
  buildCounterUsageReportEntity++;
  if (buildCounterUsageReportEntity < 3) {
    unittest.expect(
      o.customerId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entityId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.profileId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userEmail!,
      unittest.equals('foo'),
    );
  }
  buildCounterUsageReportEntity--;
}

core.Map<core.String, core.Object> buildUnnamed5806() {
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

void checkUnnamed5806(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed5807() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed5806());
  o.add(buildUnnamed5806());
  return o;
}

void checkUnnamed5807(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed5806(o[0]);
  checkUnnamed5806(o[1]);
}

core.int buildCounterUsageReportParameters = 0;
api.UsageReportParameters buildUsageReportParameters() {
  var o = api.UsageReportParameters();
  buildCounterUsageReportParameters++;
  if (buildCounterUsageReportParameters < 3) {
    o.boolValue = true;
    o.datetimeValue = core.DateTime.parse("2002-02-27T14:01:02");
    o.intValue = 'foo';
    o.msgValue = buildUnnamed5807();
    o.name = 'foo';
    o.stringValue = 'foo';
  }
  buildCounterUsageReportParameters--;
  return o;
}

void checkUsageReportParameters(api.UsageReportParameters o) {
  buildCounterUsageReportParameters++;
  if (buildCounterUsageReportParameters < 3) {
    unittest.expect(o.boolValue!, unittest.isTrue);
    unittest.expect(
      o.datetimeValue!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.intValue!,
      unittest.equals('foo'),
    );
    checkUnnamed5807(o.msgValue!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.stringValue!,
      unittest.equals('foo'),
    );
  }
  buildCounterUsageReportParameters--;
}

core.List<api.UsageReportParameters> buildUnnamed5808() {
  var o = <api.UsageReportParameters>[];
  o.add(buildUsageReportParameters());
  o.add(buildUsageReportParameters());
  return o;
}

void checkUnnamed5808(core.List<api.UsageReportParameters> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUsageReportParameters(o[0] as api.UsageReportParameters);
  checkUsageReportParameters(o[1] as api.UsageReportParameters);
}

core.int buildCounterUsageReport = 0;
api.UsageReport buildUsageReport() {
  var o = api.UsageReport();
  buildCounterUsageReport++;
  if (buildCounterUsageReport < 3) {
    o.date = 'foo';
    o.entity = buildUsageReportEntity();
    o.etag = 'foo';
    o.kind = 'foo';
    o.parameters = buildUnnamed5808();
  }
  buildCounterUsageReport--;
  return o;
}

void checkUsageReport(api.UsageReport o) {
  buildCounterUsageReport++;
  if (buildCounterUsageReport < 3) {
    unittest.expect(
      o.date!,
      unittest.equals('foo'),
    );
    checkUsageReportEntity(o.entity! as api.UsageReportEntity);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed5808(o.parameters!);
  }
  buildCounterUsageReport--;
}

core.List<api.UsageReport> buildUnnamed5809() {
  var o = <api.UsageReport>[];
  o.add(buildUsageReport());
  o.add(buildUsageReport());
  return o;
}

void checkUnnamed5809(core.List<api.UsageReport> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUsageReport(o[0] as api.UsageReport);
  checkUsageReport(o[1] as api.UsageReport);
}

core.int buildCounterUsageReportsWarningsData = 0;
api.UsageReportsWarningsData buildUsageReportsWarningsData() {
  var o = api.UsageReportsWarningsData();
  buildCounterUsageReportsWarningsData++;
  if (buildCounterUsageReportsWarningsData < 3) {
    o.key = 'foo';
    o.value = 'foo';
  }
  buildCounterUsageReportsWarningsData--;
  return o;
}

void checkUsageReportsWarningsData(api.UsageReportsWarningsData o) {
  buildCounterUsageReportsWarningsData++;
  if (buildCounterUsageReportsWarningsData < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterUsageReportsWarningsData--;
}

core.List<api.UsageReportsWarningsData> buildUnnamed5810() {
  var o = <api.UsageReportsWarningsData>[];
  o.add(buildUsageReportsWarningsData());
  o.add(buildUsageReportsWarningsData());
  return o;
}

void checkUnnamed5810(core.List<api.UsageReportsWarningsData> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUsageReportsWarningsData(o[0] as api.UsageReportsWarningsData);
  checkUsageReportsWarningsData(o[1] as api.UsageReportsWarningsData);
}

core.int buildCounterUsageReportsWarnings = 0;
api.UsageReportsWarnings buildUsageReportsWarnings() {
  var o = api.UsageReportsWarnings();
  buildCounterUsageReportsWarnings++;
  if (buildCounterUsageReportsWarnings < 3) {
    o.code = 'foo';
    o.data = buildUnnamed5810();
    o.message = 'foo';
  }
  buildCounterUsageReportsWarnings--;
  return o;
}

void checkUsageReportsWarnings(api.UsageReportsWarnings o) {
  buildCounterUsageReportsWarnings++;
  if (buildCounterUsageReportsWarnings < 3) {
    unittest.expect(
      o.code!,
      unittest.equals('foo'),
    );
    checkUnnamed5810(o.data!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterUsageReportsWarnings--;
}

core.List<api.UsageReportsWarnings> buildUnnamed5811() {
  var o = <api.UsageReportsWarnings>[];
  o.add(buildUsageReportsWarnings());
  o.add(buildUsageReportsWarnings());
  return o;
}

void checkUnnamed5811(core.List<api.UsageReportsWarnings> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUsageReportsWarnings(o[0] as api.UsageReportsWarnings);
  checkUsageReportsWarnings(o[1] as api.UsageReportsWarnings);
}

core.int buildCounterUsageReports = 0;
api.UsageReports buildUsageReports() {
  var o = api.UsageReports();
  buildCounterUsageReports++;
  if (buildCounterUsageReports < 3) {
    o.etag = 'foo';
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.usageReports = buildUnnamed5809();
    o.warnings = buildUnnamed5811();
  }
  buildCounterUsageReports--;
  return o;
}

void checkUsageReports(api.UsageReports o) {
  buildCounterUsageReports++;
  if (buildCounterUsageReports < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed5809(o.usageReports!);
    checkUnnamed5811(o.warnings!);
  }
  buildCounterUsageReports--;
}

void main() {
  unittest.group('obj-schema-Activities', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivities();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Activities.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkActivities(od as api.Activities);
    });
  });

  unittest.group('obj-schema-ActivityActor', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityActor();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityActor.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityActor(od as api.ActivityActor);
    });
  });

  unittest.group('obj-schema-ActivityEventsParametersMessageValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityEventsParametersMessageValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityEventsParametersMessageValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityEventsParametersMessageValue(
          od as api.ActivityEventsParametersMessageValue);
    });
  });

  unittest.group('obj-schema-ActivityEventsParametersMultiMessageValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityEventsParametersMultiMessageValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityEventsParametersMultiMessageValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityEventsParametersMultiMessageValue(
          od as api.ActivityEventsParametersMultiMessageValue);
    });
  });

  unittest.group('obj-schema-ActivityEventsParameters', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityEventsParameters();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityEventsParameters.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityEventsParameters(od as api.ActivityEventsParameters);
    });
  });

  unittest.group('obj-schema-ActivityEvents', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityEvents();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ActivityEvents.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkActivityEvents(od as api.ActivityEvents);
    });
  });

  unittest.group('obj-schema-ActivityId', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivityId();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ActivityId.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkActivityId(od as api.ActivityId);
    });
  });

  unittest.group('obj-schema-Activity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildActivity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Activity.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkActivity(od as api.Activity);
    });
  });

  unittest.group('obj-schema-Channel', () {
    unittest.test('to-json--from-json', () async {
      var o = buildChannel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Channel.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkChannel(od as api.Channel);
    });
  });

  unittest.group('obj-schema-NestedParameter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildNestedParameter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.NestedParameter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkNestedParameter(od as api.NestedParameter);
    });
  });

  unittest.group('obj-schema-UsageReportEntity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUsageReportEntity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UsageReportEntity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUsageReportEntity(od as api.UsageReportEntity);
    });
  });

  unittest.group('obj-schema-UsageReportParameters', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUsageReportParameters();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UsageReportParameters.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUsageReportParameters(od as api.UsageReportParameters);
    });
  });

  unittest.group('obj-schema-UsageReport', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUsageReport();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UsageReport.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUsageReport(od as api.UsageReport);
    });
  });

  unittest.group('obj-schema-UsageReportsWarningsData', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUsageReportsWarningsData();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UsageReportsWarningsData.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUsageReportsWarningsData(od as api.UsageReportsWarningsData);
    });
  });

  unittest.group('obj-schema-UsageReportsWarnings', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUsageReportsWarnings();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UsageReportsWarnings.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUsageReportsWarnings(od as api.UsageReportsWarnings);
    });
  });

  unittest.group('obj-schema-UsageReports', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUsageReports();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UsageReports.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUsageReports(od as api.UsageReports);
    });
  });

  unittest.group('resource-ActivitiesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.ReportsApi(mock).activities;
      var arg_userKey = 'foo';
      var arg_applicationName = 'foo';
      var arg_actorIpAddress = 'foo';
      var arg_customerId = 'foo';
      var arg_endTime = 'foo';
      var arg_eventName = 'foo';
      var arg_filters = 'foo';
      var arg_groupIdFilter = 'foo';
      var arg_maxResults = 42;
      var arg_orgUnitID = 'foo';
      var arg_pageToken = 'foo';
      var arg_startTime = 'foo';
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
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("admin/reports/v1/activity/users/"),
        );
        pathOffset += 32;
        index = path.indexOf('/applications/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/applications/"),
        );
        pathOffset += 14;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_applicationName'),
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
          queryMap["actorIpAddress"]!.first,
          unittest.equals(arg_actorIpAddress),
        );
        unittest.expect(
          queryMap["customerId"]!.first,
          unittest.equals(arg_customerId),
        );
        unittest.expect(
          queryMap["endTime"]!.first,
          unittest.equals(arg_endTime),
        );
        unittest.expect(
          queryMap["eventName"]!.first,
          unittest.equals(arg_eventName),
        );
        unittest.expect(
          queryMap["filters"]!.first,
          unittest.equals(arg_filters),
        );
        unittest.expect(
          queryMap["groupIdFilter"]!.first,
          unittest.equals(arg_groupIdFilter),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["orgUnitID"]!.first,
          unittest.equals(arg_orgUnitID),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["startTime"]!.first,
          unittest.equals(arg_startTime),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildActivities());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userKey, arg_applicationName,
          actorIpAddress: arg_actorIpAddress,
          customerId: arg_customerId,
          endTime: arg_endTime,
          eventName: arg_eventName,
          filters: arg_filters,
          groupIdFilter: arg_groupIdFilter,
          maxResults: arg_maxResults,
          orgUnitID: arg_orgUnitID,
          pageToken: arg_pageToken,
          startTime: arg_startTime,
          $fields: arg_$fields);
      checkActivities(response as api.Activities);
    });

    unittest.test('method--watch', () async {
      var mock = HttpServerMock();
      var res = api.ReportsApi(mock).activities;
      var arg_request = buildChannel();
      var arg_userKey = 'foo';
      var arg_applicationName = 'foo';
      var arg_actorIpAddress = 'foo';
      var arg_customerId = 'foo';
      var arg_endTime = 'foo';
      var arg_eventName = 'foo';
      var arg_filters = 'foo';
      var arg_groupIdFilter = 'foo';
      var arg_maxResults = 42;
      var arg_orgUnitID = 'foo';
      var arg_pageToken = 'foo';
      var arg_startTime = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Channel.fromJson(json as core.Map<core.String, core.dynamic>);
        checkChannel(obj as api.Channel);

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
          path.substring(pathOffset, pathOffset + 32),
          unittest.equals("admin/reports/v1/activity/users/"),
        );
        pathOffset += 32;
        index = path.indexOf('/applications/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("/applications/"),
        );
        pathOffset += 14;
        index = path.indexOf('/watch', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_applicationName'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/watch"),
        );
        pathOffset += 6;

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
          queryMap["actorIpAddress"]!.first,
          unittest.equals(arg_actorIpAddress),
        );
        unittest.expect(
          queryMap["customerId"]!.first,
          unittest.equals(arg_customerId),
        );
        unittest.expect(
          queryMap["endTime"]!.first,
          unittest.equals(arg_endTime),
        );
        unittest.expect(
          queryMap["eventName"]!.first,
          unittest.equals(arg_eventName),
        );
        unittest.expect(
          queryMap["filters"]!.first,
          unittest.equals(arg_filters),
        );
        unittest.expect(
          queryMap["groupIdFilter"]!.first,
          unittest.equals(arg_groupIdFilter),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["orgUnitID"]!.first,
          unittest.equals(arg_orgUnitID),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["startTime"]!.first,
          unittest.equals(arg_startTime),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildChannel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.watch(
          arg_request, arg_userKey, arg_applicationName,
          actorIpAddress: arg_actorIpAddress,
          customerId: arg_customerId,
          endTime: arg_endTime,
          eventName: arg_eventName,
          filters: arg_filters,
          groupIdFilter: arg_groupIdFilter,
          maxResults: arg_maxResults,
          orgUnitID: arg_orgUnitID,
          pageToken: arg_pageToken,
          startTime: arg_startTime,
          $fields: arg_$fields);
      checkChannel(response as api.Channel);
    });
  });

  unittest.group('resource-ChannelsResource', () {
    unittest.test('method--stop', () async {
      var mock = HttpServerMock();
      var res = api.ReportsApi(mock).channels;
      var arg_request = buildChannel();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Channel.fromJson(json as core.Map<core.String, core.dynamic>);
        checkChannel(obj as api.Channel);

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
          path.substring(pathOffset, pathOffset + 30),
          unittest.equals("admin/reports_v1/channels/stop"),
        );
        pathOffset += 30;

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
      await res.stop(arg_request, $fields: arg_$fields);
    });
  });

  unittest.group('resource-CustomerUsageReportsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ReportsApi(mock).customerUsageReports;
      var arg_date = 'foo';
      var arg_customerId = 'foo';
      var arg_pageToken = 'foo';
      var arg_parameters = 'foo';
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
          unittest.equals("admin/reports/v1/usage/dates/"),
        );
        pathOffset += 29;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_date'),
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
          queryMap["customerId"]!.first,
          unittest.equals(arg_customerId),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["parameters"]!.first,
          unittest.equals(arg_parameters),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildUsageReports());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_date,
          customerId: arg_customerId,
          pageToken: arg_pageToken,
          parameters: arg_parameters,
          $fields: arg_$fields);
      checkUsageReports(response as api.UsageReports);
    });
  });

  unittest.group('resource-EntityUsageReportsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ReportsApi(mock).entityUsageReports;
      var arg_entityType = 'foo';
      var arg_entityKey = 'foo';
      var arg_date = 'foo';
      var arg_customerId = 'foo';
      var arg_filters = 'foo';
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_parameters = 'foo';
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
          path.substring(pathOffset, pathOffset + 23),
          unittest.equals("admin/reports/v1/usage/"),
        );
        pathOffset += 23;
        index = path.indexOf('/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_entityType'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;
        index = path.indexOf('/dates/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_entityKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/dates/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_date'),
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
          queryMap["customerId"]!.first,
          unittest.equals(arg_customerId),
        );
        unittest.expect(
          queryMap["filters"]!.first,
          unittest.equals(arg_filters),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["parameters"]!.first,
          unittest.equals(arg_parameters),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildUsageReports());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_entityType, arg_entityKey, arg_date,
          customerId: arg_customerId,
          filters: arg_filters,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          parameters: arg_parameters,
          $fields: arg_$fields);
      checkUsageReports(response as api.UsageReports);
    });
  });

  unittest.group('resource-UserUsageReportResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.ReportsApi(mock).userUsageReport;
      var arg_userKey = 'foo';
      var arg_date = 'foo';
      var arg_customerId = 'foo';
      var arg_filters = 'foo';
      var arg_groupIdFilter = 'foo';
      var arg_maxResults = 42;
      var arg_orgUnitID = 'foo';
      var arg_pageToken = 'foo';
      var arg_parameters = 'foo';
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
          unittest.equals("admin/reports/v1/usage/users/"),
        );
        pathOffset += 29;
        index = path.indexOf('/dates/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_userKey'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/dates/"),
        );
        pathOffset += 7;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_date'),
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
          queryMap["customerId"]!.first,
          unittest.equals(arg_customerId),
        );
        unittest.expect(
          queryMap["filters"]!.first,
          unittest.equals(arg_filters),
        );
        unittest.expect(
          queryMap["groupIdFilter"]!.first,
          unittest.equals(arg_groupIdFilter),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["orgUnitID"]!.first,
          unittest.equals(arg_orgUnitID),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["parameters"]!.first,
          unittest.equals(arg_parameters),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildUsageReports());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_userKey, arg_date,
          customerId: arg_customerId,
          filters: arg_filters,
          groupIdFilter: arg_groupIdFilter,
          maxResults: arg_maxResults,
          orgUnitID: arg_orgUnitID,
          pageToken: arg_pageToken,
          parameters: arg_parameters,
          $fields: arg_$fields);
      checkUsageReports(response as api.UsageReports);
    });
  });
}
