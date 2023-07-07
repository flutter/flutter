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

import 'package:googleapis/cloudtrace/v2.dart' as api;
import 'package:http/http.dart' as http;
import 'package:test/test.dart' as unittest;

import '../test_shared.dart';

core.int buildCounterAnnotation = 0;
api.Annotation buildAnnotation() {
  var o = api.Annotation();
  buildCounterAnnotation++;
  if (buildCounterAnnotation < 3) {
    o.attributes = buildAttributes();
    o.description = buildTruncatableString();
  }
  buildCounterAnnotation--;
  return o;
}

void checkAnnotation(api.Annotation o) {
  buildCounterAnnotation++;
  if (buildCounterAnnotation < 3) {
    checkAttributes(o.attributes! as api.Attributes);
    checkTruncatableString(o.description! as api.TruncatableString);
  }
  buildCounterAnnotation--;
}

core.int buildCounterAttributeValue = 0;
api.AttributeValue buildAttributeValue() {
  var o = api.AttributeValue();
  buildCounterAttributeValue++;
  if (buildCounterAttributeValue < 3) {
    o.boolValue = true;
    o.intValue = 'foo';
    o.stringValue = buildTruncatableString();
  }
  buildCounterAttributeValue--;
  return o;
}

void checkAttributeValue(api.AttributeValue o) {
  buildCounterAttributeValue++;
  if (buildCounterAttributeValue < 3) {
    unittest.expect(o.boolValue!, unittest.isTrue);
    unittest.expect(
      o.intValue!,
      unittest.equals('foo'),
    );
    checkTruncatableString(o.stringValue! as api.TruncatableString);
  }
  buildCounterAttributeValue--;
}

core.Map<core.String, api.AttributeValue> buildUnnamed1616() {
  var o = <core.String, api.AttributeValue>{};
  o['x'] = buildAttributeValue();
  o['y'] = buildAttributeValue();
  return o;
}

void checkUnnamed1616(core.Map<core.String, api.AttributeValue> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkAttributeValue(o['x']! as api.AttributeValue);
  checkAttributeValue(o['y']! as api.AttributeValue);
}

core.int buildCounterAttributes = 0;
api.Attributes buildAttributes() {
  var o = api.Attributes();
  buildCounterAttributes++;
  if (buildCounterAttributes < 3) {
    o.attributeMap = buildUnnamed1616();
    o.droppedAttributesCount = 42;
  }
  buildCounterAttributes--;
  return o;
}

void checkAttributes(api.Attributes o) {
  buildCounterAttributes++;
  if (buildCounterAttributes < 3) {
    checkUnnamed1616(o.attributeMap!);
    unittest.expect(
      o.droppedAttributesCount!,
      unittest.equals(42),
    );
  }
  buildCounterAttributes--;
}

core.List<api.Span> buildUnnamed1617() {
  var o = <api.Span>[];
  o.add(buildSpan());
  o.add(buildSpan());
  return o;
}

void checkUnnamed1617(core.List<api.Span> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkSpan(o[0] as api.Span);
  checkSpan(o[1] as api.Span);
}

core.int buildCounterBatchWriteSpansRequest = 0;
api.BatchWriteSpansRequest buildBatchWriteSpansRequest() {
  var o = api.BatchWriteSpansRequest();
  buildCounterBatchWriteSpansRequest++;
  if (buildCounterBatchWriteSpansRequest < 3) {
    o.spans = buildUnnamed1617();
  }
  buildCounterBatchWriteSpansRequest--;
  return o;
}

void checkBatchWriteSpansRequest(api.BatchWriteSpansRequest o) {
  buildCounterBatchWriteSpansRequest++;
  if (buildCounterBatchWriteSpansRequest < 3) {
    checkUnnamed1617(o.spans!);
  }
  buildCounterBatchWriteSpansRequest--;
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

core.int buildCounterLink = 0;
api.Link buildLink() {
  var o = api.Link();
  buildCounterLink++;
  if (buildCounterLink < 3) {
    o.attributes = buildAttributes();
    o.spanId = 'foo';
    o.traceId = 'foo';
    o.type = 'foo';
  }
  buildCounterLink--;
  return o;
}

void checkLink(api.Link o) {
  buildCounterLink++;
  if (buildCounterLink < 3) {
    checkAttributes(o.attributes! as api.Attributes);
    unittest.expect(
      o.spanId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.traceId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
  }
  buildCounterLink--;
}

core.List<api.Link> buildUnnamed1618() {
  var o = <api.Link>[];
  o.add(buildLink());
  o.add(buildLink());
  return o;
}

void checkUnnamed1618(core.List<api.Link> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkLink(o[0] as api.Link);
  checkLink(o[1] as api.Link);
}

core.int buildCounterLinks = 0;
api.Links buildLinks() {
  var o = api.Links();
  buildCounterLinks++;
  if (buildCounterLinks < 3) {
    o.droppedLinksCount = 42;
    o.link = buildUnnamed1618();
  }
  buildCounterLinks--;
  return o;
}

void checkLinks(api.Links o) {
  buildCounterLinks++;
  if (buildCounterLinks < 3) {
    unittest.expect(
      o.droppedLinksCount!,
      unittest.equals(42),
    );
    checkUnnamed1618(o.link!);
  }
  buildCounterLinks--;
}

core.int buildCounterMessageEvent = 0;
api.MessageEvent buildMessageEvent() {
  var o = api.MessageEvent();
  buildCounterMessageEvent++;
  if (buildCounterMessageEvent < 3) {
    o.compressedSizeBytes = 'foo';
    o.id = 'foo';
    o.type = 'foo';
    o.uncompressedSizeBytes = 'foo';
  }
  buildCounterMessageEvent--;
  return o;
}

void checkMessageEvent(api.MessageEvent o) {
  buildCounterMessageEvent++;
  if (buildCounterMessageEvent < 3) {
    unittest.expect(
      o.compressedSizeBytes!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.id!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.type!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.uncompressedSizeBytes!,
      unittest.equals('foo'),
    );
  }
  buildCounterMessageEvent--;
}

core.int buildCounterModule = 0;
api.Module buildModule() {
  var o = api.Module();
  buildCounterModule++;
  if (buildCounterModule < 3) {
    o.buildId = buildTruncatableString();
    o.module = buildTruncatableString();
  }
  buildCounterModule--;
  return o;
}

void checkModule(api.Module o) {
  buildCounterModule++;
  if (buildCounterModule < 3) {
    checkTruncatableString(o.buildId! as api.TruncatableString);
    checkTruncatableString(o.module! as api.TruncatableString);
  }
  buildCounterModule--;
}

core.int buildCounterSpan = 0;
api.Span buildSpan() {
  var o = api.Span();
  buildCounterSpan++;
  if (buildCounterSpan < 3) {
    o.attributes = buildAttributes();
    o.childSpanCount = 42;
    o.displayName = buildTruncatableString();
    o.endTime = 'foo';
    o.links = buildLinks();
    o.name = 'foo';
    o.parentSpanId = 'foo';
    o.sameProcessAsParentSpan = true;
    o.spanId = 'foo';
    o.spanKind = 'foo';
    o.stackTrace = buildStackTrace();
    o.startTime = 'foo';
    o.status = buildStatus();
    o.timeEvents = buildTimeEvents();
  }
  buildCounterSpan--;
  return o;
}

void checkSpan(api.Span o) {
  buildCounterSpan++;
  if (buildCounterSpan < 3) {
    checkAttributes(o.attributes! as api.Attributes);
    unittest.expect(
      o.childSpanCount!,
      unittest.equals(42),
    );
    checkTruncatableString(o.displayName! as api.TruncatableString);
    unittest.expect(
      o.endTime!,
      unittest.equals('foo'),
    );
    checkLinks(o.links! as api.Links);
    unittest.expect(
      o.name!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.parentSpanId!,
      unittest.equals('foo'),
    );
    unittest.expect(o.sameProcessAsParentSpan!, unittest.isTrue);
    unittest.expect(
      o.spanId!,
      unittest.equals('foo'),
    );
    unittest.expect(
      o.spanKind!,
      unittest.equals('foo'),
    );
    checkStackTrace(o.stackTrace! as api.StackTrace);
    unittest.expect(
      o.startTime!,
      unittest.equals('foo'),
    );
    checkStatus(o.status! as api.Status);
    checkTimeEvents(o.timeEvents! as api.TimeEvents);
  }
  buildCounterSpan--;
}

core.int buildCounterStackFrame = 0;
api.StackFrame buildStackFrame() {
  var o = api.StackFrame();
  buildCounterStackFrame++;
  if (buildCounterStackFrame < 3) {
    o.columnNumber = 'foo';
    o.fileName = buildTruncatableString();
    o.functionName = buildTruncatableString();
    o.lineNumber = 'foo';
    o.loadModule = buildModule();
    o.originalFunctionName = buildTruncatableString();
    o.sourceVersion = buildTruncatableString();
  }
  buildCounterStackFrame--;
  return o;
}

void checkStackFrame(api.StackFrame o) {
  buildCounterStackFrame++;
  if (buildCounterStackFrame < 3) {
    unittest.expect(
      o.columnNumber!,
      unittest.equals('foo'),
    );
    checkTruncatableString(o.fileName! as api.TruncatableString);
    checkTruncatableString(o.functionName! as api.TruncatableString);
    unittest.expect(
      o.lineNumber!,
      unittest.equals('foo'),
    );
    checkModule(o.loadModule! as api.Module);
    checkTruncatableString(o.originalFunctionName! as api.TruncatableString);
    checkTruncatableString(o.sourceVersion! as api.TruncatableString);
  }
  buildCounterStackFrame--;
}

core.List<api.StackFrame> buildUnnamed1619() {
  var o = <api.StackFrame>[];
  o.add(buildStackFrame());
  o.add(buildStackFrame());
  return o;
}

void checkUnnamed1619(core.List<api.StackFrame> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkStackFrame(o[0] as api.StackFrame);
  checkStackFrame(o[1] as api.StackFrame);
}

core.int buildCounterStackFrames = 0;
api.StackFrames buildStackFrames() {
  var o = api.StackFrames();
  buildCounterStackFrames++;
  if (buildCounterStackFrames < 3) {
    o.droppedFramesCount = 42;
    o.frame = buildUnnamed1619();
  }
  buildCounterStackFrames--;
  return o;
}

void checkStackFrames(api.StackFrames o) {
  buildCounterStackFrames++;
  if (buildCounterStackFrames < 3) {
    unittest.expect(
      o.droppedFramesCount!,
      unittest.equals(42),
    );
    checkUnnamed1619(o.frame!);
  }
  buildCounterStackFrames--;
}

core.int buildCounterStackTrace = 0;
api.StackTrace buildStackTrace() {
  var o = api.StackTrace();
  buildCounterStackTrace++;
  if (buildCounterStackTrace < 3) {
    o.stackFrames = buildStackFrames();
    o.stackTraceHashId = 'foo';
  }
  buildCounterStackTrace--;
  return o;
}

void checkStackTrace(api.StackTrace o) {
  buildCounterStackTrace++;
  if (buildCounterStackTrace < 3) {
    checkStackFrames(o.stackFrames! as api.StackFrames);
    unittest.expect(
      o.stackTraceHashId!,
      unittest.equals('foo'),
    );
  }
  buildCounterStackTrace--;
}

core.Map<core.String, core.Object> buildUnnamed1620() {
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

void checkUnnamed1620(core.Map<core.String, core.Object> o) {
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

core.List<core.Map<core.String, core.Object>> buildUnnamed1621() {
  var o = <core.Map<core.String, core.Object>>[];
  o.add(buildUnnamed1620());
  o.add(buildUnnamed1620());
  return o;
}

void checkUnnamed1621(core.List<core.Map<core.String, core.Object>> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkUnnamed1620(o[0]);
  checkUnnamed1620(o[1]);
}

core.int buildCounterStatus = 0;
api.Status buildStatus() {
  var o = api.Status();
  buildCounterStatus++;
  if (buildCounterStatus < 3) {
    o.code = 42;
    o.details = buildUnnamed1621();
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
    checkUnnamed1621(o.details!);
    unittest.expect(
      o.message!,
      unittest.equals('foo'),
    );
  }
  buildCounterStatus--;
}

core.int buildCounterTimeEvent = 0;
api.TimeEvent buildTimeEvent() {
  var o = api.TimeEvent();
  buildCounterTimeEvent++;
  if (buildCounterTimeEvent < 3) {
    o.annotation = buildAnnotation();
    o.messageEvent = buildMessageEvent();
    o.time = 'foo';
  }
  buildCounterTimeEvent--;
  return o;
}

void checkTimeEvent(api.TimeEvent o) {
  buildCounterTimeEvent++;
  if (buildCounterTimeEvent < 3) {
    checkAnnotation(o.annotation! as api.Annotation);
    checkMessageEvent(o.messageEvent! as api.MessageEvent);
    unittest.expect(
      o.time!,
      unittest.equals('foo'),
    );
  }
  buildCounterTimeEvent--;
}

core.List<api.TimeEvent> buildUnnamed1622() {
  var o = <api.TimeEvent>[];
  o.add(buildTimeEvent());
  o.add(buildTimeEvent());
  return o;
}

void checkUnnamed1622(core.List<api.TimeEvent> o) {
  unittest.expect(o, unittest.hasLength(2));
  checkTimeEvent(o[0] as api.TimeEvent);
  checkTimeEvent(o[1] as api.TimeEvent);
}

core.int buildCounterTimeEvents = 0;
api.TimeEvents buildTimeEvents() {
  var o = api.TimeEvents();
  buildCounterTimeEvents++;
  if (buildCounterTimeEvents < 3) {
    o.droppedAnnotationsCount = 42;
    o.droppedMessageEventsCount = 42;
    o.timeEvent = buildUnnamed1622();
  }
  buildCounterTimeEvents--;
  return o;
}

void checkTimeEvents(api.TimeEvents o) {
  buildCounterTimeEvents++;
  if (buildCounterTimeEvents < 3) {
    unittest.expect(
      o.droppedAnnotationsCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.droppedMessageEventsCount!,
      unittest.equals(42),
    );
    checkUnnamed1622(o.timeEvent!);
  }
  buildCounterTimeEvents--;
}

core.int buildCounterTruncatableString = 0;
api.TruncatableString buildTruncatableString() {
  var o = api.TruncatableString();
  buildCounterTruncatableString++;
  if (buildCounterTruncatableString < 3) {
    o.truncatedByteCount = 42;
    o.value = 'foo';
  }
  buildCounterTruncatableString--;
  return o;
}

void checkTruncatableString(api.TruncatableString o) {
  buildCounterTruncatableString++;
  if (buildCounterTruncatableString < 3) {
    unittest.expect(
      o.truncatedByteCount!,
      unittest.equals(42),
    );
    unittest.expect(
      o.value!,
      unittest.equals('foo'),
    );
  }
  buildCounterTruncatableString--;
}

void main() {
  unittest.group('obj-schema-Annotation', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAnnotation();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Annotation.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAnnotation(od as api.Annotation);
    });
  });

  unittest.group('obj-schema-AttributeValue', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAttributeValue();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.AttributeValue.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkAttributeValue(od as api.AttributeValue);
    });
  });

  unittest.group('obj-schema-Attributes', () {
    unittest.test('to-json--from-json', () async {
      var o = buildAttributes();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Attributes.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkAttributes(od as api.Attributes);
    });
  });

  unittest.group('obj-schema-BatchWriteSpansRequest', () {
    unittest.test('to-json--from-json', () async {
      var o = buildBatchWriteSpansRequest();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.BatchWriteSpansRequest.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkBatchWriteSpansRequest(od as api.BatchWriteSpansRequest);
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

  unittest.group('obj-schema-Link', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLink();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Link.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLink(od as api.Link);
    });
  });

  unittest.group('obj-schema-Links', () {
    unittest.test('to-json--from-json', () async {
      var o = buildLinks();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Links.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkLinks(od as api.Links);
    });
  });

  unittest.group('obj-schema-MessageEvent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildMessageEvent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.MessageEvent.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkMessageEvent(od as api.MessageEvent);
    });
  });

  unittest.group('obj-schema-Module', () {
    unittest.test('to-json--from-json', () async {
      var o = buildModule();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.Module.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkModule(od as api.Module);
    });
  });

  unittest.group('obj-schema-Span', () {
    unittest.test('to-json--from-json', () async {
      var o = buildSpan();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.Span.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkSpan(od as api.Span);
    });
  });

  unittest.group('obj-schema-StackFrame', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStackFrame();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.StackFrame.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStackFrame(od as api.StackFrame);
    });
  });

  unittest.group('obj-schema-StackFrames', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStackFrames();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.StackFrames.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkStackFrames(od as api.StackFrames);
    });
  });

  unittest.group('obj-schema-StackTrace', () {
    unittest.test('to-json--from-json', () async {
      var o = buildStackTrace();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.StackTrace.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkStackTrace(od as api.StackTrace);
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

  unittest.group('obj-schema-TimeEvent', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimeEvent();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TimeEvent.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTimeEvent(od as api.TimeEvent);
    });
  });

  unittest.group('obj-schema-TimeEvents', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTimeEvents();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od =
          api.TimeEvents.fromJson(oJson as core.Map<core.String, core.dynamic>);
      checkTimeEvents(od as api.TimeEvents);
    });
  });

  unittest.group('obj-schema-TruncatableString', () {
    unittest.test('to-json--from-json', () async {
      var o = buildTruncatableString();
      var oJson = convert.jsonDecode(convert.jsonEncode(o));
      var od = api.TruncatableString.fromJson(
          oJson as core.Map<core.String, core.dynamic>);
      checkTruncatableString(od as api.TruncatableString);
    });
  });

  unittest.group('resource-ProjectsTracesResource', () {
    unittest.test('method--batchWrite', () async {
      var mock = HttpServerMock();
      var res = api.CloudTraceApi(mock).projects.traces;
      var arg_request = buildBatchWriteSpansRequest();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj = api.BatchWriteSpansRequest.fromJson(
            json as core.Map<core.String, core.dynamic>);
        checkBatchWriteSpansRequest(obj as api.BatchWriteSpansRequest);

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
          unittest.equals("v2/"),
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
          await res.batchWrite(arg_request, arg_name, $fields: arg_$fields);
      checkEmpty(response as api.Empty);
    });
  });

  unittest.group('resource-ProjectsTracesSpansResource', () {
    unittest.test('method--createSpan', () async {
      var mock = HttpServerMock();
      var res = api.CloudTraceApi(mock).projects.traces.spans;
      var arg_request = buildSpan();
      var arg_name = 'foo';
      var arg_$fields = 'foo';
      mock.register(unittest.expectAsync2((http.BaseRequest req, json) {
        var obj =
            api.Span.fromJson(json as core.Map<core.String, core.dynamic>);
        checkSpan(obj as api.Span);

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
          unittest.equals("v2/"),
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
        var resp = convert.json.encode(buildSpan());
        return async.Future.value(stringResponse(200, h, resp));
      }), true);
      final response =
          await res.createSpan(arg_request, arg_name, $fields: arg_$fields);
      checkSpan(response as api.Span);
    });
  });
}
