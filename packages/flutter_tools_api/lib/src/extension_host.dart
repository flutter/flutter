import 'dart:async';
import 'dart:isolate';

import 'common.dart';

/// Runs from root isolate.
///
/// The [ExtensionClient] will spawn the guest/child isolate and then receive
/// messages from it.
class ExtensionClient {
  /// Create an [ExtensionClient].
  ExtensionClient(void Function(SendPort) bootstrap) {
    final ReceivePort receivePort = ReceivePort();
    Isolate
        .spawn<SendPort>(bootstrap, receivePort.sendPort, paused: true)
        .then((Isolate isolate) {
      _isolate = isolate;
      _receiveSubscription = receivePort.listen(_receive);
      final ReceivePort errorPort = ReceivePort();
      _errorSubscription = errorPort.listen(_receiveError);
      _isolate.addErrorListener(errorPort.sendPort);
      _isolate.resume(_isolate.pauseCapability!);
    });
  }

  late final Isolate _isolate;
  late final StreamSubscription<Object?> _receiveSubscription;
  late final StreamSubscription<Object?> _errorSubscription;
  late final SendPort _sendPort;
  final Completer<void> _initializedCompleter = Completer<void>();
  int _nextRequestId = 0;
  final Map<int, Completer<Response>> _idToCompleter = <int, Completer<Response>>{};

  /// This [Future] will complete when the extensions [Isolate] is ready.
  Future<void> get initialized => _initializedCompleter.future;

  void _receive(Object? message) {
    if (message is SendPort) {
      _sendPort = message;
      _initializedCompleter.complete();
    } else if (message is Response) {
      final Completer<Response>? completer = _idToCompleter.remove(message.id);
      if (completer == null) {
        throw StateError('Received response ID #${message.id} but no completer cached from the request');
      }
      completer.complete(message);
    } else {
      throw UnimplementedError(message?.toString() ?? 'null');
    }
  }

  void _receiveError(Object? message) {
    throw ExtensionException(message! as List<Object?>);
  }

  Future<Response> query(Request request) {
    final int currentId = _nextRequestId;
    _nextRequestId += 1;

    final Completer<Response> completer = Completer<Response>();
    _idToCompleter[currentId] = completer;
    _sendPort.send(
      RequestWrapper(
        id: currentId,
        request: request,
      ),
    );

    return completer.future;
  }

  /// Call to kill the extensions isolate and cancel subscriptions.
  Future<void> dispose() async {
    print('entering dispose');
    _isolate.kill(priority: Isolate.immediate);
    print('awaiting sub cancellation');
    await Future.wait(<Future<void>>[
      _receiveSubscription.cancel(),
      _errorSubscription.cancel(),
    ]);
    print('exiting dispose');
  }
}
