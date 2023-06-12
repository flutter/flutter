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

import 'package:googleapis/translate/v3.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.Map<core.String, api.TranslateTextGlossaryConfig> buildUnnamed6122() {
  var o = <core.String, api.TranslateTextGlossaryConfig>{};
  o['x'] = buildTranslateTextGlossaryConfig();
  o['y'] = buildTranslateTextGlossaryConfig();
  return o;
}

void checkUnnamed6122(
    core.Map<core.String, api.TranslateTextGlossaryConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTranslateTextGlossaryConfig(o['x']! as api.TranslateTextGlossaryConfig);
  checkTranslateTextGlossaryConfig(o['y']! as api.TranslateTextGlossaryConfig);
}

core.List<api.InputConfig> buildUnnamed6123() {
  var o = <api.InputConfig>[];
  o.add(buildInputConfig());
  o.add(buildInputConfig());
  return o;
}

void checkUnnamed6123(core.List<api.InputConfig> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkInputConfig(o[0] as api.InputConfig);
  checkInputConfig(o[1] as api.InputConfig);
}

core.Map<core.String, core.String> buildUnnamed6124() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed6124(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed6125() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed6125(core.Map<core.String, core.String> o) {
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

core.List<core.String> buildUnnamed6126() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed6126(core.List<core.String> o) {
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

core.int buildCounterBatchTranslateTextRequest = 0;
api.BatchTranslateTextRequest buildBatchTranslateTextRequest() {
  var o = api.BatchTranslateTextRequest();
  buildCounterBatchTranslateTextRequest++;
  if (buildCounterBatchTranslateTextRequest < 3) {
    o.glossaries = buildUnnamed6122();
    o.inputConfigs = buildUnnamed6123();
    o.labels = buildUnnamed6124();
    o.models = buildUnnamed6125();
    o.outputConfig = buildOutputConfig();
    o.sourceLanguageCode = 'foo';
    o.targetLanguageCodes = buildUnnamed6126();
  }
  buildCounterBatchTranslateTextRequest--;
  return o;
}

void checkBatchTranslateTextRequest(api.BatchTranslateTextRequest o) {
  buildCounterBatchTranslateTextRequest++;
  if (buildCounterBatchTranslateTextRequest < 3) {
    checkUnnamed6122(o.glossaries!);
    checkUnnamed6123(o.inputConfigs!);
    checkUnnamed6124(o.labels!);
    checkUnnamed6125(o.models!);
    checkOutputConfig(o.outputConfig! as api.OutputConfig);
    unittest.expect(
      o.sourceLanguageCode!,
      unittest.equals('foo'),
    );
    checkUnnamed6126(o.targetLanguageCodes!);
  }
  buildCounterBatchTranslateTextRequest--;
}

core.int buildCounterCancelOperationRequest = 0;
api.CancelOperationRequest buildCancelOperationRequest() {
  var o = api.CancelOperationRequest();
  buildCounterCancelOperationRequest++;
  if (buildCounterCancelOperationRequest < 3) {}
  buildCounterCancelOperationRequest--;
  return o;
}

void checkCancelOperationRequest(api.CancelOperationRequest o) {
  buildCounterCancelOperationRequest++;
  if (buildCounterCancelOperationRequest < 3) {}
  buildCounterCancelOperationRequest--;
}

core.Map<core.String, core.String> buildUnnamed6127() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed6127(core.Map<core.String, core.String> o) {
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

core.int buildCounterDetectLanguageRequest = 0;
api.DetectLanguageRequest buildDetectLanguageRequest() {
  var o = api.DetectLanguageRequest();
  buildCounterDetectLanguageRequest++;
  if (buildCounterDetectLanguageRequest < 3) {
    o.content = 'foo';
    o.labels = buildUnnamed6127();
    o.mimeType = 'foo';
    o.model = 'foo';
  }
  buildCounterDetectLanguageRequest--;
  return o;
}

void checkDetectLanguageRequest(api.DetectLanguageRequest o) {
  buildCounterDetectLanguageRequest++;
  if (buildCounterDetectLanguageRequest < 3) {
    unittest.expect(
      o.content!,
      unittest.equals('foo'),
    );
    checkUnnamed6127(o.labels!);
    unittest.expect(
      o.mimeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.model!,
      unittest.equals('foo'),
    );
  }
  buildCounterDetectLanguageRequest--;
}

core.List<api.DetectedLanguage> buildUnnamed6128() {
  var o = <api.DetectedLanguage>[];
  o.add(buildDetectedLanguage());
  o.add(buildDetectedLanguage());
  return o;
}

void checkUnnamed6128(core.List<api.DetectedLanguage> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkDetectedLanguage(o[0] as api.DetectedLanguage);
  checkDetectedLanguage(o[1] as api.DetectedLanguage);
}

core.int buildCounterDetectLanguageResponse = 0;
api.DetectLanguageResponse buildDetectLanguageResponse() {
  var o = api.DetectLanguageResponse();
  buildCounterDetectLanguageResponse++;
  if (buildCounterDetectLanguageResponse < 3) {
    o.languages = buildUnnamed6128();
  }
  buildCounterDetectLanguageResponse--;
  return o;
}

void checkDetectLanguageResponse(api.DetectLanguageResponse o) {
  buildCounterDetectLanguageResponse++;
  if (buildCounterDetectLanguageResponse < 3) {
    checkUnnamed6128(o.languages!);
  }
  buildCounterDetectLanguageResponse--;
}

core.int buildCounterDetectedLanguage = 0;
api.DetectedLanguage buildDetectedLanguage() {
  var o = api.DetectedLanguage();
  buildCounterDetectedLanguage++;
  if (buildCounterDetectedLanguage < 3) {
    o.confidence = 42.0;
    o.languageCode = 'foo';
  }
  buildCounterDetectedLanguage--;
  return o;
}

void checkDetectedLanguage(api.DetectedLanguage o) {
  buildCounterDetectedLanguage++;
  if (buildCounterDetectedLanguage < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterDetectedLanguage--;
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

core.int buildCounterGcsDestination = 0;
api.GcsDestination buildGcsDestination() {
  var o = api.GcsDestination();
  buildCounterGcsDestination++;
  if (buildCounterGcsDestination < 3) {
    o.outputUriPrefix = 'foo';
  }
  buildCounterGcsDestination--;
  return o;
}

void checkGcsDestination(api.GcsDestination o) {
  buildCounterGcsDestination++;
  if (buildCounterGcsDestination < 3) {
    unittest.expect(
      o.outputUriPrefix!,
      unittest.equals('foo'),
    );
  }
  buildCounterGcsDestination--;
}

core.int buildCounterGcsSource = 0;
api.GcsSource buildGcsSource() {
  var o = api.GcsSource();
  buildCounterGcsSource++;
  if (buildCounterGcsSource < 3) {
    o.inputUri = 'foo';
  }
  buildCounterGcsSource--;
  return o;
}

void checkGcsSource(api.GcsSource o) {
  buildCounterGcsSource++;
  if (buildCounterGcsSource < 3) {
    unittest.expect(
      o.inputUri!,
      unittest.equals('foo'),
    );
  }
  buildCounterGcsSource--;
}

core.int buildCounterGlossary = 0;
api.Glossary buildGlossary() {
  var o = api.Glossary();
  buildCounterGlossary++;
  if (buildCounterGlossary < 3) {
    o.endTime = 'foo';
    o.entryCount = 42;
    o.inputConfig = buildGlossaryInputConfig();
    o.languageCodesSet = buildLanguageCodesSet();
    o.languagePair = buildLanguageCodePair();
    o.name = 'foo';
    o.submitTime = 'foo';
  }
  buildCounterGlossary--;
  return o;
}

void checkGlossary(api.Glossary o) {
  buildCounterGlossary++;
  if (buildCounterGlossary < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.entryCount!,
      unittest.equals(42),
    );
    checkGlossaryInputConfig(o.inputConfig! as api.GlossaryInputConfig);
    checkLanguageCodesSet(o.languageCodesSet! as api.LanguageCodesSet);
    checkLanguageCodePair(o.languagePair! as api.LanguageCodePair);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.submitTime!,
      unittest.equals('foo'),
    );
  }
  buildCounterGlossary--;
}

core.int buildCounterGlossaryInputConfig = 0;
api.GlossaryInputConfig buildGlossaryInputConfig() {
  var o = api.GlossaryInputConfig();
  buildCounterGlossaryInputConfig++;
  if (buildCounterGlossaryInputConfig < 3) {
    o.gcsSource = buildGcsSource();
  }
  buildCounterGlossaryInputConfig--;
  return o;
}

void checkGlossaryInputConfig(api.GlossaryInputConfig o) {
  buildCounterGlossaryInputConfig++;
  if (buildCounterGlossaryInputConfig < 3) {
    checkGcsSource(o.gcsSource! as api.GcsSource);
  }
  buildCounterGlossaryInputConfig--;
}

core.int buildCounterInputConfig = 0;
api.InputConfig buildInputConfig() {
  var o = api.InputConfig();
  buildCounterInputConfig++;
  if (buildCounterInputConfig < 3) {
    o.gcsSource = buildGcsSource();
    o.mimeType = 'foo';
  }
  buildCounterInputConfig--;
  return o;
}

void checkInputConfig(api.InputConfig o) {
  buildCounterInputConfig++;
  if (buildCounterInputConfig < 3) {
    checkGcsSource(o.gcsSource! as api.GcsSource);
    unittest.expect(
      o.mimeType!,
      unittest.equals('foo'),
    );
  }
  buildCounterInputConfig--;
}

core.int buildCounterLanguageCodePair = 0;
api.LanguageCodePair buildLanguageCodePair() {
  var o = api.LanguageCodePair();
  buildCounterLanguageCodePair++;
  if (buildCounterLanguageCodePair < 3) {
    o.sourceLanguageCode = 'foo';
    o.targetLanguageCode = 'foo';
  }
  buildCounterLanguageCodePair--;
  return o;
}

void checkLanguageCodePair(api.LanguageCodePair o) {
  buildCounterLanguageCodePair++;
  if (buildCounterLanguageCodePair < 3) {
    unittest.expect(
      o.sourceLanguageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetLanguageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterLanguageCodePair--;
}

core.List<core.String> buildUnnamed6129() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed6129(core.List<core.String> o) {
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

core.int buildCounterLanguageCodesSet = 0;
api.LanguageCodesSet buildLanguageCodesSet() {
  var o = api.LanguageCodesSet();
  buildCounterLanguageCodesSet++;
  if (buildCounterLanguageCodesSet < 3) {
    o.languageCodes = buildUnnamed6129();
  }
  buildCounterLanguageCodesSet--;
  return o;
}

void checkLanguageCodesSet(api.LanguageCodesSet o) {
  buildCounterLanguageCodesSet++;
  if (buildCounterLanguageCodesSet < 3) {
    checkUnnamed6129(o.languageCodes!);
  }
  buildCounterLanguageCodesSet--;
}

core.List<api.Glossary> buildUnnamed6130() {
  var o = <api.Glossary>[];
  o.add(buildGlossary());
  o.add(buildGlossary());
  return o;
}

void checkUnnamed6130(core.List<api.Glossary> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkGlossary(o[0] as api.Glossary);
  checkGlossary(o[1] as api.Glossary);
}

core.int buildCounterListGlossariesResponse = 0;
api.ListGlossariesResponse buildListGlossariesResponse() {
  var o = api.ListGlossariesResponse();
  buildCounterListGlossariesResponse++;
  if (buildCounterListGlossariesResponse < 3) {
    o.glossaries = buildUnnamed6130();
    o.nextPageToken = 'foo';
  }
  buildCounterListGlossariesResponse--;
  return o;
}

void checkListGlossariesResponse(api.ListGlossariesResponse o) {
  buildCounterListGlossariesResponse++;
  if (buildCounterListGlossariesResponse < 3) {
    checkUnnamed6130(o.glossaries!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListGlossariesResponse--;
}

core.List<api.Location> buildUnnamed6131() {
  var o = <api.Location>[];
  o.add(buildLocation());
  o.add(buildLocation());
  return o;
}

void checkUnnamed6131(core.List<api.Location> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLocation(o[0] as api.Location);
  checkLocation(o[1] as api.Location);
}

core.int buildCounterListLocationsResponse = 0;
api.ListLocationsResponse buildListLocationsResponse() {
  var o = api.ListLocationsResponse();
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    o.locations = buildUnnamed6131();
    o.nextPageToken = 'foo';
  }
  buildCounterListLocationsResponse--;
  return o;
}

void checkListLocationsResponse(api.ListLocationsResponse o) {
  buildCounterListLocationsResponse++;
  if (buildCounterListLocationsResponse < 3) {
    checkUnnamed6131(o.locations!);
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
  }
  buildCounterListLocationsResponse--;
}

core.List<api.Operation> buildUnnamed6132() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed6132(core.List<api.Operation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkOperation(o[0] as api.Operation);
  checkOperation(o[1] as api.Operation);
}

core.int buildCounterListOperationsResponse = 0;
api.ListOperationsResponse buildListOperationsResponse() {
  var o = api.ListOperationsResponse();
  buildCounterListOperationsResponse++;
  if (buildCounterListOperationsResponse < 3) {
    o.nextPageToken = 'foo';
    o.operations = buildUnnamed6132();
  }
  buildCounterListOperationsResponse--;
  return o;
}

void checkListOperationsResponse(api.ListOperationsResponse o) {
  buildCounterListOperationsResponse++;
  if (buildCounterListOperationsResponse < 3) {
    unittest.expect(
      o.nextPageToken!,
      unittest.equals('foo'),
    );
    checkUnnamed6132(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.Map<core.String, core.String> buildUnnamed6133() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed6133(core.Map<core.String, core.String> o) {
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

core.Map<core.String, core.Object> buildUnnamed6134() {
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

void checkUnnamed6134(core.Map<core.String, core.Object> o) {
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

core.int buildCounterLocation = 0;
api.Location buildLocation() {
  var o = api.Location();
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    o.displayName = 'foo';
    o.labels = buildUnnamed6133();
    o.locationId = 'foo';
    o.metadata = buildUnnamed6134();
    o.name = 'foo';
  }
  buildCounterLocation--;
  return o;
}

void checkLocation(api.Location o) {
  buildCounterLocation++;
  if (buildCounterLocation < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    checkUnnamed6133(o.labels!);
    unittest.expect(
      o.locationId!,
      unittest.equals('foo'),
    );
    checkUnnamed6134(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
  }
  buildCounterLocation--;
}

core.Map<core.String, core.Object> buildUnnamed6135() {
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

void checkUnnamed6135(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed6136() {
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

void checkUnnamed6136(core.Map<core.String, core.Object> o) {
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

core.int buildCounterOperation = 0;
api.Operation buildOperation() {
  var o = api.Operation();
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    o.done = true;
    o.error = buildStatus();
    o.metadata = buildUnnamed6135();
    o.name = 'foo';
    o.response = buildUnnamed6136();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed6135(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed6136(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterOutputConfig = 0;
api.OutputConfig buildOutputConfig() {
  var o = api.OutputConfig();
  buildCounterOutputConfig++;
  if (buildCounterOutputConfig < 3) {
    o.gcsDestination = buildGcsDestination();
  }
  buildCounterOutputConfig--;
  return o;
}

void checkOutputConfig(api.OutputConfig o) {
  buildCounterOutputConfig++;
  if (buildCounterOutputConfig < 3) {
    checkGcsDestination(o.gcsDestination! as api.GcsDestination);
  }
  buildCounterOutputConfig--;
}

core.Map<core.String, core.Object> buildUnnamed6137() {
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

void checkUnnamed6137(core.Map<core.String, core.Object> o) {
  unittest.expect(o, unittest.hasLength(2));
  var casted7 = (o['x']!) as core.Map;
  unittest.expect(casted7, unittest.hasLength(3));
  unittest.expect(
    casted7['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted7['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted7['string'],
    unittest.equals('foo'),
  );
  var casted8 = (o['y']!) as core.Map;
  unittest.expect(casted8, unittest.hasLength(3));
  unittest.expect(
    casted8['list'],
    unittest.equals([1, 2, 3]),
  );
  unittest.expect(
    casted8['bool'],
    unittest.equals(true),
  );
  unittest.expect(
    casted8['string'],
    unittest.equals('foo'),
  );
}

core.List<core.Map<core.String, core.Object>> buildUnnamed6138() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed6137());
  o.add(buildUnnamed6137());
  return o;
}

void checkUnnamed6138(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed6137(o[0]);
  checkUnnamed6137(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed6138();
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
    checkUnnamed6138(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterSupportedLanguage = 0;
api.SupportedLanguage buildSupportedLanguage() {
  var o = api.SupportedLanguage();
  buildCounterSupportedLanguage++;
  if (buildCounterSupportedLanguage < 3) {
    o.displayName = 'foo';
    o.languageCode = 'foo';
    o.supportSource = true;
    o.supportTarget = true;
  }
  buildCounterSupportedLanguage--;
  return o;
}

void checkSupportedLanguage(api.SupportedLanguage o) {
  buildCounterSupportedLanguage++;
  if (buildCounterSupportedLanguage < 3) {
    unittest.expect(
      o.displayName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(o.supportSource!, unittest.isTrue);
    unittest.expect(o.supportTarget!, unittest.isTrue);
  }
  buildCounterSupportedLanguage--;
}

core.List<api.SupportedLanguage> buildUnnamed6139() {
  var o = <api.SupportedLanguage>[];
  o.add(buildSupportedLanguage());
  o.add(buildSupportedLanguage());
  return o;
}

void checkUnnamed6139(core.List<api.SupportedLanguage> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSupportedLanguage(o[0] as api.SupportedLanguage);
  checkSupportedLanguage(o[1] as api.SupportedLanguage);
}

core.int buildCounterSupportedLanguages = 0;
api.SupportedLanguages buildSupportedLanguages() {
  var o = api.SupportedLanguages();
  buildCounterSupportedLanguages++;
  if (buildCounterSupportedLanguages < 3) {
    o.languages = buildUnnamed6139();
  }
  buildCounterSupportedLanguages--;
  return o;
}

void checkSupportedLanguages(api.SupportedLanguages o) {
  buildCounterSupportedLanguages++;
  if (buildCounterSupportedLanguages < 3) {
    checkUnnamed6139(o.languages!);
  }
  buildCounterSupportedLanguages--;
}

core.int buildCounterTranslateTextGlossaryConfig = 0;
api.TranslateTextGlossaryConfig buildTranslateTextGlossaryConfig() {
  var o = api.TranslateTextGlossaryConfig();
  buildCounterTranslateTextGlossaryConfig++;
  if (buildCounterTranslateTextGlossaryConfig < 3) {
    o.glossary = 'foo';
    o.ignoreCase = true;
  }
  buildCounterTranslateTextGlossaryConfig--;
  return o;
}

void checkTranslateTextGlossaryConfig(api.TranslateTextGlossaryConfig o) {
  buildCounterTranslateTextGlossaryConfig++;
  if (buildCounterTranslateTextGlossaryConfig < 3) {
    unittest.expect(
      o.glossary!,
      unittest.equals('foo'),
    );
    unittest.expect(o.ignoreCase!, unittest.isTrue);
  }
  buildCounterTranslateTextGlossaryConfig--;
}

core.List<core.String> buildUnnamed6140() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed6140(core.List<core.String> o) {
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

core.Map<core.String, core.String> buildUnnamed6141() {
  var o = <core.String, core.String>{};
  o['x'] = 'foo';
  o['y'] = 'foo';
  return o;
}

void checkUnnamed6141(core.Map<core.String, core.String> o) {
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

core.int buildCounterTranslateTextRequest = 0;
api.TranslateTextRequest buildTranslateTextRequest() {
  var o = api.TranslateTextRequest();
  buildCounterTranslateTextRequest++;
  if (buildCounterTranslateTextRequest < 3) {
    o.contents = buildUnnamed6140();
    o.glossaryConfig = buildTranslateTextGlossaryConfig();
    o.labels = buildUnnamed6141();
    o.mimeType = 'foo';
    o.model = 'foo';
    o.sourceLanguageCode = 'foo';
    o.targetLanguageCode = 'foo';
  }
  buildCounterTranslateTextRequest--;
  return o;
}

void checkTranslateTextRequest(api.TranslateTextRequest o) {
  buildCounterTranslateTextRequest++;
  if (buildCounterTranslateTextRequest < 3) {
    checkUnnamed6140(o.contents!);
    checkTranslateTextGlossaryConfig(
        o.glossaryConfig! as api.TranslateTextGlossaryConfig);
    checkUnnamed6141(o.labels!);
    unittest.expect(
      o.mimeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.model!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.sourceLanguageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.targetLanguageCode!,
      unittest.equals('foo'),
    );
  }
  buildCounterTranslateTextRequest--;
}

core.List<api.Translation> buildUnnamed6142() {
  var o = <api.Translation>[];
  o.add(buildTranslation());
  o.add(buildTranslation());
  return o;
}

void checkUnnamed6142(core.List<api.Translation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTranslation(o[0] as api.Translation);
  checkTranslation(o[1] as api.Translation);
}

core.List<api.Translation> buildUnnamed6143() {
  var o = <api.Translation>[];
  o.add(buildTranslation());
  o.add(buildTranslation());
  return o;
}

void checkUnnamed6143(core.List<api.Translation> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTranslation(o[0] as api.Translation);
  checkTranslation(o[1] as api.Translation);
}

core.int buildCounterTranslateTextResponse = 0;
api.TranslateTextResponse buildTranslateTextResponse() {
  var o = api.TranslateTextResponse();
  buildCounterTranslateTextResponse++;
  if (buildCounterTranslateTextResponse < 3) {
    o.glossaryTranslations = buildUnnamed6142();
    o.translations = buildUnnamed6143();
  }
  buildCounterTranslateTextResponse--;
  return o;
}

void checkTranslateTextResponse(api.TranslateTextResponse o) {
  buildCounterTranslateTextResponse++;
  if (buildCounterTranslateTextResponse < 3) {
    checkUnnamed6142(o.glossaryTranslations!);
    checkUnnamed6143(o.translations!);
  }
  buildCounterTranslateTextResponse--;
}

core.int buildCounterTranslation = 0;
api.Translation buildTranslation() {
  var o = api.Translation();
  buildCounterTranslation++;
  if (buildCounterTranslation < 3) {
    o.detectedLanguageCode = 'foo';
    o.glossaryConfig = buildTranslateTextGlossaryConfig();
    o.model = 'foo';
    o.translatedText = 'foo';
  }
  buildCounterTranslation--;
  return o;
}

void checkTranslation(api.Translation o) {
  buildCounterTranslation++;
  if (buildCounterTranslation < 3) {
    unittest.expect(
      o.detectedLanguageCode!,
      unittest.equals('foo'),
    );
    checkTranslateTextGlossaryConfig(
        o.glossaryConfig! as api.TranslateTextGlossaryConfig);
    unittest.expect(
      o.model!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.translatedText!,
      unittest.equals('foo'),
    );
  }
  buildCounterTranslation--;
}

core.int buildCounterWaitOperationRequest = 0;
api.WaitOperationRequest buildWaitOperationRequest() {
  var o = api.WaitOperationRequest();
  buildCounterWaitOperationRequest++;
  if (buildCounterWaitOperationRequest < 3) {
    o.timeout = 'foo';
  }
  buildCounterWaitOperationRequest--;
  return o;
}

void checkWaitOperationRequest(api.WaitOperationRequest o) {
  buildCounterWaitOperationRequest++;
  if (buildCounterWaitOperationRequest < 3) {
    unittest.expect(
      o.timeout!,
      unittest.equals('foo'),
    );
  }
  buildCounterWaitOperationRequest--;
}

void main() {
  unittest.group('obj-schema-BatchTranslateTextRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchTranslateTextRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchTranslateTextRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchTranslateTextRequest(od as api.BatchTranslateTextRequest);
    });
  });

  unittest.group('obj-schema-CancelOperationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildCancelOperationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.CancelOperationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkCancelOperationRequest(od as api.CancelOperationRequest);
    });
  });

  unittest.group('obj-schema-DetectLanguageRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDetectLanguageRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DetectLanguageRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDetectLanguageRequest(od as api.DetectLanguageRequest);
    });
  });

  unittest.group('obj-schema-DetectLanguageResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDetectLanguageResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DetectLanguageResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDetectLanguageResponse(od as api.DetectLanguageResponse);
    });
  });

  unittest.group('obj-schema-DetectedLanguage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildDetectedLanguage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.DetectedLanguage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkDetectedLanguage(od as api.DetectedLanguage);
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

  unittest.group('obj-schema-GcsDestination', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGcsDestination();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GcsDestination.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGcsDestination(od as api.GcsDestination);
    });
  });

  unittest.group('obj-schema-GcsSource', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGcsSource();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.GcsSource.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGcsSource(od as api.GcsSource);
    });
  });

  unittest.group('obj-schema-Glossary', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGlossary();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Glossary.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkGlossary(od as api.Glossary);
    });
  });

  unittest.group('obj-schema-GlossaryInputConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildGlossaryInputConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.GlossaryInputConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkGlossaryInputConfig(od as api.GlossaryInputConfig);
    });
  });

  unittest.group('obj-schema-InputConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildInputConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.InputConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkInputConfig(od as api.InputConfig);
    });
  });

  unittest.group('obj-schema-LanguageCodePair', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLanguageCodePair();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LanguageCodePair.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLanguageCodePair(od as api.LanguageCodePair);
    });
  });

  unittest.group('obj-schema-LanguageCodesSet', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLanguageCodesSet();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LanguageCodesSet.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLanguageCodesSet(od as api.LanguageCodesSet);
    });
  });

  unittest.group('obj-schema-ListGlossariesResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListGlossariesResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListGlossariesResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListGlossariesResponse(od as api.ListGlossariesResponse);
    });
  });

  unittest.group('obj-schema-ListLocationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListLocationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListLocationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListLocationsResponse(od as api.ListLocationsResponse);
    });
  });

  unittest.group('obj-schema-ListOperationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListOperationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListOperationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListOperationsResponse(od as api.ListOperationsResponse);
    });
  });

  unittest.group('obj-schema-Location', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLocation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Location.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLocation(od as api.Location);
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

  unittest.group('obj-schema-OutputConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildOutputConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.OutputConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkOutputConfig(od as api.OutputConfig);
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

  unittest.group('obj-schema-SupportedLanguage', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSupportedLanguage();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SupportedLanguage.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSupportedLanguage(od as api.SupportedLanguage);
    });
  });

  unittest.group('obj-schema-SupportedLanguages', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSupportedLanguages();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SupportedLanguages.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSupportedLanguages(od as api.SupportedLanguages);
    });
  });

  unittest.group('obj-schema-TranslateTextGlossaryConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTranslateTextGlossaryConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TranslateTextGlossaryConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTranslateTextGlossaryConfig(od as api.TranslateTextGlossaryConfig);
    });
  });

  unittest.group('obj-schema-TranslateTextRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTranslateTextRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TranslateTextRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTranslateTextRequest(od as api.TranslateTextRequest);
    });
  });

  unittest.group('obj-schema-TranslateTextResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTranslateTextResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TranslateTextResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTranslateTextResponse(od as api.TranslateTextResponse);
    });
  });

  unittest.group('obj-schema-Translation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTranslation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Translation.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTranslation(od as api.Translation);
    });
  });

  unittest.group('obj-schema-WaitOperationRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWaitOperationRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.WaitOperationRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkWaitOperationRequest(od as api.WaitOperationRequest);
    });
  });

  unittest.group('resource-ProjectsResource', () {
    unittest.test('method--detectLanguage', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects;
      var arg_request = buildDetectLanguageRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DetectLanguageRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDetectLanguageRequest(obj as api.DetectLanguageRequest);

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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildDetectLanguageResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.detectLanguage(arg_request, arg_parent,
          $fields: arg_$fields);
      checkDetectLanguageResponse(response as api.DetectLanguageResponse);
    });

    unittest.test('method--getSupportedLanguages', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects;
      var arg_parent = 'foo';
      var arg_displayLanguageCode = 'foo';
      var arg_model = 'foo';
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
          unittest.equals("v3/"),
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
          queryMap["displayLanguageCode"]!.first,
          unittest.equals(arg_displayLanguageCode),
        );
        unittest.expect(
          queryMap["model"]!.first,
          unittest.equals(arg_model),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSupportedLanguages());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getSupportedLanguages(arg_parent,
          displayLanguageCode: arg_displayLanguageCode,
          model: arg_model,
          $fields: arg_$fields);
      checkSupportedLanguages(response as api.SupportedLanguages);
    });

    unittest.test('method--translateText', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects;
      var arg_request = buildTranslateTextRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TranslateTextRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTranslateTextRequest(obj as api.TranslateTextRequest);

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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildTranslateTextResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.translateText(arg_request, arg_parent,
          $fields: arg_$fields);
      checkTranslateTextResponse(response as api.TranslateTextResponse);
    });
  });

  unittest.group('resource-ProjectsLocationsResource', () {
    unittest.test('method--batchTranslateText', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations;
      var arg_request = buildBatchTranslateTextRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchTranslateTextRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchTranslateTextRequest(obj as api.BatchTranslateTextRequest);

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
          unittest.equals("v3/"),
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
      final response = await res.batchTranslateText(arg_request, arg_parent,
          $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--detectLanguage', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations;
      var arg_request = buildDetectLanguageRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.DetectLanguageRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkDetectLanguageRequest(obj as api.DetectLanguageRequest);

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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildDetectLanguageResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.detectLanguage(arg_request, arg_parent,
          $fields: arg_$fields);
      checkDetectLanguageResponse(response as api.DetectLanguageResponse);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildLocation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkLocation(response as api.Location);
    });

    unittest.test('method--getSupportedLanguages', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations;
      var arg_parent = 'foo';
      var arg_displayLanguageCode = 'foo';
      var arg_model = 'foo';
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
          unittest.equals("v3/"),
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
          queryMap["displayLanguageCode"]!.first,
          unittest.equals(arg_displayLanguageCode),
        );
        unittest.expect(
          queryMap["model"]!.first,
          unittest.equals(arg_model),
        );
        unittest.expect(
          queryMap["fields"]!.first,
          unittest.equals(arg_$fields),
        );

        var h = {
          'content-type': 'application/json; charset=utf-8',
        };
        var resp = convert.json.encode(buildSupportedLanguages());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.getSupportedLanguages(arg_parent,
          displayLanguageCode: arg_displayLanguageCode,
          model: arg_model,
          $fields: arg_$fields);
      checkSupportedLanguages(response as api.SupportedLanguages);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations;
      var arg_name = 'foo';
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildListLocationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListLocationsResponse(response as api.ListLocationsResponse);
    });

    unittest.test('method--translateText', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations;
      var arg_request = buildTranslateTextRequest();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.TranslateTextRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkTranslateTextRequest(obj as api.TranslateTextRequest);

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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildTranslateTextResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.translateText(arg_request, arg_parent,
          $fields: arg_$fields);
      checkTranslateTextResponse(response as api.TranslateTextResponse);
    });
  });

  unittest.group('resource-ProjectsLocationsGlossariesResource', () {
    unittest.test('method--create', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations.glossaries;
      var arg_request = buildGlossary();
      var arg_parent = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Glossary.fromJson(json as core.Map<core.String, core.dynamic>);
        checkGlossary(obj as api.Glossary);

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
          unittest.equals("v3/"),
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
          await res.create(arg_request, arg_parent, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations.glossaries;
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
          unittest.equals("v3/"),
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
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations.glossaries;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildGlossary());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.get(arg_name, $fields: arg_$fields);
      checkGlossary(response as api.Glossary);
    });

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations.glossaries;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildListGlossariesResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_parent,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListGlossariesResponse(response as api.ListGlossariesResponse);
    });
  });

  unittest.group('resource-ProjectsLocationsOperationsResource', () {
    unittest.test('method--cancel', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations.operations;
      var arg_request = buildCancelOperationRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.CancelOperationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkCancelOperationRequest(obj as api.CancelOperationRequest);

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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.cancel(arg_request, arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--delete', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations.operations;
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildEmpty());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.delete(arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });

    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations.operations;
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
          unittest.equals("v3/"),
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

    unittest.test('method--list', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations.operations;
      var arg_name = 'foo';
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
          unittest.equals("v3/"),
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
        var resp = convert.json.encode(buildListOperationsResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.list(arg_name,
          filter: arg_filter,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListOperationsResponse(response as api.ListOperationsResponse);
    });

    unittest.test('method--wait', () async {
      var mock = HttpServerMock();
      var res = api.TranslateApi(mock).projects.locations.operations;
      var arg_request = buildWaitOperationRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.WaitOperationRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkWaitOperationRequest(obj as api.WaitOperationRequest);

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
          unittest.equals("v3/"),
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
          await res.wait(arg_request, arg_name, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });
  });
}
