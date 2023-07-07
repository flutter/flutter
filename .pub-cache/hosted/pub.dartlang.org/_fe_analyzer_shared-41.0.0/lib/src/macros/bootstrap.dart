// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'executor/serialization.dart'
    show SerializationMode, SerializationModeHelpers;

/// Generates a Dart program for a given set of macros, which can be compiled
/// and then passed as a precompiled kernel file to `MacroExecutor.loadMacro`.
///
/// The [macroDeclarations] is a map from library URIs to macro classes for the
/// macros supported. The macro classes are provided as a map from macro class
/// names to the names of the macro class constructors.
///
/// The [serializationMode] must be a client variant.
String bootstrapMacroIsolate(
    Map<String, Map<String, List<String>>> macroDeclarations,
    SerializationMode serializationMode) {
  if (!serializationMode.isClient) {
    throw new ArgumentError(
        'Got $serializationMode but expected a client version.');
  }
  StringBuffer imports = new StringBuffer();
  StringBuffer constructorEntries = new StringBuffer();
  macroDeclarations
      .forEach((String macroImport, Map<String, List<String>> macroClasses) {
    imports.writeln('import \'$macroImport\';');
    constructorEntries.writeln("Uri.parse('$macroImport'): {");
    macroClasses.forEach((String macroName, List<String> constructorNames) {
      constructorEntries.writeln("'$macroName': {");
      for (String constructor in constructorNames) {
        constructorEntries.writeln("'$constructor': "
            "$macroName.${constructor.isEmpty ? 'new' : constructor},");
      }
      constructorEntries.writeln('},');
    });
    constructorEntries.writeln('},');
  });
  return template
      .replaceFirst(_importMarker, imports.toString())
      .replaceFirst(
          _macroConstructorEntriesMarker, constructorEntries.toString())
      .replaceFirst(_modeMarker, serializationMode.asCode);
}

const String _importMarker = '{{IMPORT}}';
const String _macroConstructorEntriesMarker = '{{MACRO_CONSTRUCTOR_ENTRIES}}';
const String _modeMarker = '{{SERIALIZATION_MODE}}';

const String template = '''
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:_fe_analyzer_shared/src/macros/executor/execute_macro.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/introspection_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/message_grouper.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/remote_instance.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/response_impls.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/serialization.dart';
import 'package:_fe_analyzer_shared/src/macros/executor/protocol.dart';
import 'package:_fe_analyzer_shared/src/macros/executor.dart';
import 'package:_fe_analyzer_shared/src/macros/api.dart';

$_importMarker

/// Entrypoint to be spawned with [Isolate.spawnUri] or [Process.start].
///
/// Supports the client side of the macro expansion protocol.
void main(List<String> arguments, [SendPort? sendPort]) {
  // Function that sends the result of a [Serializer] using either [sendPort]
  // or [stdout].
  void Function(Serializer) sendResult;

  // The stream for incoming messages, could be either a ReceivePort, stdin, or
  // a socket.
  Stream<Object?> messageStream;

  String? socketAddress;
  int? socketPort;
  if (arguments.isNotEmpty) {
    if (arguments.length != 2) {
      throw new ArgumentError(
          'Expected exactly two or zero arguments, got \$arguments.');
    }
    socketAddress = arguments.first;
    socketPort = int.parse(arguments[1]);
  }

  withSerializationMode($_modeMarker, () async {
    if (sendPort != null) {
      ReceivePort receivePort = new ReceivePort();
      messageStream = receivePort;
      sendResult = (Serializer serializer) =>
          _sendIsolateResult(serializer, sendPort);
      // If using isolate communication, first send a sendPort to the parent
      // isolate.
      sendPort.send(receivePort.sendPort);
    } else {
      late Stream<List<int>> inputStream;
      if (socketAddress != null && socketPort != null) {
        var socket = await Socket.connect(socketAddress, socketPort);
        sendResult = _sendIOSinkResultFactory(socket);
        inputStream = socket;
      } else {
        sendResult = _sendIOSinkResultFactory(stdout);
        inputStream = stdin;
      }
      if (serializationMode == SerializationMode.byteDataClient) {
        messageStream = MessageGrouper(inputStream).messageStream;
      } else if (serializationMode == SerializationMode.jsonClient) {
        messageStream = const Utf8Decoder()
          .bind(inputStream)
          .transform(const LineSplitter())
          .map((line) => jsonDecode(line)!);
      } else {
        throw new UnsupportedError(
            'Unsupported serialization mode \$serializationMode for '
            'ProcessExecutor');
      }
    }

    messageStream.listen((message) => _handleMessage(message, sendResult));
  });
}

void _handleMessage(
    Object? message, void Function(Serializer) sendResult) async {
  // Serializes `request` and send it using `sendResult`.
  Future<Response> sendRequest(Request request) =>
      _sendRequest(request, sendResult);

  if (serializationMode == SerializationMode.byteDataClient
      && message is TransferableTypedData) {
    message = message.materialize().asUint8List();
  }
  var deserializer = deserializerFactory(message)
      ..moveNext();
  int zoneId = deserializer.expectInt();
  deserializer..moveNext();
  var type = MessageType.values[deserializer.expectInt()];
  var serializer = serializerFactory();
  switch (type) {
    case MessageType.instantiateMacroRequest:
      var request = new InstantiateMacroRequest.deserialize(deserializer, zoneId);
      (await _instantiateMacro(request)).serialize(serializer);
      break;
    case MessageType.executeDeclarationsPhaseRequest:
      var request = new ExecuteDeclarationsPhaseRequest.deserialize(deserializer, zoneId);
      (await _executeDeclarationsPhase(request, sendRequest)).serialize(serializer);
      break;
    case MessageType.executeDefinitionsPhaseRequest:
      var request = new ExecuteDefinitionsPhaseRequest.deserialize(deserializer, zoneId);
      (await _executeDefinitionsPhase(request, sendRequest)).serialize(serializer);
      break;
    case MessageType.executeTypesPhaseRequest:
      var request = new ExecuteTypesPhaseRequest.deserialize(deserializer, zoneId);
      (await _executeTypesPhase(request, sendRequest)).serialize(serializer);
      break;
    case MessageType.response:
      var response = new SerializableResponse.deserialize(deserializer, zoneId);
      _responseCompleters.remove(response.requestId)!.complete(response);
      return;
    default:
      throw new StateError('Unhandled event type \$type');
  }
  sendResult(serializer);
}

/// Maps libraries by uri to macros by name, and then constructors by name.
final _macroConstructors = <Uri, Map<String, Map<String, Function>>>{
  $_macroConstructorEntriesMarker
};

/// Maps macro instance identifiers to instances.
final _macroInstances = <MacroInstanceIdentifierImpl, Macro>{};

/// Handles [InstantiateMacroRequest]s.
Future<SerializableResponse> _instantiateMacro(
    InstantiateMacroRequest request) async {
  try {
    var classes = _macroConstructors[request.library];
    if (classes == null) {
      throw new ArgumentError('Unrecognized macro library \${request.library}');
    }
    var constructors = classes[request.name];
    if (constructors == null) {
      throw new ArgumentError(
          'Unrecognized macro class \${request.name} for library '
          '\${request.library}');
    }
    var constructor = constructors[request.constructor];
    if (constructor == null) {
      throw new ArgumentError(
          'Unrecognized constructor name "\${request.constructor}" for '
          'macro class "\${request.name}".');
    }

    var instance = Function.apply(constructor, request.arguments.positional, {
      for (MapEntry<String, Object?> entry in request.arguments.named.entries)
        new Symbol(entry.key): entry.value,
    }) as Macro;
    var identifier = new MacroInstanceIdentifierImpl(instance, request.instanceId);
    _macroInstances[identifier] = instance;
    return new SerializableResponse(
        responseType: MessageType.macroInstanceIdentifier,
        response: identifier,
        requestId: request.id,
        serializationZoneId: request.serializationZoneId);
  } catch (e, s) {
    return new SerializableResponse(
      responseType: MessageType.error,
      error: e.toString(),
      stackTrace: s.toString(),
      requestId: request.id,
      serializationZoneId: request.serializationZoneId);
  }
}

Future<SerializableResponse> _executeTypesPhase(
    ExecuteTypesPhaseRequest request,
    Future<Response> Function(Request request) sendRequest) async {
  try {
    Macro? instance = _macroInstances[request.macro];
    if (instance == null) {
      throw new StateError('Unrecognized macro instance \${request.macro}\\n'
          'Known instances: \$_macroInstances)');
    }
    var identifierResolver = ClientIdentifierResolver(
        sendRequest,
        remoteInstance: request.identifierResolver,
        serializationZoneId: request.serializationZoneId);

    var result = await executeTypesMacro(
        instance, request.declaration, identifierResolver);
    return new SerializableResponse(
        responseType: MessageType.macroExecutionResult,
        response: result,
        requestId: request.id,
        serializationZoneId: request.serializationZoneId);
  } catch (e, s) {
    return new SerializableResponse(
      responseType: MessageType.error,
      error: e.toString(),
      stackTrace: s.toString(),
      requestId: request.id,
      serializationZoneId: request.serializationZoneId);
  }
}

Future<SerializableResponse> _executeDeclarationsPhase(
    ExecuteDeclarationsPhaseRequest request,
    Future<Response> Function(Request request) sendRequest) async {
  try {
    Macro? instance = _macroInstances[request.macro];
    if (instance == null) {
      throw new StateError('Unrecognized macro instance \${request.macro}\\n'
          'Known instances: \$_macroInstances)');
    }
    var identifierResolver = ClientIdentifierResolver(
        sendRequest,
        remoteInstance: request.identifierResolver,
        serializationZoneId: request.serializationZoneId);
    var typeIntrospector = ClientTypeIntrospector(
        sendRequest,
        remoteInstance: request.typeIntrospector,
        serializationZoneId: request.serializationZoneId);
    var typeDeclarationResolver = ClientTypeDeclarationResolver(
        sendRequest,
        remoteInstance: request.typeDeclarationResolver,
        serializationZoneId: request.serializationZoneId);
    var typeResolver = ClientTypeResolver(
        sendRequest,
        remoteInstance: request.typeResolver,
        serializationZoneId: request.serializationZoneId);

    var result = await executeDeclarationsMacro(
        instance, request.declaration, identifierResolver, typeIntrospector,
        typeDeclarationResolver, typeResolver);
    return new SerializableResponse(
        responseType: MessageType.macroExecutionResult,
        response: result,
        requestId: request.id,
        serializationZoneId: request.serializationZoneId);
  } catch (e, s) {
    return new SerializableResponse(
      responseType: MessageType.error,
      error: e.toString(),
      stackTrace: s.toString(),
      requestId: request.id,
      serializationZoneId: request.serializationZoneId);
  }
}

Future<SerializableResponse> _executeDefinitionsPhase(
    ExecuteDefinitionsPhaseRequest request,
    Future<Response> Function(Request request) sendRequest) async {
  try {
    Macro? instance = _macroInstances[request.macro];
    if (instance == null) {
      throw new StateError('Unrecognized macro instance \${request.macro}\\n'
          'Known instances: \$_macroInstances)');
    }
    var identifierResolver = ClientIdentifierResolver(
        sendRequest,
        remoteInstance: request.identifierResolver,
        serializationZoneId: request.serializationZoneId);
    var typeResolver = ClientTypeResolver(
        sendRequest,
        remoteInstance: request.typeResolver,
        serializationZoneId: request.serializationZoneId);
    var typeDeclarationResolver = ClientTypeDeclarationResolver(
        sendRequest,
        remoteInstance: request.typeDeclarationResolver,
        serializationZoneId: request.serializationZoneId);
    var typeIntrospector = ClientTypeIntrospector(
        sendRequest,
        remoteInstance: request.typeIntrospector,
        serializationZoneId: request.serializationZoneId);
    var typeInferrer = ClientTypeInferrer(
        sendRequest,
        remoteInstance: request.typeInferrer,
        serializationZoneId: request.serializationZoneId);

    var result = await executeDefinitionMacro(
        instance, request.declaration, identifierResolver, typeIntrospector,
        typeResolver, typeDeclarationResolver, typeInferrer);
    return new SerializableResponse(
        responseType: MessageType.macroExecutionResult,
        response: result,
        requestId: request.id,
        serializationZoneId: request.serializationZoneId);
  } catch (e, s) {
    return new SerializableResponse(
      responseType: MessageType.error,
      error: e.toString(),
      stackTrace: s.toString(),
      requestId: request.id,
      serializationZoneId: request.serializationZoneId);
  }
}

/// Holds on to response completers by request id.
final _responseCompleters = <int, Completer<Response>>{};

/// Serializes [request], passes it to [sendResult], and sets up a [Completer]
/// in [_responseCompleters] to handle the response.
Future<Response> _sendRequest(
    Request request, void Function(Serializer serializer) sendResult) {
  Completer<Response> completer = Completer();
  _responseCompleters[request.id] = completer;
  Serializer serializer = serializerFactory();
  serializer.addInt(request.serializationZoneId);
  request.serialize(serializer);
  sendResult(serializer);
  return completer.future;
}

/// Sends [serializer.result] to [sendPort], possibly wrapping it in a
/// [TransferableTypedData] object.
void _sendIsolateResult(Serializer serializer, SendPort sendPort) {
  if (serializationMode == SerializationMode.byteDataClient) {
    sendPort.send(
        TransferableTypedData.fromList([serializer.result as Uint8List]));
  } else {
    sendPort.send(serializer.result);
  }
}

/// Returns a function which takes a [Serializer] and sends its result to
/// [sink].
///
/// Serializes the result to a string if using JSON.
void Function(Serializer) _sendIOSinkResultFactory(IOSink sink) =>
    (Serializer serializer) {
      if (serializationMode == SerializationMode.jsonClient) {
        sink.writeln(jsonEncode(serializer.result));
      } else if (serializationMode == SerializationMode.byteDataClient) {
        Uint8List result = (serializer as ByteDataSerializer).result;
        int length = result.lengthInBytes;
        sink.add([
          length >> 24 & 0xff,
          length >> 16 & 0xff,
          length >> 8 & 0xff,
          length & 0xff,
        ]);
        sink.add(result);
      } else {
        throw new UnsupportedError(
            'Unsupported serialization mode \$serializationMode for '
            'ProcessExecutor');
      }
    };
''';
