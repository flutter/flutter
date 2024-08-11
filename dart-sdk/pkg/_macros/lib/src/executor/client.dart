// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import '../api.dart';
import '../executor.dart';
import 'exception_impls.dart';
import 'execute_macro.dart';
import 'message_grouper.dart';
import 'protocol.dart';
import 'remote_instance.dart';
import 'response_impls.dart';
import 'serialization.dart';

/// Implements the client side of the macro instantiation/expansion protocol.
final class MacroExpansionClient {
  /// A map of the instantiable macro constructors.
  ///
  /// The outer map is keyed by the URI of the library defining macros, whose
  /// values are Maps keyed
  final Map<Uri, Map<String, Map<String, Function>>> _macroConstructors;

  /// Maps macro instance identifiers to instances.
  final Map<MacroInstanceIdentifierImpl, Macro> _macroInstances = {};

  /// Holds on to response completers by request id.
  final Map<int, Completer<Response>> _responseCompleters = {};

  MacroExpansionClient._(void Function(Serializer) sendResult,
      Stream<Object?> messageStream, this._macroConstructors) {
    messageStream.listen((message) => _handleMessage(message, sendResult));
  }

  /// Spawns a client connecting either to [sendPort] or a socket address and
  /// port given in [arguments].
  static Future<MacroExpansionClient> start(
      SerializationMode serializationMode,
      Map<Uri, Map<String, Map<String, Function>>> macroConstructors,
      List<String> arguments,
      SendPort? sendPort) {
    return withSerializationMode(serializationMode, () async {
      // Function that sends the result of a `Serializer` using either
      // `sendPort` or `stdout`.
      void Function(Serializer) sendResult;

      // The stream for incoming messages, could be either a ReceivePort, stdin,
      // or a socket.
      Stream<Object?> messageStream;

      String? socketAddress;
      int? socketPort;
      if (arguments.isNotEmpty) {
        if (arguments.length != 2) {
          throw ArgumentError(
              'Expected exactly two or zero arguments, got $arguments.');
        }
        socketAddress = arguments.first;
        socketPort = int.parse(arguments[1]);
      }

      if (sendPort != null) {
        ReceivePort receivePort = ReceivePort();
        messageStream = receivePort;
        sendResult =
            (Serializer serializer) => _sendIsolateResult(serializer, sendPort);
        // If using isolate communication, first send a sendPort to the parent
        // isolate.
        sendPort.send(receivePort.sendPort);
      } else {
        late Stream<List<int>> inputStream;
        if (socketAddress != null && socketPort != null) {
          Socket socket = await Socket.connect(socketAddress, socketPort);
          // Nagle's algorithm slows us down >100x, disable it.
          socket.setOption(SocketOption.tcpNoDelay, true);
          sendResult = _sendIOSinkResultFactory(socket);
          inputStream = socket;
        } else {
          sendResult = _sendIOSinkResultFactory(stdout);
          inputStream = stdin;
        }
        if (serializationMode == SerializationMode.byteData) {
          messageStream = MessageGrouper(inputStream).messageStream;
        } else if (serializationMode == SerializationMode.json) {
          messageStream = const Utf8Decoder()
              .bind(inputStream)
              .transform(const LineSplitter())
              .map((line) => jsonDecode(line)!);
        } else {
          throw UnsupportedError(
              'Unsupported serialization mode $serializationMode for '
              'ProcessExecutor');
        }
      }

      return MacroExpansionClient._(
          sendResult, messageStream, macroConstructors);
    });
  }

  void _handleMessage(
      Object? message, void Function(Serializer) sendResult) async {
    // Serializes `request` and sends it using `sendResult`.
    Future<Response> sendRequest(Request request) =>
        _sendRequest(request, sendResult);

    if (serializationMode == SerializationMode.byteData &&
        message is TransferableTypedData) {
      message = message.materialize().asUint8List();
    }
    Deserializer deserializer = deserializerFactory(message)..moveNext();
    int zoneId = deserializer.expectInt();
    await withRemoteInstanceZone(zoneId, () async {
      deserializer.moveNext();
      MessageType type = MessageType.values[deserializer.expectInt()];
      Serializer serializer = serializerFactory();
      switch (type) {
        case MessageType.instantiateMacroRequest:
          InstantiateMacroRequest request =
              InstantiateMacroRequest.deserialize(deserializer, zoneId);
          (await _instantiateMacro(request)).serialize(serializer);
        case MessageType.disposeMacroRequest:
          DisposeMacroRequest request =
              DisposeMacroRequest.deserialize(deserializer, zoneId);
          _macroInstances.remove(request.identifier);
          return;
        case MessageType.executeDeclarationsPhaseRequest:
          ExecuteDeclarationsPhaseRequest request =
              ExecuteDeclarationsPhaseRequest.deserialize(deserializer, zoneId);
          (await _executeDeclarationsPhase(request, sendRequest))
              .serialize(serializer);
        case MessageType.executeDefinitionsPhaseRequest:
          ExecuteDefinitionsPhaseRequest request =
              ExecuteDefinitionsPhaseRequest.deserialize(deserializer, zoneId);
          (await _executeDefinitionsPhase(request, sendRequest))
              .serialize(serializer);
        case MessageType.executeTypesPhaseRequest:
          ExecuteTypesPhaseRequest request =
              ExecuteTypesPhaseRequest.deserialize(deserializer, zoneId);
          (await _executeTypesPhase(request, sendRequest))
              .serialize(serializer);
        case MessageType.response:
          SerializableResponse response =
              SerializableResponse.deserialize(deserializer, zoneId);
          _responseCompleters.remove(response.requestId)!.complete(response);
          return;
        case MessageType.destroyRemoteInstanceZoneRequest:
          DestroyRemoteInstanceZoneRequest request =
              DestroyRemoteInstanceZoneRequest.deserialize(
                  deserializer, zoneId);
          destroyRemoteInstanceZone(request.serializationZoneId);
          return;
        default:
          throw StateError('Unhandled event type $type');
      }
      sendResult(serializer);
    }, createIfMissing: true);
  }

  /// Handles [InstantiateMacroRequest]s.
  Future<SerializableResponse> _instantiateMacro(
      InstantiateMacroRequest request) async {
    try {
      Map<String, Map<String, Function>> classes =
          _macroConstructors[request.library] ??
              (throw ArgumentError(
                  'Unrecognized macro library ${request.library}'));
      Map<String, Function> constructors = classes[request.name] ??
          (throw ArgumentError(
              'Unrecognized macro class ${request.name} for library '
              '${request.library}'));
      Function constructor = constructors[request.constructor] ??
          (throw ArgumentError(
              'Unrecognized constructor name "${request.constructor}" for '
              'macro class "${request.name}".'));

      Macro instance = Function.apply(constructor, [
        for (Argument argument in request.arguments.positional) argument.value,
      ], {
        for (MapEntry<String, Argument> entry
            in request.arguments.named.entries)
          Symbol(entry.key): entry.value.value,
      }) as Macro;
      MacroInstanceIdentifierImpl identifier =
          MacroInstanceIdentifierImpl(instance, request.instanceId);
      _macroInstances[identifier] = instance;
      return SerializableResponse(
          responseType: MessageType.macroInstanceIdentifier,
          response: identifier,
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    } catch (e, s) {
      return SerializableResponse(
          responseType: MessageType.exception,
          exception: MacroExceptionImpl.from(e, s),
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    }
  }

  Future<SerializableResponse> _executeTypesPhase(
      ExecuteTypesPhaseRequest request,
      Future<Response> Function(Request request) sendRequest) async {
    try {
      Macro instance = _macroInstances[request.macro] ??
          (throw StateError('Unrecognized macro instance ${request.macro}\n'
              'Known instances: $_macroInstances)'));
      TypePhaseIntrospector introspector = ClientTypePhaseIntrospector(
          sendRequest,
          remoteInstance: request.introspector,
          serializationZoneId: request.serializationZoneId);

      MacroExecutionResult result = await runPhase(
          () => executeTypesMacro(instance, request.target, introspector));
      return SerializableResponse(
          responseType: MessageType.macroExecutionResult,
          response: result,
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    } catch (e, s) {
      return SerializableResponse(
          responseType: MessageType.exception,
          exception: MacroExceptionImpl.from(e, s),
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    }
  }

  Future<SerializableResponse> _executeDeclarationsPhase(
      ExecuteDeclarationsPhaseRequest request,
      Future<Response> Function(Request request) sendRequest) async {
    try {
      Macro instance = _macroInstances[request.macro] ??
          (throw StateError('Unrecognized macro instance ${request.macro}\n'
              'Known instances: $_macroInstances)'));

      DeclarationPhaseIntrospector introspector =
          ClientDeclarationPhaseIntrospector(sendRequest,
              remoteInstance: request.introspector,
              serializationZoneId: request.serializationZoneId);

      MacroExecutionResult result = await runPhase(() =>
          executeDeclarationsMacro(instance, request.target, introspector));
      return SerializableResponse(
          responseType: MessageType.macroExecutionResult,
          response: result,
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    } catch (e, s) {
      return SerializableResponse(
          responseType: MessageType.exception,
          exception: MacroExceptionImpl.from(e, s),
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    }
  }

  Future<SerializableResponse> _executeDefinitionsPhase(
      ExecuteDefinitionsPhaseRequest request,
      Future<Response> Function(Request request) sendRequest) async {
    try {
      Macro instance = _macroInstances[request.macro] ??
          (throw StateError('Unrecognized macro instance ${request.macro}\n'
              'Known instances: $_macroInstances)'));
      DefinitionPhaseIntrospector introspector =
          ClientDefinitionPhaseIntrospector(sendRequest,
              remoteInstance: request.introspector,
              serializationZoneId: request.serializationZoneId);

      MacroExecutionResult result = await runPhase(
          () => executeDefinitionMacro(instance, request.target, introspector));
      return SerializableResponse(
          responseType: MessageType.macroExecutionResult,
          response: result,
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    } catch (e, s) {
      return SerializableResponse(
          responseType: MessageType.exception,
          exception: MacroExceptionImpl.from(e, s),
          requestId: request.id,
          serializationZoneId: request.serializationZoneId);
    }
  }

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
}

/// Sends [serializer.result] to [sendPort], possibly wrapping it in a
/// [TransferableTypedData] object.
void _sendIsolateResult(Serializer serializer, SendPort sendPort) {
  if (serializationMode == SerializationMode.byteData) {
    sendPort
        .send(TransferableTypedData.fromList([serializer.result as Uint8List]));
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
      if (serializationMode == SerializationMode.json) {
        sink.writeln(jsonEncode(serializer.result));
      } else if (serializationMode == SerializationMode.byteData) {
        Uint8List result = (serializer as ByteDataSerializer).result;
        int length = result.lengthInBytes;
        BytesBuilder bytesBuilder = BytesBuilder(copy: false);
        bytesBuilder.add([
          length >> 24 & 0xff,
          length >> 16 & 0xff,
          length >> 8 & 0xff,
          length & 0xff,
        ]);
        bytesBuilder.add(result);
        sink.add(bytesBuilder.takeBytes());
      } else {
        throw UnsupportedError(
            'Unsupported serialization mode $serializationMode for '
            'ProcessExecutor');
      }
    };

/// Runs [phase] in a [Zone] which tracks scheduled tasks, completing with a
/// [StateError] if [phase] returns a value while additional tasks or timers
/// are still scheduled.
Future<MacroExecutionResult> runPhase(
    Future<MacroExecutionResult> Function() phase) {
  final completer = Completer<MacroExecutionResult>();

  var pendingMicrotasks = 0;
  var activeTimers = 0;
  Zone.current
      .fork(
          specification: ZoneSpecification(
        handleUncaughtError: (self, parent, zone, error, stackTrace) {
          if (completer.isCompleted) return;
          completer.completeError(error, stackTrace);
        },
        createTimer: (self, parent, zone, duration, f) {
          activeTimers++;
          return _WrappedTimer(
              parent.createTimer(zone, duration, () {
                activeTimers--;
                f();
              }),
              onCancel: () => activeTimers--);
        },
        createPeriodicTimer: (self, parent, zone, duration, f) {
          activeTimers++;
          return _WrappedTimer(parent.createPeriodicTimer(zone, duration, f),
              onCancel: () => activeTimers--);
        },
        scheduleMicrotask: (self, parent, zone, f) {
          pendingMicrotasks++;
          parent.scheduleMicrotask(zone, () {
            pendingMicrotasks--;
            assert(pendingMicrotasks >= 0);
            // This should only happen if we have previously competed with an
            // error. Just skip this scheduled task in that case.
            if (completer.isCompleted) return;
            f();
          });
        },
      ))
      .runGuarded(() => phase().then((value) {
            if (completer.isCompleted) return;
            if (pendingMicrotasks != 0) {
              throw StateError(
                  'Macro completed but has $pendingMicrotasks async tasks still '
                  'pending. Macros must complete all async work prior to '
                  'returning.');
            }
            if (activeTimers != 0) {
              throw StateError(
                  'Macro completed but has $activeTimers active timers. '
                  'Macros must cancel all timers prior to returning.');
            }
            completer.complete(value);
          }));
  return completer.future;
}

/// Wraps a [Timer] to track when it is cancelled and calls [onCancel], if the
/// timer is still active.
class _WrappedTimer implements Timer {
  final Timer timer;

  final void Function() onCancel;

  _WrappedTimer(this.timer, {required this.onCancel});

  @override
  void cancel() {
    if (isActive) onCancel();
    timer.cancel();
  }

  @override
  bool get isActive => timer.isActive;

  @override
  int get tick => timer.tick;
}
