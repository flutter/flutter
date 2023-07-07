// This is a generated file (see the discoveryapis_generator project).

// ignore_for_file: camel_case_types
// ignore_for_file: comment_references
// ignore_for_file: file_names
// ignore_for_file: library_names
// ignore_for_file: lines_longer_than_80_chars
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: prefer_expression_function_bodies
// ignore_for_file: prefer_interpolation_to_compose_strings
// ignore_for_file: unnecessary_brace_in_string_interps
// ignore_for_file: unnecessary_lambdas
// ignore_for_file: unnecessary_string_interpolations

/// Cloud Trace API - v2
///
/// Sends application trace data to Cloud Trace for viewing. Trace data is
/// collected for all App Engine applications by default. Trace data from other
/// applications can be provided using this API. This library is used to
/// interact with the Cloud Trace API directly. If you are looking to instrument
/// your application for Cloud Trace, we recommend using OpenCensus.
///
/// For more information, see <https://cloud.google.com/trace>
///
/// Create an instance of [CloudTraceApi] to access these resources:
///
/// - [ProjectsResource]
///   - [ProjectsTracesResource]
///     - [ProjectsTracesSpansResource]
library cloudtrace.v2;

import 'dart:async' as async;
import 'dart:convert' as convert;
import 'dart:core' as core;

import 'package:_discoveryapis_commons/_discoveryapis_commons.dart' as commons;
import 'package:http/http.dart' as http;

import '../src/user_agent.dart';

export 'package:_discoveryapis_commons/_discoveryapis_commons.dart'
    show ApiRequestError, DetailedApiRequestError;

/// Sends application trace data to Cloud Trace for viewing.
///
/// Trace data is collected for all App Engine applications by default. Trace
/// data from other applications can be provided using this API. This library is
/// used to interact with the Cloud Trace API directly. If you are looking to
/// instrument your application for Cloud Trace, we recommend using OpenCensus.
class CloudTraceApi {
  /// See, edit, configure, and delete your Google Cloud Platform data
  static const cloudPlatformScope =
      'https://www.googleapis.com/auth/cloud-platform';

  /// Write Trace data for a project or application
  static const traceAppendScope =
      'https://www.googleapis.com/auth/trace.append';

  final commons.ApiRequester _requester;

  ProjectsResource get projects => ProjectsResource(_requester);

  CloudTraceApi(http.Client client,
      {core.String rootUrl = 'https://cloudtrace.googleapis.com/',
      core.String servicePath = ''})
      : _requester =
            commons.ApiRequester(client, rootUrl, servicePath, requestHeaders);
}

class ProjectsResource {
  final commons.ApiRequester _requester;

  ProjectsTracesResource get traces => ProjectsTracesResource(_requester);

  ProjectsResource(commons.ApiRequester client) : _requester = client;
}

class ProjectsTracesResource {
  final commons.ApiRequester _requester;

  ProjectsTracesSpansResource get spans =>
      ProjectsTracesSpansResource(_requester);

  ProjectsTracesResource(commons.ApiRequester client) : _requester = client;

  /// Sends new spans to new or existing traces.
  ///
  /// You cannot update existing spans.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The name of the project where the spans belong. The
  /// format is `projects/[PROJECT_ID]`.
  /// Value must have pattern `^projects/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Empty].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Empty> batchWrite(
    BatchWriteSpansRequest request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name') + '/traces:batchWrite';

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Empty.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

class ProjectsTracesSpansResource {
  final commons.ApiRequester _requester;

  ProjectsTracesSpansResource(commons.ApiRequester client)
      : _requester = client;

  /// Creates a new span.
  ///
  /// [request] - The metadata request object.
  ///
  /// Request parameters:
  ///
  /// [name] - Required. The resource name of the span in the following format:
  /// projects/\[PROJECT_ID\]/traces/\[TRACE_ID\]/spans/SPAN_ID is a unique
  /// identifier for a trace within a project; it is a 32-character hexadecimal
  /// encoding of a 16-byte array. \[SPAN_ID\] is a unique identifier for a span
  /// within a trace; it is a 16-character hexadecimal encoding of an 8-byte
  /// array. It should not be zero.
  /// Value must have pattern `^projects/\[^/\]+/traces/\[^/\]+/spans/\[^/\]+$`.
  ///
  /// [$fields] - Selector specifying which fields to include in a partial
  /// response.
  ///
  /// Completes with a [Span].
  ///
  /// Completes with a [commons.ApiRequestError] if the API endpoint returned an
  /// error.
  ///
  /// If the used [http.Client] completes with an error when making a REST call,
  /// this method will complete with the same error.
  async.Future<Span> createSpan(
    Span request,
    core.String name, {
    core.String? $fields,
  }) async {
    final _body = convert.json.encode(request.toJson());
    final _queryParams = <core.String, core.List<core.String>>{
      if ($fields != null) 'fields': [$fields],
    };

    final _url = 'v2/' + core.Uri.encodeFull('$name');

    final _response = await _requester.request(
      _url,
      'POST',
      body: _body,
      queryParams: _queryParams,
    );
    return Span.fromJson(_response as core.Map<core.String, core.dynamic>);
  }
}

/// Text annotation with a set of attributes.
class Annotation {
  /// A set of attributes on the annotation.
  ///
  /// You can have up to 4 attributes per Annotation.
  Attributes? attributes;

  /// A user-supplied message describing the event.
  ///
  /// The maximum length for the description is 256 bytes.
  TruncatableString? description;

  Annotation();

  Annotation.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = Attributes.fromJson(
          _json['attributes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('description')) {
      description = TruncatableString.fromJson(
          _json['description'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null) 'attributes': attributes!.toJson(),
        if (description != null) 'description': description!.toJson(),
      };
}

/// The allowed types for \[VALUE\] in a `[KEY]:[VALUE]` attribute.
class AttributeValue {
  /// A Boolean value represented by `true` or `false`.
  core.bool? boolValue;

  /// A 64-bit signed integer.
  core.String? intValue;

  /// A string up to 256 bytes long.
  TruncatableString? stringValue;

  AttributeValue();

  AttributeValue.fromJson(core.Map _json) {
    if (_json.containsKey('boolValue')) {
      boolValue = _json['boolValue'] as core.bool;
    }
    if (_json.containsKey('intValue')) {
      intValue = _json['intValue'] as core.String;
    }
    if (_json.containsKey('stringValue')) {
      stringValue = TruncatableString.fromJson(
          _json['stringValue'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (boolValue != null) 'boolValue': boolValue!,
        if (intValue != null) 'intValue': intValue!,
        if (stringValue != null) 'stringValue': stringValue!.toJson(),
      };
}

/// A set of attributes, each in the format `[KEY]:[VALUE]`.
class Attributes {
  /// The set of attributes.
  ///
  /// Each attribute's key can be up to 128 bytes long. The value can be a
  /// string up to 256 bytes, a signed 64-bit integer, or the Boolean values
  /// `true` and `false`. For example: "/instance_id": { "string_value": {
  /// "value": "my-instance" } } "/http/request_bytes": { "int_value": 300 }
  /// "abc.com/myattribute": { "bool_value": false }
  core.Map<core.String, AttributeValue>? attributeMap;

  /// The number of attributes that were discarded.
  ///
  /// Attributes can be discarded because their keys are too long or because
  /// there are too many attributes. If this value is 0 then all attributes are
  /// valid.
  core.int? droppedAttributesCount;

  Attributes();

  Attributes.fromJson(core.Map _json) {
    if (_json.containsKey('attributeMap')) {
      attributeMap =
          (_json['attributeMap'] as core.Map<core.String, core.dynamic>).map(
        (key, item) => core.MapEntry(
          key,
          AttributeValue.fromJson(item as core.Map<core.String, core.dynamic>),
        ),
      );
    }
    if (_json.containsKey('droppedAttributesCount')) {
      droppedAttributesCount = _json['droppedAttributesCount'] as core.int;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributeMap != null)
          'attributeMap': attributeMap!
              .map((key, item) => core.MapEntry(key, item.toJson())),
        if (droppedAttributesCount != null)
          'droppedAttributesCount': droppedAttributesCount!,
      };
}

/// The request message for the `BatchWriteSpans` method.
class BatchWriteSpansRequest {
  /// A list of new spans.
  ///
  /// The span names must not match existing spans, or the results are
  /// undefined.
  ///
  /// Required.
  core.List<Span>? spans;

  BatchWriteSpansRequest();

  BatchWriteSpansRequest.fromJson(core.Map _json) {
    if (_json.containsKey('spans')) {
      spans = (_json['spans'] as core.List)
          .map<Span>((value) =>
              Span.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (spans != null)
          'spans': spans!.map((value) => value.toJson()).toList(),
      };
}

/// A generic empty message that you can re-use to avoid defining duplicated
/// empty messages in your APIs.
///
/// A typical example is to use it as the request or the response type of an API
/// method. For instance: service Foo { rpc Bar(google.protobuf.Empty) returns
/// (google.protobuf.Empty); } The JSON representation for `Empty` is empty JSON
/// object `{}`.
class Empty {
  Empty();

  Empty.fromJson(
      // ignore: avoid_unused_constructor_parameters
      core.Map _json);

  core.Map<core.String, core.dynamic> toJson() => {};
}

/// A pointer from the current span to another span in the same trace or in a
/// different trace.
///
/// For example, this can be used in batching operations, where a single batch
/// handler processes multiple requests from different traces or when the
/// handler receives a request from a different project.
class Link {
  /// A set of attributes on the link.
  ///
  /// You have have up to 32 attributes per link.
  Attributes? attributes;

  /// The \[SPAN_ID\] for a span within a trace.
  core.String? spanId;

  /// The \[TRACE_ID\] for a trace within a project.
  core.String? traceId;

  /// The relationship of the current span relative to the linked span.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : The relationship of the two spans is unknown.
  /// - "CHILD_LINKED_SPAN" : The linked span is a child of the current span.
  /// - "PARENT_LINKED_SPAN" : The linked span is a parent of the current span.
  core.String? type;

  Link();

  Link.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = Attributes.fromJson(
          _json['attributes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('spanId')) {
      spanId = _json['spanId'] as core.String;
    }
    if (_json.containsKey('traceId')) {
      traceId = _json['traceId'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null) 'attributes': attributes!.toJson(),
        if (spanId != null) 'spanId': spanId!,
        if (traceId != null) 'traceId': traceId!,
        if (type != null) 'type': type!,
      };
}

/// A collection of links, which are references from this span to a span in the
/// same or different trace.
class Links {
  /// The number of dropped links after the maximum size was enforced.
  ///
  /// If this value is 0, then no links were dropped.
  core.int? droppedLinksCount;

  /// A collection of links.
  core.List<Link>? link;

  Links();

  Links.fromJson(core.Map _json) {
    if (_json.containsKey('droppedLinksCount')) {
      droppedLinksCount = _json['droppedLinksCount'] as core.int;
    }
    if (_json.containsKey('link')) {
      link = (_json['link'] as core.List)
          .map<Link>((value) =>
              Link.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (droppedLinksCount != null) 'droppedLinksCount': droppedLinksCount!,
        if (link != null) 'link': link!.map((value) => value.toJson()).toList(),
      };
}

/// An event describing a message sent/received between Spans.
class MessageEvent {
  /// The number of compressed bytes sent or received.
  ///
  /// If missing assumed to be the same size as uncompressed.
  core.String? compressedSizeBytes;

  /// An identifier for the MessageEvent's message that can be used to match
  /// SENT and RECEIVED MessageEvents.
  ///
  /// It is recommended to be unique within a Span.
  core.String? id;

  /// Type of MessageEvent.
  ///
  /// Indicates whether the message was sent or received.
  /// Possible string values are:
  /// - "TYPE_UNSPECIFIED" : Unknown event type.
  /// - "SENT" : Indicates a sent message.
  /// - "RECEIVED" : Indicates a received message.
  core.String? type;

  /// The number of uncompressed bytes sent or received.
  core.String? uncompressedSizeBytes;

  MessageEvent();

  MessageEvent.fromJson(core.Map _json) {
    if (_json.containsKey('compressedSizeBytes')) {
      compressedSizeBytes = _json['compressedSizeBytes'] as core.String;
    }
    if (_json.containsKey('id')) {
      id = _json['id'] as core.String;
    }
    if (_json.containsKey('type')) {
      type = _json['type'] as core.String;
    }
    if (_json.containsKey('uncompressedSizeBytes')) {
      uncompressedSizeBytes = _json['uncompressedSizeBytes'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (compressedSizeBytes != null)
          'compressedSizeBytes': compressedSizeBytes!,
        if (id != null) 'id': id!,
        if (type != null) 'type': type!,
        if (uncompressedSizeBytes != null)
          'uncompressedSizeBytes': uncompressedSizeBytes!,
      };
}

/// Binary module.
class Module {
  /// A unique identifier for the module, usually a hash of its contents (up to
  /// 128 bytes).
  TruncatableString? buildId;

  /// For example: main binary, kernel modules, and dynamic libraries such as
  /// libc.so, sharedlib.so (up to 256 bytes).
  TruncatableString? module;

  Module();

  Module.fromJson(core.Map _json) {
    if (_json.containsKey('buildId')) {
      buildId = TruncatableString.fromJson(
          _json['buildId'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('module')) {
      module = TruncatableString.fromJson(
          _json['module'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (buildId != null) 'buildId': buildId!.toJson(),
        if (module != null) 'module': module!.toJson(),
      };
}

/// A span represents a single operation within a trace.
///
/// Spans can be nested to form a trace tree. Often, a trace contains a root
/// span that describes the end-to-end latency, and one or more subspans for its
/// sub-operations. A trace can also contain multiple root spans, or none at
/// all. Spans do not need to be contiguous—there may be gaps or overlaps
/// between spans in a trace.
class Span {
  /// A set of attributes on the span.
  ///
  /// You can have up to 32 attributes per span.
  Attributes? attributes;

  /// The number of child spans that were generated while this span was active.
  ///
  /// If set, allows implementation to detect missing child spans.
  ///
  /// Optional.
  core.int? childSpanCount;

  /// A description of the span's operation (up to 128 bytes).
  ///
  /// Trace displays the description in the Google Cloud Platform Console. For
  /// example, the display name can be a qualified method name or a file name
  /// and a line number where the operation is called. A best practice is to use
  /// the same display name within an application and at the same call point.
  /// This makes it easier to correlate spans in different traces.
  ///
  /// Required.
  TruncatableString? displayName;

  /// The end time of the span.
  ///
  /// On the client side, this is the time kept by the local machine where the
  /// span execution ends. On the server side, this is the time when the server
  /// application handler stops running.
  ///
  /// Required.
  core.String? endTime;

  /// Links associated with the span.
  ///
  /// You can have up to 128 links per Span.
  Links? links;

  /// The resource name of the span in the following format:
  /// projects/\[PROJECT_ID\]/traces/\[TRACE_ID\]/spans/SPAN_ID is a unique
  /// identifier for a trace within a project; it is a 32-character hexadecimal
  /// encoding of a 16-byte array.
  ///
  /// \[SPAN_ID\] is a unique identifier for a span within a trace; it is a
  /// 16-character hexadecimal encoding of an 8-byte array. It should not be
  /// zero.
  ///
  /// Required.
  core.String? name;

  /// The \[SPAN_ID\] of this span's parent span.
  ///
  /// If this is a root span, then this field must be empty.
  core.String? parentSpanId;

  /// Set this parameter to indicate whether this span is in the same process as
  /// its parent.
  ///
  /// If you do not set this parameter, Trace is unable to take advantage of
  /// this helpful information.
  ///
  /// Optional.
  core.bool? sameProcessAsParentSpan;

  /// The \[SPAN_ID\] portion of the span's resource name.
  ///
  /// Required.
  core.String? spanId;

  /// Distinguishes between spans generated in a particular context.
  ///
  /// For example, two spans with the same name may be distinguished using
  /// `CLIENT` (caller) and `SERVER` (callee) to identify an RPC call.
  ///
  /// Optional.
  /// Possible string values are:
  /// - "SPAN_KIND_UNSPECIFIED" : Unspecified. Do NOT use as default.
  /// Implementations MAY assume SpanKind.INTERNAL to be default.
  /// - "INTERNAL" : Indicates that the span is used internally. Default value.
  /// - "SERVER" : Indicates that the span covers server-side handling of an RPC
  /// or other remote network request.
  /// - "CLIENT" : Indicates that the span covers the client-side wrapper around
  /// an RPC or other remote request.
  /// - "PRODUCER" : Indicates that the span describes producer sending a
  /// message to a broker. Unlike client and server, there is no direct critical
  /// path latency relationship between producer and consumer spans (e.g.
  /// publishing a message to a pubsub service).
  /// - "CONSUMER" : Indicates that the span describes consumer receiving a
  /// message from a broker. Unlike client and server, there is no direct
  /// critical path latency relationship between producer and consumer spans
  /// (e.g. receiving a message from a pubsub service subscription).
  core.String? spanKind;

  /// Stack trace captured at the start of the span.
  StackTrace? stackTrace;

  /// The start time of the span.
  ///
  /// On the client side, this is the time kept by the local machine where the
  /// span execution starts. On the server side, this is the time when the
  /// server's application handler starts running.
  ///
  /// Required.
  core.String? startTime;

  /// The final status for this span.
  ///
  /// Optional.
  Status? status;

  /// A set of time events.
  ///
  /// You can have up to 32 annotations and 128 message events per span.
  TimeEvents? timeEvents;

  Span();

  Span.fromJson(core.Map _json) {
    if (_json.containsKey('attributes')) {
      attributes = Attributes.fromJson(
          _json['attributes'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('childSpanCount')) {
      childSpanCount = _json['childSpanCount'] as core.int;
    }
    if (_json.containsKey('displayName')) {
      displayName = TruncatableString.fromJson(
          _json['displayName'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('endTime')) {
      endTime = _json['endTime'] as core.String;
    }
    if (_json.containsKey('links')) {
      links =
          Links.fromJson(_json['links'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('name')) {
      name = _json['name'] as core.String;
    }
    if (_json.containsKey('parentSpanId')) {
      parentSpanId = _json['parentSpanId'] as core.String;
    }
    if (_json.containsKey('sameProcessAsParentSpan')) {
      sameProcessAsParentSpan = _json['sameProcessAsParentSpan'] as core.bool;
    }
    if (_json.containsKey('spanId')) {
      spanId = _json['spanId'] as core.String;
    }
    if (_json.containsKey('spanKind')) {
      spanKind = _json['spanKind'] as core.String;
    }
    if (_json.containsKey('stackTrace')) {
      stackTrace = StackTrace.fromJson(
          _json['stackTrace'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('startTime')) {
      startTime = _json['startTime'] as core.String;
    }
    if (_json.containsKey('status')) {
      status = Status.fromJson(
          _json['status'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('timeEvents')) {
      timeEvents = TimeEvents.fromJson(
          _json['timeEvents'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (attributes != null) 'attributes': attributes!.toJson(),
        if (childSpanCount != null) 'childSpanCount': childSpanCount!,
        if (displayName != null) 'displayName': displayName!.toJson(),
        if (endTime != null) 'endTime': endTime!,
        if (links != null) 'links': links!.toJson(),
        if (name != null) 'name': name!,
        if (parentSpanId != null) 'parentSpanId': parentSpanId!,
        if (sameProcessAsParentSpan != null)
          'sameProcessAsParentSpan': sameProcessAsParentSpan!,
        if (spanId != null) 'spanId': spanId!,
        if (spanKind != null) 'spanKind': spanKind!,
        if (stackTrace != null) 'stackTrace': stackTrace!.toJson(),
        if (startTime != null) 'startTime': startTime!,
        if (status != null) 'status': status!.toJson(),
        if (timeEvents != null) 'timeEvents': timeEvents!.toJson(),
      };
}

/// Represents a single stack frame in a stack trace.
class StackFrame {
  /// The column number where the function call appears, if available.
  ///
  /// This is important in JavaScript because of its anonymous functions.
  core.String? columnNumber;

  /// The name of the source file where the function call appears (up to 256
  /// bytes).
  TruncatableString? fileName;

  /// The fully-qualified name that uniquely identifies the function or method
  /// that is active in this frame (up to 1024 bytes).
  TruncatableString? functionName;

  /// The line number in `file_name` where the function call appears.
  core.String? lineNumber;

  /// The binary module from where the code was loaded.
  Module? loadModule;

  /// An un-mangled function name, if `function_name` is
  /// [mangled](http://www.avabodh.com/cxxin/namemangling.html).
  ///
  /// The name can be fully-qualified (up to 1024 bytes).
  TruncatableString? originalFunctionName;

  /// The version of the deployed source code (up to 128 bytes).
  TruncatableString? sourceVersion;

  StackFrame();

  StackFrame.fromJson(core.Map _json) {
    if (_json.containsKey('columnNumber')) {
      columnNumber = _json['columnNumber'] as core.String;
    }
    if (_json.containsKey('fileName')) {
      fileName = TruncatableString.fromJson(
          _json['fileName'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('functionName')) {
      functionName = TruncatableString.fromJson(
          _json['functionName'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('lineNumber')) {
      lineNumber = _json['lineNumber'] as core.String;
    }
    if (_json.containsKey('loadModule')) {
      loadModule = Module.fromJson(
          _json['loadModule'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('originalFunctionName')) {
      originalFunctionName = TruncatableString.fromJson(
          _json['originalFunctionName'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('sourceVersion')) {
      sourceVersion = TruncatableString.fromJson(
          _json['sourceVersion'] as core.Map<core.String, core.dynamic>);
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (columnNumber != null) 'columnNumber': columnNumber!,
        if (fileName != null) 'fileName': fileName!.toJson(),
        if (functionName != null) 'functionName': functionName!.toJson(),
        if (lineNumber != null) 'lineNumber': lineNumber!,
        if (loadModule != null) 'loadModule': loadModule!.toJson(),
        if (originalFunctionName != null)
          'originalFunctionName': originalFunctionName!.toJson(),
        if (sourceVersion != null) 'sourceVersion': sourceVersion!.toJson(),
      };
}

/// A collection of stack frames, which can be truncated.
class StackFrames {
  /// The number of stack frames that were dropped because there were too many
  /// stack frames.
  ///
  /// If this value is 0, then no stack frames were dropped.
  core.int? droppedFramesCount;

  /// Stack frames in this call stack.
  core.List<StackFrame>? frame;

  StackFrames();

  StackFrames.fromJson(core.Map _json) {
    if (_json.containsKey('droppedFramesCount')) {
      droppedFramesCount = _json['droppedFramesCount'] as core.int;
    }
    if (_json.containsKey('frame')) {
      frame = (_json['frame'] as core.List)
          .map<StackFrame>((value) =>
              StackFrame.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (droppedFramesCount != null)
          'droppedFramesCount': droppedFramesCount!,
        if (frame != null)
          'frame': frame!.map((value) => value.toJson()).toList(),
      };
}

/// A call stack appearing in a trace.
class StackTrace {
  /// Stack frames in this stack trace.
  ///
  /// A maximum of 128 frames are allowed.
  StackFrames? stackFrames;

  /// The hash ID is used to conserve network bandwidth for duplicate stack
  /// traces within a single trace.
  ///
  /// Often multiple spans will have identical stack traces. The first
  /// occurrence of a stack trace should contain both the `stackFrame` content
  /// and a value in `stackTraceHashId`. Subsequent spans within the same
  /// request can refer to that stack trace by only setting `stackTraceHashId`.
  core.String? stackTraceHashId;

  StackTrace();

  StackTrace.fromJson(core.Map _json) {
    if (_json.containsKey('stackFrames')) {
      stackFrames = StackFrames.fromJson(
          _json['stackFrames'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('stackTraceHashId')) {
      stackTraceHashId = _json['stackTraceHashId'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (stackFrames != null) 'stackFrames': stackFrames!.toJson(),
        if (stackTraceHashId != null) 'stackTraceHashId': stackTraceHashId!,
      };
}

/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs.
///
/// It is used by [gRPC](https://github.com/grpc). Each `Status` message
/// contains three pieces of data: error code, error message, and error details.
/// You can find out more about this error model and how to work with it in the
/// [API Design Guide](https://cloud.google.com/apis/design/errors).
class Status {
  /// The status code, which should be an enum value of google.rpc.Code.
  core.int? code;

  /// A list of messages that carry the error details.
  ///
  /// There is a common set of message types for APIs to use.
  ///
  /// The values for Object must be JSON objects. It can consist of `num`,
  /// `String`, `bool` and `null` as well as `Map` and `List` values.
  core.List<core.Map<core.String, core.Object>>? details;

  /// A developer-facing error message, which should be in English.
  ///
  /// Any user-facing error message should be localized and sent in the
  /// google.rpc.Status.details field, or localized by the client.
  core.String? message;

  Status();

  Status.fromJson(core.Map _json) {
    if (_json.containsKey('code')) {
      code = _json['code'] as core.int;
    }
    if (_json.containsKey('details')) {
      details = (_json['details'] as core.List)
          .map<core.Map<core.String, core.Object>>(
              (value) => (value as core.Map<core.String, core.dynamic>).map(
                    (key, item) => core.MapEntry(
                      key,
                      item as core.Object,
                    ),
                  ))
          .toList();
    }
    if (_json.containsKey('message')) {
      message = _json['message'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (code != null) 'code': code!,
        if (details != null) 'details': details!,
        if (message != null) 'message': message!,
      };
}

/// A time-stamped annotation or message event in the Span.
class TimeEvent {
  /// Text annotation with a set of attributes.
  Annotation? annotation;

  /// An event describing a message sent/received between Spans.
  MessageEvent? messageEvent;

  /// The timestamp indicating the time the event occurred.
  core.String? time;

  TimeEvent();

  TimeEvent.fromJson(core.Map _json) {
    if (_json.containsKey('annotation')) {
      annotation = Annotation.fromJson(
          _json['annotation'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('messageEvent')) {
      messageEvent = MessageEvent.fromJson(
          _json['messageEvent'] as core.Map<core.String, core.dynamic>);
    }
    if (_json.containsKey('time')) {
      time = _json['time'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (annotation != null) 'annotation': annotation!.toJson(),
        if (messageEvent != null) 'messageEvent': messageEvent!.toJson(),
        if (time != null) 'time': time!,
      };
}

/// A collection of `TimeEvent`s.
///
/// A `TimeEvent` is a time-stamped annotation on the span, consisting of either
/// user-supplied key:value pairs, or details of a message sent/received between
/// Spans.
class TimeEvents {
  /// The number of dropped annotations in all the included time events.
  ///
  /// If the value is 0, then no annotations were dropped.
  core.int? droppedAnnotationsCount;

  /// The number of dropped message events in all the included time events.
  ///
  /// If the value is 0, then no message events were dropped.
  core.int? droppedMessageEventsCount;

  /// A collection of `TimeEvent`s.
  core.List<TimeEvent>? timeEvent;

  TimeEvents();

  TimeEvents.fromJson(core.Map _json) {
    if (_json.containsKey('droppedAnnotationsCount')) {
      droppedAnnotationsCount = _json['droppedAnnotationsCount'] as core.int;
    }
    if (_json.containsKey('droppedMessageEventsCount')) {
      droppedMessageEventsCount =
          _json['droppedMessageEventsCount'] as core.int;
    }
    if (_json.containsKey('timeEvent')) {
      timeEvent = (_json['timeEvent'] as core.List)
          .map<TimeEvent>((value) =>
              TimeEvent.fromJson(value as core.Map<core.String, core.dynamic>))
          .toList();
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (droppedAnnotationsCount != null)
          'droppedAnnotationsCount': droppedAnnotationsCount!,
        if (droppedMessageEventsCount != null)
          'droppedMessageEventsCount': droppedMessageEventsCount!,
        if (timeEvent != null)
          'timeEvent': timeEvent!.map((value) => value.toJson()).toList(),
      };
}

/// Represents a string that might be shortened to a specified length.
class TruncatableString {
  /// The number of bytes removed from the original string.
  ///
  /// If this value is 0, then the string was not shortened.
  core.int? truncatedByteCount;

  /// The shortened string.
  ///
  /// For example, if the original string is 500 bytes long and the limit of the
  /// string is 128 bytes, then `value` contains the first 128 bytes of the
  /// 500-byte string. Truncation always happens on a UTF8 character boundary.
  /// If there are multi-byte characters in the string, then the length of the
  /// shortened string might be less than the size limit.
  core.String? value;

  TruncatableString();

  TruncatableString.fromJson(core.Map _json) {
    if (_json.containsKey('truncatedByteCount')) {
      truncatedByteCount = _json['truncatedByteCount'] as core.int;
    }
    if (_json.containsKey('value')) {
      value = _json['value'] as core.String;
    }
  }

  core.Map<core.String, core.dynamic> toJson() => {
        if (truncatedByteCount != null)
          'truncatedByteCount': truncatedByteCount!,
        if (value != null) 'value': value!,
      };
}
