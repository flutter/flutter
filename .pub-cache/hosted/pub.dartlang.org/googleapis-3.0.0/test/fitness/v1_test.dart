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

import 'package:googleapis/fitness/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.Dataset> buildUnnamed1571() {
  var o = <api.Dataset>[];
  o.add(buildDataset());
  o.add(buildDataset());
  return o;
}

void checkUnnamed1571(core.List<api.Dataset> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataset(o[0] as api.Dataset);
  checkDataset(o[1] as api.Dataset);
}

core.int buildCounterAggregateBucket = 0;
api.AggregateBucket buildAggregateBucket() {
  var o = api.AggregateBucket();
  buildCounterAggregateBucket++;
  if (buildCounterAggregateBucket < 3) {
    o.activity = 42;
    o.dataset = buildUnnamed1571();
    o.endTimeMillis = 'foo';
    o.session = buildSession();
    o.startTimeMillis = 'foo';
    o.type = 'foo';
  }
  buildCounterAggregateBucket--;
  return o;
}

void checkAggregateBucket(api.AggregateBucket o) {
  buildCounterAggregateBucket++;
  if (buildCounterAggregateBucket < 3) {
    unittest.expect(
      o.activity!,
      unittest.equals(42),
    );
    checkUnnamed1571(o.dataset!);
    unittest.expect(
      o.endTimeMillis!,
      unittest.equals('foo'),
    );
    checkSession(o.session! as api.Session);
    unittest.expect(
      o.startTimeMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterAggregateBucket--;
}

core.int buildCounterAggregateBy = 0;
api.AggregateBy buildAggregateBy() {
  var o = api.AggregateBy();
  buildCounterAggregateBy++;
  if (buildCounterAggregateBy < 3) {
    o.dataSourceId = 'foo';
    o.dataTypeName = 'foo';
  }
  buildCounterAggregateBy--;
  return o;
}

void checkAggregateBy(api.AggregateBy o) {
  buildCounterAggregateBy++;
  if (buildCounterAggregateBy < 3) {
    unittest.expect(
      o.dataSourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dataTypeName!,
      unittest.equals('foo'),
    );
  }
  buildCounterAggregateBy--;
}

core.List<api.AggregateBy> buildUnnamed1572() {
  var o = <api.AggregateBy>[];
  o.add(buildAggregateBy());
  o.add(buildAggregateBy());
  return o;
}

void checkUnnamed1572(core.List<api.AggregateBy> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAggregateBy(o[0] as api.AggregateBy);
  checkAggregateBy(o[1] as api.AggregateBy);
}

core.List<core.String> buildUnnamed1573() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1573(core.List<core.String> o) {
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

core.int buildCounterAggregateRequest = 0;
api.AggregateRequest buildAggregateRequest() {
  var o = api.AggregateRequest();
  buildCounterAggregateRequest++;
  if (buildCounterAggregateRequest < 3) {
    o.aggregateBy = buildUnnamed1572();
    o.bucketByActivitySegment = buildBucketByActivity();
    o.bucketByActivityType = buildBucketByActivity();
    o.bucketBySession = buildBucketBySession();
    o.bucketByTime = buildBucketByTime();
    o.endTimeMillis = 'foo';
    o.filteredDataQualityStandard = buildUnnamed1573();
    o.startTimeMillis = 'foo';
  }
  buildCounterAggregateRequest--;
  return o;
}

void checkAggregateRequest(api.AggregateRequest o) {
  buildCounterAggregateRequest++;
  if (buildCounterAggregateRequest < 3) {
    checkUnnamed1572(o.aggregateBy!);
    checkBucketByActivity(o.bucketByActivitySegment! as api.BucketByActivity);
    checkBucketByActivity(o.bucketByActivityType! as api.BucketByActivity);
    checkBucketBySession(o.bucketBySession! as api.BucketBySession);
    checkBucketByTime(o.bucketByTime! as api.BucketByTime);
    unittest.expect(
      o.endTimeMillis!,
      unittest.equals('foo'),
    );
    checkUnnamed1573(o.filteredDataQualityStandard!);
    unittest.expect(
      o.startTimeMillis!,
      unittest.equals('foo'),
    );
  }
  buildCounterAggregateRequest--;
}

core.List<api.AggregateBucket> buildUnnamed1574() {
  var o = <api.AggregateBucket>[];
  o.add(buildAggregateBucket());
  o.add(buildAggregateBucket());
  return o;
}

void checkUnnamed1574(core.List<api.AggregateBucket> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAggregateBucket(o[0] as api.AggregateBucket);
  checkAggregateBucket(o[1] as api.AggregateBucket);
}

core.int buildCounterAggregateResponse = 0;
api.AggregateResponse buildAggregateResponse() {
  var o = api.AggregateResponse();
  buildCounterAggregateResponse++;
  if (buildCounterAggregateResponse < 3) {
    o.bucket = buildUnnamed1574();
  }
  buildCounterAggregateResponse--;
  return o;
}

void checkAggregateResponse(api.AggregateResponse o) {
  buildCounterAggregateResponse++;
  if (buildCounterAggregateResponse < 3) {
    checkUnnamed1574(o.bucket!);
  }
  buildCounterAggregateResponse--;
}

core.int buildCounterApplication = 0;
api.Application buildApplication() {
  var o = api.Application();
  buildCounterApplication++;
  if (buildCounterApplication < 3) {
    o.detailsUrl = 'foo';
    o.name = 'foo';
    o.packageName = 'foo';
    o.version = 'foo';
  }
  buildCounterApplication--;
  return o;
}

void checkApplication(api.Application o) {
  buildCounterApplication++;
  if (buildCounterApplication < 3) {
    unittest.expect(
      o.detailsUrl!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.packageName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterApplication--;
}

core.int buildCounterBucketByActivity = 0;
api.BucketByActivity buildBucketByActivity() {
  var o = api.BucketByActivity();
  buildCounterBucketByActivity++;
  if (buildCounterBucketByActivity < 3) {
    o.activityDataSourceId = 'foo';
    o.minDurationMillis = 'foo';
  }
  buildCounterBucketByActivity--;
  return o;
}

void checkBucketByActivity(api.BucketByActivity o) {
  buildCounterBucketByActivity++;
  if (buildCounterBucketByActivity < 3) {
    unittest.expect(
      o.activityDataSourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minDurationMillis!,
      unittest.equals('foo'),
    );
  }
  buildCounterBucketByActivity--;
}

core.int buildCounterBucketBySession = 0;
api.BucketBySession buildBucketBySession() {
  var o = api.BucketBySession();
  buildCounterBucketBySession++;
  if (buildCounterBucketBySession < 3) {
    o.minDurationMillis = 'foo';
  }
  buildCounterBucketBySession--;
  return o;
}

void checkBucketBySession(api.BucketBySession o) {
  buildCounterBucketBySession++;
  if (buildCounterBucketBySession < 3) {
    unittest.expect(
      o.minDurationMillis!,
      unittest.equals('foo'),
    );
  }
  buildCounterBucketBySession--;
}

core.int buildCounterBucketByTime = 0;
api.BucketByTime buildBucketByTime() {
  var o = api.BucketByTime();
  buildCounterBucketByTime++;
  if (buildCounterBucketByTime < 3) {
    o.durationMillis = 'foo';
    o.period = buildBucketByTimePeriod();
  }
  buildCounterBucketByTime--;
  return o;
}

void checkBucketByTime(api.BucketByTime o) {
  buildCounterBucketByTime++;
  if (buildCounterBucketByTime < 3) {
    unittest.expect(
      o.durationMillis!,
      unittest.equals('foo'),
    );
    checkBucketByTimePeriod(o.period! as api.BucketByTimePeriod);
  }
  buildCounterBucketByTime--;
}

core.int buildCounterBucketByTimePeriod = 0;
api.BucketByTimePeriod buildBucketByTimePeriod() {
  var o = api.BucketByTimePeriod();
  buildCounterBucketByTimePeriod++;
  if (buildCounterBucketByTimePeriod < 3) {
    o.timeZoneId = 'foo';
    o.type = 'foo';
    o.value = 42;
  }
  buildCounterBucketByTimePeriod--;
  return o;
}

void checkBucketByTimePeriod(api.BucketByTimePeriod o) {
  buildCounterBucketByTimePeriod++;
  if (buildCounterBucketByTimePeriod < 3) {
    unittest.expect(
      o.timeZoneId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals(42),
    );
  }
  buildCounterBucketByTimePeriod--;
}

core.List<api.Value> buildUnnamed1575() {
  var o = <api.Value>[];
  o.add(buildValue());
  o.add(buildValue());
  return o;
}

void checkUnnamed1575(core.List<api.Value> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkValue(o[0] as api.Value);
  checkValue(o[1] as api.Value);
}

core.int buildCounterDataPoint = 0;
api.DataPoint buildDataPoint() {
  var o = api.DataPoint();
  buildCounterDataPoint++;
  if (buildCounterDataPoint < 3) {
    o.computationTimeMillis = 'foo';
    o.dataTypeName = 'foo';
    o.endTimeNanos = 'foo';
    o.modifiedTimeMillis = 'foo';
    o.originDataSourceId = 'foo';
    o.rawTimestampNanos = 'foo';
    o.startTimeNanos = 'foo';
    o.value = buildUnnamed1575();
  }
  buildCounterDataPoint--;
  return o;
}

void checkDataPoint(api.DataPoint o) {
  buildCounterDataPoint++;
  if (buildCounterDataPoint < 3) {
    unittest.expect(
      o.computationTimeMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dataTypeName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTimeNanos!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.modifiedTimeMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.originDataSourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.rawTimestampNanos!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTimeNanos!,
      unittest.equals('foo'),
    );
    checkUnnamed1575(o.value!);
  }
  buildCounterDataPoint--;
}

core.List<core.String> buildUnnamed1576() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1576(core.List<core.String> o) {
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

core.int buildCounterDataSource = 0;
api.DataSource buildDataSource() {
  var o = api.DataSource();
  buildCounterDataSource++;
  if (buildCounterDataSource < 3) {
    o.application = buildApplication();
    o.dataQualityStandard = buildUnnamed1576();
    o.dataStreamId = 'foo';
    o.dataStreamName = 'foo';
    o.dataType = buildDataType();
    o.device = buildDevice();
    o.name = 'foo';
    o.type = 'foo';
  }
  buildCounterDataSource--;
  return o;
}

void checkDataSource(api.DataSource o) {
  buildCounterDataSource++;
  if (buildCounterDataSource < 3) {
    checkApplication(o.application! as api.Application);
    checkUnnamed1576(o.dataQualityStandard!);
    unittest.expect(
      o.dataStreamId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dataStreamName!,
      unittest.equals('foo'),
    );
    checkDataType(o.dataType! as api.DataType);
    checkDevice(o.device! as api.Device);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataSource--;
}

core.List<api.DataTypeField> buildUnnamed1577() {
  var o = <api.DataTypeField>[];
  o.add(buildDataTypeField());
  o.add(buildDataTypeField());
  return o;
}

void checkUnnamed1577(core.List<api.DataTypeField> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataTypeField(o[0] as api.DataTypeField);
  checkDataTypeField(o[1] as api.DataTypeField);
}

core.int buildCounterDataType = 0;
api.DataType buildDataType() {
  var o = api.DataType();
  buildCounterDataType++;
  if (buildCounterDataType < 3) {
    o.field = buildUnnamed1577();
    o.name = 'foo';
  }
  buildCounterDataType--;
  return o;
}

void checkDataType(api.DataType o) {
  buildCounterDataType++;
  if (buildCounterDataType < 3) {
    checkUnnamed1577(o.field!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataType--;
}

core.int buildCounterDataTypeField = 0;
api.DataTypeField buildDataTypeField() {
  var o = api.DataTypeField();
  buildCounterDataTypeField++;
  if (buildCounterDataTypeField < 3) {
    o.format = 'foo';
    o.name = 'foo';
    o.optional = true;
  }
  buildCounterDataTypeField--;
  return o;
}

void checkDataTypeField(api.DataTypeField o) {
  buildCounterDataTypeField++;
  if (buildCounterDataTypeField < 3) {
    unittest.expect(
      o.format!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(o.optional!, unittest.isTrue);
  }
  buildCounterDataTypeField--;
}

core.List<api.DataPoint> buildUnnamed1578() {
  var o = <api.DataPoint>[];
  o.add(buildDataPoint());
  o.add(buildDataPoint());
  return o;
}

void checkUnnamed1578(core.List<api.DataPoint> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataPoint(o[0] as api.DataPoint);
  checkDataPoint(o[1] as api.DataPoint);
}

core.int buildCounterDataset = 0;
api.Dataset buildDataset() {
  var o = api.Dataset();
  buildCounterDataset++;
  if (buildCounterDataset < 3) {
    o.dataSourceId = 'foo';
    o.maxEndTimeNs = 'foo';
    o.minStartTimeNs = 'foo';
    o.nextPageToken = 'foo';
    o.point = buildUnnamed1578();
  }
  buildCounterDataset--;
  return o;
}

void checkDataset(api.Dataset o) {
  buildCounterDataset++;
  if (buildCounterDataset < 3) {
    unittest.expect(
      o.dataSourceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxEndTimeNs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minStartTimeNs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1578(o.point!);
  }
  buildCounterDataset--;
}

core.int buildCounterDevice = 0;
api.Device buildDevice() {
  var o = api.Device();
  buildCounterDevice++;
  if (buildCounterDevice < 3) {
    o.manufacturer = 'foo';
    o.model = 'foo';
    o.type = 'foo';
    o.uid = 'foo';
    o.version = 'foo';
  }
  buildCounterDevice--;
  return o;
}

void checkDevice(api.Device o) {
  buildCounterDevice++;
  if (buildCounterDevice < 3) {
    unittest.expect(
      o.manufacturer!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.model!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uid!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals('foo'),
    );
  }
  buildCounterDevice--;
}

core.List<api.DataPoint> buildUnnamed1579() {
  var o = <api.DataPoint>[];
  o.add(buildDataPoint());
  o.add(buildDataPoint());
  return o;
}

void checkUnnamed1579(core.List<api.DataPoint> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataPoint(o[0] as api.DataPoint);
  checkDataPoint(o[1] as api.DataPoint);
}

core.List<api.DataPoint> buildUnnamed1580() {
  var o = <api.DataPoint>[];
  o.add(buildDataPoint());
  o.add(buildDataPoint());
  return o;
}

void checkUnnamed1580(core.List<api.DataPoint> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataPoint(o[0] as api.DataPoint);
  checkDataPoint(o[1] as api.DataPoint);
}

core.int buildCounterListDataPointChangesResponse = 0;
api.ListDataPointChangesResponse buildListDataPointChangesResponse() {
  var o = api.ListDataPointChangesResponse();
  buildCounterListDataPointChangesResponse++;
  if (buildCounterListDataPointChangesResponse < 3) {
    o.dataSourceId = 'foo';
    o.deletedDataPoint = buildUnnamed1579();
    o.insertedDataPoint = buildUnnamed1580();
    o.nextPageToken = 'foo';
  }
  buildCounterListDataPointChangesResponse--;
  return o;
}

void checkListDataPointChangesResponse(api.ListDataPointChangesResponse o) {
  buildCounterListDataPointChangesResponse++;
  if (buildCounterListDataPointChangesResponse < 3) {
    unittest.expect(
      o.dataSourceId!,
      unittest.equals('foo'),
    );
    checkUnnamed1579(o.deletedDataPoint!);
    checkUnnamed1580(o.insertedDataPoint!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListDataPointChangesResponse--;
}

core.List<api.DataSource> buildUnnamed1581() {
  var o = <api.DataSource>[];
  o.add(buildDataSource());
  o.add(buildDataSource());
  return o;
}

void checkUnnamed1581(core.List<api.DataSource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDataSource(o[0] as api.DataSource);
  checkDataSource(o[1] as api.DataSource);
}

core.int buildCounterListDataSourcesResponse = 0;
api.ListDataSourcesResponse buildListDataSourcesResponse() {
  var o = api.ListDataSourcesResponse();
  buildCounterListDataSourcesResponse++;
  if (buildCounterListDataSourcesResponse < 3) {
    o.dataSource = buildUnnamed1581();
  }
  buildCounterListDataSourcesResponse--;
  return o;
}

void checkListDataSourcesResponse(api.ListDataSourcesResponse o) {
  buildCounterListDataSourcesResponse++;
  if (buildCounterListDataSourcesResponse < 3) {
    checkUnnamed1581(o.dataSource!);
  }
  buildCounterListDataSourcesResponse--;
}

core.List<api.Session> buildUnnamed1582() {
  var o = <api.Session>[];
  o.add(buildSession());
  o.add(buildSession());
  return o;
}

void checkUnnamed1582(core.List<api.Session> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSession(o[0] as api.Session);
  checkSession(o[1] as api.Session);
}

core.List<api.Session> buildUnnamed1583() {
  var o = <api.Session>[];
  o.add(buildSession());
  o.add(buildSession());
  return o;
}

void checkUnnamed1583(core.List<api.Session> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSession(o[0] as api.Session);
  checkSession(o[1] as api.Session);
}

core.int buildCounterListSessionsResponse = 0;
api.ListSessionsResponse buildListSessionsResponse() {
  var o = api.ListSessionsResponse();
  buildCounterListSessionsResponse++;
  if (buildCounterListSessionsResponse < 3) {
    o.deletedSession = buildUnnamed1582();
    o.hasMoreData = true;
    o.nextPageToken = 'foo';
    o.session = buildUnnamed1583();
  }
  buildCounterListSessionsResponse--;
  return o;
}

void checkListSessionsResponse(api.ListSessionsResponse o) {
  buildCounterListSessionsResponse++;
  if (buildCounterListSessionsResponse < 3) {
    checkUnnamed1582(o.deletedSession!);
    unittest.expect(o.hasMoreData!, unittest.isTrue);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1583(o.session!);
  }
  buildCounterListSessionsResponse--;
}

core.int buildCounterMapValue = 0;
api.MapValue buildMapValue() {
  var o = api.MapValue();
  buildCounterMapValue++;
  if (buildCounterMapValue < 3) {
    o.fpVal = 42.0;
  }
  buildCounterMapValue--;
  return o;
}

void checkMapValue(api.MapValue o) {
  buildCounterMapValue++;
  if (buildCounterMapValue < 3) {
    unittest.expect(
      o.fpVal!,
      unittest.equals(42.0),
    );
  }
  buildCounterMapValue--;
}

core.int buildCounterSession = 0;
api.Session buildSession() {
  var o = api.Session();
  buildCounterSession++;
  if (buildCounterSession < 3) {
    o.activeTimeMillis = 'foo';
    o.activityType = 42;
    o.application = buildApplication();
    o.description = 'foo';
    o.endTimeMillis = 'foo';
    o.id = 'foo';
    o.modifiedTimeMillis = 'foo';
    o.name = 'foo';
    o.startTimeMillis = 'foo';
  }
  buildCounterSession--;
  return o;
}

void checkSession(api.Session o) {
  buildCounterSession++;
  if (buildCounterSession < 3) {
    unittest.expect(
      o.activeTimeMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.activityType!,
      unittest.equals(42),
    );
    checkApplication(o.application! as api.Application);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTimeMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.modifiedTimeMillis!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startTimeMillis!,
      unittest.equals('foo'),
    );
  }
  buildCounterSession--;
}

core.List<api.ValueMapValEntry> buildUnnamed1584() {
  var o = <api.ValueMapValEntry>[];
  o.add(buildValueMapValEntry());
  o.add(buildValueMapValEntry());
  return o;
}

void checkUnnamed1584(core.List<api.ValueMapValEntry> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkValueMapValEntry(o[0] as api.ValueMapValEntry);
  checkValueMapValEntry(o[1] as api.ValueMapValEntry);
}

core.int buildCounterValue = 0;
api.Value buildValue() {
  var o = api.Value();
  buildCounterValue++;
  if (buildCounterValue < 3) {
    o.fpVal = 42.0;
    o.intVal = 42;
    o.mapVal = buildUnnamed1584();
    o.stringVal = 'foo';
  }
  buildCounterValue--;
  return o;
}

void checkValue(api.Value o) {
  buildCounterValue++;
  if (buildCounterValue < 3) {
    unittest.expect(
      o.fpVal!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.intVal!,
      unittest.equals(42),
    );
    checkUnnamed1584(o.mapVal!);
    unittest.expect(
      o.stringVal!,
      unittest.equals('foo'),
    );
  }
  buildCounterValue--;
}

core.int buildCounterValueMapValEntry = 0;
api.ValueMapValEntry buildValueMapValEntry() {
  var o = api.ValueMapValEntry();
  buildCounterValueMapValEntry++;
  if (buildCounterValueMapValEntry < 3) {
    o.key = 'foo';
    o.value = buildMapValue();
  }
  buildCounterValueMapValEntry--;
  return o;
}

void checkValueMapValEntry(api.ValueMapValEntry o) {
  buildCounterValueMapValEntry++;
  if (buildCounterValueMapValEntry < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    checkMapValue(o.value! as api.MapValue);
  }
  buildCounterValueMapValEntry--;
}

core.List<core.String> buildUnnamed1585() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1585(core.List<core.String> o) {
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

core.List<core.int> buildUnnamed1586() {
  var o = <core.int>[];
  o.add(42);
  o.add(42);
  return o;
}

void checkUnnamed1586(core.List<core.int> o) {
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

void main() {
  unittest.group('obj-schema-AggregateBucket', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAggregateBucket();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AggregateBucket.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAggregateBucket(od as api.AggregateBucket);
    });
  });

  unittest.group('obj-schema-AggregateBy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAggregateBy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AggregateBy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAggregateBy(od as api.AggregateBy);
    });
  });

  unittest.group('obj-schema-AggregateRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAggregateRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AggregateRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAggregateRequest(od as api.AggregateRequest);
    });
  });

  unittest.group('obj-schema-AggregateResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAggregateResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AggregateResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAggregateResponse(od as api.AggregateResponse);
    });
  });

  unittest.group('obj-schema-Application', () {
    unittest.test('to-json--from-json', () async {
      var o = buildApplication();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Application.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkApplication(od as api.Application);
    });
  });

  unittest.group('obj-schema-BucketByActivity', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBucketByActivity();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BucketByActivity.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBucketByActivity(od as api.BucketByActivity);
    });
  });

  unittest.group('obj-schema-BucketBySession', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBucketBySession();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BucketBySession.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBucketBySession(od as api.BucketBySession);
    });
  });

  unittest.group('obj-schema-BucketByTime', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBucketByTime();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BucketByTime.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBucketByTime(od as api.BucketByTime);
    });
  });

  unittest.group('obj-schema-BucketByTimePeriod', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBucketByTimePeriod();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BucketByTimePeriod.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBucketByTimePeriod(od as api.BucketByTimePeriod);
    });
  });

  unittest.group('obj-schema-DataPoint', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataPoint();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DataPoint.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDataPoint(od as api.DataPoint);
    });
  });

  unittest.group('obj-schema-DataSource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DataSource.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDataSource(od as api.DataSource);
    });
  });

  unittest.group('obj-schema-DataType', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.DataType.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDataType(od as api.DataType);
    });
  });

  unittest.group('obj-schema-DataTypeField', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataTypeField();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataTypeField.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataTypeField(od as api.DataTypeField);
    });
  });

  unittest.group('obj-schema-Dataset', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataset();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Dataset.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDataset(od as api.Dataset);
    });
  });

  unittest.group('obj-schema-Device', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDevice();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Device.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkDevice(od as api.Device);
    });
  });

  unittest.group('obj-schema-ListDataPointChangesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDataPointChangesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDataPointChangesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDataPointChangesResponse(od as api.ListDataPointChangesResponse);
    });
  });

  unittest.group('obj-schema-ListDataSourcesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListDataSourcesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListDataSourcesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListDataSourcesResponse(od as api.ListDataSourcesResponse);
    });
  });

  unittest.group('obj-schema-ListSessionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListSessionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListSessionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListSessionsResponse(od as api.ListSessionsResponse);
    });
  });

  unittest.group('obj-schema-MapValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMapValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.MapValue.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkMapValue(od as api.MapValue);
    });
  });

  unittest.group('obj-schema-Session', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSession();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Session.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSession(od as api.Session);
    });
  });

  unittest.group('obj-schema-Value', () {
    unittest.test('to-json--from-json', () async {
      var o = buildValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Value.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkValue(od as api.Value);
    });
  });

  unittest.group('obj-schema-ValueMapValEntry', () {
    unittest.test('to-json--from-json', () async {
      var o = buildValueMapValEntry();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ValueMapValEntry.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkValueMapValEntry(od as api.ValueMapValEntry);
    });
  });

  unittest.group('resource-UsersDataSourcesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.FitnessApi(mock).users.dataSources;
      var arg_request = buildDataSource();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DataSource.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDataSource(obj as api.DataSource);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;

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
        var resp = convert.json.encode(buildDataSource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.create(arg_request, arg_userId, $fields: arg_$fields);
      checkDataSource(response as api.DataSource);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.FitnessApi(mock).users.dataSources;
      var arg_userId = 'foo';
      var arg_dataSourceId = 'foo';
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
        var resp = convert.json.encode(buildDataSource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.delete(arg_userId, arg_dataSourceId, $fields: arg_$fields);
      checkDataSource(response as api.DataSource);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.FitnessApi(mock).users.dataSources;
      var arg_userId = 'foo';
      var arg_dataSourceId = 'foo';
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
        var resp = convert.json.encode(buildDataSource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_userId, arg_dataSourceId, $fields: arg_$fields);
      checkDataSource(response as api.DataSource);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.FitnessApi(mock).users.dataSources;
      var arg_userId = 'foo';
      var arg_dataTypeName = buildUnnamed1585();
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
          queryMap["dataTypeName"]!,
          unittest.equals(arg_dataTypeName),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListDataSourcesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userId,
          dataTypeName: arg_dataTypeName, $fields: arg_$fields);
      checkListDataSourcesResponse(response as api.ListDataSourcesResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.FitnessApi(mock).users.dataSources;
      var arg_request = buildDataSource();
      var arg_userId = 'foo';
      var arg_dataSourceId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DataSource.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDataSource(obj as api.DataSource);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;

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
        var resp = convert.json.encode(buildDataSource());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_userId, arg_dataSourceId,
          $fields: arg_$fields);
      checkDataSource(response as api.DataSource);
    });
  });

  unittest.group('resource-UsersDataSourcesDataPointChangesResource', () {
    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.FitnessApi(mock).users.dataSources.dataPointChanges;
      var arg_userId = 'foo';
      var arg_dataSourceId = 'foo';
      var arg_limit = 42;
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
          core.int.parse(queryMap["limit"]!.first),
          unittest.equals(arg_limit),
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
        var resp = convert.json.encode(buildListDataPointChangesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userId, arg_dataSourceId,
          limit: arg_limit, pageToken: arg_pageToken, $fields: arg_$fields);
      checkListDataPointChangesResponse(
          response as api.ListDataPointChangesResponse);
    });
  });

  unittest.group('resource-UsersDataSourcesDatasetsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.FitnessApi(mock).users.dataSources.datasets;
      var arg_userId = 'foo';
      var arg_dataSourceId = 'foo';
      var arg_datasetId = 'foo';
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
      await res.delete(arg_userId, arg_dataSourceId, arg_datasetId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.FitnessApi(mock).users.dataSources.datasets;
      var arg_userId = 'foo';
      var arg_dataSourceId = 'foo';
      var arg_datasetId = 'foo';
      var arg_limit = 42;
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
          core.int.parse(queryMap["limit"]!.first),
          unittest.equals(arg_limit),
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
        var resp = convert.json.encode(buildDataset());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_userId, arg_dataSourceId, arg_datasetId,
          limit: arg_limit, pageToken: arg_pageToken, $fields: arg_$fields);
      checkDataset(response as api.Dataset);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.FitnessApi(mock).users.dataSources.datasets;
      var arg_request = buildDataset();
      var arg_userId = 'foo';
      var arg_dataSourceId = 'foo';
      var arg_datasetId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Dataset.fromJson(json as core.Map<core.String, core.dynamic>);
        checkDataset(obj as api.Dataset);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;

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
        var resp = convert.json.encode(buildDataset());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_userId, arg_dataSourceId, arg_datasetId,
          $fields: arg_$fields);
      checkDataset(response as api.Dataset);
    });
  });

  unittest.group('resource-UsersDatasetResource', () {
    unittest.test('method--aggregate', () async {
      var mock = HttpServerMock();
      var res = api.FitnessApi(mock).users.dataset;
      var arg_request = buildAggregateRequest();
      var arg_userId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.AggregateRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkAggregateRequest(obj as api.AggregateRequest);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;

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
        var resp = convert.json.encode(buildAggregateResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.aggregate(arg_request, arg_userId, $fields: arg_$fields);
      checkAggregateResponse(response as api.AggregateResponse);
    });
  });

  unittest.group('resource-UsersSessionsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.FitnessApi(mock).users.sessions;
      var arg_userId = 'foo';
      var arg_sessionId = 'foo';
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
      await res.delete(arg_userId, arg_sessionId, $fields: arg_$fields);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.FitnessApi(mock).users.sessions;
      var arg_userId = 'foo';
      var arg_activityType = buildUnnamed1586();
      var arg_endTime = 'foo';
      var arg_includeDeleted = true;
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
          queryMap["activityType"]!.map(core.int.parse).toList(),
          unittest.equals(arg_activityType),
        );
        unittest.expect(
          queryMap["endTime"]!.first,
          unittest.equals(arg_endTime),
        );
        unittest.expect(
          queryMap["includeDeleted"]!.first,
          unittest.equals("$arg_includeDeleted"),
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
        var resp = convert.json.encode(buildListSessionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_userId,
          activityType: arg_activityType,
          endTime: arg_endTime,
          includeDeleted: arg_includeDeleted,
          pageToken: arg_pageToken,
          startTime: arg_startTime,
          $fields: arg_$fields);
      checkListSessionsResponse(response as api.ListSessionsResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.FitnessApi(mock).users.sessions;
      var arg_request = buildSession();
      var arg_userId = 'foo';
      var arg_sessionId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Session.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSession(obj as api.Session);

        var path = (req.url).path;
        var pathOffset = 0;
        core.int index;
        core.String subPart;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 1),
          unittest.equals("/"),
        );
        pathOffset += 1;

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
        var resp = convert.json.encode(buildSession());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(arg_request, arg_userId, arg_sessionId,
          $fields: arg_$fields);
      checkSession(response as api.Session);
    });
  });
}
