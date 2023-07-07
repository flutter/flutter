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

import 'package:googleapis/bigquery/v2.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAggregateClassificationMetrics = 0;
api.AggregateClassificationMetrics buildAggregateClassificationMetrics() {
  var o = api.AggregateClassificationMetrics();
  buildCounterAggregateClassificationMetrics++;
  if (buildCounterAggregateClassificationMetrics < 3) {
    o.accuracy = 42.0;
    o.f1Score = 42.0;
    o.logLoss = 42.0;
    o.precision = 42.0;
    o.recall = 42.0;
    o.rocAuc = 42.0;
    o.threshold = 42.0;
  }
  buildCounterAggregateClassificationMetrics--;
  return o;
}

void checkAggregateClassificationMetrics(api.AggregateClassificationMetrics o) {
  buildCounterAggregateClassificationMetrics++;
  if (buildCounterAggregateClassificationMetrics < 3) {
    unittest.expect(
      o.accuracy!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.f1Score!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.logLoss!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.precision!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.recall!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.rocAuc!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.threshold!,
      unittest.equals(42.0),
    );
  }
  buildCounterAggregateClassificationMetrics--;
}

core.int buildCounterArgument = 0;
api.Argument buildArgument() {
  var o = api.Argument();
  buildCounterArgument++;
  if (buildCounterArgument < 3) {
    o.argumentKind = 'foo';
    o.dataType = buildStandardSqlDataType();
    o.mode = 'foo';
    o.name = 'foo';
  }
  buildCounterArgument--;
  return o;
}

void checkArgument(api.Argument o) {
  buildCounterArgument++;
  if (buildCounterArgument < 3) {
    unittest.expect(
      o.argumentKind!,
      unittest.equals('foo'),
    );
    checkStandardSqlDataType(o.dataType! as api.StandardSqlDataType);
    unittest.expect(
      o.mode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterArgument--;
}

core.List<core.double> buildUnnamed1459() {
  var o = <core.double>[];
  o.add(42.0);
  o.add(42.0);
  return o;
}

void checkUnnamed1459(core.List<core.double> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42.0),
  );
  unittest.expect(
    o[1],
    unittest.equals(42.0),
  );
}

core.List<core.double> buildUnnamed1460() {
  var o = <core.double>[];
  o.add(42.0);
  o.add(42.0);
  return o;
}

void checkUnnamed1460(core.List<core.double> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o[0],
    unittest.equals(42.0),
  );
  unittest.expect(
    o[1],
    unittest.equals(42.0),
  );
}

core.int buildCounterArimaCoefficients = 0;
api.ArimaCoefficients buildArimaCoefficients() {
  var o = api.ArimaCoefficients();
  buildCounterArimaCoefficients++;
  if (buildCounterArimaCoefficients < 3) {
    o.autoRegressiveCoefficients = buildUnnamed1459();
    o.interceptCoefficient = 42.0;
    o.movingAverageCoefficients = buildUnnamed1460();
  }
  buildCounterArimaCoefficients--;
  return o;
}

void checkArimaCoefficients(api.ArimaCoefficients o) {
  buildCounterArimaCoefficients++;
  if (buildCounterArimaCoefficients < 3) {
    checkUnnamed1459(o.autoRegressiveCoefficients!);
    unittest.expect(
      o.interceptCoefficient!,
      unittest.equals(42.0),
    );
    checkUnnamed1460(o.movingAverageCoefficients!);
  }
  buildCounterArimaCoefficients--;
}

core.int buildCounterArimaFittingMetrics = 0;
api.ArimaFittingMetrics buildArimaFittingMetrics() {
  var o = api.ArimaFittingMetrics();
  buildCounterArimaFittingMetrics++;
  if (buildCounterArimaFittingMetrics < 3) {
    o.aic = 42.0;
    o.logLikelihood = 42.0;
    o.variance = 42.0;
  }
  buildCounterArimaFittingMetrics--;
  return o;
}

void checkArimaFittingMetrics(api.ArimaFittingMetrics o) {
  buildCounterArimaFittingMetrics++;
  if (buildCounterArimaFittingMetrics < 3) {
    unittest.expect(
      o.aic!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.logLikelihood!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.variance!,
      unittest.equals(42.0),
    );
  }
  buildCounterArimaFittingMetrics--;
}

core.List<api.ArimaFittingMetrics> buildUnnamed1461() {
  var o = <api.ArimaFittingMetrics>[];
  o.add(buildArimaFittingMetrics());
  o.add(buildArimaFittingMetrics());
  return o;
}

void checkUnnamed1461(core.List<api.ArimaFittingMetrics> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkArimaFittingMetrics(o[0] as api.ArimaFittingMetrics);
  checkArimaFittingMetrics(o[1] as api.ArimaFittingMetrics);
}

core.List<api.ArimaSingleModelForecastingMetrics> buildUnnamed1462() {
  var o = <api.ArimaSingleModelForecastingMetrics>[];
  o.add(buildArimaSingleModelForecastingMetrics());
  o.add(buildArimaSingleModelForecastingMetrics());
  return o;
}

void checkUnnamed1462(core.List<api.ArimaSingleModelForecastingMetrics> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkArimaSingleModelForecastingMetrics(
      o[0] as api.ArimaSingleModelForecastingMetrics);
  checkArimaSingleModelForecastingMetrics(
      o[1] as api.ArimaSingleModelForecastingMetrics);
}

core.List<core.bool> buildUnnamed1463() {
  var o = <core.bool>[];
  o.add(true);
  o.add(true);
  return o;
}

void checkUnnamed1463(core.List<core.bool> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(o[0], unittest.isTrue);
  unittest.expect(o[1], unittest.isTrue);
}

core.List<api.ArimaOrder> buildUnnamed1464() {
  var o = <api.ArimaOrder>[];
  o.add(buildArimaOrder());
  o.add(buildArimaOrder());
  return o;
}

void checkUnnamed1464(core.List<api.ArimaOrder> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkArimaOrder(o[0] as api.ArimaOrder);
  checkArimaOrder(o[1] as api.ArimaOrder);
}

core.List<core.String> buildUnnamed1465() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1465(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1466() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1466(core.List<core.String> o) {
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

core.int buildCounterArimaForecastingMetrics = 0;
api.ArimaForecastingMetrics buildArimaForecastingMetrics() {
  var o = api.ArimaForecastingMetrics();
  buildCounterArimaForecastingMetrics++;
  if (buildCounterArimaForecastingMetrics < 3) {
    o.arimaFittingMetrics = buildUnnamed1461();
    o.arimaSingleModelForecastingMetrics = buildUnnamed1462();
    o.hasDrift = buildUnnamed1463();
    o.nonSeasonalOrder = buildUnnamed1464();
    o.seasonalPeriods = buildUnnamed1465();
    o.timeSeriesId = buildUnnamed1466();
  }
  buildCounterArimaForecastingMetrics--;
  return o;
}

void checkArimaForecastingMetrics(api.ArimaForecastingMetrics o) {
  buildCounterArimaForecastingMetrics++;
  if (buildCounterArimaForecastingMetrics < 3) {
    checkUnnamed1461(o.arimaFittingMetrics!);
    checkUnnamed1462(o.arimaSingleModelForecastingMetrics!);
    checkUnnamed1463(o.hasDrift!);
    checkUnnamed1464(o.nonSeasonalOrder!);
    checkUnnamed1465(o.seasonalPeriods!);
    checkUnnamed1466(o.timeSeriesId!);
  }
  buildCounterArimaForecastingMetrics--;
}

core.List<core.String> buildUnnamed1467() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1467(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1468() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1468(core.List<core.String> o) {
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

core.int buildCounterArimaModelInfo = 0;
api.ArimaModelInfo buildArimaModelInfo() {
  var o = api.ArimaModelInfo();
  buildCounterArimaModelInfo++;
  if (buildCounterArimaModelInfo < 3) {
    o.arimaCoefficients = buildArimaCoefficients();
    o.arimaFittingMetrics = buildArimaFittingMetrics();
    o.hasDrift = true;
    o.hasHolidayEffect = true;
    o.hasSpikesAndDips = true;
    o.hasStepChanges = true;
    o.nonSeasonalOrder = buildArimaOrder();
    o.seasonalPeriods = buildUnnamed1467();
    o.timeSeriesId = 'foo';
    o.timeSeriesIds = buildUnnamed1468();
  }
  buildCounterArimaModelInfo--;
  return o;
}

void checkArimaModelInfo(api.ArimaModelInfo o) {
  buildCounterArimaModelInfo++;
  if (buildCounterArimaModelInfo < 3) {
    checkArimaCoefficients(o.arimaCoefficients! as api.ArimaCoefficients);
    checkArimaFittingMetrics(o.arimaFittingMetrics! as api.ArimaFittingMetrics);
    unittest.expect(o.hasDrift!, unittest.isTrue);
    unittest.expect(o.hasHolidayEffect!, unittest.isTrue);
    unittest.expect(o.hasSpikesAndDips!, unittest.isTrue);
    unittest.expect(o.hasStepChanges!, unittest.isTrue);
    checkArimaOrder(o.nonSeasonalOrder! as api.ArimaOrder);
    checkUnnamed1467(o.seasonalPeriods!);
    unittest.expect(
      o.timeSeriesId!,
      unittest.equals('foo'),
    );
    checkUnnamed1468(o.timeSeriesIds!);
  }
  buildCounterArimaModelInfo--;
}

core.int buildCounterArimaOrder = 0;
api.ArimaOrder buildArimaOrder() {
  var o = api.ArimaOrder();
  buildCounterArimaOrder++;
  if (buildCounterArimaOrder < 3) {
    o.d = 'foo';
    o.p = 'foo';
    o.q = 'foo';
  }
  buildCounterArimaOrder--;
  return o;
}

void checkArimaOrder(api.ArimaOrder o) {
  buildCounterArimaOrder++;
  if (buildCounterArimaOrder < 3) {
    unittest.expect(
      o.d!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.p!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.q!,
      unittest.equals('foo'),
    );
  }
  buildCounterArimaOrder--;
}

core.List<api.ArimaModelInfo> buildUnnamed1469() {
  var o = <api.ArimaModelInfo>[];
  o.add(buildArimaModelInfo());
  o.add(buildArimaModelInfo());
  return o;
}

void checkUnnamed1469(core.List<api.ArimaModelInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkArimaModelInfo(o[0] as api.ArimaModelInfo);
  checkArimaModelInfo(o[1] as api.ArimaModelInfo);
}

core.List<core.String> buildUnnamed1470() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1470(core.List<core.String> o) {
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

core.int buildCounterArimaResult = 0;
api.ArimaResult buildArimaResult() {
  var o = api.ArimaResult();
  buildCounterArimaResult++;
  if (buildCounterArimaResult < 3) {
    o.arimaModelInfo = buildUnnamed1469();
    o.seasonalPeriods = buildUnnamed1470();
  }
  buildCounterArimaResult--;
  return o;
}

void checkArimaResult(api.ArimaResult o) {
  buildCounterArimaResult++;
  if (buildCounterArimaResult < 3) {
    checkUnnamed1469(o.arimaModelInfo!);
    checkUnnamed1470(o.seasonalPeriods!);
  }
  buildCounterArimaResult--;
}

core.List<core.String> buildUnnamed1471() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1471(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1472() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1472(core.List<core.String> o) {
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

core.int buildCounterArimaSingleModelForecastingMetrics = 0;
api.ArimaSingleModelForecastingMetrics
    buildArimaSingleModelForecastingMetrics() {
  var o = api.ArimaSingleModelForecastingMetrics();
  buildCounterArimaSingleModelForecastingMetrics++;
  if (buildCounterArimaSingleModelForecastingMetrics < 3) {
    o.arimaFittingMetrics = buildArimaFittingMetrics();
    o.hasDrift = true;
    o.hasHolidayEffect = true;
    o.hasSpikesAndDips = true;
    o.hasStepChanges = true;
    o.nonSeasonalOrder = buildArimaOrder();
    o.seasonalPeriods = buildUnnamed1471();
    o.timeSeriesId = 'foo';
    o.timeSeriesIds = buildUnnamed1472();
  }
  buildCounterArimaSingleModelForecastingMetrics--;
  return o;
}

void checkArimaSingleModelForecastingMetrics(
    api.ArimaSingleModelForecastingMetrics o) {
  buildCounterArimaSingleModelForecastingMetrics++;
  if (buildCounterArimaSingleModelForecastingMetrics < 3) {
    checkArimaFittingMetrics(o.arimaFittingMetrics! as api.ArimaFittingMetrics);
    unittest.expect(o.hasDrift!, unittest.isTrue);
    unittest.expect(o.hasHolidayEffect!, unittest.isTrue);
    unittest.expect(o.hasSpikesAndDips!, unittest.isTrue);
    unittest.expect(o.hasStepChanges!, unittest.isTrue);
    checkArimaOrder(o.nonSeasonalOrder! as api.ArimaOrder);
    checkUnnamed1471(o.seasonalPeriods!);
    unittest.expect(
      o.timeSeriesId!,
      unittest.equals('foo'),
    );
    checkUnnamed1472(o.timeSeriesIds!);
  }
  buildCounterArimaSingleModelForecastingMetrics--;
}

core.List<api.AuditLogConfig> buildUnnamed1473() {
  var o = <api.AuditLogConfig>[];
  o.add(buildAuditLogConfig());
  o.add(buildAuditLogConfig());
  return o;
}

void checkUnnamed1473(core.List<api.AuditLogConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditLogConfig(o[0] as api.AuditLogConfig);
  checkAuditLogConfig(o[1] as api.AuditLogConfig);
}

core.int buildCounterAuditConfig = 0;
api.AuditConfig buildAuditConfig() {
  var o = api.AuditConfig();
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    o.auditLogConfigs = buildUnnamed1473();
    o.service = 'foo';
  }
  buildCounterAuditConfig--;
  return o;
}

void checkAuditConfig(api.AuditConfig o) {
  buildCounterAuditConfig++;
  if (buildCounterAuditConfig < 3) {
    checkUnnamed1473(o.auditLogConfigs!);
    unittest.expect(
      o.service!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditConfig--;
}

core.List<core.String> buildUnnamed1474() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1474(core.List<core.String> o) {
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

core.int buildCounterAuditLogConfig = 0;
api.AuditLogConfig buildAuditLogConfig() {
  var o = api.AuditLogConfig();
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    o.exemptedMembers = buildUnnamed1474();
    o.logType = 'foo';
  }
  buildCounterAuditLogConfig--;
  return o;
}

void checkAuditLogConfig(api.AuditLogConfig o) {
  buildCounterAuditLogConfig++;
  if (buildCounterAuditLogConfig < 3) {
    checkUnnamed1474(o.exemptedMembers!);
    unittest.expect(
      o.logType!,
      unittest.equals('foo'),
    );
  }
  buildCounterAuditLogConfig--;
}

core.int buildCounterBigQueryModelTraining = 0;
api.BigQueryModelTraining buildBigQueryModelTraining() {
  var o = api.BigQueryModelTraining();
  buildCounterBigQueryModelTraining++;
  if (buildCounterBigQueryModelTraining < 3) {
    o.currentIteration = 42;
    o.expectedTotalIterations = 'foo';
  }
  buildCounterBigQueryModelTraining--;
  return o;
}

void checkBigQueryModelTraining(api.BigQueryModelTraining o) {
  buildCounterBigQueryModelTraining++;
  if (buildCounterBigQueryModelTraining < 3) {
    unittest.expect(
      o.currentIteration!,
      unittest.equals(42),
    );
    unittest.expect(
      o.expectedTotalIterations!,
      unittest.equals('foo'),
    );
  }
  buildCounterBigQueryModelTraining--;
}

core.int buildCounterBigtableColumn = 0;
api.BigtableColumn buildBigtableColumn() {
  var o = api.BigtableColumn();
  buildCounterBigtableColumn++;
  if (buildCounterBigtableColumn < 3) {
    o.encoding = 'foo';
    o.fieldName = 'foo';
    o.onlyReadLatest = true;
    o.qualifierEncoded = 'foo';
    o.qualifierString = 'foo';
    o.type = 'foo';
  }
  buildCounterBigtableColumn--;
  return o;
}

void checkBigtableColumn(api.BigtableColumn o) {
  buildCounterBigtableColumn++;
  if (buildCounterBigtableColumn < 3) {
    unittest.expect(
      o.encoding!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldName!,
      unittest.equals('foo'),
    );
    unittest.expect(o.onlyReadLatest!, unittest.isTrue);
    unittest.expect(
      o.qualifierEncoded!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.qualifierString!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterBigtableColumn--;
}

core.List<api.BigtableColumn> buildUnnamed1475() {
  var o = <api.BigtableColumn>[];
  o.add(buildBigtableColumn());
  o.add(buildBigtableColumn());
  return o;
}

void checkUnnamed1475(core.List<api.BigtableColumn> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBigtableColumn(o[0] as api.BigtableColumn);
  checkBigtableColumn(o[1] as api.BigtableColumn);
}

core.int buildCounterBigtableColumnFamily = 0;
api.BigtableColumnFamily buildBigtableColumnFamily() {
  var o = api.BigtableColumnFamily();
  buildCounterBigtableColumnFamily++;
  if (buildCounterBigtableColumnFamily < 3) {
    o.columns = buildUnnamed1475();
    o.encoding = 'foo';
    o.familyId = 'foo';
    o.onlyReadLatest = true;
    o.type = 'foo';
  }
  buildCounterBigtableColumnFamily--;
  return o;
}

void checkBigtableColumnFamily(api.BigtableColumnFamily o) {
  buildCounterBigtableColumnFamily++;
  if (buildCounterBigtableColumnFamily < 3) {
    checkUnnamed1475(o.columns!);
    unittest.expect(
      o.encoding!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.familyId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.onlyReadLatest!, unittest.isTrue);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterBigtableColumnFamily--;
}

core.List<api.BigtableColumnFamily> buildUnnamed1476() {
  var o = <api.BigtableColumnFamily>[];
  o.add(buildBigtableColumnFamily());
  o.add(buildBigtableColumnFamily());
  return o;
}

void checkUnnamed1476(core.List<api.BigtableColumnFamily> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBigtableColumnFamily(o[0] as api.BigtableColumnFamily);
  checkBigtableColumnFamily(o[1] as api.BigtableColumnFamily);
}

core.int buildCounterBigtableOptions = 0;
api.BigtableOptions buildBigtableOptions() {
  var o = api.BigtableOptions();
  buildCounterBigtableOptions++;
  if (buildCounterBigtableOptions < 3) {
    o.columnFamilies = buildUnnamed1476();
    o.ignoreUnspecifiedColumnFamilies = true;
    o.readRowkeyAsString = true;
  }
  buildCounterBigtableOptions--;
  return o;
}

void checkBigtableOptions(api.BigtableOptions o) {
  buildCounterBigtableOptions++;
  if (buildCounterBigtableOptions < 3) {
    checkUnnamed1476(o.columnFamilies!);
    unittest.expect(o.ignoreUnspecifiedColumnFamilies!, unittest.isTrue);
    unittest.expect(o.readRowkeyAsString!, unittest.isTrue);
  }
  buildCounterBigtableOptions--;
}

core.List<api.BinaryConfusionMatrix> buildUnnamed1477() {
  var o = <api.BinaryConfusionMatrix>[];
  o.add(buildBinaryConfusionMatrix());
  o.add(buildBinaryConfusionMatrix());
  return o;
}

void checkUnnamed1477(core.List<api.BinaryConfusionMatrix> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinaryConfusionMatrix(o[0] as api.BinaryConfusionMatrix);
  checkBinaryConfusionMatrix(o[1] as api.BinaryConfusionMatrix);
}

core.int buildCounterBinaryClassificationMetrics = 0;
api.BinaryClassificationMetrics buildBinaryClassificationMetrics() {
  var o = api.BinaryClassificationMetrics();
  buildCounterBinaryClassificationMetrics++;
  if (buildCounterBinaryClassificationMetrics < 3) {
    o.aggregateClassificationMetrics = buildAggregateClassificationMetrics();
    o.binaryConfusionMatrixList = buildUnnamed1477();
    o.negativeLabel = 'foo';
    o.positiveLabel = 'foo';
  }
  buildCounterBinaryClassificationMetrics--;
  return o;
}

void checkBinaryClassificationMetrics(api.BinaryClassificationMetrics o) {
  buildCounterBinaryClassificationMetrics++;
  if (buildCounterBinaryClassificationMetrics < 3) {
    checkAggregateClassificationMetrics(o.aggregateClassificationMetrics!
        as api.AggregateClassificationMetrics);
    checkUnnamed1477(o.binaryConfusionMatrixList!);
    unittest.expect(
      o.negativeLabel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.positiveLabel!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinaryClassificationMetrics--;
}

core.int buildCounterBinaryConfusionMatrix = 0;
api.BinaryConfusionMatrix buildBinaryConfusionMatrix() {
  var o = api.BinaryConfusionMatrix();
  buildCounterBinaryConfusionMatrix++;
  if (buildCounterBinaryConfusionMatrix < 3) {
    o.accuracy = 42.0;
    o.f1Score = 42.0;
    o.falseNegatives = 'foo';
    o.falsePositives = 'foo';
    o.positiveClassThreshold = 42.0;
    o.precision = 42.0;
    o.recall = 42.0;
    o.trueNegatives = 'foo';
    o.truePositives = 'foo';
  }
  buildCounterBinaryConfusionMatrix--;
  return o;
}

void checkBinaryConfusionMatrix(api.BinaryConfusionMatrix o) {
  buildCounterBinaryConfusionMatrix++;
  if (buildCounterBinaryConfusionMatrix < 3) {
    unittest.expect(
      o.accuracy!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.f1Score!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.falseNegatives!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.falsePositives!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.positiveClassThreshold!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.precision!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.recall!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.trueNegatives!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.truePositives!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinaryConfusionMatrix--;
}

core.List<core.String> buildUnnamed1478() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1478(core.List<core.String> o) {
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

core.int buildCounterBinding = 0;
api.Binding buildBinding() {
  var o = api.Binding();
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    o.condition = buildExpr();
    o.members = buildUnnamed1478();
    o.role = 'foo';
  }
  buildCounterBinding--;
  return o;
}

void checkBinding(api.Binding o) {
  buildCounterBinding++;
  if (buildCounterBinding < 3) {
    checkExpr(o.condition! as api.Expr);
    checkUnnamed1478(o.members!);
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
  }
  buildCounterBinding--;
}

core.int buildCounterBqmlIterationResult = 0;
api.BqmlIterationResult buildBqmlIterationResult() {
  var o = api.BqmlIterationResult();
  buildCounterBqmlIterationResult++;
  if (buildCounterBqmlIterationResult < 3) {
    o.durationMs = 'foo';
    o.evalLoss = 42.0;
    o.index = 42;
    o.learnRate = 42.0;
    o.trainingLoss = 42.0;
  }
  buildCounterBqmlIterationResult--;
  return o;
}

void checkBqmlIterationResult(api.BqmlIterationResult o) {
  buildCounterBqmlIterationResult++;
  if (buildCounterBqmlIterationResult < 3) {
    unittest.expect(
      o.durationMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.evalLoss!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
    unittest.expect(
      o.learnRate!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.trainingLoss!,
      unittest.equals(42.0),
    );
  }
  buildCounterBqmlIterationResult--;
}

core.List<api.BqmlIterationResult> buildUnnamed1479() {
  var o = <api.BqmlIterationResult>[];
  o.add(buildBqmlIterationResult());
  o.add(buildBqmlIterationResult());
  return o;
}

void checkUnnamed1479(core.List<api.BqmlIterationResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBqmlIterationResult(o[0] as api.BqmlIterationResult);
  checkBqmlIterationResult(o[1] as api.BqmlIterationResult);
}

core.int buildCounterBqmlTrainingRunTrainingOptions = 0;
api.BqmlTrainingRunTrainingOptions buildBqmlTrainingRunTrainingOptions() {
  var o = api.BqmlTrainingRunTrainingOptions();
  buildCounterBqmlTrainingRunTrainingOptions++;
  if (buildCounterBqmlTrainingRunTrainingOptions < 3) {
    o.earlyStop = true;
    o.l1Reg = 42.0;
    o.l2Reg = 42.0;
    o.learnRate = 42.0;
    o.learnRateStrategy = 'foo';
    o.lineSearchInitLearnRate = 42.0;
    o.maxIteration = 'foo';
    o.minRelProgress = 42.0;
    o.warmStart = true;
  }
  buildCounterBqmlTrainingRunTrainingOptions--;
  return o;
}

void checkBqmlTrainingRunTrainingOptions(api.BqmlTrainingRunTrainingOptions o) {
  buildCounterBqmlTrainingRunTrainingOptions++;
  if (buildCounterBqmlTrainingRunTrainingOptions < 3) {
    unittest.expect(o.earlyStop!, unittest.isTrue);
    unittest.expect(
      o.l1Reg!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.l2Reg!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.learnRate!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.learnRateStrategy!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lineSearchInitLearnRate!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.maxIteration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minRelProgress!,
      unittest.equals(42.0),
    );
    unittest.expect(o.warmStart!, unittest.isTrue);
  }
  buildCounterBqmlTrainingRunTrainingOptions--;
}

core.int buildCounterBqmlTrainingRun = 0;
api.BqmlTrainingRun buildBqmlTrainingRun() {
  var o = api.BqmlTrainingRun();
  buildCounterBqmlTrainingRun++;
  if (buildCounterBqmlTrainingRun < 3) {
    o.iterationResults = buildUnnamed1479();
    o.startTime = core.DateTime.parse("2002-02-27T14:01:02");
    o.state = 'foo';
    o.trainingOptions = buildBqmlTrainingRunTrainingOptions();
  }
  buildCounterBqmlTrainingRun--;
  return o;
}

void checkBqmlTrainingRun(api.BqmlTrainingRun o) {
  buildCounterBqmlTrainingRun++;
  if (buildCounterBqmlTrainingRun < 3) {
    checkUnnamed1479(o.iterationResults!);
    unittest.expect(
      o.startTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    checkBqmlTrainingRunTrainingOptions(
        o.trainingOptions! as api.BqmlTrainingRunTrainingOptions);
  }
  buildCounterBqmlTrainingRun--;
}

core.List<api.CategoryCount> buildUnnamed1480() {
  var o = <api.CategoryCount>[];
  o.add(buildCategoryCount());
  o.add(buildCategoryCount());
  return o;
}

void checkUnnamed1480(core.List<api.CategoryCount> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCategoryCount(o[0] as api.CategoryCount);
  checkCategoryCount(o[1] as api.CategoryCount);
}

core.int buildCounterCategoricalValue = 0;
api.CategoricalValue buildCategoricalValue() {
  var o = api.CategoricalValue();
  buildCounterCategoricalValue++;
  if (buildCounterCategoricalValue < 3) {
    o.categoryCounts = buildUnnamed1480();
  }
  buildCounterCategoricalValue--;
  return o;
}

void checkCategoricalValue(api.CategoricalValue o) {
  buildCounterCategoricalValue++;
  if (buildCounterCategoricalValue < 3) {
    checkUnnamed1480(o.categoryCounts!);
  }
  buildCounterCategoricalValue--;
}

core.int buildCounterCategoryCount = 0;
api.CategoryCount buildCategoryCount() {
  var o = api.CategoryCount();
  buildCounterCategoryCount++;
  if (buildCounterCategoryCount < 3) {
    o.category = 'foo';
    o.count = 'foo';
  }
  buildCounterCategoryCount--;
  return o;
}

void checkCategoryCount(api.CategoryCount o) {
  buildCounterCategoryCount++;
  if (buildCounterCategoryCount < 3) {
    unittest.expect(
      o.category!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.count!,
      unittest.equals('foo'),
    );
  }
  buildCounterCategoryCount--;
}

core.List<api.FeatureValue> buildUnnamed1481() {
  var o = <api.FeatureValue>[];
  o.add(buildFeatureValue());
  o.add(buildFeatureValue());
  return o;
}

void checkUnnamed1481(core.List<api.FeatureValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkFeatureValue(o[0] as api.FeatureValue);
  checkFeatureValue(o[1] as api.FeatureValue);
}

core.int buildCounterCluster = 0;
api.Cluster buildCluster() {
  var o = api.Cluster();
  buildCounterCluster++;
  if (buildCounterCluster < 3) {
    o.centroidId = 'foo';
    o.count = 'foo';
    o.featureValues = buildUnnamed1481();
  }
  buildCounterCluster--;
  return o;
}

void checkCluster(api.Cluster o) {
  buildCounterCluster++;
  if (buildCounterCluster < 3) {
    unittest.expect(
      o.centroidId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.count!,
      unittest.equals('foo'),
    );
    checkUnnamed1481(o.featureValues!);
  }
  buildCounterCluster--;
}

core.int buildCounterClusterInfo = 0;
api.ClusterInfo buildClusterInfo() {
  var o = api.ClusterInfo();
  buildCounterClusterInfo++;
  if (buildCounterClusterInfo < 3) {
    o.centroidId = 'foo';
    o.clusterRadius = 42.0;
    o.clusterSize = 'foo';
  }
  buildCounterClusterInfo--;
  return o;
}

void checkClusterInfo(api.ClusterInfo o) {
  buildCounterClusterInfo++;
  if (buildCounterClusterInfo < 3) {
    unittest.expect(
      o.centroidId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.clusterRadius!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.clusterSize!,
      unittest.equals('foo'),
    );
  }
  buildCounterClusterInfo--;
}

core.List<core.String> buildUnnamed1482() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1482(core.List<core.String> o) {
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

core.int buildCounterClustering = 0;
api.Clustering buildClustering() {
  var o = api.Clustering();
  buildCounterClustering++;
  if (buildCounterClustering < 3) {
    o.fields = buildUnnamed1482();
  }
  buildCounterClustering--;
  return o;
}

void checkClustering(api.Clustering o) {
  buildCounterClustering++;
  if (buildCounterClustering < 3) {
    checkUnnamed1482(o.fields!);
  }
  buildCounterClustering--;
}

core.List<api.Cluster> buildUnnamed1483() {
  var o = <api.Cluster>[];
  o.add(buildCluster());
  o.add(buildCluster());
  return o;
}

void checkUnnamed1483(core.List<api.Cluster> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkCluster(o[0] as api.Cluster);
  checkCluster(o[1] as api.Cluster);
}

core.int buildCounterClusteringMetrics = 0;
api.ClusteringMetrics buildClusteringMetrics() {
  var o = api.ClusteringMetrics();
  buildCounterClusteringMetrics++;
  if (buildCounterClusteringMetrics < 3) {
    o.clusters = buildUnnamed1483();
    o.daviesBouldinIndex = 42.0;
    o.meanSquaredDistance = 42.0;
  }
  buildCounterClusteringMetrics--;
  return o;
}

void checkClusteringMetrics(api.ClusteringMetrics o) {
  buildCounterClusteringMetrics++;
  if (buildCounterClusteringMetrics < 3) {
    checkUnnamed1483(o.clusters!);
    unittest.expect(
      o.daviesBouldinIndex!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.meanSquaredDistance!,
      unittest.equals(42.0),
    );
  }
  buildCounterClusteringMetrics--;
}

core.List<api.Row> buildUnnamed1484() {
  var o = <api.Row>[];
  o.add(buildRow());
  o.add(buildRow());
  return o;
}

void checkUnnamed1484(core.List<api.Row> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRow(o[0] as api.Row);
  checkRow(o[1] as api.Row);
}

core.int buildCounterConfusionMatrix = 0;
api.ConfusionMatrix buildConfusionMatrix() {
  var o = api.ConfusionMatrix();
  buildCounterConfusionMatrix++;
  if (buildCounterConfusionMatrix < 3) {
    o.confidenceThreshold = 42.0;
    o.rows = buildUnnamed1484();
  }
  buildCounterConfusionMatrix--;
  return o;
}

void checkConfusionMatrix(api.ConfusionMatrix o) {
  buildCounterConfusionMatrix++;
  if (buildCounterConfusionMatrix < 3) {
    unittest.expect(
      o.confidenceThreshold!,
      unittest.equals(42.0),
    );
    checkUnnamed1484(o.rows!);
  }
  buildCounterConfusionMatrix--;
}

core.int buildCounterConnectionProperty = 0;
api.ConnectionProperty buildConnectionProperty() {
  var o = api.ConnectionProperty();
  buildCounterConnectionProperty++;
  if (buildCounterConnectionProperty < 3) {
    o.key = 'foo';
    o.value = 'foo';
  }
  buildCounterConnectionProperty--;
  return o;
}

void checkConnectionProperty(api.ConnectionProperty o) {
  buildCounterConnectionProperty++;
  if (buildCounterConnectionProperty < 3) {
    unittest.expect(
      o.key!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterConnectionProperty--;
}

core.int buildCounterCsvOptions = 0;
api.CsvOptions buildCsvOptions() {
  var o = api.CsvOptions();
  buildCounterCsvOptions++;
  if (buildCounterCsvOptions < 3) {
    o.allowJaggedRows = true;
    o.allowQuotedNewlines = true;
    o.encoding = 'foo';
    o.fieldDelimiter = 'foo';
    o.quote = 'foo';
    o.skipLeadingRows = 'foo';
  }
  buildCounterCsvOptions--;
  return o;
}

void checkCsvOptions(api.CsvOptions o) {
  buildCounterCsvOptions++;
  if (buildCounterCsvOptions < 3) {
    unittest.expect(o.allowJaggedRows!, unittest.isTrue);
    unittest.expect(o.allowQuotedNewlines!, unittest.isTrue);
    unittest.expect(
      o.encoding!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldDelimiter!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.quote!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.skipLeadingRows!,
      unittest.equals('foo'),
    );
  }
  buildCounterCsvOptions--;
}

core.int buildCounterDataSplitResult = 0;
api.DataSplitResult buildDataSplitResult() {
  var o = api.DataSplitResult();
  buildCounterDataSplitResult++;
  if (buildCounterDataSplitResult < 3) {
    o.evaluationTable = buildTableReference();
    o.trainingTable = buildTableReference();
  }
  buildCounterDataSplitResult--;
  return o;
}

void checkDataSplitResult(api.DataSplitResult o) {
  buildCounterDataSplitResult++;
  if (buildCounterDataSplitResult < 3) {
    checkTableReference(o.evaluationTable! as api.TableReference);
    checkTableReference(o.trainingTable! as api.TableReference);
  }
  buildCounterDataSplitResult--;
}

core.int buildCounterDatasetAccess = 0;
api.DatasetAccess buildDatasetAccess() {
  var o = api.DatasetAccess();
  buildCounterDatasetAccess++;
  if (buildCounterDatasetAccess < 3) {
    o.dataset = buildDatasetAccessEntry();
    o.domain = 'foo';
    o.groupByEmail = 'foo';
    o.iamMember = 'foo';
    o.role = 'foo';
    o.routine = buildRoutineReference();
    o.specialGroup = 'foo';
    o.userByEmail = 'foo';
    o.view = buildTableReference();
  }
  buildCounterDatasetAccess--;
  return o;
}

void checkDatasetAccess(api.DatasetAccess o) {
  buildCounterDatasetAccess++;
  if (buildCounterDatasetAccess < 3) {
    checkDatasetAccessEntry(o.dataset! as api.DatasetAccessEntry);
    unittest.expect(
      o.domain!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.groupByEmail!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.iamMember!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.role!,
      unittest.equals('foo'),
    );
    checkRoutineReference(o.routine! as api.RoutineReference);
    unittest.expect(
      o.specialGroup!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userByEmail!,
      unittest.equals('foo'),
    );
    checkTableReference(o.view! as api.TableReference);
  }
  buildCounterDatasetAccess--;
}

core.List<api.DatasetAccess> buildUnnamed1485() {
  var o = <api.DatasetAccess>[];
  o.add(buildDatasetAccess());
  o.add(buildDatasetAccess());
  return o;
}

void checkUnnamed1485(core.List<api.DatasetAccess> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDatasetAccess(o[0] as api.DatasetAccess);
  checkDatasetAccess(o[1] as api.DatasetAccess);
}

core.Map<core.String, core.String> buildUnnamed1486() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed1486(core.Map<core.String, core.String> o) {
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

core.int buildCounterDataset = 0;
api.Dataset buildDataset() {
  var o = api.Dataset();
  buildCounterDataset++;
  if (buildCounterDataset < 3) {
    o.access = buildUnnamed1485();
    o.creationTime = 'foo';
    o.datasetReference = buildDatasetReference();
    o.defaultEncryptionConfiguration = buildEncryptionConfiguration();
    o.defaultPartitionExpirationMs = 'foo';
    o.defaultTableExpirationMs = 'foo';
    o.description = 'foo';
    o.etag = 'foo';
    o.friendlyName = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.labels = buildUnnamed1486();
    o.lastModifiedTime = 'foo';
    o.location = 'foo';
    o.satisfiesPZS = true;
    o.selfLink = 'foo';
  }
  buildCounterDataset--;
  return o;
}

void checkDataset(api.Dataset o) {
  buildCounterDataset++;
  if (buildCounterDataset < 3) {
    checkUnnamed1485(o.access!);
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    checkDatasetReference(o.datasetReference! as api.DatasetReference);
    checkEncryptionConfiguration(
        o.defaultEncryptionConfiguration! as api.EncryptionConfiguration);
    unittest.expect(
      o.defaultPartitionExpirationMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.defaultTableExpirationMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.friendlyName!,
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
    checkUnnamed1486(o.labels!);
    unittest.expect(
      o.lastModifiedTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(o.satisfiesPZS!, unittest.isTrue);
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
  }
  buildCounterDataset--;
}

core.int buildCounterDatasetAccessEntryTargetTypes = 0;
api.DatasetAccessEntryTargetTypes buildDatasetAccessEntryTargetTypes() {
  var o = api.DatasetAccessEntryTargetTypes();
  buildCounterDatasetAccessEntryTargetTypes++;
  if (buildCounterDatasetAccessEntryTargetTypes < 3) {
    o.targetType = 'foo';
  }
  buildCounterDatasetAccessEntryTargetTypes--;
  return o;
}

void checkDatasetAccessEntryTargetTypes(api.DatasetAccessEntryTargetTypes o) {
  buildCounterDatasetAccessEntryTargetTypes++;
  if (buildCounterDatasetAccessEntryTargetTypes < 3) {
    unittest.expect(
      o.targetType!,
      unittest.equals('foo'),
    );
  }
  buildCounterDatasetAccessEntryTargetTypes--;
}

core.List<api.DatasetAccessEntryTargetTypes> buildUnnamed1487() {
  var o = <api.DatasetAccessEntryTargetTypes>[];
  o.add(buildDatasetAccessEntryTargetTypes());
  o.add(buildDatasetAccessEntryTargetTypes());
  return o;
}

void checkUnnamed1487(core.List<api.DatasetAccessEntryTargetTypes> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDatasetAccessEntryTargetTypes(o[0] as api.DatasetAccessEntryTargetTypes);
  checkDatasetAccessEntryTargetTypes(o[1] as api.DatasetAccessEntryTargetTypes);
}

core.int buildCounterDatasetAccessEntry = 0;
api.DatasetAccessEntry buildDatasetAccessEntry() {
  var o = api.DatasetAccessEntry();
  buildCounterDatasetAccessEntry++;
  if (buildCounterDatasetAccessEntry < 3) {
    o.dataset = buildDatasetReference();
    o.targetTypes = buildUnnamed1487();
  }
  buildCounterDatasetAccessEntry--;
  return o;
}

void checkDatasetAccessEntry(api.DatasetAccessEntry o) {
  buildCounterDatasetAccessEntry++;
  if (buildCounterDatasetAccessEntry < 3) {
    checkDatasetReference(o.dataset! as api.DatasetReference);
    checkUnnamed1487(o.targetTypes!);
  }
  buildCounterDatasetAccessEntry--;
}

core.Map<core.String, core.String> buildUnnamed1488() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed1488(core.Map<core.String, core.String> o) {
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

core.int buildCounterDatasetListDatasets = 0;
api.DatasetListDatasets buildDatasetListDatasets() {
  var o = api.DatasetListDatasets();
  buildCounterDatasetListDatasets++;
  if (buildCounterDatasetListDatasets < 3) {
    o.datasetReference = buildDatasetReference();
    o.friendlyName = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.labels = buildUnnamed1488();
    o.location = 'foo';
  }
  buildCounterDatasetListDatasets--;
  return o;
}

void checkDatasetListDatasets(api.DatasetListDatasets o) {
  buildCounterDatasetListDatasets++;
  if (buildCounterDatasetListDatasets < 3) {
    checkDatasetReference(o.datasetReference! as api.DatasetReference);
    unittest.expect(
      o.friendlyName!,
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
    checkUnnamed1488(o.labels!);
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
  }
  buildCounterDatasetListDatasets--;
}

core.List<api.DatasetListDatasets> buildUnnamed1489() {
  var o = <api.DatasetListDatasets>[];
  o.add(buildDatasetListDatasets());
  o.add(buildDatasetListDatasets());
  return o;
}

void checkUnnamed1489(core.List<api.DatasetListDatasets> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDatasetListDatasets(o[0] as api.DatasetListDatasets);
  checkDatasetListDatasets(o[1] as api.DatasetListDatasets);
}

core.int buildCounterDatasetList = 0;
api.DatasetList buildDatasetList() {
  var o = api.DatasetList();
  buildCounterDatasetList++;
  if (buildCounterDatasetList < 3) {
    o.datasets = buildUnnamed1489();
    o.etag = 'foo';
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterDatasetList--;
  return o;
}

void checkDatasetList(api.DatasetList o) {
  buildCounterDatasetList++;
  if (buildCounterDatasetList < 3) {
    checkUnnamed1489(o.datasets!);
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
  }
  buildCounterDatasetList--;
}

core.int buildCounterDatasetReference = 0;
api.DatasetReference buildDatasetReference() {
  var o = api.DatasetReference();
  buildCounterDatasetReference++;
  if (buildCounterDatasetReference < 3) {
    o.datasetId = 'foo';
    o.projectId = 'foo';
  }
  buildCounterDatasetReference--;
  return o;
}

void checkDatasetReference(api.DatasetReference o) {
  buildCounterDatasetReference++;
  if (buildCounterDatasetReference < 3) {
    unittest.expect(
      o.datasetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterDatasetReference--;
}

core.Map<core.String, core.String> buildUnnamed1490() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed1490(core.Map<core.String, core.String> o) {
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

core.int buildCounterDestinationTableProperties = 0;
api.DestinationTableProperties buildDestinationTableProperties() {
  var o = api.DestinationTableProperties();
  buildCounterDestinationTableProperties++;
  if (buildCounterDestinationTableProperties < 3) {
    o.description = 'foo';
    o.friendlyName = 'foo';
    o.labels = buildUnnamed1490();
  }
  buildCounterDestinationTableProperties--;
  return o;
}

void checkDestinationTableProperties(api.DestinationTableProperties o) {
  buildCounterDestinationTableProperties++;
  if (buildCounterDestinationTableProperties < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.friendlyName!,
      unittest.equals('foo'),
    );
    checkUnnamed1490(o.labels!);
  }
  buildCounterDestinationTableProperties--;
}

core.int buildCounterEncryptionConfiguration = 0;
api.EncryptionConfiguration buildEncryptionConfiguration() {
  var o = api.EncryptionConfiguration();
  buildCounterEncryptionConfiguration++;
  if (buildCounterEncryptionConfiguration < 3) {
    o.kmsKeyName = 'foo';
  }
  buildCounterEncryptionConfiguration--;
  return o;
}

void checkEncryptionConfiguration(api.EncryptionConfiguration o) {
  buildCounterEncryptionConfiguration++;
  if (buildCounterEncryptionConfiguration < 3) {
    unittest.expect(
      o.kmsKeyName!,
      unittest.equals('foo'),
    );
  }
  buildCounterEncryptionConfiguration--;
}

core.int buildCounterEntry = 0;
api.Entry buildEntry() {
  var o = api.Entry();
  buildCounterEntry++;
  if (buildCounterEntry < 3) {
    o.itemCount = 'foo';
    o.predictedLabel = 'foo';
  }
  buildCounterEntry--;
  return o;
}

void checkEntry(api.Entry o) {
  buildCounterEntry++;
  if (buildCounterEntry < 3) {
    unittest.expect(
      o.itemCount!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.predictedLabel!,
      unittest.equals('foo'),
    );
  }
  buildCounterEntry--;
}

core.int buildCounterErrorProto = 0;
api.ErrorProto buildErrorProto() {
  var o = api.ErrorProto();
  buildCounterErrorProto++;
  if (buildCounterErrorProto < 3) {
    o.debugInfo = 'foo';
    o.location = 'foo';
    o.message = 'foo';
    o.reason = 'foo';
  }
  buildCounterErrorProto--;
  return o;
}

void checkErrorProto(api.ErrorProto o) {
  buildCounterErrorProto++;
  if (buildCounterErrorProto < 3) {
    unittest.expect(
      o.debugInfo!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.reason!,
      unittest.equals('foo'),
    );
  }
  buildCounterErrorProto--;
}

core.int buildCounterEvaluationMetrics = 0;
api.EvaluationMetrics buildEvaluationMetrics() {
  var o = api.EvaluationMetrics();
  buildCounterEvaluationMetrics++;
  if (buildCounterEvaluationMetrics < 3) {
    o.arimaForecastingMetrics = buildArimaForecastingMetrics();
    o.binaryClassificationMetrics = buildBinaryClassificationMetrics();
    o.clusteringMetrics = buildClusteringMetrics();
    o.multiClassClassificationMetrics = buildMultiClassClassificationMetrics();
    o.rankingMetrics = buildRankingMetrics();
    o.regressionMetrics = buildRegressionMetrics();
  }
  buildCounterEvaluationMetrics--;
  return o;
}

void checkEvaluationMetrics(api.EvaluationMetrics o) {
  buildCounterEvaluationMetrics++;
  if (buildCounterEvaluationMetrics < 3) {
    checkArimaForecastingMetrics(
        o.arimaForecastingMetrics! as api.ArimaForecastingMetrics);
    checkBinaryClassificationMetrics(
        o.binaryClassificationMetrics! as api.BinaryClassificationMetrics);
    checkClusteringMetrics(o.clusteringMetrics! as api.ClusteringMetrics);
    checkMultiClassClassificationMetrics(o.multiClassClassificationMetrics!
        as api.MultiClassClassificationMetrics);
    checkRankingMetrics(o.rankingMetrics! as api.RankingMetrics);
    checkRegressionMetrics(o.regressionMetrics! as api.RegressionMetrics);
  }
  buildCounterEvaluationMetrics--;
}

core.List<core.String> buildUnnamed1491() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1491(core.List<core.String> o) {
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

core.List<api.ExplainQueryStep> buildUnnamed1492() {
  var o = <api.ExplainQueryStep>[];
  o.add(buildExplainQueryStep());
  o.add(buildExplainQueryStep());
  return o;
}

void checkUnnamed1492(core.List<api.ExplainQueryStep> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExplainQueryStep(o[0] as api.ExplainQueryStep);
  checkExplainQueryStep(o[1] as api.ExplainQueryStep);
}

core.int buildCounterExplainQueryStage = 0;
api.ExplainQueryStage buildExplainQueryStage() {
  var o = api.ExplainQueryStage();
  buildCounterExplainQueryStage++;
  if (buildCounterExplainQueryStage < 3) {
    o.completedParallelInputs = 'foo';
    o.computeMsAvg = 'foo';
    o.computeMsMax = 'foo';
    o.computeRatioAvg = 42.0;
    o.computeRatioMax = 42.0;
    o.endMs = 'foo';
    o.id = 'foo';
    o.inputStages = buildUnnamed1491();
    o.name = 'foo';
    o.parallelInputs = 'foo';
    o.readMsAvg = 'foo';
    o.readMsMax = 'foo';
    o.readRatioAvg = 42.0;
    o.readRatioMax = 42.0;
    o.recordsRead = 'foo';
    o.recordsWritten = 'foo';
    o.shuffleOutputBytes = 'foo';
    o.shuffleOutputBytesSpilled = 'foo';
    o.slotMs = 'foo';
    o.startMs = 'foo';
    o.status = 'foo';
    o.steps = buildUnnamed1492();
    o.waitMsAvg = 'foo';
    o.waitMsMax = 'foo';
    o.waitRatioAvg = 42.0;
    o.waitRatioMax = 42.0;
    o.writeMsAvg = 'foo';
    o.writeMsMax = 'foo';
    o.writeRatioAvg = 42.0;
    o.writeRatioMax = 42.0;
  }
  buildCounterExplainQueryStage--;
  return o;
}

void checkExplainQueryStage(api.ExplainQueryStage o) {
  buildCounterExplainQueryStage++;
  if (buildCounterExplainQueryStage < 3) {
    unittest.expect(
      o.completedParallelInputs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.computeMsAvg!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.computeMsMax!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.computeRatioAvg!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.computeRatioMax!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.endMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkUnnamed1491(o.inputStages!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parallelInputs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readMsAvg!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readMsMax!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.readRatioAvg!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.readRatioMax!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.recordsRead!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.recordsWritten!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.shuffleOutputBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.shuffleOutputBytesSpilled!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.slotMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.status!,
      unittest.equals('foo'),
    );
    checkUnnamed1492(o.steps!);
    unittest.expect(
      o.waitMsAvg!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.waitMsMax!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.waitRatioAvg!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.waitRatioMax!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.writeMsAvg!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.writeMsMax!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.writeRatioAvg!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.writeRatioMax!,
      unittest.equals(42.0),
    );
  }
  buildCounterExplainQueryStage--;
}

core.List<core.String> buildUnnamed1493() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1493(core.List<core.String> o) {
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

core.int buildCounterExplainQueryStep = 0;
api.ExplainQueryStep buildExplainQueryStep() {
  var o = api.ExplainQueryStep();
  buildCounterExplainQueryStep++;
  if (buildCounterExplainQueryStep < 3) {
    o.kind = 'foo';
    o.substeps = buildUnnamed1493();
  }
  buildCounterExplainQueryStep--;
  return o;
}

void checkExplainQueryStep(api.ExplainQueryStep o) {
  buildCounterExplainQueryStep++;
  if (buildCounterExplainQueryStep < 3) {
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed1493(o.substeps!);
  }
  buildCounterExplainQueryStep--;
}

core.int buildCounterExplanation = 0;
api.Explanation buildExplanation() {
  var o = api.Explanation();
  buildCounterExplanation++;
  if (buildCounterExplanation < 3) {
    o.attribution = 42.0;
    o.featureName = 'foo';
  }
  buildCounterExplanation--;
  return o;
}

void checkExplanation(api.Explanation o) {
  buildCounterExplanation++;
  if (buildCounterExplanation < 3) {
    unittest.expect(
      o.attribution!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.featureName!,
      unittest.equals('foo'),
    );
  }
  buildCounterExplanation--;
}

core.int buildCounterExpr = 0;
api.Expr buildExpr() {
  var o = api.Expr();
  buildCounterExpr++;
  if (buildCounterExpr < 3) {
    o.description = 'foo';
    o.expression = 'foo';
    o.location = 'foo';
    o.title = 'foo';
  }
  buildCounterExpr--;
  return o;
}

void checkExpr(api.Expr o) {
  buildCounterExpr++;
  if (buildCounterExpr < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expression!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.title!,
      unittest.equals('foo'),
    );
  }
  buildCounterExpr--;
}

core.List<core.String> buildUnnamed1494() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1494(core.List<core.String> o) {
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

core.int buildCounterExternalDataConfiguration = 0;
api.ExternalDataConfiguration buildExternalDataConfiguration() {
  var o = api.ExternalDataConfiguration();
  buildCounterExternalDataConfiguration++;
  if (buildCounterExternalDataConfiguration < 3) {
    o.autodetect = true;
    o.bigtableOptions = buildBigtableOptions();
    o.compression = 'foo';
    o.connectionId = 'foo';
    o.csvOptions = buildCsvOptions();
    o.googleSheetsOptions = buildGoogleSheetsOptions();
    o.hivePartitioningOptions = buildHivePartitioningOptions();
    o.ignoreUnknownValues = true;
    o.maxBadRecords = 42;
    o.parquetOptions = buildParquetOptions();
    o.schema = buildTableSchema();
    o.sourceFormat = 'foo';
    o.sourceUris = buildUnnamed1494();
  }
  buildCounterExternalDataConfiguration--;
  return o;
}

void checkExternalDataConfiguration(api.ExternalDataConfiguration o) {
  buildCounterExternalDataConfiguration++;
  if (buildCounterExternalDataConfiguration < 3) {
    unittest.expect(o.autodetect!, unittest.isTrue);
    checkBigtableOptions(o.bigtableOptions! as api.BigtableOptions);
    unittest.expect(
      o.compression!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.connectionId!,
      unittest.equals('foo'),
    );
    checkCsvOptions(o.csvOptions! as api.CsvOptions);
    checkGoogleSheetsOptions(o.googleSheetsOptions! as api.GoogleSheetsOptions);
    checkHivePartitioningOptions(
        o.hivePartitioningOptions! as api.HivePartitioningOptions);
    unittest.expect(o.ignoreUnknownValues!, unittest.isTrue);
    unittest.expect(
      o.maxBadRecords!,
      unittest.equals(42),
    );
    checkParquetOptions(o.parquetOptions! as api.ParquetOptions);
    checkTableSchema(o.schema! as api.TableSchema);
    unittest.expect(
      o.sourceFormat!,
      unittest.equals('foo'),
    );
    checkUnnamed1494(o.sourceUris!);
  }
  buildCounterExternalDataConfiguration--;
}

core.int buildCounterFeatureValue = 0;
api.FeatureValue buildFeatureValue() {
  var o = api.FeatureValue();
  buildCounterFeatureValue++;
  if (buildCounterFeatureValue < 3) {
    o.categoricalValue = buildCategoricalValue();
    o.featureColumn = 'foo';
    o.numericalValue = 42.0;
  }
  buildCounterFeatureValue--;
  return o;
}

void checkFeatureValue(api.FeatureValue o) {
  buildCounterFeatureValue++;
  if (buildCounterFeatureValue < 3) {
    checkCategoricalValue(o.categoricalValue! as api.CategoricalValue);
    unittest.expect(
      o.featureColumn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numericalValue!,
      unittest.equals(42.0),
    );
  }
  buildCounterFeatureValue--;
}

core.int buildCounterGetIamPolicyRequest = 0;
api.GetIamPolicyRequest buildGetIamPolicyRequest() {
  var o = api.GetIamPolicyRequest();
  buildCounterGetIamPolicyRequest++;
  if (buildCounterGetIamPolicyRequest < 3) {
    o.options = buildGetPolicyOptions();
  }
  buildCounterGetIamPolicyRequest--;
  return o;
}

void checkGetIamPolicyRequest(api.GetIamPolicyRequest o) {
  buildCounterGetIamPolicyRequest++;
  if (buildCounterGetIamPolicyRequest < 3) {
    checkGetPolicyOptions(o.options! as api.GetPolicyOptions);
  }
  buildCounterGetIamPolicyRequest--;
}

core.int buildCounterGetPolicyOptions = 0;
api.GetPolicyOptions buildGetPolicyOptions() {
  var o = api.GetPolicyOptions();
  buildCounterGetPolicyOptions++;
  if (buildCounterGetPolicyOptions < 3) {
    o.requestedPolicyVersion = 42;
  }
  buildCounterGetPolicyOptions--;
  return o;
}

void checkGetPolicyOptions(api.GetPolicyOptions o) {
  buildCounterGetPolicyOptions++;
  if (buildCounterGetPolicyOptions < 3) {
    unittest.expect(
      o.requestedPolicyVersion!,
      unittest.equals(42),
    );
  }
  buildCounterGetPolicyOptions--;
}

core.List<api.ErrorProto> buildUnnamed1495() {
  var o = <api.ErrorProto>[];
  o.add(buildErrorProto());
  o.add(buildErrorProto());
  return o;
}

void checkUnnamed1495(core.List<api.ErrorProto> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkErrorProto(o[0] as api.ErrorProto);
  checkErrorProto(o[1] as api.ErrorProto);
}

core.List<api.TableRow> buildUnnamed1496() {
  var o = <api.TableRow>[];
  o.add(buildTableRow());
  o.add(buildTableRow());
  return o;
}

void checkUnnamed1496(core.List<api.TableRow> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableRow(o[0] as api.TableRow);
  checkTableRow(o[1] as api.TableRow);
}

core.int buildCounterGetQueryResultsResponse = 0;
api.GetQueryResultsResponse buildGetQueryResultsResponse() {
  var o = api.GetQueryResultsResponse();
  buildCounterGetQueryResultsResponse++;
  if (buildCounterGetQueryResultsResponse < 3) {
    o.cacheHit = true;
    o.errors = buildUnnamed1495();
    o.etag = 'foo';
    o.jobComplete = true;
    o.jobReference = buildJobReference();
    o.kind = 'foo';
    o.numDmlAffectedRows = 'foo';
    o.pageToken = 'foo';
    o.rows = buildUnnamed1496();
    o.schema = buildTableSchema();
    o.totalBytesProcessed = 'foo';
    o.totalRows = 'foo';
  }
  buildCounterGetQueryResultsResponse--;
  return o;
}

void checkGetQueryResultsResponse(api.GetQueryResultsResponse o) {
  buildCounterGetQueryResultsResponse++;
  if (buildCounterGetQueryResultsResponse < 3) {
    unittest.expect(o.cacheHit!, unittest.isTrue);
    checkUnnamed1495(o.errors!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(o.jobComplete!, unittest.isTrue);
    checkJobReference(o.jobReference! as api.JobReference);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numDmlAffectedRows!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1496(o.rows!);
    checkTableSchema(o.schema! as api.TableSchema);
    unittest.expect(
      o.totalBytesProcessed!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalRows!,
      unittest.equals('foo'),
    );
  }
  buildCounterGetQueryResultsResponse--;
}

core.int buildCounterGetServiceAccountResponse = 0;
api.GetServiceAccountResponse buildGetServiceAccountResponse() {
  var o = api.GetServiceAccountResponse();
  buildCounterGetServiceAccountResponse++;
  if (buildCounterGetServiceAccountResponse < 3) {
    o.email = 'foo';
    o.kind = 'foo';
  }
  buildCounterGetServiceAccountResponse--;
  return o;
}

void checkGetServiceAccountResponse(api.GetServiceAccountResponse o) {
  buildCounterGetServiceAccountResponse++;
  if (buildCounterGetServiceAccountResponse < 3) {
    unittest.expect(
      o.email!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterGetServiceAccountResponse--;
}

core.List<api.Explanation> buildUnnamed1497() {
  var o = <api.Explanation>[];
  o.add(buildExplanation());
  o.add(buildExplanation());
  return o;
}

void checkUnnamed1497(core.List<api.Explanation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExplanation(o[0] as api.Explanation);
  checkExplanation(o[1] as api.Explanation);
}

core.int buildCounterGlobalExplanation = 0;
api.GlobalExplanation buildGlobalExplanation() {
  var o = api.GlobalExplanation();
  buildCounterGlobalExplanation++;
  if (buildCounterGlobalExplanation < 3) {
    o.classLabel = 'foo';
    o.explanations = buildUnnamed1497();
  }
  buildCounterGlobalExplanation--;
  return o;
}

void checkGlobalExplanation(api.GlobalExplanation o) {
  buildCounterGlobalExplanation++;
  if (buildCounterGlobalExplanation < 3) {
    unittest.expect(
      o.classLabel!,
      unittest.equals('foo'),
    );
    checkUnnamed1497(o.explanations!);
  }
  buildCounterGlobalExplanation--;
}

core.int buildCounterGoogleSheetsOptions = 0;
api.GoogleSheetsOptions buildGoogleSheetsOptions() {
  var o = api.GoogleSheetsOptions();
  buildCounterGoogleSheetsOptions++;
  if (buildCounterGoogleSheetsOptions < 3) {
    o.range = 'foo';
    o.skipLeadingRows = 'foo';
  }
  buildCounterGoogleSheetsOptions--;
  return o;
}

void checkGoogleSheetsOptions(api.GoogleSheetsOptions o) {
  buildCounterGoogleSheetsOptions++;
  if (buildCounterGoogleSheetsOptions < 3) {
    unittest.expect(
      o.range!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.skipLeadingRows!,
      unittest.equals('foo'),
    );
  }
  buildCounterGoogleSheetsOptions--;
}

core.int buildCounterHivePartitioningOptions = 0;
api.HivePartitioningOptions buildHivePartitioningOptions() {
  var o = api.HivePartitioningOptions();
  buildCounterHivePartitioningOptions++;
  if (buildCounterHivePartitioningOptions < 3) {
    o.mode = 'foo';
    o.requirePartitionFilter = true;
    o.sourceUriPrefix = 'foo';
  }
  buildCounterHivePartitioningOptions--;
  return o;
}

void checkHivePartitioningOptions(api.HivePartitioningOptions o) {
  buildCounterHivePartitioningOptions++;
  if (buildCounterHivePartitioningOptions < 3) {
    unittest.expect(
      o.mode!,
      unittest.equals('foo'),
    );
    unittest.expect(o.requirePartitionFilter!, unittest.isTrue);
    unittest.expect(
      o.sourceUriPrefix!,
      unittest.equals('foo'),
    );
  }
  buildCounterHivePartitioningOptions--;
}

core.List<api.ClusterInfo> buildUnnamed1498() {
  var o = <api.ClusterInfo>[];
  o.add(buildClusterInfo());
  o.add(buildClusterInfo());
  return o;
}

void checkUnnamed1498(core.List<api.ClusterInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkClusterInfo(o[0] as api.ClusterInfo);
  checkClusterInfo(o[1] as api.ClusterInfo);
}

core.int buildCounterIterationResult = 0;
api.IterationResult buildIterationResult() {
  var o = api.IterationResult();
  buildCounterIterationResult++;
  if (buildCounterIterationResult < 3) {
    o.arimaResult = buildArimaResult();
    o.clusterInfos = buildUnnamed1498();
    o.durationMs = 'foo';
    o.evalLoss = 42.0;
    o.index = 42;
    o.learnRate = 42.0;
    o.trainingLoss = 42.0;
  }
  buildCounterIterationResult--;
  return o;
}

void checkIterationResult(api.IterationResult o) {
  buildCounterIterationResult++;
  if (buildCounterIterationResult < 3) {
    checkArimaResult(o.arimaResult! as api.ArimaResult);
    checkUnnamed1498(o.clusterInfos!);
    unittest.expect(
      o.durationMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.evalLoss!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
    unittest.expect(
      o.learnRate!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.trainingLoss!,
      unittest.equals(42.0),
    );
  }
  buildCounterIterationResult--;
}

core.int buildCounterJob = 0;
api.Job buildJob() {
  var o = api.Job();
  buildCounterJob++;
  if (buildCounterJob < 3) {
    o.configuration = buildJobConfiguration();
    o.etag = 'foo';
    o.id = 'foo';
    o.jobReference = buildJobReference();
    o.kind = 'foo';
    o.selfLink = 'foo';
    o.statistics = buildJobStatistics();
    o.status = buildJobStatus();
    o.userEmail = 'foo';
  }
  buildCounterJob--;
  return o;
}

void checkJob(api.Job o) {
  buildCounterJob++;
  if (buildCounterJob < 3) {
    checkJobConfiguration(o.configuration! as api.JobConfiguration);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkJobReference(o.jobReference! as api.JobReference);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    checkJobStatistics(o.statistics! as api.JobStatistics);
    checkJobStatus(o.status! as api.JobStatus);
    unittest.expect(
      o.userEmail!,
      unittest.equals('foo'),
    );
  }
  buildCounterJob--;
}

core.int buildCounterJobCancelResponse = 0;
api.JobCancelResponse buildJobCancelResponse() {
  var o = api.JobCancelResponse();
  buildCounterJobCancelResponse++;
  if (buildCounterJobCancelResponse < 3) {
    o.job = buildJob();
    o.kind = 'foo';
  }
  buildCounterJobCancelResponse--;
  return o;
}

void checkJobCancelResponse(api.JobCancelResponse o) {
  buildCounterJobCancelResponse++;
  if (buildCounterJobCancelResponse < 3) {
    checkJob(o.job! as api.Job);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterJobCancelResponse--;
}

core.Map<core.String, core.String> buildUnnamed1499() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed1499(core.Map<core.String, core.String> o) {
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

core.int buildCounterJobConfiguration = 0;
api.JobConfiguration buildJobConfiguration() {
  var o = api.JobConfiguration();
  buildCounterJobConfiguration++;
  if (buildCounterJobConfiguration < 3) {
    o.copy = buildJobConfigurationTableCopy();
    o.dryRun = true;
    o.extract = buildJobConfigurationExtract();
    o.jobTimeoutMs = 'foo';
    o.jobType = 'foo';
    o.labels = buildUnnamed1499();
    o.load = buildJobConfigurationLoad();
    o.query = buildJobConfigurationQuery();
  }
  buildCounterJobConfiguration--;
  return o;
}

void checkJobConfiguration(api.JobConfiguration o) {
  buildCounterJobConfiguration++;
  if (buildCounterJobConfiguration < 3) {
    checkJobConfigurationTableCopy(o.copy! as api.JobConfigurationTableCopy);
    unittest.expect(o.dryRun!, unittest.isTrue);
    checkJobConfigurationExtract(o.extract! as api.JobConfigurationExtract);
    unittest.expect(
      o.jobTimeoutMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.jobType!,
      unittest.equals('foo'),
    );
    checkUnnamed1499(o.labels!);
    checkJobConfigurationLoad(o.load! as api.JobConfigurationLoad);
    checkJobConfigurationQuery(o.query! as api.JobConfigurationQuery);
  }
  buildCounterJobConfiguration--;
}

core.List<core.String> buildUnnamed1500() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1500(core.List<core.String> o) {
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

core.int buildCounterJobConfigurationExtract = 0;
api.JobConfigurationExtract buildJobConfigurationExtract() {
  var o = api.JobConfigurationExtract();
  buildCounterJobConfigurationExtract++;
  if (buildCounterJobConfigurationExtract < 3) {
    o.compression = 'foo';
    o.destinationFormat = 'foo';
    o.destinationUri = 'foo';
    o.destinationUris = buildUnnamed1500();
    o.fieldDelimiter = 'foo';
    o.printHeader = true;
    o.sourceModel = buildModelReference();
    o.sourceTable = buildTableReference();
    o.useAvroLogicalTypes = true;
  }
  buildCounterJobConfigurationExtract--;
  return o;
}

void checkJobConfigurationExtract(api.JobConfigurationExtract o) {
  buildCounterJobConfigurationExtract++;
  if (buildCounterJobConfigurationExtract < 3) {
    unittest.expect(
      o.compression!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.destinationFormat!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.destinationUri!,
      unittest.equals('foo'),
    );
    checkUnnamed1500(o.destinationUris!);
    unittest.expect(
      o.fieldDelimiter!,
      unittest.equals('foo'),
    );
    unittest.expect(o.printHeader!, unittest.isTrue);
    checkModelReference(o.sourceModel! as api.ModelReference);
    checkTableReference(o.sourceTable! as api.TableReference);
    unittest.expect(o.useAvroLogicalTypes!, unittest.isTrue);
  }
  buildCounterJobConfigurationExtract--;
}

core.List<core.String> buildUnnamed1501() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1501(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1502() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1502(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1503() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1503(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1504() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1504(core.List<core.String> o) {
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

core.int buildCounterJobConfigurationLoad = 0;
api.JobConfigurationLoad buildJobConfigurationLoad() {
  var o = api.JobConfigurationLoad();
  buildCounterJobConfigurationLoad++;
  if (buildCounterJobConfigurationLoad < 3) {
    o.allowJaggedRows = true;
    o.allowQuotedNewlines = true;
    o.autodetect = true;
    o.clustering = buildClustering();
    o.createDisposition = 'foo';
    o.decimalTargetTypes = buildUnnamed1501();
    o.destinationEncryptionConfiguration = buildEncryptionConfiguration();
    o.destinationTable = buildTableReference();
    o.destinationTableProperties = buildDestinationTableProperties();
    o.encoding = 'foo';
    o.fieldDelimiter = 'foo';
    o.hivePartitioningOptions = buildHivePartitioningOptions();
    o.ignoreUnknownValues = true;
    o.jsonExtension = 'foo';
    o.maxBadRecords = 42;
    o.nullMarker = 'foo';
    o.parquetOptions = buildParquetOptions();
    o.projectionFields = buildUnnamed1502();
    o.quote = 'foo';
    o.rangePartitioning = buildRangePartitioning();
    o.schema = buildTableSchema();
    o.schemaInline = 'foo';
    o.schemaInlineFormat = 'foo';
    o.schemaUpdateOptions = buildUnnamed1503();
    o.skipLeadingRows = 42;
    o.sourceFormat = 'foo';
    o.sourceUris = buildUnnamed1504();
    o.timePartitioning = buildTimePartitioning();
    o.useAvroLogicalTypes = true;
    o.writeDisposition = 'foo';
  }
  buildCounterJobConfigurationLoad--;
  return o;
}

void checkJobConfigurationLoad(api.JobConfigurationLoad o) {
  buildCounterJobConfigurationLoad++;
  if (buildCounterJobConfigurationLoad < 3) {
    unittest.expect(o.allowJaggedRows!, unittest.isTrue);
    unittest.expect(o.allowQuotedNewlines!, unittest.isTrue);
    unittest.expect(o.autodetect!, unittest.isTrue);
    checkClustering(o.clustering! as api.Clustering);
    unittest.expect(
      o.createDisposition!,
      unittest.equals('foo'),
    );
    checkUnnamed1501(o.decimalTargetTypes!);
    checkEncryptionConfiguration(
        o.destinationEncryptionConfiguration! as api.EncryptionConfiguration);
    checkTableReference(o.destinationTable! as api.TableReference);
    checkDestinationTableProperties(
        o.destinationTableProperties! as api.DestinationTableProperties);
    unittest.expect(
      o.encoding!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.fieldDelimiter!,
      unittest.equals('foo'),
    );
    checkHivePartitioningOptions(
        o.hivePartitioningOptions! as api.HivePartitioningOptions);
    unittest.expect(o.ignoreUnknownValues!, unittest.isTrue);
    unittest.expect(
      o.jsonExtension!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxBadRecords!,
      unittest.equals(42),
    );
    unittest.expect(
      o.nullMarker!,
      unittest.equals('foo'),
    );
    checkParquetOptions(o.parquetOptions! as api.ParquetOptions);
    checkUnnamed1502(o.projectionFields!);
    unittest.expect(
      o.quote!,
      unittest.equals('foo'),
    );
    checkRangePartitioning(o.rangePartitioning! as api.RangePartitioning);
    checkTableSchema(o.schema! as api.TableSchema);
    unittest.expect(
      o.schemaInline!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.schemaInlineFormat!,
      unittest.equals('foo'),
    );
    checkUnnamed1503(o.schemaUpdateOptions!);
    unittest.expect(
      o.skipLeadingRows!,
      unittest.equals(42),
    );
    unittest.expect(
      o.sourceFormat!,
      unittest.equals('foo'),
    );
    checkUnnamed1504(o.sourceUris!);
    checkTimePartitioning(o.timePartitioning! as api.TimePartitioning);
    unittest.expect(o.useAvroLogicalTypes!, unittest.isTrue);
    unittest.expect(
      o.writeDisposition!,
      unittest.equals('foo'),
    );
  }
  buildCounterJobConfigurationLoad--;
}

core.List<api.ConnectionProperty> buildUnnamed1505() {
  var o = <api.ConnectionProperty>[];
  o.add(buildConnectionProperty());
  o.add(buildConnectionProperty());
  return o;
}

void checkUnnamed1505(core.List<api.ConnectionProperty> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConnectionProperty(o[0] as api.ConnectionProperty);
  checkConnectionProperty(o[1] as api.ConnectionProperty);
}

core.List<api.QueryParameter> buildUnnamed1506() {
  var o = <api.QueryParameter>[];
  o.add(buildQueryParameter());
  o.add(buildQueryParameter());
  return o;
}

void checkUnnamed1506(core.List<api.QueryParameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkQueryParameter(o[0] as api.QueryParameter);
  checkQueryParameter(o[1] as api.QueryParameter);
}

core.List<core.String> buildUnnamed1507() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1507(core.List<core.String> o) {
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

core.Map<core.String, api.ExternalDataConfiguration> buildUnnamed1508() {
  var o = <core.String, api.ExternalDataConfiguration>{};
  o['x'] = buildExternalDataConfiguration();
  o['y'] = buildExternalDataConfiguration();
  return o;
}

void checkUnnamed1508(core.Map<core.String, api.ExternalDataConfiguration> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExternalDataConfiguration(o['x']! as api.ExternalDataConfiguration);
  checkExternalDataConfiguration(o['y']! as api.ExternalDataConfiguration);
}

core.List<api.UserDefinedFunctionResource> buildUnnamed1509() {
  var o = <api.UserDefinedFunctionResource>[];
  o.add(buildUserDefinedFunctionResource());
  o.add(buildUserDefinedFunctionResource());
  return o;
}

void checkUnnamed1509(core.List<api.UserDefinedFunctionResource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUserDefinedFunctionResource(o[0] as api.UserDefinedFunctionResource);
  checkUserDefinedFunctionResource(o[1] as api.UserDefinedFunctionResource);
}

core.int buildCounterJobConfigurationQuery = 0;
api.JobConfigurationQuery buildJobConfigurationQuery() {
  var o = api.JobConfigurationQuery();
  buildCounterJobConfigurationQuery++;
  if (buildCounterJobConfigurationQuery < 3) {
    o.allowLargeResults = true;
    o.clustering = buildClustering();
    o.connectionProperties = buildUnnamed1505();
    o.createDisposition = 'foo';
    o.createSession = true;
    o.defaultDataset = buildDatasetReference();
    o.destinationEncryptionConfiguration = buildEncryptionConfiguration();
    o.destinationTable = buildTableReference();
    o.flattenResults = true;
    o.maximumBillingTier = 42;
    o.maximumBytesBilled = 'foo';
    o.parameterMode = 'foo';
    o.preserveNulls = true;
    o.priority = 'foo';
    o.query = 'foo';
    o.queryParameters = buildUnnamed1506();
    o.rangePartitioning = buildRangePartitioning();
    o.schemaUpdateOptions = buildUnnamed1507();
    o.tableDefinitions = buildUnnamed1508();
    o.timePartitioning = buildTimePartitioning();
    o.useLegacySql = true;
    o.useQueryCache = true;
    o.userDefinedFunctionResources = buildUnnamed1509();
    o.writeDisposition = 'foo';
  }
  buildCounterJobConfigurationQuery--;
  return o;
}

void checkJobConfigurationQuery(api.JobConfigurationQuery o) {
  buildCounterJobConfigurationQuery++;
  if (buildCounterJobConfigurationQuery < 3) {
    unittest.expect(o.allowLargeResults!, unittest.isTrue);
    checkClustering(o.clustering! as api.Clustering);
    checkUnnamed1505(o.connectionProperties!);
    unittest.expect(
      o.createDisposition!,
      unittest.equals('foo'),
    );
    unittest.expect(o.createSession!, unittest.isTrue);
    checkDatasetReference(o.defaultDataset! as api.DatasetReference);
    checkEncryptionConfiguration(
        o.destinationEncryptionConfiguration! as api.EncryptionConfiguration);
    checkTableReference(o.destinationTable! as api.TableReference);
    unittest.expect(o.flattenResults!, unittest.isTrue);
    unittest.expect(
      o.maximumBillingTier!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maximumBytesBilled!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parameterMode!,
      unittest.equals('foo'),
    );
    unittest.expect(o.preserveNulls!, unittest.isTrue);
    unittest.expect(
      o.priority!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.query!,
      unittest.equals('foo'),
    );
    checkUnnamed1506(o.queryParameters!);
    checkRangePartitioning(o.rangePartitioning! as api.RangePartitioning);
    checkUnnamed1507(o.schemaUpdateOptions!);
    checkUnnamed1508(o.tableDefinitions!);
    checkTimePartitioning(o.timePartitioning! as api.TimePartitioning);
    unittest.expect(o.useLegacySql!, unittest.isTrue);
    unittest.expect(o.useQueryCache!, unittest.isTrue);
    checkUnnamed1509(o.userDefinedFunctionResources!);
    unittest.expect(
      o.writeDisposition!,
      unittest.equals('foo'),
    );
  }
  buildCounterJobConfigurationQuery--;
}

core.List<api.TableReference> buildUnnamed1510() {
  var o = <api.TableReference>[];
  o.add(buildTableReference());
  o.add(buildTableReference());
  return o;
}

void checkUnnamed1510(core.List<api.TableReference> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableReference(o[0] as api.TableReference);
  checkTableReference(o[1] as api.TableReference);
}

core.int buildCounterJobConfigurationTableCopy = 0;
api.JobConfigurationTableCopy buildJobConfigurationTableCopy() {
  var o = api.JobConfigurationTableCopy();
  buildCounterJobConfigurationTableCopy++;
  if (buildCounterJobConfigurationTableCopy < 3) {
    o.createDisposition = 'foo';
    o.destinationEncryptionConfiguration = buildEncryptionConfiguration();
    o.destinationExpirationTime = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
    o.destinationTable = buildTableReference();
    o.operationType = 'foo';
    o.sourceTable = buildTableReference();
    o.sourceTables = buildUnnamed1510();
    o.writeDisposition = 'foo';
  }
  buildCounterJobConfigurationTableCopy--;
  return o;
}

void checkJobConfigurationTableCopy(api.JobConfigurationTableCopy o) {
  buildCounterJobConfigurationTableCopy++;
  if (buildCounterJobConfigurationTableCopy < 3) {
    unittest.expect(
      o.createDisposition!,
      unittest.equals('foo'),
    );
    checkEncryptionConfiguration(
        o.destinationEncryptionConfiguration! as api.EncryptionConfiguration);
    var casted1 = (o.destinationExpirationTime!) as core.Map;
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
    checkTableReference(o.destinationTable! as api.TableReference);
    unittest.expect(
      o.operationType!,
      unittest.equals('foo'),
    );
    checkTableReference(o.sourceTable! as api.TableReference);
    checkUnnamed1510(o.sourceTables!);
    unittest.expect(
      o.writeDisposition!,
      unittest.equals('foo'),
    );
  }
  buildCounterJobConfigurationTableCopy--;
}

core.int buildCounterJobListJobs = 0;
api.JobListJobs buildJobListJobs() {
  var o = api.JobListJobs();
  buildCounterJobListJobs++;
  if (buildCounterJobListJobs < 3) {
    o.configuration = buildJobConfiguration();
    o.errorResult = buildErrorProto();
    o.id = 'foo';
    o.jobReference = buildJobReference();
    o.kind = 'foo';
    o.state = 'foo';
    o.statistics = buildJobStatistics();
    o.status = buildJobStatus();
    o.userEmail = 'foo';
  }
  buildCounterJobListJobs--;
  return o;
}

void checkJobListJobs(api.JobListJobs o) {
  buildCounterJobListJobs++;
  if (buildCounterJobListJobs < 3) {
    checkJobConfiguration(o.configuration! as api.JobConfiguration);
    checkErrorProto(o.errorResult! as api.ErrorProto);
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    checkJobReference(o.jobReference! as api.JobReference);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
    checkJobStatistics(o.statistics! as api.JobStatistics);
    checkJobStatus(o.status! as api.JobStatus);
    unittest.expect(
      o.userEmail!,
      unittest.equals('foo'),
    );
  }
  buildCounterJobListJobs--;
}

core.List<api.JobListJobs> buildUnnamed1511() {
  var o = <api.JobListJobs>[];
  o.add(buildJobListJobs());
  o.add(buildJobListJobs());
  return o;
}

void checkUnnamed1511(core.List<api.JobListJobs> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkJobListJobs(o[0] as api.JobListJobs);
  checkJobListJobs(o[1] as api.JobListJobs);
}

core.int buildCounterJobList = 0;
api.JobList buildJobList() {
  var o = api.JobList();
  buildCounterJobList++;
  if (buildCounterJobList < 3) {
    o.etag = 'foo';
    o.jobs = buildUnnamed1511();
    o.kind = 'foo';
    o.nextPageToken = 'foo';
  }
  buildCounterJobList--;
  return o;
}

void checkJobList(api.JobList o) {
  buildCounterJobList++;
  if (buildCounterJobList < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed1511(o.jobs!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterJobList--;
}

core.int buildCounterJobReference = 0;
api.JobReference buildJobReference() {
  var o = api.JobReference();
  buildCounterJobReference++;
  if (buildCounterJobReference < 3) {
    o.jobId = 'foo';
    o.location = 'foo';
    o.projectId = 'foo';
  }
  buildCounterJobReference--;
  return o;
}

void checkJobReference(api.JobReference o) {
  buildCounterJobReference++;
  if (buildCounterJobReference < 3) {
    unittest.expect(
      o.jobId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterJobReference--;
}

core.List<core.String> buildUnnamed1512() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1512(core.List<core.String> o) {
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

core.int buildCounterJobStatisticsReservationUsage = 0;
api.JobStatisticsReservationUsage buildJobStatisticsReservationUsage() {
  var o = api.JobStatisticsReservationUsage();
  buildCounterJobStatisticsReservationUsage++;
  if (buildCounterJobStatisticsReservationUsage < 3) {
    o.name = 'foo';
    o.slotMs = 'foo';
  }
  buildCounterJobStatisticsReservationUsage--;
  return o;
}

void checkJobStatisticsReservationUsage(api.JobStatisticsReservationUsage o) {
  buildCounterJobStatisticsReservationUsage++;
  if (buildCounterJobStatisticsReservationUsage < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.slotMs!,
      unittest.equals('foo'),
    );
  }
  buildCounterJobStatisticsReservationUsage--;
}

core.List<api.JobStatisticsReservationUsage> buildUnnamed1513() {
  var o = <api.JobStatisticsReservationUsage>[];
  o.add(buildJobStatisticsReservationUsage());
  o.add(buildJobStatisticsReservationUsage());
  return o;
}

void checkUnnamed1513(core.List<api.JobStatisticsReservationUsage> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkJobStatisticsReservationUsage(o[0] as api.JobStatisticsReservationUsage);
  checkJobStatisticsReservationUsage(o[1] as api.JobStatisticsReservationUsage);
}

core.int buildCounterJobStatistics = 0;
api.JobStatistics buildJobStatistics() {
  var o = api.JobStatistics();
  buildCounterJobStatistics++;
  if (buildCounterJobStatistics < 3) {
    o.completionRatio = 42.0;
    o.creationTime = 'foo';
    o.endTime = 'foo';
    o.extract = buildJobStatistics4();
    o.load = buildJobStatistics3();
    o.numChildJobs = 'foo';
    o.parentJobId = 'foo';
    o.query = buildJobStatistics2();
    o.quotaDeferments = buildUnnamed1512();
    o.reservationUsage = buildUnnamed1513();
    o.reservationId = 'foo';
    o.rowLevelSecurityStatistics = buildRowLevelSecurityStatistics();
    o.scriptStatistics = buildScriptStatistics();
    o.sessionInfoTemplate = buildSessionInfo();
    o.startTime = 'foo';
    o.totalBytesProcessed = 'foo';
    o.totalSlotMs = 'foo';
    o.transactionInfoTemplate = buildTransactionInfo();
  }
  buildCounterJobStatistics--;
  return o;
}

void checkJobStatistics(api.JobStatistics o) {
  buildCounterJobStatistics++;
  if (buildCounterJobStatistics < 3) {
    unittest.expect(
      o.completionRatio!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    checkJobStatistics4(o.extract! as api.JobStatistics4);
    checkJobStatistics3(o.load! as api.JobStatistics3);
    unittest.expect(
      o.numChildJobs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parentJobId!,
      unittest.equals('foo'),
    );
    checkJobStatistics2(o.query! as api.JobStatistics2);
    checkUnnamed1512(o.quotaDeferments!);
    checkUnnamed1513(o.reservationUsage!);
    unittest.expect(
      o.reservationId!,
      unittest.equals('foo'),
    );
    checkRowLevelSecurityStatistics(
        o.rowLevelSecurityStatistics! as api.RowLevelSecurityStatistics);
    checkScriptStatistics(o.scriptStatistics! as api.ScriptStatistics);
    checkSessionInfo(o.sessionInfoTemplate! as api.SessionInfo);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalBytesProcessed!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSlotMs!,
      unittest.equals('foo'),
    );
    checkTransactionInfo(o.transactionInfoTemplate! as api.TransactionInfo);
  }
  buildCounterJobStatistics--;
}

core.List<api.ExplainQueryStage> buildUnnamed1514() {
  var o = <api.ExplainQueryStage>[];
  o.add(buildExplainQueryStage());
  o.add(buildExplainQueryStage());
  return o;
}

void checkUnnamed1514(core.List<api.ExplainQueryStage> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkExplainQueryStage(o[0] as api.ExplainQueryStage);
  checkExplainQueryStage(o[1] as api.ExplainQueryStage);
}

core.List<api.RoutineReference> buildUnnamed1515() {
  var o = <api.RoutineReference>[];
  o.add(buildRoutineReference());
  o.add(buildRoutineReference());
  return o;
}

void checkUnnamed1515(core.List<api.RoutineReference> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRoutineReference(o[0] as api.RoutineReference);
  checkRoutineReference(o[1] as api.RoutineReference);
}

core.List<api.TableReference> buildUnnamed1516() {
  var o = <api.TableReference>[];
  o.add(buildTableReference());
  o.add(buildTableReference());
  return o;
}

void checkUnnamed1516(core.List<api.TableReference> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableReference(o[0] as api.TableReference);
  checkTableReference(o[1] as api.TableReference);
}

core.int buildCounterJobStatistics2ReservationUsage = 0;
api.JobStatistics2ReservationUsage buildJobStatistics2ReservationUsage() {
  var o = api.JobStatistics2ReservationUsage();
  buildCounterJobStatistics2ReservationUsage++;
  if (buildCounterJobStatistics2ReservationUsage < 3) {
    o.name = 'foo';
    o.slotMs = 'foo';
  }
  buildCounterJobStatistics2ReservationUsage--;
  return o;
}

void checkJobStatistics2ReservationUsage(api.JobStatistics2ReservationUsage o) {
  buildCounterJobStatistics2ReservationUsage++;
  if (buildCounterJobStatistics2ReservationUsage < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.slotMs!,
      unittest.equals('foo'),
    );
  }
  buildCounterJobStatistics2ReservationUsage--;
}

core.List<api.JobStatistics2ReservationUsage> buildUnnamed1517() {
  var o = <api.JobStatistics2ReservationUsage>[];
  o.add(buildJobStatistics2ReservationUsage());
  o.add(buildJobStatistics2ReservationUsage());
  return o;
}

void checkUnnamed1517(core.List<api.JobStatistics2ReservationUsage> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkJobStatistics2ReservationUsage(
      o[0] as api.JobStatistics2ReservationUsage);
  checkJobStatistics2ReservationUsage(
      o[1] as api.JobStatistics2ReservationUsage);
}

core.List<api.QueryTimelineSample> buildUnnamed1518() {
  var o = <api.QueryTimelineSample>[];
  o.add(buildQueryTimelineSample());
  o.add(buildQueryTimelineSample());
  return o;
}

void checkUnnamed1518(core.List<api.QueryTimelineSample> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkQueryTimelineSample(o[0] as api.QueryTimelineSample);
  checkQueryTimelineSample(o[1] as api.QueryTimelineSample);
}

core.List<api.QueryParameter> buildUnnamed1519() {
  var o = <api.QueryParameter>[];
  o.add(buildQueryParameter());
  o.add(buildQueryParameter());
  return o;
}

void checkUnnamed1519(core.List<api.QueryParameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkQueryParameter(o[0] as api.QueryParameter);
  checkQueryParameter(o[1] as api.QueryParameter);
}

core.int buildCounterJobStatistics2 = 0;
api.JobStatistics2 buildJobStatistics2() {
  var o = api.JobStatistics2();
  buildCounterJobStatistics2++;
  if (buildCounterJobStatistics2 < 3) {
    o.billingTier = 42;
    o.cacheHit = true;
    o.ddlAffectedRowAccessPolicyCount = 'foo';
    o.ddlDestinationTable = buildTableReference();
    o.ddlOperationPerformed = 'foo';
    o.ddlTargetDataset = buildDatasetReference();
    o.ddlTargetRoutine = buildRoutineReference();
    o.ddlTargetRowAccessPolicy = buildRowAccessPolicyReference();
    o.ddlTargetTable = buildTableReference();
    o.estimatedBytesProcessed = 'foo';
    o.modelTraining = buildBigQueryModelTraining();
    o.modelTrainingCurrentIteration = 42;
    o.modelTrainingExpectedTotalIteration = 'foo';
    o.numDmlAffectedRows = 'foo';
    o.queryPlan = buildUnnamed1514();
    o.referencedRoutines = buildUnnamed1515();
    o.referencedTables = buildUnnamed1516();
    o.reservationUsage = buildUnnamed1517();
    o.schema = buildTableSchema();
    o.statementType = 'foo';
    o.timeline = buildUnnamed1518();
    o.totalBytesBilled = 'foo';
    o.totalBytesProcessed = 'foo';
    o.totalBytesProcessedAccuracy = 'foo';
    o.totalPartitionsProcessed = 'foo';
    o.totalSlotMs = 'foo';
    o.undeclaredQueryParameters = buildUnnamed1519();
  }
  buildCounterJobStatistics2--;
  return o;
}

void checkJobStatistics2(api.JobStatistics2 o) {
  buildCounterJobStatistics2++;
  if (buildCounterJobStatistics2 < 3) {
    unittest.expect(
      o.billingTier!,
      unittest.equals(42),
    );
    unittest.expect(o.cacheHit!, unittest.isTrue);
    unittest.expect(
      o.ddlAffectedRowAccessPolicyCount!,
      unittest.equals('foo'),
    );
    checkTableReference(o.ddlDestinationTable! as api.TableReference);
    unittest.expect(
      o.ddlOperationPerformed!,
      unittest.equals('foo'),
    );
    checkDatasetReference(o.ddlTargetDataset! as api.DatasetReference);
    checkRoutineReference(o.ddlTargetRoutine! as api.RoutineReference);
    checkRowAccessPolicyReference(
        o.ddlTargetRowAccessPolicy! as api.RowAccessPolicyReference);
    checkTableReference(o.ddlTargetTable! as api.TableReference);
    unittest.expect(
      o.estimatedBytesProcessed!,
      unittest.equals('foo'),
    );
    checkBigQueryModelTraining(o.modelTraining! as api.BigQueryModelTraining);
    unittest.expect(
      o.modelTrainingCurrentIteration!,
      unittest.equals(42),
    );
    unittest.expect(
      o.modelTrainingExpectedTotalIteration!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numDmlAffectedRows!,
      unittest.equals('foo'),
    );
    checkUnnamed1514(o.queryPlan!);
    checkUnnamed1515(o.referencedRoutines!);
    checkUnnamed1516(o.referencedTables!);
    checkUnnamed1517(o.reservationUsage!);
    checkTableSchema(o.schema! as api.TableSchema);
    unittest.expect(
      o.statementType!,
      unittest.equals('foo'),
    );
    checkUnnamed1518(o.timeline!);
    unittest.expect(
      o.totalBytesBilled!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalBytesProcessed!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalBytesProcessedAccuracy!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalPartitionsProcessed!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSlotMs!,
      unittest.equals('foo'),
    );
    checkUnnamed1519(o.undeclaredQueryParameters!);
  }
  buildCounterJobStatistics2--;
}

core.int buildCounterJobStatistics3 = 0;
api.JobStatistics3 buildJobStatistics3() {
  var o = api.JobStatistics3();
  buildCounterJobStatistics3++;
  if (buildCounterJobStatistics3 < 3) {
    o.badRecords = 'foo';
    o.inputFileBytes = 'foo';
    o.inputFiles = 'foo';
    o.outputBytes = 'foo';
    o.outputRows = 'foo';
  }
  buildCounterJobStatistics3--;
  return o;
}

void checkJobStatistics3(api.JobStatistics3 o) {
  buildCounterJobStatistics3++;
  if (buildCounterJobStatistics3 < 3) {
    unittest.expect(
      o.badRecords!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inputFileBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.inputFiles!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.outputBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.outputRows!,
      unittest.equals('foo'),
    );
  }
  buildCounterJobStatistics3--;
}

core.List<core.String> buildUnnamed1520() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1520(core.List<core.String> o) {
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

core.int buildCounterJobStatistics4 = 0;
api.JobStatistics4 buildJobStatistics4() {
  var o = api.JobStatistics4();
  buildCounterJobStatistics4++;
  if (buildCounterJobStatistics4 < 3) {
    o.destinationUriFileCounts = buildUnnamed1520();
    o.inputBytes = 'foo';
  }
  buildCounterJobStatistics4--;
  return o;
}

void checkJobStatistics4(api.JobStatistics4 o) {
  buildCounterJobStatistics4++;
  if (buildCounterJobStatistics4 < 3) {
    checkUnnamed1520(o.destinationUriFileCounts!);
    unittest.expect(
      o.inputBytes!,
      unittest.equals('foo'),
    );
  }
  buildCounterJobStatistics4--;
}

core.List<api.ErrorProto> buildUnnamed1521() {
  var o = <api.ErrorProto>[];
  o.add(buildErrorProto());
  o.add(buildErrorProto());
  return o;
}

void checkUnnamed1521(core.List<api.ErrorProto> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkErrorProto(o[0] as api.ErrorProto);
  checkErrorProto(o[1] as api.ErrorProto);
}

core.int buildCounterJobStatus = 0;
api.JobStatus buildJobStatus() {
  var o = api.JobStatus();
  buildCounterJobStatus++;
  if (buildCounterJobStatus < 3) {
    o.errorResult = buildErrorProto();
    o.errors = buildUnnamed1521();
    o.state = 'foo';
  }
  buildCounterJobStatus--;
  return o;
}

void checkJobStatus(api.JobStatus o) {
  buildCounterJobStatus++;
  if (buildCounterJobStatus < 3) {
    checkErrorProto(o.errorResult! as api.ErrorProto);
    checkUnnamed1521(o.errors!);
    unittest.expect(
      o.state!,
      unittest.equals('foo'),
    );
  }
  buildCounterJobStatus--;
}

api.JsonObject buildJsonObject() {
  var o = api.JsonObject();
  o["a"] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  o["b"] = {
    'list': [1, 2, 3],
    'bool': true,
    'string': 'foo'
  };
  return o;
}

void checkJsonObject(api.JsonObject o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted2 = (o["a"]!) as core.Map;
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
  var casted3 = (o["b"]!) as core.Map;
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

core.List<api.Model> buildUnnamed1522() {
  var o = <api.Model>[];
  o.add(buildModel());
  o.add(buildModel());
  return o;
}

void checkUnnamed1522(core.List<api.Model> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkModel(o[0] as api.Model);
  checkModel(o[1] as api.Model);
}

core.int buildCounterListModelsResponse = 0;
api.ListModelsResponse buildListModelsResponse() {
  var o = api.ListModelsResponse();
  buildCounterListModelsResponse++;
  if (buildCounterListModelsResponse < 3) {
    o.models = buildUnnamed1522();
    o.nextPageToken = 'foo';
  }
  buildCounterListModelsResponse--;
  return o;
}

void checkListModelsResponse(api.ListModelsResponse o) {
  buildCounterListModelsResponse++;
  if (buildCounterListModelsResponse < 3) {
    checkUnnamed1522(o.models!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListModelsResponse--;
}

core.List<api.Routine> buildUnnamed1523() {
  var o = <api.Routine>[];
  o.add(buildRoutine());
  o.add(buildRoutine());
  return o;
}

void checkUnnamed1523(core.List<api.Routine> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRoutine(o[0] as api.Routine);
  checkRoutine(o[1] as api.Routine);
}

core.int buildCounterListRoutinesResponse = 0;
api.ListRoutinesResponse buildListRoutinesResponse() {
  var o = api.ListRoutinesResponse();
  buildCounterListRoutinesResponse++;
  if (buildCounterListRoutinesResponse < 3) {
    o.nextPageToken = 'foo';
    o.routines = buildUnnamed1523();
  }
  buildCounterListRoutinesResponse--;
  return o;
}

void checkListRoutinesResponse(api.ListRoutinesResponse o) {
  buildCounterListRoutinesResponse++;
  if (buildCounterListRoutinesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1523(o.routines!);
  }
  buildCounterListRoutinesResponse--;
}

core.List<api.RowAccessPolicy> buildUnnamed1524() {
  var o = <api.RowAccessPolicy>[];
  o.add(buildRowAccessPolicy());
  o.add(buildRowAccessPolicy());
  return o;
}

void checkUnnamed1524(core.List<api.RowAccessPolicy> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkRowAccessPolicy(o[0] as api.RowAccessPolicy);
  checkRowAccessPolicy(o[1] as api.RowAccessPolicy);
}

core.int buildCounterListRowAccessPoliciesResponse = 0;
api.ListRowAccessPoliciesResponse buildListRowAccessPoliciesResponse() {
  var o = api.ListRowAccessPoliciesResponse();
  buildCounterListRowAccessPoliciesResponse++;
  if (buildCounterListRowAccessPoliciesResponse < 3) {
    o.nextPageToken = 'foo';
    o.rowAccessPolicies = buildUnnamed1524();
  }
  buildCounterListRowAccessPoliciesResponse--;
  return o;
}

void checkListRowAccessPoliciesResponse(api.ListRowAccessPoliciesResponse o) {
  buildCounterListRowAccessPoliciesResponse++;
  if (buildCounterListRowAccessPoliciesResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1524(o.rowAccessPolicies!);
  }
  buildCounterListRowAccessPoliciesResponse--;
}

core.int buildCounterLocationMetadata = 0;
api.LocationMetadata buildLocationMetadata() {
  var o = api.LocationMetadata();
  buildCounterLocationMetadata++;
  if (buildCounterLocationMetadata < 3) {
    o.legacyLocationId = 'foo';
  }
  buildCounterLocationMetadata--;
  return o;
}

void checkLocationMetadata(api.LocationMetadata o) {
  buildCounterLocationMetadata++;
  if (buildCounterLocationMetadata < 3) {
    unittest.expect(
      o.legacyLocationId!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocationMetadata--;
}

core.int buildCounterMaterializedViewDefinition = 0;
api.MaterializedViewDefinition buildMaterializedViewDefinition() {
  var o = api.MaterializedViewDefinition();
  buildCounterMaterializedViewDefinition++;
  if (buildCounterMaterializedViewDefinition < 3) {
    o.enableRefresh = true;
    o.lastRefreshTime = 'foo';
    o.query = 'foo';
    o.refreshIntervalMs = 'foo';
  }
  buildCounterMaterializedViewDefinition--;
  return o;
}

void checkMaterializedViewDefinition(api.MaterializedViewDefinition o) {
  buildCounterMaterializedViewDefinition++;
  if (buildCounterMaterializedViewDefinition < 3) {
    unittest.expect(o.enableRefresh!, unittest.isTrue);
    unittest.expect(
      o.lastRefreshTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.query!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.refreshIntervalMs!,
      unittest.equals('foo'),
    );
  }
  buildCounterMaterializedViewDefinition--;
}

core.List<api.StandardSqlField> buildUnnamed1525() {
  var o = <api.StandardSqlField>[];
  o.add(buildStandardSqlField());
  o.add(buildStandardSqlField());
  return o;
}

void checkUnnamed1525(core.List<api.StandardSqlField> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStandardSqlField(o[0] as api.StandardSqlField);
  checkStandardSqlField(o[1] as api.StandardSqlField);
}

core.List<api.StandardSqlField> buildUnnamed1526() {
  var o = <api.StandardSqlField>[];
  o.add(buildStandardSqlField());
  o.add(buildStandardSqlField());
  return o;
}

void checkUnnamed1526(core.List<api.StandardSqlField> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStandardSqlField(o[0] as api.StandardSqlField);
  checkStandardSqlField(o[1] as api.StandardSqlField);
}

core.Map<core.String, core.String> buildUnnamed1527() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed1527(core.Map<core.String, core.String> o) {
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

core.List<api.TrainingRun> buildUnnamed1528() {
  var o = <api.TrainingRun>[];
  o.add(buildTrainingRun());
  o.add(buildTrainingRun());
  return o;
}

void checkUnnamed1528(core.List<api.TrainingRun> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTrainingRun(o[0] as api.TrainingRun);
  checkTrainingRun(o[1] as api.TrainingRun);
}

core.int buildCounterModel = 0;
api.Model buildModel() {
  var o = api.Model();
  buildCounterModel++;
  if (buildCounterModel < 3) {
    o.bestTrialId = 'foo';
    o.creationTime = 'foo';
    o.description = 'foo';
    o.encryptionConfiguration = buildEncryptionConfiguration();
    o.etag = 'foo';
    o.expirationTime = 'foo';
    o.featureColumns = buildUnnamed1525();
    o.friendlyName = 'foo';
    o.labelColumns = buildUnnamed1526();
    o.labels = buildUnnamed1527();
    o.lastModifiedTime = 'foo';
    o.location = 'foo';
    o.modelReference = buildModelReference();
    o.modelType = 'foo';
    o.trainingRuns = buildUnnamed1528();
  }
  buildCounterModel--;
  return o;
}

void checkModel(api.Model o) {
  buildCounterModel++;
  if (buildCounterModel < 3) {
    unittest.expect(
      o.bestTrialId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkEncryptionConfiguration(
        o.encryptionConfiguration! as api.EncryptionConfiguration);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expirationTime!,
      unittest.equals('foo'),
    );
    checkUnnamed1525(o.featureColumns!);
    unittest.expect(
      o.friendlyName!,
      unittest.equals('foo'),
    );
    checkUnnamed1526(o.labelColumns!);
    checkUnnamed1527(o.labels!);
    unittest.expect(
      o.lastModifiedTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    checkModelReference(o.modelReference! as api.ModelReference);
    unittest.expect(
      o.modelType!,
      unittest.equals('foo'),
    );
    checkUnnamed1528(o.trainingRuns!);
  }
  buildCounterModel--;
}

core.List<core.String> buildUnnamed1529() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1529(core.List<core.String> o) {
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

core.int buildCounterModelDefinitionModelOptions = 0;
api.ModelDefinitionModelOptions buildModelDefinitionModelOptions() {
  var o = api.ModelDefinitionModelOptions();
  buildCounterModelDefinitionModelOptions++;
  if (buildCounterModelDefinitionModelOptions < 3) {
    o.labels = buildUnnamed1529();
    o.lossType = 'foo';
    o.modelType = 'foo';
  }
  buildCounterModelDefinitionModelOptions--;
  return o;
}

void checkModelDefinitionModelOptions(api.ModelDefinitionModelOptions o) {
  buildCounterModelDefinitionModelOptions++;
  if (buildCounterModelDefinitionModelOptions < 3) {
    checkUnnamed1529(o.labels!);
    unittest.expect(
      o.lossType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.modelType!,
      unittest.equals('foo'),
    );
  }
  buildCounterModelDefinitionModelOptions--;
}

core.List<api.BqmlTrainingRun> buildUnnamed1530() {
  var o = <api.BqmlTrainingRun>[];
  o.add(buildBqmlTrainingRun());
  o.add(buildBqmlTrainingRun());
  return o;
}

void checkUnnamed1530(core.List<api.BqmlTrainingRun> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBqmlTrainingRun(o[0] as api.BqmlTrainingRun);
  checkBqmlTrainingRun(o[1] as api.BqmlTrainingRun);
}

core.int buildCounterModelDefinition = 0;
api.ModelDefinition buildModelDefinition() {
  var o = api.ModelDefinition();
  buildCounterModelDefinition++;
  if (buildCounterModelDefinition < 3) {
    o.modelOptions = buildModelDefinitionModelOptions();
    o.trainingRuns = buildUnnamed1530();
  }
  buildCounterModelDefinition--;
  return o;
}

void checkModelDefinition(api.ModelDefinition o) {
  buildCounterModelDefinition++;
  if (buildCounterModelDefinition < 3) {
    checkModelDefinitionModelOptions(
        o.modelOptions! as api.ModelDefinitionModelOptions);
    checkUnnamed1530(o.trainingRuns!);
  }
  buildCounterModelDefinition--;
}

core.int buildCounterModelReference = 0;
api.ModelReference buildModelReference() {
  var o = api.ModelReference();
  buildCounterModelReference++;
  if (buildCounterModelReference < 3) {
    o.datasetId = 'foo';
    o.modelId = 'foo';
    o.projectId = 'foo';
  }
  buildCounterModelReference--;
  return o;
}

void checkModelReference(api.ModelReference o) {
  buildCounterModelReference++;
  if (buildCounterModelReference < 3) {
    unittest.expect(
      o.datasetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.modelId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterModelReference--;
}

core.List<api.ConfusionMatrix> buildUnnamed1531() {
  var o = <api.ConfusionMatrix>[];
  o.add(buildConfusionMatrix());
  o.add(buildConfusionMatrix());
  return o;
}

void checkUnnamed1531(core.List<api.ConfusionMatrix> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConfusionMatrix(o[0] as api.ConfusionMatrix);
  checkConfusionMatrix(o[1] as api.ConfusionMatrix);
}

core.int buildCounterMultiClassClassificationMetrics = 0;
api.MultiClassClassificationMetrics buildMultiClassClassificationMetrics() {
  var o = api.MultiClassClassificationMetrics();
  buildCounterMultiClassClassificationMetrics++;
  if (buildCounterMultiClassClassificationMetrics < 3) {
    o.aggregateClassificationMetrics = buildAggregateClassificationMetrics();
    o.confusionMatrixList = buildUnnamed1531();
  }
  buildCounterMultiClassClassificationMetrics--;
  return o;
}

void checkMultiClassClassificationMetrics(
    api.MultiClassClassificationMetrics o) {
  buildCounterMultiClassClassificationMetrics++;
  if (buildCounterMultiClassClassificationMetrics < 3) {
    checkAggregateClassificationMetrics(o.aggregateClassificationMetrics!
        as api.AggregateClassificationMetrics);
    checkUnnamed1531(o.confusionMatrixList!);
  }
  buildCounterMultiClassClassificationMetrics--;
}

core.int buildCounterParquetOptions = 0;
api.ParquetOptions buildParquetOptions() {
  var o = api.ParquetOptions();
  buildCounterParquetOptions++;
  if (buildCounterParquetOptions < 3) {
    o.enableListInference = true;
    o.enumAsString = true;
  }
  buildCounterParquetOptions--;
  return o;
}

void checkParquetOptions(api.ParquetOptions o) {
  buildCounterParquetOptions++;
  if (buildCounterParquetOptions < 3) {
    unittest.expect(o.enableListInference!, unittest.isTrue);
    unittest.expect(o.enumAsString!, unittest.isTrue);
  }
  buildCounterParquetOptions--;
}

core.List<api.AuditConfig> buildUnnamed1532() {
  var o = <api.AuditConfig>[];
  o.add(buildAuditConfig());
  o.add(buildAuditConfig());
  return o;
}

void checkUnnamed1532(core.List<api.AuditConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAuditConfig(o[0] as api.AuditConfig);
  checkAuditConfig(o[1] as api.AuditConfig);
}

core.List<api.Binding> buildUnnamed1533() {
  var o = <api.Binding>[];
  o.add(buildBinding());
  o.add(buildBinding());
  return o;
}

void checkUnnamed1533(core.List<api.Binding> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkBinding(o[0] as api.Binding);
  checkBinding(o[1] as api.Binding);
}

core.int buildCounterPolicy = 0;
api.Policy buildPolicy() {
  var o = api.Policy();
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    o.auditConfigs = buildUnnamed1532();
    o.bindings = buildUnnamed1533();
    o.etag = 'foo';
    o.version = 42;
  }
  buildCounterPolicy--;
  return o;
}

void checkPolicy(api.Policy o) {
  buildCounterPolicy++;
  if (buildCounterPolicy < 3) {
    checkUnnamed1532(o.auditConfigs!);
    checkUnnamed1533(o.bindings!);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.version!,
      unittest.equals(42),
    );
  }
  buildCounterPolicy--;
}

core.int buildCounterProjectListProjects = 0;
api.ProjectListProjects buildProjectListProjects() {
  var o = api.ProjectListProjects();
  buildCounterProjectListProjects++;
  if (buildCounterProjectListProjects < 3) {
    o.friendlyName = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.numericId = 'foo';
    o.projectReference = buildProjectReference();
  }
  buildCounterProjectListProjects--;
  return o;
}

void checkProjectListProjects(api.ProjectListProjects o) {
  buildCounterProjectListProjects++;
  if (buildCounterProjectListProjects < 3) {
    unittest.expect(
      o.friendlyName!,
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
    unittest.expect(
      o.numericId!,
      unittest.equals('foo'),
    );
    checkProjectReference(o.projectReference! as api.ProjectReference);
  }
  buildCounterProjectListProjects--;
}

core.List<api.ProjectListProjects> buildUnnamed1534() {
  var o = <api.ProjectListProjects>[];
  o.add(buildProjectListProjects());
  o.add(buildProjectListProjects());
  return o;
}

void checkUnnamed1534(core.List<api.ProjectListProjects> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkProjectListProjects(o[0] as api.ProjectListProjects);
  checkProjectListProjects(o[1] as api.ProjectListProjects);
}

core.int buildCounterProjectList = 0;
api.ProjectList buildProjectList() {
  var o = api.ProjectList();
  buildCounterProjectList++;
  if (buildCounterProjectList < 3) {
    o.etag = 'foo';
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.projects = buildUnnamed1534();
    o.totalItems = 42;
  }
  buildCounterProjectList--;
  return o;
}

void checkProjectList(api.ProjectList o) {
  buildCounterProjectList++;
  if (buildCounterProjectList < 3) {
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
    checkUnnamed1534(o.projects!);
    unittest.expect(
      o.totalItems!,
      unittest.equals(42),
    );
  }
  buildCounterProjectList--;
}

core.int buildCounterProjectReference = 0;
api.ProjectReference buildProjectReference() {
  var o = api.ProjectReference();
  buildCounterProjectReference++;
  if (buildCounterProjectReference < 3) {
    o.projectId = 'foo';
  }
  buildCounterProjectReference--;
  return o;
}

void checkProjectReference(api.ProjectReference o) {
  buildCounterProjectReference++;
  if (buildCounterProjectReference < 3) {
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
  }
  buildCounterProjectReference--;
}

core.int buildCounterQueryParameter = 0;
api.QueryParameter buildQueryParameter() {
  var o = api.QueryParameter();
  buildCounterQueryParameter++;
  if (buildCounterQueryParameter < 3) {
    o.name = 'foo';
    o.parameterType = buildQueryParameterType();
    o.parameterValue = buildQueryParameterValue();
  }
  buildCounterQueryParameter--;
  return o;
}

void checkQueryParameter(api.QueryParameter o) {
  buildCounterQueryParameter++;
  if (buildCounterQueryParameter < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkQueryParameterType(o.parameterType! as api.QueryParameterType);
    checkQueryParameterValue(o.parameterValue! as api.QueryParameterValue);
  }
  buildCounterQueryParameter--;
}

core.int buildCounterQueryParameterTypeStructTypes = 0;
api.QueryParameterTypeStructTypes buildQueryParameterTypeStructTypes() {
  var o = api.QueryParameterTypeStructTypes();
  buildCounterQueryParameterTypeStructTypes++;
  if (buildCounterQueryParameterTypeStructTypes < 3) {
    o.description = 'foo';
    o.name = 'foo';
    o.type = buildQueryParameterType();
  }
  buildCounterQueryParameterTypeStructTypes--;
  return o;
}

void checkQueryParameterTypeStructTypes(api.QueryParameterTypeStructTypes o) {
  buildCounterQueryParameterTypeStructTypes++;
  if (buildCounterQueryParameterTypeStructTypes < 3) {
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkQueryParameterType(o.type! as api.QueryParameterType);
  }
  buildCounterQueryParameterTypeStructTypes--;
}

core.List<api.QueryParameterTypeStructTypes> buildUnnamed1535() {
  var o = <api.QueryParameterTypeStructTypes>[];
  o.add(buildQueryParameterTypeStructTypes());
  o.add(buildQueryParameterTypeStructTypes());
  return o;
}

void checkUnnamed1535(core.List<api.QueryParameterTypeStructTypes> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkQueryParameterTypeStructTypes(o[0] as api.QueryParameterTypeStructTypes);
  checkQueryParameterTypeStructTypes(o[1] as api.QueryParameterTypeStructTypes);
}

core.int buildCounterQueryParameterType = 0;
api.QueryParameterType buildQueryParameterType() {
  var o = api.QueryParameterType();
  buildCounterQueryParameterType++;
  if (buildCounterQueryParameterType < 3) {
    o.arrayType = buildQueryParameterType();
    o.structTypes = buildUnnamed1535();
    o.type = 'foo';
  }
  buildCounterQueryParameterType--;
  return o;
}

void checkQueryParameterType(api.QueryParameterType o) {
  buildCounterQueryParameterType++;
  if (buildCounterQueryParameterType < 3) {
    checkQueryParameterType(o.arrayType! as api.QueryParameterType);
    checkUnnamed1535(o.structTypes!);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterQueryParameterType--;
}

core.List<api.QueryParameterValue> buildUnnamed1536() {
  var o = <api.QueryParameterValue>[];
  o.add(buildQueryParameterValue());
  o.add(buildQueryParameterValue());
  return o;
}

void checkUnnamed1536(core.List<api.QueryParameterValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkQueryParameterValue(o[0] as api.QueryParameterValue);
  checkQueryParameterValue(o[1] as api.QueryParameterValue);
}

core.Map<core.String, api.QueryParameterValue> buildUnnamed1537() {
  var o = <core.String, api.QueryParameterValue>{};
  o['x'] = buildQueryParameterValue();
  o['y'] = buildQueryParameterValue();
  return o;
}

void checkUnnamed1537(core.Map<core.String, api.QueryParameterValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkQueryParameterValue(o['x']! as api.QueryParameterValue);
  checkQueryParameterValue(o['y']! as api.QueryParameterValue);
}

core.int buildCounterQueryParameterValue = 0;
api.QueryParameterValue buildQueryParameterValue() {
  var o = api.QueryParameterValue();
  buildCounterQueryParameterValue++;
  if (buildCounterQueryParameterValue < 3) {
    o.arrayValues = buildUnnamed1536();
    o.structValues = buildUnnamed1537();
    o.value = 'foo';
  }
  buildCounterQueryParameterValue--;
  return o;
}

void checkQueryParameterValue(api.QueryParameterValue o) {
  buildCounterQueryParameterValue++;
  if (buildCounterQueryParameterValue < 3) {
    checkUnnamed1536(o.arrayValues!);
    checkUnnamed1537(o.structValues!);
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterQueryParameterValue--;
}

core.List<api.ConnectionProperty> buildUnnamed1538() {
  var o = <api.ConnectionProperty>[];
  o.add(buildConnectionProperty());
  o.add(buildConnectionProperty());
  return o;
}

void checkUnnamed1538(core.List<api.ConnectionProperty> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkConnectionProperty(o[0] as api.ConnectionProperty);
  checkConnectionProperty(o[1] as api.ConnectionProperty);
}

core.Map<core.String, core.String> buildUnnamed1539() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed1539(core.Map<core.String, core.String> o) {
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

core.List<api.QueryParameter> buildUnnamed1540() {
  var o = <api.QueryParameter>[];
  o.add(buildQueryParameter());
  o.add(buildQueryParameter());
  return o;
}

void checkUnnamed1540(core.List<api.QueryParameter> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkQueryParameter(o[0] as api.QueryParameter);
  checkQueryParameter(o[1] as api.QueryParameter);
}

core.int buildCounterQueryRequest = 0;
api.QueryRequest buildQueryRequest() {
  var o = api.QueryRequest();
  buildCounterQueryRequest++;
  if (buildCounterQueryRequest < 3) {
    o.connectionProperties = buildUnnamed1538();
    o.createSession = true;
    o.defaultDataset = buildDatasetReference();
    o.dryRun = true;
    o.kind = 'foo';
    o.labels = buildUnnamed1539();
    o.location = 'foo';
    o.maxResults = 42;
    o.maximumBytesBilled = 'foo';
    o.parameterMode = 'foo';
    o.preserveNulls = true;
    o.query = 'foo';
    o.queryParameters = buildUnnamed1540();
    o.requestId = 'foo';
    o.timeoutMs = 42;
    o.useLegacySql = true;
    o.useQueryCache = true;
  }
  buildCounterQueryRequest--;
  return o;
}

void checkQueryRequest(api.QueryRequest o) {
  buildCounterQueryRequest++;
  if (buildCounterQueryRequest < 3) {
    checkUnnamed1538(o.connectionProperties!);
    unittest.expect(o.createSession!, unittest.isTrue);
    checkDatasetReference(o.defaultDataset! as api.DatasetReference);
    unittest.expect(o.dryRun!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed1539(o.labels!);
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxResults!,
      unittest.equals(42),
    );
    unittest.expect(
      o.maximumBytesBilled!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parameterMode!,
      unittest.equals('foo'),
    );
    unittest.expect(o.preserveNulls!, unittest.isTrue);
    unittest.expect(
      o.query!,
      unittest.equals('foo'),
    );
    checkUnnamed1540(o.queryParameters!);
    unittest.expect(
      o.requestId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeoutMs!,
      unittest.equals(42),
    );
    unittest.expect(o.useLegacySql!, unittest.isTrue);
    unittest.expect(o.useQueryCache!, unittest.isTrue);
  }
  buildCounterQueryRequest--;
}

core.List<api.ErrorProto> buildUnnamed1541() {
  var o = <api.ErrorProto>[];
  o.add(buildErrorProto());
  o.add(buildErrorProto());
  return o;
}

void checkUnnamed1541(core.List<api.ErrorProto> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkErrorProto(o[0] as api.ErrorProto);
  checkErrorProto(o[1] as api.ErrorProto);
}

core.List<api.TableRow> buildUnnamed1542() {
  var o = <api.TableRow>[];
  o.add(buildTableRow());
  o.add(buildTableRow());
  return o;
}

void checkUnnamed1542(core.List<api.TableRow> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableRow(o[0] as api.TableRow);
  checkTableRow(o[1] as api.TableRow);
}

core.int buildCounterQueryResponse = 0;
api.QueryResponse buildQueryResponse() {
  var o = api.QueryResponse();
  buildCounterQueryResponse++;
  if (buildCounterQueryResponse < 3) {
    o.cacheHit = true;
    o.errors = buildUnnamed1541();
    o.jobComplete = true;
    o.jobReference = buildJobReference();
    o.kind = 'foo';
    o.numDmlAffectedRows = 'foo';
    o.pageToken = 'foo';
    o.rows = buildUnnamed1542();
    o.schema = buildTableSchema();
    o.sessionInfoTemplate = buildSessionInfo();
    o.totalBytesProcessed = 'foo';
    o.totalRows = 'foo';
  }
  buildCounterQueryResponse--;
  return o;
}

void checkQueryResponse(api.QueryResponse o) {
  buildCounterQueryResponse++;
  if (buildCounterQueryResponse < 3) {
    unittest.expect(o.cacheHit!, unittest.isTrue);
    checkUnnamed1541(o.errors!);
    unittest.expect(o.jobComplete!, unittest.isTrue);
    checkJobReference(o.jobReference! as api.JobReference);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numDmlAffectedRows!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1542(o.rows!);
    checkTableSchema(o.schema! as api.TableSchema);
    checkSessionInfo(o.sessionInfoTemplate! as api.SessionInfo);
    unittest.expect(
      o.totalBytesProcessed!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalRows!,
      unittest.equals('foo'),
    );
  }
  buildCounterQueryResponse--;
}

core.int buildCounterQueryTimelineSample = 0;
api.QueryTimelineSample buildQueryTimelineSample() {
  var o = api.QueryTimelineSample();
  buildCounterQueryTimelineSample++;
  if (buildCounterQueryTimelineSample < 3) {
    o.activeUnits = 'foo';
    o.completedUnits = 'foo';
    o.elapsedMs = 'foo';
    o.pendingUnits = 'foo';
    o.totalSlotMs = 'foo';
  }
  buildCounterQueryTimelineSample--;
  return o;
}

void checkQueryTimelineSample(api.QueryTimelineSample o) {
  buildCounterQueryTimelineSample++;
  if (buildCounterQueryTimelineSample < 3) {
    unittest.expect(
      o.activeUnits!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.completedUnits!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.elapsedMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pendingUnits!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.totalSlotMs!,
      unittest.equals('foo'),
    );
  }
  buildCounterQueryTimelineSample--;
}

core.int buildCounterRangePartitioningRange = 0;
api.RangePartitioningRange buildRangePartitioningRange() {
  var o = api.RangePartitioningRange();
  buildCounterRangePartitioningRange++;
  if (buildCounterRangePartitioningRange < 3) {
    o.end = 'foo';
    o.interval = 'foo';
    o.start = 'foo';
  }
  buildCounterRangePartitioningRange--;
  return o;
}

void checkRangePartitioningRange(api.RangePartitioningRange o) {
  buildCounterRangePartitioningRange++;
  if (buildCounterRangePartitioningRange < 3) {
    unittest.expect(
      o.end!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.interval!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.start!,
      unittest.equals('foo'),
    );
  }
  buildCounterRangePartitioningRange--;
}

core.int buildCounterRangePartitioning = 0;
api.RangePartitioning buildRangePartitioning() {
  var o = api.RangePartitioning();
  buildCounterRangePartitioning++;
  if (buildCounterRangePartitioning < 3) {
    o.field = 'foo';
    o.range = buildRangePartitioningRange();
  }
  buildCounterRangePartitioning--;
  return o;
}

void checkRangePartitioning(api.RangePartitioning o) {
  buildCounterRangePartitioning++;
  if (buildCounterRangePartitioning < 3) {
    unittest.expect(
      o.field!,
      unittest.equals('foo'),
    );
    checkRangePartitioningRange(o.range! as api.RangePartitioningRange);
  }
  buildCounterRangePartitioning--;
}

core.int buildCounterRankingMetrics = 0;
api.RankingMetrics buildRankingMetrics() {
  var o = api.RankingMetrics();
  buildCounterRankingMetrics++;
  if (buildCounterRankingMetrics < 3) {
    o.averageRank = 42.0;
    o.meanAveragePrecision = 42.0;
    o.meanSquaredError = 42.0;
    o.normalizedDiscountedCumulativeGain = 42.0;
  }
  buildCounterRankingMetrics--;
  return o;
}

void checkRankingMetrics(api.RankingMetrics o) {
  buildCounterRankingMetrics++;
  if (buildCounterRankingMetrics < 3) {
    unittest.expect(
      o.averageRank!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.meanAveragePrecision!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.meanSquaredError!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.normalizedDiscountedCumulativeGain!,
      unittest.equals(42.0),
    );
  }
  buildCounterRankingMetrics--;
}

core.int buildCounterRegressionMetrics = 0;
api.RegressionMetrics buildRegressionMetrics() {
  var o = api.RegressionMetrics();
  buildCounterRegressionMetrics++;
  if (buildCounterRegressionMetrics < 3) {
    o.meanAbsoluteError = 42.0;
    o.meanSquaredError = 42.0;
    o.meanSquaredLogError = 42.0;
    o.medianAbsoluteError = 42.0;
    o.rSquared = 42.0;
  }
  buildCounterRegressionMetrics--;
  return o;
}

void checkRegressionMetrics(api.RegressionMetrics o) {
  buildCounterRegressionMetrics++;
  if (buildCounterRegressionMetrics < 3) {
    unittest.expect(
      o.meanAbsoluteError!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.meanSquaredError!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.meanSquaredLogError!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.medianAbsoluteError!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.rSquared!,
      unittest.equals(42.0),
    );
  }
  buildCounterRegressionMetrics--;
}

core.List<api.Argument> buildUnnamed1543() {
  var o = <api.Argument>[];
  o.add(buildArgument());
  o.add(buildArgument());
  return o;
}

void checkUnnamed1543(core.List<api.Argument> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkArgument(o[0] as api.Argument);
  checkArgument(o[1] as api.Argument);
}

core.List<core.String> buildUnnamed1544() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1544(core.List<core.String> o) {
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

core.int buildCounterRoutine = 0;
api.Routine buildRoutine() {
  var o = api.Routine();
  buildCounterRoutine++;
  if (buildCounterRoutine < 3) {
    o.arguments = buildUnnamed1543();
    o.creationTime = 'foo';
    o.definitionBody = 'foo';
    o.description = 'foo';
    o.determinismLevel = 'foo';
    o.etag = 'foo';
    o.importedLibraries = buildUnnamed1544();
    o.language = 'foo';
    o.lastModifiedTime = 'foo';
    o.returnTableType = buildStandardSqlTableType();
    o.returnType = buildStandardSqlDataType();
    o.routineReference = buildRoutineReference();
    o.routineType = 'foo';
  }
  buildCounterRoutine--;
  return o;
}

void checkRoutine(api.Routine o) {
  buildCounterRoutine++;
  if (buildCounterRoutine < 3) {
    checkUnnamed1543(o.arguments!);
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.definitionBody!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.determinismLevel!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    checkUnnamed1544(o.importedLibraries!);
    unittest.expect(
      o.language!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastModifiedTime!,
      unittest.equals('foo'),
    );
    checkStandardSqlTableType(o.returnTableType! as api.StandardSqlTableType);
    checkStandardSqlDataType(o.returnType! as api.StandardSqlDataType);
    checkRoutineReference(o.routineReference! as api.RoutineReference);
    unittest.expect(
      o.routineType!,
      unittest.equals('foo'),
    );
  }
  buildCounterRoutine--;
}

core.int buildCounterRoutineReference = 0;
api.RoutineReference buildRoutineReference() {
  var o = api.RoutineReference();
  buildCounterRoutineReference++;
  if (buildCounterRoutineReference < 3) {
    o.datasetId = 'foo';
    o.projectId = 'foo';
    o.routineId = 'foo';
  }
  buildCounterRoutineReference--;
  return o;
}

void checkRoutineReference(api.RoutineReference o) {
  buildCounterRoutineReference++;
  if (buildCounterRoutineReference < 3) {
    unittest.expect(
      o.datasetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.routineId!,
      unittest.equals('foo'),
    );
  }
  buildCounterRoutineReference--;
}

core.List<api.Entry> buildUnnamed1545() {
  var o = <api.Entry>[];
  o.add(buildEntry());
  o.add(buildEntry());
  return o;
}

void checkUnnamed1545(core.List<api.Entry> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkEntry(o[0] as api.Entry);
  checkEntry(o[1] as api.Entry);
}

core.int buildCounterRow = 0;
api.Row buildRow() {
  var o = api.Row();
  buildCounterRow++;
  if (buildCounterRow < 3) {
    o.actualLabel = 'foo';
    o.entries = buildUnnamed1545();
  }
  buildCounterRow--;
  return o;
}

void checkRow(api.Row o) {
  buildCounterRow++;
  if (buildCounterRow < 3) {
    unittest.expect(
      o.actualLabel!,
      unittest.equals('foo'),
    );
    checkUnnamed1545(o.entries!);
  }
  buildCounterRow--;
}

core.int buildCounterRowAccessPolicy = 0;
api.RowAccessPolicy buildRowAccessPolicy() {
  var o = api.RowAccessPolicy();
  buildCounterRowAccessPolicy++;
  if (buildCounterRowAccessPolicy < 3) {
    o.creationTime = 'foo';
    o.etag = 'foo';
    o.filterPredicate = 'foo';
    o.lastModifiedTime = 'foo';
    o.rowAccessPolicyReference = buildRowAccessPolicyReference();
  }
  buildCounterRowAccessPolicy--;
  return o;
}

void checkRowAccessPolicy(api.RowAccessPolicy o) {
  buildCounterRowAccessPolicy++;
  if (buildCounterRowAccessPolicy < 3) {
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.filterPredicate!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lastModifiedTime!,
      unittest.equals('foo'),
    );
    checkRowAccessPolicyReference(
        o.rowAccessPolicyReference! as api.RowAccessPolicyReference);
  }
  buildCounterRowAccessPolicy--;
}

core.int buildCounterRowAccessPolicyReference = 0;
api.RowAccessPolicyReference buildRowAccessPolicyReference() {
  var o = api.RowAccessPolicyReference();
  buildCounterRowAccessPolicyReference++;
  if (buildCounterRowAccessPolicyReference < 3) {
    o.datasetId = 'foo';
    o.policyId = 'foo';
    o.projectId = 'foo';
    o.tableId = 'foo';
  }
  buildCounterRowAccessPolicyReference--;
  return o;
}

void checkRowAccessPolicyReference(api.RowAccessPolicyReference o) {
  buildCounterRowAccessPolicyReference++;
  if (buildCounterRowAccessPolicyReference < 3) {
    unittest.expect(
      o.datasetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.policyId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tableId!,
      unittest.equals('foo'),
    );
  }
  buildCounterRowAccessPolicyReference--;
}

core.int buildCounterRowLevelSecurityStatistics = 0;
api.RowLevelSecurityStatistics buildRowLevelSecurityStatistics() {
  var o = api.RowLevelSecurityStatistics();
  buildCounterRowLevelSecurityStatistics++;
  if (buildCounterRowLevelSecurityStatistics < 3) {
    o.rowLevelSecurityApplied = true;
  }
  buildCounterRowLevelSecurityStatistics--;
  return o;
}

void checkRowLevelSecurityStatistics(api.RowLevelSecurityStatistics o) {
  buildCounterRowLevelSecurityStatistics++;
  if (buildCounterRowLevelSecurityStatistics < 3) {
    unittest.expect(o.rowLevelSecurityApplied!, unittest.isTrue);
  }
  buildCounterRowLevelSecurityStatistics--;
}

core.int buildCounterScriptStackFrame = 0;
api.ScriptStackFrame buildScriptStackFrame() {
  var o = api.ScriptStackFrame();
  buildCounterScriptStackFrame++;
  if (buildCounterScriptStackFrame < 3) {
    o.endColumn = 42;
    o.endLine = 42;
    o.procedureId = 'foo';
    o.startColumn = 42;
    o.startLine = 42;
    o.text = 'foo';
  }
  buildCounterScriptStackFrame--;
  return o;
}

void checkScriptStackFrame(api.ScriptStackFrame o) {
  buildCounterScriptStackFrame++;
  if (buildCounterScriptStackFrame < 3) {
    unittest.expect(
      o.endColumn!,
      unittest.equals(42),
    );
    unittest.expect(
      o.endLine!,
      unittest.equals(42),
    );
    unittest.expect(
      o.procedureId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.startColumn!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startLine!,
      unittest.equals(42),
    );
    unittest.expect(
      o.text!,
      unittest.equals('foo'),
    );
  }
  buildCounterScriptStackFrame--;
}

core.List<api.ScriptStackFrame> buildUnnamed1546() {
  var o = <api.ScriptStackFrame>[];
  o.add(buildScriptStackFrame());
  o.add(buildScriptStackFrame());
  return o;
}

void checkUnnamed1546(core.List<api.ScriptStackFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkScriptStackFrame(o[0] as api.ScriptStackFrame);
  checkScriptStackFrame(o[1] as api.ScriptStackFrame);
}

core.int buildCounterScriptStatistics = 0;
api.ScriptStatistics buildScriptStatistics() {
  var o = api.ScriptStatistics();
  buildCounterScriptStatistics++;
  if (buildCounterScriptStatistics < 3) {
    o.evaluationKind = 'foo';
    o.stackFrames = buildUnnamed1546();
  }
  buildCounterScriptStatistics--;
  return o;
}

void checkScriptStatistics(api.ScriptStatistics o) {
  buildCounterScriptStatistics++;
  if (buildCounterScriptStatistics < 3) {
    unittest.expect(
      o.evaluationKind!,
      unittest.equals('foo'),
    );
    checkUnnamed1546(o.stackFrames!);
  }
  buildCounterScriptStatistics--;
}

core.int buildCounterSessionInfo = 0;
api.SessionInfo buildSessionInfo() {
  var o = api.SessionInfo();
  buildCounterSessionInfo++;
  if (buildCounterSessionInfo < 3) {
    o.sessionId = 'foo';
  }
  buildCounterSessionInfo--;
  return o;
}

void checkSessionInfo(api.SessionInfo o) {
  buildCounterSessionInfo++;
  if (buildCounterSessionInfo < 3) {
    unittest.expect(
      o.sessionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterSessionInfo--;
}

core.int buildCounterSetIamPolicyRequest = 0;
api.SetIamPolicyRequest buildSetIamPolicyRequest() {
  var o = api.SetIamPolicyRequest();
  buildCounterSetIamPolicyRequest++;
  if (buildCounterSetIamPolicyRequest < 3) {
    o.policy = buildPolicy();
    o.updateMask = 'foo';
  }
  buildCounterSetIamPolicyRequest--;
  return o;
}

void checkSetIamPolicyRequest(api.SetIamPolicyRequest o) {
  buildCounterSetIamPolicyRequest++;
  if (buildCounterSetIamPolicyRequest < 3) {
    checkPolicy(o.policy! as api.Policy);
    unittest.expect(
      o.updateMask!,
      unittest.equals('foo'),
    );
  }
  buildCounterSetIamPolicyRequest--;
}

core.int buildCounterSnapshotDefinition = 0;
api.SnapshotDefinition buildSnapshotDefinition() {
  var o = api.SnapshotDefinition();
  buildCounterSnapshotDefinition++;
  if (buildCounterSnapshotDefinition < 3) {
    o.baseTableReference = buildTableReference();
    o.snapshotTime = core.DateTime.parse("2002-02-27T14:01:02");
  }
  buildCounterSnapshotDefinition--;
  return o;
}

void checkSnapshotDefinition(api.SnapshotDefinition o) {
  buildCounterSnapshotDefinition++;
  if (buildCounterSnapshotDefinition < 3) {
    checkTableReference(o.baseTableReference! as api.TableReference);
    unittest.expect(
      o.snapshotTime!,
      unittest.equals(core.DateTime.parse("2002-02-27T14:01:02")),
    );
  }
  buildCounterSnapshotDefinition--;
}

core.int buildCounterStandardSqlDataType = 0;
api.StandardSqlDataType buildStandardSqlDataType() {
  var o = api.StandardSqlDataType();
  buildCounterStandardSqlDataType++;
  if (buildCounterStandardSqlDataType < 3) {
    o.arrayElementType = buildStandardSqlDataType();
    o.structType = buildStandardSqlStructType();
    o.typeKind = 'foo';
  }
  buildCounterStandardSqlDataType--;
  return o;
}

void checkStandardSqlDataType(api.StandardSqlDataType o) {
  buildCounterStandardSqlDataType++;
  if (buildCounterStandardSqlDataType < 3) {
    checkStandardSqlDataType(o.arrayElementType! as api.StandardSqlDataType);
    checkStandardSqlStructType(o.structType! as api.StandardSqlStructType);
    unittest.expect(
      o.typeKind!,
      unittest.equals('foo'),
    );
  }
  buildCounterStandardSqlDataType--;
}

core.int buildCounterStandardSqlField = 0;
api.StandardSqlField buildStandardSqlField() {
  var o = api.StandardSqlField();
  buildCounterStandardSqlField++;
  if (buildCounterStandardSqlField < 3) {
    o.name = 'foo';
    o.type = buildStandardSqlDataType();
  }
  buildCounterStandardSqlField--;
  return o;
}

void checkStandardSqlField(api.StandardSqlField o) {
  buildCounterStandardSqlField++;
  if (buildCounterStandardSqlField < 3) {
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkStandardSqlDataType(o.type! as api.StandardSqlDataType);
  }
  buildCounterStandardSqlField--;
}

core.List<api.StandardSqlField> buildUnnamed1547() {
  var o = <api.StandardSqlField>[];
  o.add(buildStandardSqlField());
  o.add(buildStandardSqlField());
  return o;
}

void checkUnnamed1547(core.List<api.StandardSqlField> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStandardSqlField(o[0] as api.StandardSqlField);
  checkStandardSqlField(o[1] as api.StandardSqlField);
}

core.int buildCounterStandardSqlStructType = 0;
api.StandardSqlStructType buildStandardSqlStructType() {
  var o = api.StandardSqlStructType();
  buildCounterStandardSqlStructType++;
  if (buildCounterStandardSqlStructType < 3) {
    o.fields = buildUnnamed1547();
  }
  buildCounterStandardSqlStructType--;
  return o;
}

void checkStandardSqlStructType(api.StandardSqlStructType o) {
  buildCounterStandardSqlStructType++;
  if (buildCounterStandardSqlStructType < 3) {
    checkUnnamed1547(o.fields!);
  }
  buildCounterStandardSqlStructType--;
}

core.List<api.StandardSqlField> buildUnnamed1548() {
  var o = <api.StandardSqlField>[];
  o.add(buildStandardSqlField());
  o.add(buildStandardSqlField());
  return o;
}

void checkUnnamed1548(core.List<api.StandardSqlField> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStandardSqlField(o[0] as api.StandardSqlField);
  checkStandardSqlField(o[1] as api.StandardSqlField);
}

core.int buildCounterStandardSqlTableType = 0;
api.StandardSqlTableType buildStandardSqlTableType() {
  var o = api.StandardSqlTableType();
  buildCounterStandardSqlTableType++;
  if (buildCounterStandardSqlTableType < 3) {
    o.columns = buildUnnamed1548();
  }
  buildCounterStandardSqlTableType--;
  return o;
}

void checkStandardSqlTableType(api.StandardSqlTableType o) {
  buildCounterStandardSqlTableType++;
  if (buildCounterStandardSqlTableType < 3) {
    checkUnnamed1548(o.columns!);
  }
  buildCounterStandardSqlTableType--;
}

core.int buildCounterStreamingbuffer = 0;
api.Streamingbuffer buildStreamingbuffer() {
  var o = api.Streamingbuffer();
  buildCounterStreamingbuffer++;
  if (buildCounterStreamingbuffer < 3) {
    o.estimatedBytes = 'foo';
    o.estimatedRows = 'foo';
    o.oldestEntryTime = 'foo';
  }
  buildCounterStreamingbuffer--;
  return o;
}

void checkStreamingbuffer(api.Streamingbuffer o) {
  buildCounterStreamingbuffer++;
  if (buildCounterStreamingbuffer < 3) {
    unittest.expect(
      o.estimatedBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.estimatedRows!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.oldestEntryTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterStreamingbuffer--;
}

core.Map<core.String, core.String> buildUnnamed1549() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed1549(core.Map<core.String, core.String> o) {
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

core.int buildCounterTable = 0;
api.Table buildTable() {
  var o = api.Table();
  buildCounterTable++;
  if (buildCounterTable < 3) {
    o.clustering = buildClustering();
    o.creationTime = 'foo';
    o.description = 'foo';
    o.encryptionConfiguration = buildEncryptionConfiguration();
    o.etag = 'foo';
    o.expirationTime = 'foo';
    o.externalDataConfiguration = buildExternalDataConfiguration();
    o.friendlyName = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.labels = buildUnnamed1549();
    o.lastModifiedTime = 'foo';
    o.location = 'foo';
    o.materializedView = buildMaterializedViewDefinition();
    o.model = buildModelDefinition();
    o.numBytes = 'foo';
    o.numLongTermBytes = 'foo';
    o.numPhysicalBytes = 'foo';
    o.numRows = 'foo';
    o.rangePartitioning = buildRangePartitioning();
    o.requirePartitionFilter = true;
    o.schema = buildTableSchema();
    o.selfLink = 'foo';
    o.snapshotDefinition = buildSnapshotDefinition();
    o.streamingBuffer = buildStreamingbuffer();
    o.tableReference = buildTableReference();
    o.timePartitioning = buildTimePartitioning();
    o.type = 'foo';
    o.view = buildViewDefinition();
  }
  buildCounterTable--;
  return o;
}

void checkTable(api.Table o) {
  buildCounterTable++;
  if (buildCounterTable < 3) {
    checkClustering(o.clustering! as api.Clustering);
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkEncryptionConfiguration(
        o.encryptionConfiguration! as api.EncryptionConfiguration);
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expirationTime!,
      unittest.equals('foo'),
    );
    checkExternalDataConfiguration(
        o.externalDataConfiguration! as api.ExternalDataConfiguration);
    unittest.expect(
      o.friendlyName!,
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
    checkUnnamed1549(o.labels!);
    unittest.expect(
      o.lastModifiedTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.location!,
      unittest.equals('foo'),
    );
    checkMaterializedViewDefinition(
        o.materializedView! as api.MaterializedViewDefinition);
    checkModelDefinition(o.model! as api.ModelDefinition);
    unittest.expect(
      o.numBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numLongTermBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numPhysicalBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numRows!,
      unittest.equals('foo'),
    );
    checkRangePartitioning(o.rangePartitioning! as api.RangePartitioning);
    unittest.expect(o.requirePartitionFilter!, unittest.isTrue);
    checkTableSchema(o.schema! as api.TableSchema);
    unittest.expect(
      o.selfLink!,
      unittest.equals('foo'),
    );
    checkSnapshotDefinition(o.snapshotDefinition! as api.SnapshotDefinition);
    checkStreamingbuffer(o.streamingBuffer! as api.Streamingbuffer);
    checkTableReference(o.tableReference! as api.TableReference);
    checkTimePartitioning(o.timePartitioning! as api.TimePartitioning);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    checkViewDefinition(o.view! as api.ViewDefinition);
  }
  buildCounterTable--;
}

core.int buildCounterTableCell = 0;
api.TableCell buildTableCell() {
  var o = api.TableCell();
  buildCounterTableCell++;
  if (buildCounterTableCell < 3) {
    o.v = {
      'list': [1, 2, 3],
      'bool': true,
      'string': 'foo'
    };
  }
  buildCounterTableCell--;
  return o;
}

void checkTableCell(api.TableCell o) {
  buildCounterTableCell++;
  if (buildCounterTableCell < 3) {
    var casted4 = (o.v!) as core.Map;
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
  buildCounterTableCell--;
}

core.int buildCounterTableDataInsertAllRequestRows = 0;
api.TableDataInsertAllRequestRows buildTableDataInsertAllRequestRows() {
  var o = api.TableDataInsertAllRequestRows();
  buildCounterTableDataInsertAllRequestRows++;
  if (buildCounterTableDataInsertAllRequestRows < 3) {
    o.insertId = 'foo';
    o.json = buildJsonObject();
  }
  buildCounterTableDataInsertAllRequestRows--;
  return o;
}

void checkTableDataInsertAllRequestRows(api.TableDataInsertAllRequestRows o) {
  buildCounterTableDataInsertAllRequestRows++;
  if (buildCounterTableDataInsertAllRequestRows < 3) {
    unittest.expect(
      o.insertId!,
      unittest.equals('foo'),
    );
    checkJsonObject(o.json! as api.JsonObject);
  }
  buildCounterTableDataInsertAllRequestRows--;
}

core.List<api.TableDataInsertAllRequestRows> buildUnnamed1550() {
  var o = <api.TableDataInsertAllRequestRows>[];
  o.add(buildTableDataInsertAllRequestRows());
  o.add(buildTableDataInsertAllRequestRows());
  return o;
}

void checkUnnamed1550(core.List<api.TableDataInsertAllRequestRows> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableDataInsertAllRequestRows(o[0] as api.TableDataInsertAllRequestRows);
  checkTableDataInsertAllRequestRows(o[1] as api.TableDataInsertAllRequestRows);
}

core.int buildCounterTableDataInsertAllRequest = 0;
api.TableDataInsertAllRequest buildTableDataInsertAllRequest() {
  var o = api.TableDataInsertAllRequest();
  buildCounterTableDataInsertAllRequest++;
  if (buildCounterTableDataInsertAllRequest < 3) {
    o.ignoreUnknownValues = true;
    o.kind = 'foo';
    o.rows = buildUnnamed1550();
    o.skipInvalidRows = true;
    o.templateSuffix = 'foo';
  }
  buildCounterTableDataInsertAllRequest--;
  return o;
}

void checkTableDataInsertAllRequest(api.TableDataInsertAllRequest o) {
  buildCounterTableDataInsertAllRequest++;
  if (buildCounterTableDataInsertAllRequest < 3) {
    unittest.expect(o.ignoreUnknownValues!, unittest.isTrue);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    checkUnnamed1550(o.rows!);
    unittest.expect(o.skipInvalidRows!, unittest.isTrue);
    unittest.expect(
      o.templateSuffix!,
      unittest.equals('foo'),
    );
  }
  buildCounterTableDataInsertAllRequest--;
}

core.List<api.ErrorProto> buildUnnamed1551() {
  var o = <api.ErrorProto>[];
  o.add(buildErrorProto());
  o.add(buildErrorProto());
  return o;
}

void checkUnnamed1551(core.List<api.ErrorProto> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkErrorProto(o[0] as api.ErrorProto);
  checkErrorProto(o[1] as api.ErrorProto);
}

core.int buildCounterTableDataInsertAllResponseInsertErrors = 0;
api.TableDataInsertAllResponseInsertErrors
    buildTableDataInsertAllResponseInsertErrors() {
  var o = api.TableDataInsertAllResponseInsertErrors();
  buildCounterTableDataInsertAllResponseInsertErrors++;
  if (buildCounterTableDataInsertAllResponseInsertErrors < 3) {
    o.errors = buildUnnamed1551();
    o.index = 42;
  }
  buildCounterTableDataInsertAllResponseInsertErrors--;
  return o;
}

void checkTableDataInsertAllResponseInsertErrors(
    api.TableDataInsertAllResponseInsertErrors o) {
  buildCounterTableDataInsertAllResponseInsertErrors++;
  if (buildCounterTableDataInsertAllResponseInsertErrors < 3) {
    checkUnnamed1551(o.errors!);
    unittest.expect(
      o.index!,
      unittest.equals(42),
    );
  }
  buildCounterTableDataInsertAllResponseInsertErrors--;
}

core.List<api.TableDataInsertAllResponseInsertErrors> buildUnnamed1552() {
  var o = <api.TableDataInsertAllResponseInsertErrors>[];
  o.add(buildTableDataInsertAllResponseInsertErrors());
  o.add(buildTableDataInsertAllResponseInsertErrors());
  return o;
}

void checkUnnamed1552(core.List<api.TableDataInsertAllResponseInsertErrors> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableDataInsertAllResponseInsertErrors(
      o[0] as api.TableDataInsertAllResponseInsertErrors);
  checkTableDataInsertAllResponseInsertErrors(
      o[1] as api.TableDataInsertAllResponseInsertErrors);
}

core.int buildCounterTableDataInsertAllResponse = 0;
api.TableDataInsertAllResponse buildTableDataInsertAllResponse() {
  var o = api.TableDataInsertAllResponse();
  buildCounterTableDataInsertAllResponse++;
  if (buildCounterTableDataInsertAllResponse < 3) {
    o.insertErrors = buildUnnamed1552();
    o.kind = 'foo';
  }
  buildCounterTableDataInsertAllResponse--;
  return o;
}

void checkTableDataInsertAllResponse(api.TableDataInsertAllResponse o) {
  buildCounterTableDataInsertAllResponse++;
  if (buildCounterTableDataInsertAllResponse < 3) {
    checkUnnamed1552(o.insertErrors!);
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
  }
  buildCounterTableDataInsertAllResponse--;
}

core.List<api.TableRow> buildUnnamed1553() {
  var o = <api.TableRow>[];
  o.add(buildTableRow());
  o.add(buildTableRow());
  return o;
}

void checkUnnamed1553(core.List<api.TableRow> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableRow(o[0] as api.TableRow);
  checkTableRow(o[1] as api.TableRow);
}

core.int buildCounterTableDataList = 0;
api.TableDataList buildTableDataList() {
  var o = api.TableDataList();
  buildCounterTableDataList++;
  if (buildCounterTableDataList < 3) {
    o.etag = 'foo';
    o.kind = 'foo';
    o.pageToken = 'foo';
    o.rows = buildUnnamed1553();
    o.totalRows = 'foo';
  }
  buildCounterTableDataList--;
  return o;
}

void checkTableDataList(api.TableDataList o) {
  buildCounterTableDataList++;
  if (buildCounterTableDataList < 3) {
    unittest.expect(
      o.etag!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kind!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.pageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed1553(o.rows!);
    unittest.expect(
      o.totalRows!,
      unittest.equals('foo'),
    );
  }
  buildCounterTableDataList--;
}

core.List<core.String> buildUnnamed1554() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1554(core.List<core.String> o) {
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

core.int buildCounterTableFieldSchemaCategories = 0;
api.TableFieldSchemaCategories buildTableFieldSchemaCategories() {
  var o = api.TableFieldSchemaCategories();
  buildCounterTableFieldSchemaCategories++;
  if (buildCounterTableFieldSchemaCategories < 3) {
    o.names = buildUnnamed1554();
  }
  buildCounterTableFieldSchemaCategories--;
  return o;
}

void checkTableFieldSchemaCategories(api.TableFieldSchemaCategories o) {
  buildCounterTableFieldSchemaCategories++;
  if (buildCounterTableFieldSchemaCategories < 3) {
    checkUnnamed1554(o.names!);
  }
  buildCounterTableFieldSchemaCategories--;
}

core.List<api.TableFieldSchema> buildUnnamed1555() {
  var o = <api.TableFieldSchema>[];
  o.add(buildTableFieldSchema());
  o.add(buildTableFieldSchema());
  return o;
}

void checkUnnamed1555(core.List<api.TableFieldSchema> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableFieldSchema(o[0] as api.TableFieldSchema);
  checkTableFieldSchema(o[1] as api.TableFieldSchema);
}

core.List<core.String> buildUnnamed1556() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1556(core.List<core.String> o) {
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

core.int buildCounterTableFieldSchemaPolicyTags = 0;
api.TableFieldSchemaPolicyTags buildTableFieldSchemaPolicyTags() {
  var o = api.TableFieldSchemaPolicyTags();
  buildCounterTableFieldSchemaPolicyTags++;
  if (buildCounterTableFieldSchemaPolicyTags < 3) {
    o.names = buildUnnamed1556();
  }
  buildCounterTableFieldSchemaPolicyTags--;
  return o;
}

void checkTableFieldSchemaPolicyTags(api.TableFieldSchemaPolicyTags o) {
  buildCounterTableFieldSchemaPolicyTags++;
  if (buildCounterTableFieldSchemaPolicyTags < 3) {
    checkUnnamed1556(o.names!);
  }
  buildCounterTableFieldSchemaPolicyTags--;
}

core.int buildCounterTableFieldSchema = 0;
api.TableFieldSchema buildTableFieldSchema() {
  var o = api.TableFieldSchema();
  buildCounterTableFieldSchema++;
  if (buildCounterTableFieldSchema < 3) {
    o.categories = buildTableFieldSchemaCategories();
    o.description = 'foo';
    o.fields = buildUnnamed1555();
    o.maxLength = 'foo';
    o.mode = 'foo';
    o.name = 'foo';
    o.policyTags = buildTableFieldSchemaPolicyTags();
    o.precision = 'foo';
    o.scale = 'foo';
    o.type = 'foo';
  }
  buildCounterTableFieldSchema--;
  return o;
}

void checkTableFieldSchema(api.TableFieldSchema o) {
  buildCounterTableFieldSchema++;
  if (buildCounterTableFieldSchema < 3) {
    checkTableFieldSchemaCategories(
        o.categories! as api.TableFieldSchemaCategories);
    unittest.expect(
      o.description!,
      unittest.equals('foo'),
    );
    checkUnnamed1555(o.fields!);
    unittest.expect(
      o.maxLength!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.mode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkTableFieldSchemaPolicyTags(
        o.policyTags! as api.TableFieldSchemaPolicyTags);
    unittest.expect(
      o.precision!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.scale!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterTableFieldSchema--;
}

core.Map<core.String, core.String> buildUnnamed1557() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed1557(core.Map<core.String, core.String> o) {
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

core.int buildCounterTableListTablesView = 0;
api.TableListTablesView buildTableListTablesView() {
  var o = api.TableListTablesView();
  buildCounterTableListTablesView++;
  if (buildCounterTableListTablesView < 3) {
    o.useLegacySql = true;
  }
  buildCounterTableListTablesView--;
  return o;
}

void checkTableListTablesView(api.TableListTablesView o) {
  buildCounterTableListTablesView++;
  if (buildCounterTableListTablesView < 3) {
    unittest.expect(o.useLegacySql!, unittest.isTrue);
  }
  buildCounterTableListTablesView--;
}

core.int buildCounterTableListTables = 0;
api.TableListTables buildTableListTables() {
  var o = api.TableListTables();
  buildCounterTableListTables++;
  if (buildCounterTableListTables < 3) {
    o.clustering = buildClustering();
    o.creationTime = 'foo';
    o.expirationTime = 'foo';
    o.friendlyName = 'foo';
    o.id = 'foo';
    o.kind = 'foo';
    o.labels = buildUnnamed1557();
    o.rangePartitioning = buildRangePartitioning();
    o.tableReference = buildTableReference();
    o.timePartitioning = buildTimePartitioning();
    o.type = 'foo';
    o.view = buildTableListTablesView();
  }
  buildCounterTableListTables--;
  return o;
}

void checkTableListTables(api.TableListTables o) {
  buildCounterTableListTables++;
  if (buildCounterTableListTables < 3) {
    checkClustering(o.clustering! as api.Clustering);
    unittest.expect(
      o.creationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.expirationTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.friendlyName!,
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
    checkUnnamed1557(o.labels!);
    checkRangePartitioning(o.rangePartitioning! as api.RangePartitioning);
    checkTableReference(o.tableReference! as api.TableReference);
    checkTimePartitioning(o.timePartitioning! as api.TimePartitioning);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    checkTableListTablesView(o.view! as api.TableListTablesView);
  }
  buildCounterTableListTables--;
}

core.List<api.TableListTables> buildUnnamed1558() {
  var o = <api.TableListTables>[];
  o.add(buildTableListTables());
  o.add(buildTableListTables());
  return o;
}

void checkUnnamed1558(core.List<api.TableListTables> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableListTables(o[0] as api.TableListTables);
  checkTableListTables(o[1] as api.TableListTables);
}

core.int buildCounterTableList = 0;
api.TableList buildTableList() {
  var o = api.TableList();
  buildCounterTableList++;
  if (buildCounterTableList < 3) {
    o.etag = 'foo';
    o.kind = 'foo';
    o.nextPageToken = 'foo';
    o.tables = buildUnnamed1558();
    o.totalItems = 42;
  }
  buildCounterTableList--;
  return o;
}

void checkTableList(api.TableList o) {
  buildCounterTableList++;
  if (buildCounterTableList < 3) {
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
    checkUnnamed1558(o.tables!);
    unittest.expect(
      o.totalItems!,
      unittest.equals(42),
    );
  }
  buildCounterTableList--;
}

core.int buildCounterTableReference = 0;
api.TableReference buildTableReference() {
  var o = api.TableReference();
  buildCounterTableReference++;
  if (buildCounterTableReference < 3) {
    o.datasetId = 'foo';
    o.projectId = 'foo';
    o.tableId = 'foo';
  }
  buildCounterTableReference--;
  return o;
}

void checkTableReference(api.TableReference o) {
  buildCounterTableReference++;
  if (buildCounterTableReference < 3) {
    unittest.expect(
      o.datasetId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.projectId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.tableId!,
      unittest.equals('foo'),
    );
  }
  buildCounterTableReference--;
}

core.List<api.TableCell> buildUnnamed1559() {
  var o = <api.TableCell>[];
  o.add(buildTableCell());
  o.add(buildTableCell());
  return o;
}

void checkUnnamed1559(core.List<api.TableCell> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableCell(o[0] as api.TableCell);
  checkTableCell(o[1] as api.TableCell);
}

core.int buildCounterTableRow = 0;
api.TableRow buildTableRow() {
  var o = api.TableRow();
  buildCounterTableRow++;
  if (buildCounterTableRow < 3) {
    o.f = buildUnnamed1559();
  }
  buildCounterTableRow--;
  return o;
}

void checkTableRow(api.TableRow o) {
  buildCounterTableRow++;
  if (buildCounterTableRow < 3) {
    checkUnnamed1559(o.f!);
  }
  buildCounterTableRow--;
}

core.List<api.TableFieldSchema> buildUnnamed1560() {
  var o = <api.TableFieldSchema>[];
  o.add(buildTableFieldSchema());
  o.add(buildTableFieldSchema());
  return o;
}

void checkUnnamed1560(core.List<api.TableFieldSchema> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTableFieldSchema(o[0] as api.TableFieldSchema);
  checkTableFieldSchema(o[1] as api.TableFieldSchema);
}

core.int buildCounterTableSchema = 0;
api.TableSchema buildTableSchema() {
  var o = api.TableSchema();
  buildCounterTableSchema++;
  if (buildCounterTableSchema < 3) {
    o.fields = buildUnnamed1560();
  }
  buildCounterTableSchema--;
  return o;
}

void checkTableSchema(api.TableSchema o) {
  buildCounterTableSchema++;
  if (buildCounterTableSchema < 3) {
    checkUnnamed1560(o.fields!);
  }
  buildCounterTableSchema--;
}

core.List<core.String> buildUnnamed1561() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1561(core.List<core.String> o) {
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

core.int buildCounterTestIamPermissionsRequest = 0;
api.TestIamPermissionsRequest buildTestIamPermissionsRequest() {
  var o = api.TestIamPermissionsRequest();
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    o.permissions = buildUnnamed1561();
  }
  buildCounterTestIamPermissionsRequest--;
  return o;
}

void checkTestIamPermissionsRequest(api.TestIamPermissionsRequest o) {
  buildCounterTestIamPermissionsRequest++;
  if (buildCounterTestIamPermissionsRequest < 3) {
    checkUnnamed1561(o.permissions!);
  }
  buildCounterTestIamPermissionsRequest--;
}

core.List<core.String> buildUnnamed1562() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1562(core.List<core.String> o) {
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

core.int buildCounterTestIamPermissionsResponse = 0;
api.TestIamPermissionsResponse buildTestIamPermissionsResponse() {
  var o = api.TestIamPermissionsResponse();
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    o.permissions = buildUnnamed1562();
  }
  buildCounterTestIamPermissionsResponse--;
  return o;
}

void checkTestIamPermissionsResponse(api.TestIamPermissionsResponse o) {
  buildCounterTestIamPermissionsResponse++;
  if (buildCounterTestIamPermissionsResponse < 3) {
    checkUnnamed1562(o.permissions!);
  }
  buildCounterTestIamPermissionsResponse--;
}

core.int buildCounterTimePartitioning = 0;
api.TimePartitioning buildTimePartitioning() {
  var o = api.TimePartitioning();
  buildCounterTimePartitioning++;
  if (buildCounterTimePartitioning < 3) {
    o.expirationMs = 'foo';
    o.field = 'foo';
    o.requirePartitionFilter = true;
    o.type = 'foo';
  }
  buildCounterTimePartitioning--;
  return o;
}

void checkTimePartitioning(api.TimePartitioning o) {
  buildCounterTimePartitioning++;
  if (buildCounterTimePartitioning < 3) {
    unittest.expect(
      o.expirationMs!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.field!,
      unittest.equals('foo'),
    );
    unittest.expect(o.requirePartitionFilter!, unittest.isTrue);
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterTimePartitioning--;
}

core.List<core.String> buildUnnamed1563() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1563(core.List<core.String> o) {
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

core.List<core.String> buildUnnamed1564() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1564(core.List<core.String> o) {
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

core.Map<core.String, core.double> buildUnnamed1565() {
  var o = <core.String, core.double>{};
  o['x'] = 42.0;
  o['y'] = 42.0;
  return o;
}

void checkUnnamed1565(core.Map<core.String, core.double> o) {
  unittest.expect(o, unittest.hasLength(2));
  unittest.expect(
    o['x']!,
    unittest.equals(42.0),
  );
  unittest.expect(
    o['y']!,
    unittest.equals(42.0),
  );
}

core.List<core.String> buildUnnamed1566() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1566(core.List<core.String> o) {
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

core.int buildCounterTrainingOptions = 0;
api.TrainingOptions buildTrainingOptions() {
  var o = api.TrainingOptions();
  buildCounterTrainingOptions++;
  if (buildCounterTrainingOptions < 3) {
    o.adjustStepChanges = true;
    o.autoArima = true;
    o.autoArimaMaxOrder = 'foo';
    o.batchSize = 'foo';
    o.cleanSpikesAndDips = true;
    o.dataFrequency = 'foo';
    o.dataSplitColumn = 'foo';
    o.dataSplitEvalFraction = 42.0;
    o.dataSplitMethod = 'foo';
    o.decomposeTimeSeries = true;
    o.distanceType = 'foo';
    o.dropout = 42.0;
    o.earlyStop = true;
    o.feedbackType = 'foo';
    o.hiddenUnits = buildUnnamed1563();
    o.holidayRegion = 'foo';
    o.horizon = 'foo';
    o.includeDrift = true;
    o.initialLearnRate = 42.0;
    o.inputLabelColumns = buildUnnamed1564();
    o.itemColumn = 'foo';
    o.kmeansInitializationColumn = 'foo';
    o.kmeansInitializationMethod = 'foo';
    o.l1Regularization = 42.0;
    o.l2Regularization = 42.0;
    o.labelClassWeights = buildUnnamed1565();
    o.learnRate = 42.0;
    o.learnRateStrategy = 'foo';
    o.lossType = 'foo';
    o.maxIterations = 'foo';
    o.maxTreeDepth = 'foo';
    o.minRelativeProgress = 42.0;
    o.minSplitLoss = 42.0;
    o.modelUri = 'foo';
    o.nonSeasonalOrder = buildArimaOrder();
    o.numClusters = 'foo';
    o.numFactors = 'foo';
    o.optimizationStrategy = 'foo';
    o.preserveInputStructs = true;
    o.subsample = 42.0;
    o.timeSeriesDataColumn = 'foo';
    o.timeSeriesIdColumn = 'foo';
    o.timeSeriesIdColumns = buildUnnamed1566();
    o.timeSeriesTimestampColumn = 'foo';
    o.userColumn = 'foo';
    o.walsAlpha = 42.0;
    o.warmStart = true;
  }
  buildCounterTrainingOptions--;
  return o;
}

void checkTrainingOptions(api.TrainingOptions o) {
  buildCounterTrainingOptions++;
  if (buildCounterTrainingOptions < 3) {
    unittest.expect(o.adjustStepChanges!, unittest.isTrue);
    unittest.expect(o.autoArima!, unittest.isTrue);
    unittest.expect(
      o.autoArimaMaxOrder!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.batchSize!,
      unittest.equals('foo'),
    );
    unittest.expect(o.cleanSpikesAndDips!, unittest.isTrue);
    unittest.expect(
      o.dataFrequency!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dataSplitColumn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dataSplitEvalFraction!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.dataSplitMethod!,
      unittest.equals('foo'),
    );
    unittest.expect(o.decomposeTimeSeries!, unittest.isTrue);
    unittest.expect(
      o.distanceType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.dropout!,
      unittest.equals(42.0),
    );
    unittest.expect(o.earlyStop!, unittest.isTrue);
    unittest.expect(
      o.feedbackType!,
      unittest.equals('foo'),
    );
    checkUnnamed1563(o.hiddenUnits!);
    unittest.expect(
      o.holidayRegion!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.horizon!,
      unittest.equals('foo'),
    );
    unittest.expect(o.includeDrift!, unittest.isTrue);
    unittest.expect(
      o.initialLearnRate!,
      unittest.equals(42.0),
    );
    checkUnnamed1564(o.inputLabelColumns!);
    unittest.expect(
      o.itemColumn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kmeansInitializationColumn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.kmeansInitializationMethod!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.l1Regularization!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.l2Regularization!,
      unittest.equals(42.0),
    );
    checkUnnamed1565(o.labelClassWeights!);
    unittest.expect(
      o.learnRate!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.learnRateStrategy!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.lossType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxIterations!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxTreeDepth!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.minRelativeProgress!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.minSplitLoss!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.modelUri!,
      unittest.equals('foo'),
    );
    checkArimaOrder(o.nonSeasonalOrder! as api.ArimaOrder);
    unittest.expect(
      o.numClusters!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.numFactors!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.optimizationStrategy!,
      unittest.equals('foo'),
    );
    unittest.expect(o.preserveInputStructs!, unittest.isTrue);
    unittest.expect(
      o.subsample!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.timeSeriesDataColumn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.timeSeriesIdColumn!,
      unittest.equals('foo'),
    );
    checkUnnamed1566(o.timeSeriesIdColumns!);
    unittest.expect(
      o.timeSeriesTimestampColumn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.userColumn!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.walsAlpha!,
      unittest.equals(42.0),
    );
    unittest.expect(o.warmStart!, unittest.isTrue);
  }
  buildCounterTrainingOptions--;
}

core.List<api.GlobalExplanation> buildUnnamed1567() {
  var o = <api.GlobalExplanation>[];
  o.add(buildGlobalExplanation());
  o.add(buildGlobalExplanation());
  return o;
}

void checkUnnamed1567(core.List<api.GlobalExplanation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGlobalExplanation(o[0] as api.GlobalExplanation);
  checkGlobalExplanation(o[1] as api.GlobalExplanation);
}

core.List<api.IterationResult> buildUnnamed1568() {
  var o = <api.IterationResult>[];
  o.add(buildIterationResult());
  o.add(buildIterationResult());
  return o;
}

void checkUnnamed1568(core.List<api.IterationResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkIterationResult(o[0] as api.IterationResult);
  checkIterationResult(o[1] as api.IterationResult);
}

core.int buildCounterTrainingRun = 0;
api.TrainingRun buildTrainingRun() {
  var o = api.TrainingRun();
  buildCounterTrainingRun++;
  if (buildCounterTrainingRun < 3) {
    o.dataSplitResult = buildDataSplitResult();
    o.evaluationMetrics = buildEvaluationMetrics();
    o.globalExplanations = buildUnnamed1567();
    o.results = buildUnnamed1568();
    o.startTime = 'foo';
    o.trainingOptions = buildTrainingOptions();
  }
  buildCounterTrainingRun--;
  return o;
}

void checkTrainingRun(api.TrainingRun o) {
  buildCounterTrainingRun++;
  if (buildCounterTrainingRun < 3) {
    checkDataSplitResult(o.dataSplitResult! as api.DataSplitResult);
    checkEvaluationMetrics(o.evaluationMetrics! as api.EvaluationMetrics);
    checkUnnamed1567(o.globalExplanations!);
    checkUnnamed1568(o.results!);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    checkTrainingOptions(o.trainingOptions! as api.TrainingOptions);
  }
  buildCounterTrainingRun--;
}

core.int buildCounterTransactionInfo = 0;
api.TransactionInfo buildTransactionInfo() {
  var o = api.TransactionInfo();
  buildCounterTransactionInfo++;
  if (buildCounterTransactionInfo < 3) {
    o.transactionId = 'foo';
  }
  buildCounterTransactionInfo--;
  return o;
}

void checkTransactionInfo(api.TransactionInfo o) {
  buildCounterTransactionInfo++;
  if (buildCounterTransactionInfo < 3) {
    unittest.expect(
      o.transactionId!,
      unittest.equals('foo'),
    );
  }
  buildCounterTransactionInfo--;
}

core.int buildCounterUserDefinedFunctionResource = 0;
api.UserDefinedFunctionResource buildUserDefinedFunctionResource() {
  var o = api.UserDefinedFunctionResource();
  buildCounterUserDefinedFunctionResource++;
  if (buildCounterUserDefinedFunctionResource < 3) {
    o.inlineCode = 'foo';
    o.resourceUri = 'foo';
  }
  buildCounterUserDefinedFunctionResource--;
  return o;
}

void checkUserDefinedFunctionResource(api.UserDefinedFunctionResource o) {
  buildCounterUserDefinedFunctionResource++;
  if (buildCounterUserDefinedFunctionResource < 3) {
    unittest.expect(
      o.inlineCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.resourceUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterUserDefinedFunctionResource--;
}

core.List<api.UserDefinedFunctionResource> buildUnnamed1569() {
  var o = <api.UserDefinedFunctionResource>[];
  o.add(buildUserDefinedFunctionResource());
  o.add(buildUserDefinedFunctionResource());
  return o;
}

void checkUnnamed1569(core.List<api.UserDefinedFunctionResource> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUserDefinedFunctionResource(o[0] as api.UserDefinedFunctionResource);
  checkUserDefinedFunctionResource(o[1] as api.UserDefinedFunctionResource);
}

core.int buildCounterViewDefinition = 0;
api.ViewDefinition buildViewDefinition() {
  var o = api.ViewDefinition();
  buildCounterViewDefinition++;
  if (buildCounterViewDefinition < 3) {
    o.query = 'foo';
    o.useLegacySql = true;
    o.userDefinedFunctionResources = buildUnnamed1569();
  }
  buildCounterViewDefinition--;
  return o;
}

void checkViewDefinition(api.ViewDefinition o) {
  buildCounterViewDefinition++;
  if (buildCounterViewDefinition < 3) {
    unittest.expect(
      o.query!,
      unittest.equals('foo'),
    );
    unittest.expect(o.useLegacySql!, unittest.isTrue);
    checkUnnamed1569(o.userDefinedFunctionResources!);
  }
  buildCounterViewDefinition--;
}

core.List<core.String> buildUnnamed1570() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed1570(core.List<core.String> o) {
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
  unittest.group('obj-schema-AggregateClassificationMetrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAggregateClassificationMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AggregateClassificationMetrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAggregateClassificationMetrics(
          od as api.AggregateClassificationMetrics);
    });
  });

  unittest.group('obj-schema-Argument', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArgument();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Argument.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkArgument(od as api.Argument);
    });
  });

  unittest.group('obj-schema-ArimaCoefficients', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArimaCoefficients();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ArimaCoefficients.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkArimaCoefficients(od as api.ArimaCoefficients);
    });
  });

  unittest.group('obj-schema-ArimaFittingMetrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArimaFittingMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ArimaFittingMetrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkArimaFittingMetrics(od as api.ArimaFittingMetrics);
    });
  });

  unittest.group('obj-schema-ArimaForecastingMetrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArimaForecastingMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ArimaForecastingMetrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkArimaForecastingMetrics(od as api.ArimaForecastingMetrics);
    });
  });

  unittest.group('obj-schema-ArimaModelInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArimaModelInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ArimaModelInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkArimaModelInfo(od as api.ArimaModelInfo);
    });
  });

  unittest.group('obj-schema-ArimaOrder', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArimaOrder();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ArimaOrder.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkArimaOrder(od as api.ArimaOrder);
    });
  });

  unittest.group('obj-schema-ArimaResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArimaResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ArimaResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkArimaResult(od as api.ArimaResult);
    });
  });

  unittest.group('obj-schema-ArimaSingleModelForecastingMetrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildArimaSingleModelForecastingMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ArimaSingleModelForecastingMetrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkArimaSingleModelForecastingMetrics(
          od as api.ArimaSingleModelForecastingMetrics);
    });
  });

  unittest.group('obj-schema-AuditConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuditConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuditConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuditConfig(od as api.AuditConfig);
    });
  });

  unittest.group('obj-schema-AuditLogConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAuditLogConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AuditLogConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAuditLogConfig(od as api.AuditLogConfig);
    });
  });

  unittest.group('obj-schema-BigQueryModelTraining', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBigQueryModelTraining();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BigQueryModelTraining.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBigQueryModelTraining(od as api.BigQueryModelTraining);
    });
  });

  unittest.group('obj-schema-BigtableColumn', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBigtableColumn();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BigtableColumn.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBigtableColumn(od as api.BigtableColumn);
    });
  });

  unittest.group('obj-schema-BigtableColumnFamily', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBigtableColumnFamily();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BigtableColumnFamily.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBigtableColumnFamily(od as api.BigtableColumnFamily);
    });
  });

  unittest.group('obj-schema-BigtableOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBigtableOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BigtableOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBigtableOptions(od as api.BigtableOptions);
    });
  });

  unittest.group('obj-schema-BinaryClassificationMetrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBinaryClassificationMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BinaryClassificationMetrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBinaryClassificationMetrics(od as api.BinaryClassificationMetrics);
    });
  });

  unittest.group('obj-schema-BinaryConfusionMatrix', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBinaryConfusionMatrix();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BinaryConfusionMatrix.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBinaryConfusionMatrix(od as api.BinaryConfusionMatrix);
    });
  });

  unittest.group('obj-schema-Binding', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBinding();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Binding.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkBinding(od as api.Binding);
    });
  });

  unittest.group('obj-schema-BqmlIterationResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBqmlIterationResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BqmlIterationResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBqmlIterationResult(od as api.BqmlIterationResult);
    });
  });

  unittest.group('obj-schema-BqmlTrainingRunTrainingOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBqmlTrainingRunTrainingOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BqmlTrainingRunTrainingOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBqmlTrainingRunTrainingOptions(
          od as api.BqmlTrainingRunTrainingOptions);
    });
  });

  unittest.group('obj-schema-BqmlTrainingRun', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBqmlTrainingRun();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BqmlTrainingRun.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBqmlTrainingRun(od as api.BqmlTrainingRun);
    });
  });

  unittest.group('obj-schema-CategoricalValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCategoricalValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CategoricalValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCategoricalValue(od as api.CategoricalValue);
    });
  });

  unittest.group('obj-schema-CategoryCount', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCategoryCount();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CategoryCount.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCategoryCount(od as api.CategoryCount);
    });
  });

  unittest.group('obj-schema-Cluster', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCluster();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Cluster.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCluster(od as api.Cluster);
    });
  });

  unittest.group('obj-schema-ClusterInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClusterInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClusterInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClusterInfo(od as api.ClusterInfo);
    });
  });

  unittest.group('obj-schema-Clustering', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClustering();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Clustering.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkClustering(od as api.Clustering);
    });
  });

  unittest.group('obj-schema-ClusteringMetrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildClusteringMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ClusteringMetrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkClusteringMetrics(od as api.ClusteringMetrics);
    });
  });

  unittest.group('obj-schema-ConfusionMatrix', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConfusionMatrix();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConfusionMatrix.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConfusionMatrix(od as api.ConfusionMatrix);
    });
  });

  unittest.group('obj-schema-ConnectionProperty', () {
    unittest.test('to-json--from-json', () async {
      var o = buildConnectionProperty();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ConnectionProperty.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkConnectionProperty(od as api.ConnectionProperty);
    });
  });

  unittest.group('obj-schema-CsvOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCsvOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.CsvOptions.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkCsvOptions(od as api.CsvOptions);
    });
  });

  unittest.group('obj-schema-DataSplitResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDataSplitResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DataSplitResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDataSplitResult(od as api.DataSplitResult);
    });
  });

  unittest.group('obj-schema-DatasetAccess', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDatasetAccess();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DatasetAccess.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDatasetAccess(od as api.DatasetAccess);
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

  unittest.group('obj-schema-DatasetAccessEntryTargetTypes', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDatasetAccessEntryTargetTypes();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DatasetAccessEntryTargetTypes.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDatasetAccessEntryTargetTypes(
          od as api.DatasetAccessEntryTargetTypes);
    });
  });

  unittest.group('obj-schema-DatasetAccessEntry', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDatasetAccessEntry();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DatasetAccessEntry.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDatasetAccessEntry(od as api.DatasetAccessEntry);
    });
  });

  unittest.group('obj-schema-DatasetListDatasets', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDatasetListDatasets();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DatasetListDatasets.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDatasetListDatasets(od as api.DatasetListDatasets);
    });
  });

  unittest.group('obj-schema-DatasetList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDatasetList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DatasetList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDatasetList(od as api.DatasetList);
    });
  });

  unittest.group('obj-schema-DatasetReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDatasetReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DatasetReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDatasetReference(od as api.DatasetReference);
    });
  });

  unittest.group('obj-schema-DestinationTableProperties', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDestinationTableProperties();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DestinationTableProperties.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDestinationTableProperties(od as api.DestinationTableProperties);
    });
  });

  unittest.group('obj-schema-EncryptionConfiguration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEncryptionConfiguration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EncryptionConfiguration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEncryptionConfiguration(od as api.EncryptionConfiguration);
    });
  });

  unittest.group('obj-schema-Entry', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEntry();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Entry.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkEntry(od as api.Entry);
    });
  });

  unittest.group('obj-schema-ErrorProto', () {
    unittest.test('to-json--from-json', () async {
      var o = buildErrorProto();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.ErrorProto.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkErrorProto(od as api.ErrorProto);
    });
  });

  unittest.group('obj-schema-EvaluationMetrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildEvaluationMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.EvaluationMetrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkEvaluationMetrics(od as api.EvaluationMetrics);
    });
  });

  unittest.group('obj-schema-ExplainQueryStage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExplainQueryStage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExplainQueryStage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExplainQueryStage(od as api.ExplainQueryStage);
    });
  });

  unittest.group('obj-schema-ExplainQueryStep', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExplainQueryStep();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExplainQueryStep.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExplainQueryStep(od as api.ExplainQueryStep);
    });
  });

  unittest.group('obj-schema-Explanation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExplanation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Explanation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExplanation(od as api.Explanation);
    });
  });

  unittest.group('obj-schema-Expr', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExpr();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Expr.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkExpr(od as api.Expr);
    });
  });

  unittest.group('obj-schema-ExternalDataConfiguration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildExternalDataConfiguration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ExternalDataConfiguration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkExternalDataConfiguration(od as api.ExternalDataConfiguration);
    });
  });

  unittest.group('obj-schema-FeatureValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildFeatureValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.FeatureValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkFeatureValue(od as api.FeatureValue);
    });
  });

  unittest.group('obj-schema-GetIamPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetIamPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetIamPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetIamPolicyRequest(od as api.GetIamPolicyRequest);
    });
  });

  unittest.group('obj-schema-GetPolicyOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetPolicyOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetPolicyOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetPolicyOptions(od as api.GetPolicyOptions);
    });
  });

  unittest.group('obj-schema-GetQueryResultsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetQueryResultsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetQueryResultsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetQueryResultsResponse(od as api.GetQueryResultsResponse);
    });
  });

  unittest.group('obj-schema-GetServiceAccountResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGetServiceAccountResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GetServiceAccountResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGetServiceAccountResponse(od as api.GetServiceAccountResponse);
    });
  });

  unittest.group('obj-schema-GlobalExplanation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGlobalExplanation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GlobalExplanation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGlobalExplanation(od as api.GlobalExplanation);
    });
  });

  unittest.group('obj-schema-GoogleSheetsOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGoogleSheetsOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GoogleSheetsOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGoogleSheetsOptions(od as api.GoogleSheetsOptions);
    });
  });

  unittest.group('obj-schema-HivePartitioningOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildHivePartitioningOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.HivePartitioningOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkHivePartitioningOptions(od as api.HivePartitioningOptions);
    });
  });

  unittest.group('obj-schema-IterationResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildIterationResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.IterationResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkIterationResult(od as api.IterationResult);
    });
  });

  unittest.group('obj-schema-Job', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJob();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Job.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkJob(od as api.Job);
    });
  });

  unittest.group('obj-schema-JobCancelResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobCancelResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobCancelResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobCancelResponse(od as api.JobCancelResponse);
    });
  });

  unittest.group('obj-schema-JobConfiguration', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobConfiguration();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobConfiguration.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobConfiguration(od as api.JobConfiguration);
    });
  });

  unittest.group('obj-schema-JobConfigurationExtract', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobConfigurationExtract();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobConfigurationExtract.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobConfigurationExtract(od as api.JobConfigurationExtract);
    });
  });

  unittest.group('obj-schema-JobConfigurationLoad', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobConfigurationLoad();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobConfigurationLoad.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobConfigurationLoad(od as api.JobConfigurationLoad);
    });
  });

  unittest.group('obj-schema-JobConfigurationQuery', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobConfigurationQuery();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobConfigurationQuery.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobConfigurationQuery(od as api.JobConfigurationQuery);
    });
  });

  unittest.group('obj-schema-JobConfigurationTableCopy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobConfigurationTableCopy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobConfigurationTableCopy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobConfigurationTableCopy(od as api.JobConfigurationTableCopy);
    });
  });

  unittest.group('obj-schema-JobListJobs', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobListJobs();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobListJobs.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobListJobs(od as api.JobListJobs);
    });
  });

  unittest.group('obj-schema-JobList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.JobList.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkJobList(od as api.JobList);
    });
  });

  unittest.group('obj-schema-JobReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobReference(od as api.JobReference);
    });
  });

  unittest.group('obj-schema-JobStatisticsReservationUsage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobStatisticsReservationUsage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobStatisticsReservationUsage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobStatisticsReservationUsage(
          od as api.JobStatisticsReservationUsage);
    });
  });

  unittest.group('obj-schema-JobStatistics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobStatistics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobStatistics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobStatistics(od as api.JobStatistics);
    });
  });

  unittest.group('obj-schema-JobStatistics2ReservationUsage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobStatistics2ReservationUsage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobStatistics2ReservationUsage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobStatistics2ReservationUsage(
          od as api.JobStatistics2ReservationUsage);
    });
  });

  unittest.group('obj-schema-JobStatistics2', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobStatistics2();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobStatistics2.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobStatistics2(od as api.JobStatistics2);
    });
  });

  unittest.group('obj-schema-JobStatistics3', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobStatistics3();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobStatistics3.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobStatistics3(od as api.JobStatistics3);
    });
  });

  unittest.group('obj-schema-JobStatistics4', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobStatistics4();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.JobStatistics4.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkJobStatistics4(od as api.JobStatistics4);
    });
  });

  unittest.group('obj-schema-JobStatus', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJobStatus();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.JobStatus.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkJobStatus(od as api.JobStatus);
    });
  });

  unittest.group('obj-schema-JsonObject', () {
    unittest.test('to-json--from-json', () async {
      var o = buildJsonObject();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.JsonObject.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkJsonObject(od as api.JsonObject);
    });
  });

  unittest.group('obj-schema-ListModelsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListModelsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListModelsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListModelsResponse(od as api.ListModelsResponse);
    });
  });

  unittest.group('obj-schema-ListRoutinesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListRoutinesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListRoutinesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListRoutinesResponse(od as api.ListRoutinesResponse);
    });
  });

  unittest.group('obj-schema-ListRowAccessPoliciesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListRowAccessPoliciesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListRowAccessPoliciesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListRowAccessPoliciesResponse(
          od as api.ListRowAccessPoliciesResponse);
    });
  });

  unittest.group('obj-schema-LocationMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocationMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LocationMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLocationMetadata(od as api.LocationMetadata);
    });
  });

  unittest.group('obj-schema-MaterializedViewDefinition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMaterializedViewDefinition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MaterializedViewDefinition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMaterializedViewDefinition(od as api.MaterializedViewDefinition);
    });
  });

  unittest.group('obj-schema-Model', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModel();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Model.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkModel(od as api.Model);
    });
  });

  unittest.group('obj-schema-ModelDefinitionModelOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModelDefinitionModelOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ModelDefinitionModelOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkModelDefinitionModelOptions(od as api.ModelDefinitionModelOptions);
    });
  });

  unittest.group('obj-schema-ModelDefinition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModelDefinition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ModelDefinition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkModelDefinition(od as api.ModelDefinition);
    });
  });

  unittest.group('obj-schema-ModelReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModelReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ModelReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkModelReference(od as api.ModelReference);
    });
  });

  unittest.group('obj-schema-MultiClassClassificationMetrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMultiClassClassificationMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MultiClassClassificationMetrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMultiClassClassificationMetrics(
          od as api.MultiClassClassificationMetrics);
    });
  });

  unittest.group('obj-schema-ParquetOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildParquetOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ParquetOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkParquetOptions(od as api.ParquetOptions);
    });
  });

  unittest.group('obj-schema-Policy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Policy.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkPolicy(od as api.Policy);
    });
  });

  unittest.group('obj-schema-ProjectListProjects', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProjectListProjects();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProjectListProjects.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProjectListProjects(od as api.ProjectListProjects);
    });
  });

  unittest.group('obj-schema-ProjectList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProjectList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProjectList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProjectList(od as api.ProjectList);
    });
  });

  unittest.group('obj-schema-ProjectReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildProjectReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ProjectReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkProjectReference(od as api.ProjectReference);
    });
  });

  unittest.group('obj-schema-QueryParameter', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryParameter();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryParameter.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryParameter(od as api.QueryParameter);
    });
  });

  unittest.group('obj-schema-QueryParameterTypeStructTypes', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryParameterTypeStructTypes();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryParameterTypeStructTypes.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryParameterTypeStructTypes(
          od as api.QueryParameterTypeStructTypes);
    });
  });

  unittest.group('obj-schema-QueryParameterType', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryParameterType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryParameterType.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryParameterType(od as api.QueryParameterType);
    });
  });

  unittest.group('obj-schema-QueryParameterValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryParameterValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryParameterValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryParameterValue(od as api.QueryParameterValue);
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

  unittest.group('obj-schema-QueryTimelineSample', () {
    unittest.test('to-json--from-json', () async {
      var o = buildQueryTimelineSample();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.QueryTimelineSample.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkQueryTimelineSample(od as api.QueryTimelineSample);
    });
  });

  unittest.group('obj-schema-RangePartitioningRange', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRangePartitioningRange();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RangePartitioningRange.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRangePartitioningRange(od as api.RangePartitioningRange);
    });
  });

  unittest.group('obj-schema-RangePartitioning', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRangePartitioning();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RangePartitioning.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRangePartitioning(od as api.RangePartitioning);
    });
  });

  unittest.group('obj-schema-RankingMetrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRankingMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RankingMetrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRankingMetrics(od as api.RankingMetrics);
    });
  });

  unittest.group('obj-schema-RegressionMetrics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRegressionMetrics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RegressionMetrics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRegressionMetrics(od as api.RegressionMetrics);
    });
  });

  unittest.group('obj-schema-Routine', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRoutine();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Routine.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRoutine(od as api.Routine);
    });
  });

  unittest.group('obj-schema-RoutineReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRoutineReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RoutineReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRoutineReference(od as api.RoutineReference);
    });
  });

  unittest.group('obj-schema-Row', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRow();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Row.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkRow(od as api.Row);
    });
  });

  unittest.group('obj-schema-RowAccessPolicy', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRowAccessPolicy();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RowAccessPolicy.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRowAccessPolicy(od as api.RowAccessPolicy);
    });
  });

  unittest.group('obj-schema-RowAccessPolicyReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRowAccessPolicyReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RowAccessPolicyReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRowAccessPolicyReference(od as api.RowAccessPolicyReference);
    });
  });

  unittest.group('obj-schema-RowLevelSecurityStatistics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRowLevelSecurityStatistics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RowLevelSecurityStatistics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRowLevelSecurityStatistics(od as api.RowLevelSecurityStatistics);
    });
  });

  unittest.group('obj-schema-ScriptStackFrame', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScriptStackFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ScriptStackFrame.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkScriptStackFrame(od as api.ScriptStackFrame);
    });
  });

  unittest.group('obj-schema-ScriptStatistics', () {
    unittest.test('to-json--from-json', () async {
      var o = buildScriptStatistics();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ScriptStatistics.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkScriptStatistics(od as api.ScriptStatistics);
    });
  });

  unittest.group('obj-schema-SessionInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSessionInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SessionInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSessionInfo(od as api.SessionInfo);
    });
  });

  unittest.group('obj-schema-SetIamPolicyRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSetIamPolicyRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SetIamPolicyRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSetIamPolicyRequest(od as api.SetIamPolicyRequest);
    });
  });

  unittest.group('obj-schema-SnapshotDefinition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSnapshotDefinition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SnapshotDefinition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSnapshotDefinition(od as api.SnapshotDefinition);
    });
  });

  unittest.group('obj-schema-StandardSqlDataType', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStandardSqlDataType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StandardSqlDataType.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStandardSqlDataType(od as api.StandardSqlDataType);
    });
  });

  unittest.group('obj-schema-StandardSqlField', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStandardSqlField();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StandardSqlField.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStandardSqlField(od as api.StandardSqlField);
    });
  });

  unittest.group('obj-schema-StandardSqlStructType', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStandardSqlStructType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StandardSqlStructType.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStandardSqlStructType(od as api.StandardSqlStructType);
    });
  });

  unittest.group('obj-schema-StandardSqlTableType', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStandardSqlTableType();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StandardSqlTableType.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStandardSqlTableType(od as api.StandardSqlTableType);
    });
  });

  unittest.group('obj-schema-Streamingbuffer', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStreamingbuffer();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Streamingbuffer.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStreamingbuffer(od as api.Streamingbuffer);
    });
  });

  unittest.group('obj-schema-Table', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTable();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Table.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTable(od as api.Table);
    });
  });

  unittest.group('obj-schema-TableCell', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableCell();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TableCell.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTableCell(od as api.TableCell);
    });
  });

  unittest.group('obj-schema-TableDataInsertAllRequestRows', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableDataInsertAllRequestRows();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableDataInsertAllRequestRows.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableDataInsertAllRequestRows(
          od as api.TableDataInsertAllRequestRows);
    });
  });

  unittest.group('obj-schema-TableDataInsertAllRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableDataInsertAllRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableDataInsertAllRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableDataInsertAllRequest(od as api.TableDataInsertAllRequest);
    });
  });

  unittest.group('obj-schema-TableDataInsertAllResponseInsertErrors', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableDataInsertAllResponseInsertErrors();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableDataInsertAllResponseInsertErrors.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableDataInsertAllResponseInsertErrors(
          od as api.TableDataInsertAllResponseInsertErrors);
    });
  });

  unittest.group('obj-schema-TableDataInsertAllResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableDataInsertAllResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableDataInsertAllResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableDataInsertAllResponse(od as api.TableDataInsertAllResponse);
    });
  });

  unittest.group('obj-schema-TableDataList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableDataList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableDataList.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableDataList(od as api.TableDataList);
    });
  });

  unittest.group('obj-schema-TableFieldSchemaCategories', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableFieldSchemaCategories();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableFieldSchemaCategories.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableFieldSchemaCategories(od as api.TableFieldSchemaCategories);
    });
  });

  unittest.group('obj-schema-TableFieldSchemaPolicyTags', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableFieldSchemaPolicyTags();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableFieldSchemaPolicyTags.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableFieldSchemaPolicyTags(od as api.TableFieldSchemaPolicyTags);
    });
  });

  unittest.group('obj-schema-TableFieldSchema', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableFieldSchema();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableFieldSchema.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableFieldSchema(od as api.TableFieldSchema);
    });
  });

  unittest.group('obj-schema-TableListTablesView', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableListTablesView();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableListTablesView.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableListTablesView(od as api.TableListTablesView);
    });
  });

  unittest.group('obj-schema-TableListTables', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableListTables();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableListTables.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableListTables(od as api.TableListTables);
    });
  });

  unittest.group('obj-schema-TableList', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableList();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TableList.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTableList(od as api.TableList);
    });
  });

  unittest.group('obj-schema-TableReference', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableReference();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableReference.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableReference(od as api.TableReference);
    });
  });

  unittest.group('obj-schema-TableRow', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableRow();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TableRow.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTableRow(od as api.TableRow);
    });
  });

  unittest.group('obj-schema-TableSchema', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTableSchema();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TableSchema.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTableSchema(od as api.TableSchema);
    });
  });

  unittest.group('obj-schema-TestIamPermissionsRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestIamPermissionsRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestIamPermissionsRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestIamPermissionsRequest(od as api.TestIamPermissionsRequest);
    });
  });

  unittest.group('obj-schema-TestIamPermissionsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTestIamPermissionsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TestIamPermissionsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTestIamPermissionsResponse(od as api.TestIamPermissionsResponse);
    });
  });

  unittest.group('obj-schema-TimePartitioning', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimePartitioning();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TimePartitioning.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTimePartitioning(od as api.TimePartitioning);
    });
  });

  unittest.group('obj-schema-TrainingOptions', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTrainingOptions();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TrainingOptions.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTrainingOptions(od as api.TrainingOptions);
    });
  });

  unittest.group('obj-schema-TrainingRun', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTrainingRun();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TrainingRun.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTrainingRun(od as api.TrainingRun);
    });
  });

  unittest.group('obj-schema-TransactionInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTransactionInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TransactionInfo.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTransactionInfo(od as api.TransactionInfo);
    });
  });

  unittest.group('obj-schema-UserDefinedFunctionResource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildUserDefinedFunctionResource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.UserDefinedFunctionResource.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkUserDefinedFunctionResource(od as api.UserDefinedFunctionResource);
    });
  });

  unittest.group('obj-schema-ViewDefinition', () {
    unittest.test('to-json--from-json', () async {
      var o = buildViewDefinition();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ViewDefinition.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkViewDefinition(od as api.ViewDefinition);
    });
  });

  unittest.group('resource-DatasetsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).datasets;
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_deleteContents = true;
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/datasets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/datasets/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_datasetId'),
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
          queryMap["deleteContents"]!.first,
          unittest.equals("$arg_deleteContents"),
        );
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
      await res.delete(arg_projectId, arg_datasetId,
          deleteContents: arg_deleteContents, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).datasets;
      var arg_projectId = 'foo';
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
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/datasets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/datasets/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_datasetId'),
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
        var resp = convert.json.encode(buildDataset());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.get(arg_projectId, arg_datasetId, $fields: arg_$fields);
      checkDataset(response as api.Dataset);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).datasets;
      var arg_request = buildDataset();
      var arg_projectId = 'foo';
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
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/datasets', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/datasets"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDataset());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_projectId, $fields: arg_$fields);
      checkDataset(response as api.Dataset);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).datasets;
      var arg_projectId = 'foo';
      var arg_all = true;
      var arg_filter = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/datasets', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/datasets"),
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
          queryMap["all"]!.first,
          unittest.equals("$arg_all"),
        );
        unittest.expect(
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildDatasetList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_projectId,
          all: arg_all,
          filter: arg_filter,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkDatasetList(response as api.DatasetList);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).datasets;
      var arg_request = buildDataset();
      var arg_projectId = 'foo';
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
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/datasets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/datasets/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_datasetId'),
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
        var resp = convert.json.encode(buildDataset());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_projectId, arg_datasetId,
          $fields: arg_$fields);
      checkDataset(response as api.Dataset);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).datasets;
      var arg_request = buildDataset();
      var arg_projectId = 'foo';
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
        unittest.expect(
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/datasets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/datasets/"),
        );
        pathOffset += 10;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_datasetId'),
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
        var resp = convert.json.encode(buildDataset());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_projectId, arg_datasetId,
          $fields: arg_$fields);
      checkDataset(response as api.Dataset);
    });
  });

  unittest.group('resource-JobsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).jobs;
      var arg_projectId = 'foo';
      var arg_jobId = 'foo';
      var arg_location = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/jobs/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/jobs/"),
        );
        pathOffset += 6;
        index = path.indexOf('/cancel', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_jobId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/cancel"),
        );
        pathOffset += 7;

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
          queryMap["location"]!.first,
          unittest.equals(arg_location),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildJobCancelResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.cancel(arg_projectId, arg_jobId,
          location: arg_location, $fields: arg_$fields);
      checkJobCancelResponse(response as api.JobCancelResponse);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).jobs;
      var arg_projectId = 'foo';
      var arg_jobId = 'foo';
      var arg_location = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
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
          queryMap["location"]!.first,
          unittest.equals(arg_location),
        );
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
      await res.delete(arg_projectId, arg_jobId,
          location: arg_location, $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).jobs;
      var arg_projectId = 'foo';
      var arg_jobId = 'foo';
      var arg_location = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/jobs/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 6),
          unittest.equals("/jobs/"),
        );
        pathOffset += 6;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_jobId'),
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
          queryMap["location"]!.first,
          unittest.equals(arg_location),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_projectId, arg_jobId,
          location: arg_location, $fields: arg_$fields);
      checkJob(response as api.Job);
    });

    unittest.test('method--getQueryResults', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).jobs;
      var arg_projectId = 'foo';
      var arg_jobId = 'foo';
      var arg_location = 'foo';
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_startIndex = 'foo';
      var arg_timeoutMs = 42;
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/queries/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("/queries/"),
        );
        pathOffset += 9;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_jobId'),
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
          queryMap["location"]!.first,
          unittest.equals(arg_location),
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
          queryMap["startIndex"]!.first,
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          core.int.parse(queryMap["timeoutMs"]!.first),
          unittest.equals(arg_timeoutMs),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildGetQueryResultsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getQueryResults(arg_projectId, arg_jobId,
          location: arg_location,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          startIndex: arg_startIndex,
          timeoutMs: arg_timeoutMs,
          $fields: arg_$fields);
      checkGetQueryResultsResponse(response as api.GetQueryResultsResponse);
    });

    unittest.test('method--insert', () async {
      // TODO: Implement tests for media upload;
      // TODO: Implement tests for media download;

      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).jobs;
      var arg_request = buildJob();
      var arg_projectId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.Job.fromJson(json as core.Map<core.String, core.dynamic>);
        checkJob(obj as api.Job);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/jobs', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 5),
          unittest.equals("/jobs"),
        );
        pathOffset += 5;

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
        var resp = convert.json.encode(buildJob());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.insert(arg_request, arg_projectId, $fields: arg_$fields);
      checkJob(response as api.Job);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).jobs;
      var arg_projectId = 'foo';
      var arg_allUsers = true;
      var arg_maxCreationTime = 'foo';
      var arg_maxResults = 42;
      var arg_minCreationTime = 'foo';
      var arg_pageToken = 'foo';
      var arg_parentJobId = 'foo';
      var arg_projection = 'foo';
      var arg_stateFilter = buildUnnamed1570();
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/jobs', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 5),
          unittest.equals("/jobs"),
        );
        pathOffset += 5;

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
          queryMap["allUsers"]!.first,
          unittest.equals("$arg_allUsers"),
        );
        unittest.expect(
          queryMap["maxCreationTime"]!.first,
          unittest.equals(arg_maxCreationTime),
        );
        unittest.expect(
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["minCreationTime"]!.first,
          unittest.equals(arg_minCreationTime),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["parentJobId"]!.first,
          unittest.equals(arg_parentJobId),
        );
        unittest.expect(
          queryMap["projection"]!.first,
          unittest.equals(arg_projection),
        );
        unittest.expect(
          queryMap["stateFilter"]!,
          unittest.equals(arg_stateFilter),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildJobList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_projectId,
          allUsers: arg_allUsers,
          maxCreationTime: arg_maxCreationTime,
          maxResults: arg_maxResults,
          minCreationTime: arg_minCreationTime,
          pageToken: arg_pageToken,
          parentJobId: arg_parentJobId,
          projection: arg_projection,
          stateFilter: arg_stateFilter,
          $fields: arg_$fields);
      checkJobList(response as api.JobList);
    });

    unittest.test('method--query', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).jobs;
      var arg_request = buildQueryRequest();
      var arg_projectId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/queries', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/queries"),
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
        var resp = convert.json.encode(buildQueryResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.query(arg_request, arg_projectId, $fields: arg_$fields);
      checkQueryResponse(response as api.QueryResponse);
    });
  });

  unittest.group('resource-ModelsResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).models;
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_modelId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_projectId, arg_datasetId, arg_modelId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).models;
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_modelId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
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
        var resp = convert.json.encode(buildModel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_projectId, arg_datasetId, arg_modelId,
          $fields: arg_$fields);
      checkModel(response as api.Model);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).models;
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
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
        var resp = convert.json.encode(buildListModelsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_projectId, arg_datasetId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListModelsResponse(response as api.ListModelsResponse);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).models;
      var arg_request = buildModel();
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_modelId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Model.fromJson(json as core.Map<core.String, core.dynamic>);
        checkModel(obj as api.Model);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
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
        var resp = convert.json.encode(buildModel());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_projectId, arg_datasetId, arg_modelId,
          $fields: arg_$fields);
      checkModel(response as api.Model);
    });
  });

  unittest.group('resource-ProjectsResource', () {
    unittest.test('method--getServiceAccount', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).projects;
      var arg_projectId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/serviceAccount', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 15),
          unittest.equals("/serviceAccount"),
        );
        pathOffset += 15;

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
        var resp = convert.json.encode(buildGetServiceAccountResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.getServiceAccount(arg_projectId, $fields: arg_$fields);
      checkGetServiceAccountResponse(response as api.GetServiceAccountResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).projects;
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("projects"),
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
        var resp = convert.json.encode(buildProjectList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkProjectList(response as api.ProjectList);
    });
  });

  unittest.group('resource-RoutinesResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).routines;
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_routineId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
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
        var resp = '';
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      await res.delete(arg_projectId, arg_datasetId, arg_routineId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).routines;
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_routineId = 'foo';
      var arg_readMask = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
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
          queryMap["readMask"]!.first,
          unittest.equals(arg_readMask),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildRoutine());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(
          arg_projectId, arg_datasetId, arg_routineId,
          readMask: arg_readMask, $fields: arg_$fields);
      checkRoutine(response as api.Routine);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).routines;
      var arg_request = buildRoutine();
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Routine.fromJson(json as core.Map<core.String, core.dynamic>);
        checkRoutine(obj as api.Routine);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
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
        var resp = convert.json.encode(buildRoutine());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(
          arg_request, arg_projectId, arg_datasetId,
          $fields: arg_$fields);
      checkRoutine(response as api.Routine);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).routines;
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_filter = 'foo';
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_readMask = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
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
          core.int.parse(queryMap["maxResults"]!.first),
          unittest.equals(arg_maxResults),
        );
        unittest.expect(
          queryMap["pageToken"]!.first,
          unittest.equals(arg_pageToken),
        );
        unittest.expect(
          queryMap["readMask"]!.first,
          unittest.equals(arg_readMask),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildListRoutinesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_projectId, arg_datasetId,
          filter: arg_filter,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          readMask: arg_readMask,
          $fields: arg_$fields);
      checkListRoutinesResponse(response as api.ListRoutinesResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).routines;
      var arg_request = buildRoutine();
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_routineId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Routine.fromJson(json as core.Map<core.String, core.dynamic>);
        checkRoutine(obj as api.Routine);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
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
        var resp = convert.json.encode(buildRoutine());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_projectId, arg_datasetId, arg_routineId,
          $fields: arg_$fields);
      checkRoutine(response as api.Routine);
    });
  });

  unittest.group('resource-RowAccessPoliciesResource', () {
    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).rowAccessPolicies;
      var arg_request = buildGetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetIamPolicyRequest(obj as api.GetIamPolicyRequest);

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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).rowAccessPolicies;
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_tableId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
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
        var resp = convert.json.encode(buildListRowAccessPoliciesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_projectId, arg_datasetId, arg_tableId,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListRowAccessPoliciesResponse(
          response as api.ListRowAccessPoliciesResponse);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).rowAccessPolicies;
      var arg_request = buildSetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetIamPolicyRequest(obj as api.SetIamPolicyRequest);

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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).rowAccessPolicies;
      var arg_request = buildTestIamPermissionsRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TestIamPermissionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTestIamPermissionsRequest(obj as api.TestIamPermissionsRequest);

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
        var resp = convert.json.encode(buildTestIamPermissionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.testIamPermissions(arg_request, arg_resource,
          $fields: arg_$fields);
      checkTestIamPermissionsResponse(
          response as api.TestIamPermissionsResponse);
    });
  });

  unittest.group('resource-TabledataResource', () {
    unittest.test('method--insertAll', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).tabledata;
      var arg_request = buildTableDataInsertAllRequest();
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_tableId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TableDataInsertAllRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTableDataInsertAllRequest(obj as api.TableDataInsertAllRequest);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/datasets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/datasets/"),
        );
        pathOffset += 10;
        index = path.indexOf('/tables/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_datasetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tables/"),
        );
        pathOffset += 8;
        index = path.indexOf('/insertAll', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tableId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/insertAll"),
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
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTableDataInsertAllResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insertAll(
          arg_request, arg_projectId, arg_datasetId, arg_tableId,
          $fields: arg_$fields);
      checkTableDataInsertAllResponse(
          response as api.TableDataInsertAllResponse);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).tabledata;
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_tableId = 'foo';
      var arg_maxResults = 42;
      var arg_pageToken = 'foo';
      var arg_selectedFields = 'foo';
      var arg_startIndex = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/datasets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/datasets/"),
        );
        pathOffset += 10;
        index = path.indexOf('/tables/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_datasetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tables/"),
        );
        pathOffset += 8;
        index = path.indexOf('/data', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tableId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 5),
          unittest.equals("/data"),
        );
        pathOffset += 5;

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
          queryMap["selectedFields"]!.first,
          unittest.equals(arg_selectedFields),
        );
        unittest.expect(
          queryMap["startIndex"]!.first,
          unittest.equals(arg_startIndex),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTableDataList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_projectId, arg_datasetId, arg_tableId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          selectedFields: arg_selectedFields,
          startIndex: arg_startIndex,
          $fields: arg_$fields);
      checkTableDataList(response as api.TableDataList);
    });
  });

  unittest.group('resource-TablesResource', () {
    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).tables;
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_tableId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/datasets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/datasets/"),
        );
        pathOffset += 10;
        index = path.indexOf('/tables/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_datasetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tables/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tableId'),
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
      await res.delete(arg_projectId, arg_datasetId, arg_tableId,
          $fields: arg_$fields);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).tables;
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_tableId = 'foo';
      var arg_selectedFields = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/datasets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/datasets/"),
        );
        pathOffset += 10;
        index = path.indexOf('/tables/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_datasetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tables/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tableId'),
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
          queryMap["selectedFields"]!.first,
          unittest.equals(arg_selectedFields),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildTable());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_projectId, arg_datasetId, arg_tableId,
          selectedFields: arg_selectedFields, $fields: arg_$fields);
      checkTable(response as api.Table);
    });

    unittest.test('method--getIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).tables;
      var arg_request = buildGetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.GetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkGetIamPolicyRequest(obj as api.GetIamPolicyRequest);

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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--insert', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).tables;
      var arg_request = buildTable();
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Table.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTable(obj as api.Table);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/datasets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/datasets/"),
        );
        pathOffset += 10;
        index = path.indexOf('/tables', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_datasetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/tables"),
        );
        pathOffset += 7;

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
        var resp = convert.json.encode(buildTable());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.insert(
          arg_request, arg_projectId, arg_datasetId,
          $fields: arg_$fields);
      checkTable(response as api.Table);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).tables;
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/datasets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/datasets/"),
        );
        pathOffset += 10;
        index = path.indexOf('/tables', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_datasetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 7),
          unittest.equals("/tables"),
        );
        pathOffset += 7;

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
        var resp = convert.json.encode(buildTableList());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_projectId, arg_datasetId,
          maxResults: arg_maxResults,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkTableList(response as api.TableList);
    });

    unittest.test('method--patch', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).tables;
      var arg_request = buildTable();
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_tableId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Table.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTable(obj as api.Table);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/datasets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/datasets/"),
        );
        pathOffset += 10;
        index = path.indexOf('/tables/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_datasetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tables/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tableId'),
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
        var resp = convert.json.encode(buildTable());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.patch(
          arg_request, arg_projectId, arg_datasetId, arg_tableId,
          $fields: arg_$fields);
      checkTable(response as api.Table);
    });

    unittest.test('method--setIamPolicy', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).tables;
      var arg_request = buildSetIamPolicyRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.SetIamPolicyRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkSetIamPolicyRequest(obj as api.SetIamPolicyRequest);

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
        var resp = convert.json.encode(buildPolicy());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.setIamPolicy(arg_request, arg_resource,
          $fields: arg_$fields);
      checkPolicy(response as api.Policy);
    });

    unittest.test('method--testIamPermissions', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).tables;
      var arg_request = buildTestIamPermissionsRequest();
      var arg_resource = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TestIamPermissionsRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTestIamPermissionsRequest(obj as api.TestIamPermissionsRequest);

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
        var resp = convert.json.encode(buildTestIamPermissionsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.testIamPermissions(arg_request, arg_resource,
          $fields: arg_$fields);
      checkTestIamPermissionsResponse(
          response as api.TestIamPermissionsResponse);
    });

    unittest.test('method--update', () async {
      var mock = HttpServerMock();
      var res = api.BigqueryApi(mock).tables;
      var arg_request = buildTable();
      var arg_projectId = 'foo';
      var arg_datasetId = 'foo';
      var arg_tableId = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Table.fromJson(json as core.Map<core.String, core.dynamic>);
        checkTable(obj as api.Table);

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
          path.substring(pathOffset, pathOffset + 12),
          unittest.equals("bigquery/v2/"),
        );
        pathOffset += 12;
        unittest.expect(
          path.substring(pathOffset, pathOffset + 9),
          unittest.equals("projects/"),
        );
        pathOffset += 9;
        index = path.indexOf('/datasets/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_projectId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 10),
          unittest.equals("/datasets/"),
        );
        pathOffset += 10;
        index = path.indexOf('/tables/', pathOffset);
        unittest.expect(index >= 0, unittest.isTrue);
        subPart =
            core.Uri.decodeQueryComponent(path.substring(pathOffset, index));
        pathOffset = index;
        unittest.expect(
          subPart,
          unittest.equals('$arg_datasetId'),
        );
        unittest.expect(
          path.substring(pathOffset, pathOffset + 8),
          unittest.equals("/tables/"),
        );
        pathOffset += 8;
        subPart = core.Uri.decodeQueryComponent(path.substring(pathOffset));
        pathOffset = path.length;
        unittest.expect(
          subPart,
          unittest.equals('$arg_tableId'),
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
        var resp = convert.json.encode(buildTable());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.update(
          arg_request, arg_projectId, arg_datasetId, arg_tableId,
          $fields: arg_$fields);
      checkTable(response as api.Table);
    });
  });
}
