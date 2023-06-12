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

import 'package:googleapis/speech/v1.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.List<api.Operation> buildUnnamed5574() {
  var o = <api.Operation>[];
  o.add(buildOperation());
  o.add(buildOperation());
  return o;
}

void checkUnnamed5574(core.List<api.Operation> o) {
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
    o.operations = buildUnnamed5574();
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
    checkUnnamed5574(o.operations!);
  }
  buildCounterListOperationsResponse--;
}

core.int buildCounterLongRunningRecognizeMetadata = 0;
api.LongRunningRecognizeMetadata buildLongRunningRecognizeMetadata() {
  var o = api.LongRunningRecognizeMetadata();
  buildCounterLongRunningRecognizeMetadata++;
  if (buildCounterLongRunningRecognizeMetadata < 3) {
    o.lastUpdateTime = 'foo';
    o.progressPercent = 42;
    o.startTime = 'foo';
    o.uri = 'foo';
  }
  buildCounterLongRunningRecognizeMetadata--;
  return o;
}

void checkLongRunningRecognizeMetadata(api.LongRunningRecognizeMetadata o) {
  buildCounterLongRunningRecognizeMetadata++;
  if (buildCounterLongRunningRecognizeMetadata < 3) {
    unittest.expect(
      o.lastUpdateTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.progressPercent!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterLongRunningRecognizeMetadata--;
}

core.int buildCounterLongRunningRecognizeRequest = 0;
api.LongRunningRecognizeRequest buildLongRunningRecognizeRequest() {
  var o = api.LongRunningRecognizeRequest();
  buildCounterLongRunningRecognizeRequest++;
  if (buildCounterLongRunningRecognizeRequest < 3) {
    o.audio = buildRecognitionAudio();
    o.config = buildRecognitionConfig();
  }
  buildCounterLongRunningRecognizeRequest--;
  return o;
}

void checkLongRunningRecognizeRequest(api.LongRunningRecognizeRequest o) {
  buildCounterLongRunningRecognizeRequest++;
  if (buildCounterLongRunningRecognizeRequest < 3) {
    checkRecognitionAudio(o.audio! as api.RecognitionAudio);
    checkRecognitionConfig(o.config! as api.RecognitionConfig);
  }
  buildCounterLongRunningRecognizeRequest--;
}

core.List<api.SpeechRecognitionResult> buildUnnamed5575() {
  var o = <api.SpeechRecognitionResult>[];
  o.add(buildSpeechRecognitionResult());
  o.add(buildSpeechRecognitionResult());
  return o;
}

void checkUnnamed5575(core.List<api.SpeechRecognitionResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSpeechRecognitionResult(o[0] as api.SpeechRecognitionResult);
  checkSpeechRecognitionResult(o[1] as api.SpeechRecognitionResult);
}

core.int buildCounterLongRunningRecognizeResponse = 0;
api.LongRunningRecognizeResponse buildLongRunningRecognizeResponse() {
  var o = api.LongRunningRecognizeResponse();
  buildCounterLongRunningRecognizeResponse++;
  if (buildCounterLongRunningRecognizeResponse < 3) {
    o.results = buildUnnamed5575();
  }
  buildCounterLongRunningRecognizeResponse--;
  return o;
}

void checkLongRunningRecognizeResponse(api.LongRunningRecognizeResponse o) {
  buildCounterLongRunningRecognizeResponse++;
  if (buildCounterLongRunningRecognizeResponse < 3) {
    checkUnnamed5575(o.results!);
  }
  buildCounterLongRunningRecognizeResponse--;
}

core.Map<core.String, core.Object> buildUnnamed5576() {
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

void checkUnnamed5576(core.Map<core.String, core.Object> o) {
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

core.Map<core.String, core.Object> buildUnnamed5577() {
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

void checkUnnamed5577(core.Map<core.String, core.Object> o) {
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
    o.metadata = buildUnnamed5576();
    o.name = 'foo';
    o.response = buildUnnamed5577();
  }
  buildCounterOperation--;
  return o;
}

void checkOperation(api.Operation o) {
  buildCounterOperation++;
  if (buildCounterOperation < 3) {
    unittest.expect(o.done!, unittest.isTrue);
    checkStatus(o.error! as api.Status);
    checkUnnamed5576(o.metadata!);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    checkUnnamed5577(o.response!);
  }
  buildCounterOperation--;
}

core.int buildCounterRecognitionAudio = 0;
api.RecognitionAudio buildRecognitionAudio() {
  var o = api.RecognitionAudio();
  buildCounterRecognitionAudio++;
  if (buildCounterRecognitionAudio < 3) {
    o.content = 'foo';
    o.uri = 'foo';
  }
  buildCounterRecognitionAudio--;
  return o;
}

void checkRecognitionAudio(api.RecognitionAudio o) {
  buildCounterRecognitionAudio++;
  if (buildCounterRecognitionAudio < 3) {
    unittest.expect(
      o.content!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uri!,
      unittest.equals('foo'),
    );
  }
  buildCounterRecognitionAudio--;
}

core.List<api.SpeechContext> buildUnnamed5578() {
  var o = <api.SpeechContext>[];
  o.add(buildSpeechContext());
  o.add(buildSpeechContext());
  return o;
}

void checkUnnamed5578(core.List<api.SpeechContext> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSpeechContext(o[0] as api.SpeechContext);
  checkSpeechContext(o[1] as api.SpeechContext);
}

core.int buildCounterRecognitionConfig = 0;
api.RecognitionConfig buildRecognitionConfig() {
  var o = api.RecognitionConfig();
  buildCounterRecognitionConfig++;
  if (buildCounterRecognitionConfig < 3) {
    o.audioChannelCount = 42;
    o.diarizationConfig = buildSpeakerDiarizationConfig();
    o.enableAutomaticPunctuation = true;
    o.enableSeparateRecognitionPerChannel = true;
    o.enableWordTimeOffsets = true;
    o.encoding = 'foo';
    o.languageCode = 'foo';
    o.maxAlternatives = 42;
    o.metadata = buildRecognitionMetadata();
    o.model = 'foo';
    o.profanityFilter = true;
    o.sampleRateHertz = 42;
    o.speechContexts = buildUnnamed5578();
    o.useEnhanced = true;
  }
  buildCounterRecognitionConfig--;
  return o;
}

void checkRecognitionConfig(api.RecognitionConfig o) {
  buildCounterRecognitionConfig++;
  if (buildCounterRecognitionConfig < 3) {
    unittest.expect(
      o.audioChannelCount!,
      unittest.equals(42),
    );
    checkSpeakerDiarizationConfig(
        o.diarizationConfig! as api.SpeakerDiarizationConfig);
    unittest.expect(o.enableAutomaticPunctuation!, unittest.isTrue);
    unittest.expect(o.enableSeparateRecognitionPerChannel!, unittest.isTrue);
    unittest.expect(o.enableWordTimeOffsets!, unittest.isTrue);
    unittest.expect(
      o.encoding!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.languageCode!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.maxAlternatives!,
      unittest.equals(42),
    );
    checkRecognitionMetadata(o.metadata! as api.RecognitionMetadata);
    unittest.expect(
      o.model!,
      unittest.equals('foo'),
    );
    unittest.expect(o.profanityFilter!, unittest.isTrue);
    unittest.expect(
      o.sampleRateHertz!,
      unittest.equals(42),
    );
    checkUnnamed5578(o.speechContexts!);
    unittest.expect(o.useEnhanced!, unittest.isTrue);
  }
  buildCounterRecognitionConfig--;
}

core.int buildCounterRecognitionMetadata = 0;
api.RecognitionMetadata buildRecognitionMetadata() {
  var o = api.RecognitionMetadata();
  buildCounterRecognitionMetadata++;
  if (buildCounterRecognitionMetadata < 3) {
    o.audioTopic = 'foo';
    o.industryNaicsCodeOfAudio = 42;
    o.interactionType = 'foo';
    o.microphoneDistance = 'foo';
    o.originalMediaType = 'foo';
    o.originalMimeType = 'foo';
    o.recordingDeviceName = 'foo';
    o.recordingDeviceType = 'foo';
  }
  buildCounterRecognitionMetadata--;
  return o;
}

void checkRecognitionMetadata(api.RecognitionMetadata o) {
  buildCounterRecognitionMetadata++;
  if (buildCounterRecognitionMetadata < 3) {
    unittest.expect(
      o.audioTopic!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.industryNaicsCodeOfAudio!,
      unittest.equals(42),
    );
    unittest.expect(
      o.interactionType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.microphoneDistance!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.originalMediaType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.originalMimeType!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.recordingDeviceName!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.recordingDeviceType!,
      unittest.equals('foo'),
    );
  }
  buildCounterRecognitionMetadata--;
}

core.int buildCounterRecognizeRequest = 0;
api.RecognizeRequest buildRecognizeRequest() {
  var o = api.RecognizeRequest();
  buildCounterRecognizeRequest++;
  if (buildCounterRecognizeRequest < 3) {
    o.audio = buildRecognitionAudio();
    o.config = buildRecognitionConfig();
  }
  buildCounterRecognizeRequest--;
  return o;
}

void checkRecognizeRequest(api.RecognizeRequest o) {
  buildCounterRecognizeRequest++;
  if (buildCounterRecognizeRequest < 3) {
    checkRecognitionAudio(o.audio! as api.RecognitionAudio);
    checkRecognitionConfig(o.config! as api.RecognitionConfig);
  }
  buildCounterRecognizeRequest--;
}

core.List<api.SpeechRecognitionResult> buildUnnamed5579() {
  var o = <api.SpeechRecognitionResult>[];
  o.add(buildSpeechRecognitionResult());
  o.add(buildSpeechRecognitionResult());
  return o;
}

void checkUnnamed5579(core.List<api.SpeechRecognitionResult> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSpeechRecognitionResult(o[0] as api.SpeechRecognitionResult);
  checkSpeechRecognitionResult(o[1] as api.SpeechRecognitionResult);
}

core.int buildCounterRecognizeResponse = 0;
api.RecognizeResponse buildRecognizeResponse() {
  var o = api.RecognizeResponse();
  buildCounterRecognizeResponse++;
  if (buildCounterRecognizeResponse < 3) {
    o.results = buildUnnamed5579();
  }
  buildCounterRecognizeResponse--;
  return o;
}

void checkRecognizeResponse(api.RecognizeResponse o) {
  buildCounterRecognizeResponse++;
  if (buildCounterRecognizeResponse < 3) {
    checkUnnamed5579(o.results!);
  }
  buildCounterRecognizeResponse--;
}

core.int buildCounterSpeakerDiarizationConfig = 0;
api.SpeakerDiarizationConfig buildSpeakerDiarizationConfig() {
  var o = api.SpeakerDiarizationConfig();
  buildCounterSpeakerDiarizationConfig++;
  if (buildCounterSpeakerDiarizationConfig < 3) {
    o.enableSpeakerDiarization = true;
    o.maxSpeakerCount = 42;
    o.minSpeakerCount = 42;
    o.speakerTag = 42;
  }
  buildCounterSpeakerDiarizationConfig--;
  return o;
}

void checkSpeakerDiarizationConfig(api.SpeakerDiarizationConfig o) {
  buildCounterSpeakerDiarizationConfig++;
  if (buildCounterSpeakerDiarizationConfig < 3) {
    unittest.expect(o.enableSpeakerDiarization!, unittest.isTrue);
    unittest.expect(
      o.maxSpeakerCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.minSpeakerCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.speakerTag!,
      unittest.equals(42),
    );
  }
  buildCounterSpeakerDiarizationConfig--;
}

core.List<core.String> buildUnnamed5580() {
  var o = <core.String>[];
  o.add('foo');
  o.add('foo');
  return o;
}

void checkUnnamed5580(core.List<core.String> o) {
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

core.int buildCounterSpeechContext = 0;
api.SpeechContext buildSpeechContext() {
  var o = api.SpeechContext();
  buildCounterSpeechContext++;
  if (buildCounterSpeechContext < 3) {
    o.phrases = buildUnnamed5580();
  }
  buildCounterSpeechContext--;
  return o;
}

void checkSpeechContext(api.SpeechContext o) {
  buildCounterSpeechContext++;
  if (buildCounterSpeechContext < 3) {
    checkUnnamed5580(o.phrases!);
  }
  buildCounterSpeechContext--;
}

core.List<api.WordInfo> buildUnnamed5581() {
  var o = <api.WordInfo>[];
  o.add(buildWordInfo());
  o.add(buildWordInfo());
  return o;
}

void checkUnnamed5581(core.List<api.WordInfo> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkWordInfo(o[0] as api.WordInfo);
  checkWordInfo(o[1] as api.WordInfo);
}

core.int buildCounterSpeechRecognitionAlternative = 0;
api.SpeechRecognitionAlternative buildSpeechRecognitionAlternative() {
  var o = api.SpeechRecognitionAlternative();
  buildCounterSpeechRecognitionAlternative++;
  if (buildCounterSpeechRecognitionAlternative < 3) {
    o.confidence = 42.0;
    o.transcript = 'foo';
    o.words = buildUnnamed5581();
  }
  buildCounterSpeechRecognitionAlternative--;
  return o;
}

void checkSpeechRecognitionAlternative(api.SpeechRecognitionAlternative o) {
  buildCounterSpeechRecognitionAlternative++;
  if (buildCounterSpeechRecognitionAlternative < 3) {
    unittest.expect(
      o.confidence!,
      unittest.equals(42.0),
    );
    unittest.expect(
      o.transcript!,
      unittest.equals('foo'),
    );
    checkUnnamed5581(o.words!);
  }
  buildCounterSpeechRecognitionAlternative--;
}

core.List<api.SpeechRecognitionAlternative> buildUnnamed5582() {
  var o = <api.SpeechRecognitionAlternative>[];
  o.add(buildSpeechRecognitionAlternative());
  o.add(buildSpeechRecognitionAlternative());
  return o;
}

void checkUnnamed5582(core.List<api.SpeechRecognitionAlternative> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSpeechRecognitionAlternative(o[0] as api.SpeechRecognitionAlternative);
  checkSpeechRecognitionAlternative(o[1] as api.SpeechRecognitionAlternative);
}

core.int buildCounterSpeechRecognitionResult = 0;
api.SpeechRecognitionResult buildSpeechRecognitionResult() {
  var o = api.SpeechRecognitionResult();
  buildCounterSpeechRecognitionResult++;
  if (buildCounterSpeechRecognitionResult < 3) {
    o.alternatives = buildUnnamed5582();
    o.channelTag = 42;
  }
  buildCounterSpeechRecognitionResult--;
  return o;
}

void checkSpeechRecognitionResult(api.SpeechRecognitionResult o) {
  buildCounterSpeechRecognitionResult++;
  if (buildCounterSpeechRecognitionResult < 3) {
    checkUnnamed5582(o.alternatives!);
    unittest.expect(
      o.channelTag!,
      unittest.equals(42),
    );
  }
  buildCounterSpeechRecognitionResult--;
}

core.Map<core.String, core.Object> buildUnnamed5583() {
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

void checkUnnamed5583(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed5584() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed5583());
  o.add(buildUnnamed5583());
  return o;
}

void checkUnnamed5584(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed5583(o[0]);
  checkUnnamed5583(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed5584();
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
    checkUnnamed5584(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterWordInfo = 0;
api.WordInfo buildWordInfo() {
  var o = api.WordInfo();
  buildCounterWordInfo++;
  if (buildCounterWordInfo < 3) {
    o.endTime = 'foo';
    o.speakerTag = 42;
    o.startTime = 'foo';
    o.word = 'foo';
  }
  buildCounterWordInfo--;
  return o;
}

void checkWordInfo(api.WordInfo o) {
  buildCounterWordInfo++;
  if (buildCounterWordInfo < 3) {
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.speakerTag!,
      unittest.equals(42),
    );
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.word!,
      unittest.equals('foo'),
    );
  }
  buildCounterWordInfo--;
}

void main() {
  unittest.group('obj-schema-ListOperationsResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildListOperationsResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.ListOperationsResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkListOperationsResponse(od as api.ListOperationsResponse);
    });
  });

  unittest.group('obj-schema-LongRunningRecognizeMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLongRunningRecognizeMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LongRunningRecognizeMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLongRunningRecognizeMetadata(od as api.LongRunningRecognizeMetadata);
    });
  });

  unittest.group('obj-schema-LongRunningRecognizeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLongRunningRecognizeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LongRunningRecognizeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLongRunningRecognizeRequest(od as api.LongRunningRecognizeRequest);
    });
  });

  unittest.group('obj-schema-LongRunningRecognizeResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLongRunningRecognizeResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.LongRunningRecognizeResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkLongRunningRecognizeResponse(od as api.LongRunningRecognizeResponse);
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

  unittest.group('obj-schema-RecognitionAudio', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRecognitionAudio();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RecognitionAudio.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRecognitionAudio(od as api.RecognitionAudio);
    });
  });

  unittest.group('obj-schema-RecognitionConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRecognitionConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RecognitionConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRecognitionConfig(od as api.RecognitionConfig);
    });
  });

  unittest.group('obj-schema-RecognitionMetadata', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRecognitionMetadata();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RecognitionMetadata.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRecognitionMetadata(od as api.RecognitionMetadata);
    });
  });

  unittest.group('obj-schema-RecognizeRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRecognizeRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RecognizeRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRecognizeRequest(od as api.RecognizeRequest);
    });
  });

  unittest.group('obj-schema-RecognizeResponse', () {
    unittest.test('to-json--from-json', () async {
      var o = buildRecognizeResponse();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.RecognizeResponse.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkRecognizeResponse(od as api.RecognizeResponse);
    });
  });

  unittest.group('obj-schema-SpeakerDiarizationConfig', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSpeakerDiarizationConfig();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SpeakerDiarizationConfig.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSpeakerDiarizationConfig(od as api.SpeakerDiarizationConfig);
    });
  });

  unittest.group('obj-schema-SpeechContext', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSpeechContext();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SpeechContext.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSpeechContext(od as api.SpeechContext);
    });
  });

  unittest.group('obj-schema-SpeechRecognitionAlternative', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSpeechRecognitionAlternative();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SpeechRecognitionAlternative.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSpeechRecognitionAlternative(od as api.SpeechRecognitionAlternative);
    });
  });

  unittest.group('obj-schema-SpeechRecognitionResult', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSpeechRecognitionResult();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.SpeechRecognitionResult.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkSpeechRecognitionResult(od as api.SpeechRecognitionResult);
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

  unittest.group('obj-schema-WordInfo', () {
    unittest.test('to-json--from-json', () async {
      var o = buildWordInfo();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.WordInfo.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkWordInfo(od as api.WordInfo);
    });
  });

  unittest.group('resource-OperationsResource', () {
    unittest.test('method--get', () async {
      var mock = HttpServerMock();
      var res = api.SpeechApi(mock).operations;
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
          path.substring(pathOffset, pathOffset + 14),
          unittest.equals("v1/operations/"),
        );
        pathOffset += 14;
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
      var res = api.SpeechApi(mock).operations;
      var arg_filter = 'foo';
      var arg_name = 'foo';
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
          path.substring(pathOffset, pathOffset + 13),
          unittest.equals("v1/operations"),
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
          queryMap["filter"]!.first,
          unittest.equals(arg_filter),
        );
        unittest.expect(
          queryMap["name"]!.first,
          unittest.equals(arg_name),
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
      final response = await res.list(
          filter: arg_filter,
          name: arg_name,
          pageSize: arg_pageSize,
          pageToken: arg_pageToken,
          $fields: arg_$fields);
      checkListOperationsResponse(response as api.ListOperationsResponse);
    });
  });

  unittest.group('resource-SpeechResource', () {
    unittest.test('method--longrunningrecognize', () async {
      var mock = HttpServerMock();
      var res = api.SpeechApi(mock).speech;
      var arg_request = buildLongRunningRecognizeRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.LongRunningRecognizeRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkLongRunningRecognizeRequest(
            obj as api.LongRunningRecognizeRequest);

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
          unittest.equals("v1/speech:longrunningrecognize"),
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
        var resp = convert.json.encode(buildOperation());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.longrunningrecognize(arg_request, $fields: arg_$fields);
      checkOperation(response as api.Operation);
    });

    unittest.test('method--recognize', () async {
      var mock = HttpServerMock();
      var res = api.SpeechApi(mock).speech;
      var arg_request = buildRecognizeRequest();
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.RecognizeRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkRecognizeRequest(obj as api.RecognizeRequest);

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
          path.substring(pathOffset, pathOffset + 19),
          unittest.equals("v1/speech:recognize"),
        );
        pathOffset += 19;

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
        var resp = convert.json.encode(buildRecognizeResponse());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response = await res.recognize(arg_request, $fields: arg_$fields);
      checkRecognizeResponse(response as api.RecognizeResponse);
    });
  });
}
