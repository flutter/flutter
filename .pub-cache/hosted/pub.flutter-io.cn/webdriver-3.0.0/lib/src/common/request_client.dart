import 'dart:async';

import 'package:stack_trace/stack_trace.dart';
import 'command_event.dart';

import 'request.dart';

/// Client to send to and receive from WebDriver.
abstract class RequestClient {
  final Uri _prefix;

  RequestClient(this._prefix);

  Uri resolve(String command) => _prefix.resolve(
      command.isEmpty ? _prefix.path.replaceFirst(RegExp('/\$'), '') : command);

  @override
  String toString() => _prefix.toString();
}

typedef SyncWebDriverListener = void Function(WebDriverCommandEvent event);

/// Sync client to send to and receive from WebDriver.
abstract class SyncRequestClient extends RequestClient {
  final _commandListeners = <SyncWebDriverListener>[];

  SyncRequestClient(Uri prefix) : super(prefix);

  void addEventListener(SyncWebDriverListener listener) {
    _commandListeners.add(listener);
  }

  T send<T>(WebDriverRequest request, T Function(WebDriverResponse) process) {
    if (request.method == null) {
      return process(WebDriverResponse(200, null, request.body));
    }

    final startTime = DateTime.now();
    var trace = Chain.current();
    trace = trace.foldFrames((f) => f.library.startsWith('package:webdriver/'),
        terse: true);

    Object? exception;
    T? response;
    try {
      return response = process(sendRaw(request));
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      final event = WebDriverCommandEvent(
          method: request.method!.name,
          endPoint: resolve(request.uri!).toString(),
          params: request.body,
          startTime: startTime,
          endTime: DateTime.now(),
          exception: exception,
          result: response,
          stackTrace: trace);
      for (final listener in _commandListeners) {
        listener(event);
      }
    }
  }

  WebDriverResponse sendRaw(WebDriverRequest request);
}

typedef AsyncWebDriverListener = Future<dynamic> Function(
    WebDriverCommandEvent event);

/// Async client to send to and receive from WebDriver.
abstract class AsyncRequestClient extends RequestClient {
  final _commandListeners = <AsyncWebDriverListener>[];

  AsyncRequestClient(Uri prefix) : super(prefix);

  void addEventListener(AsyncWebDriverListener listener) {
    _commandListeners.add(listener);
  }

  Future<T> send<T>(
      WebDriverRequest request, T Function(WebDriverResponse) process) async {
    if (request.method == null) {
      return process(WebDriverResponse(200, null, request.body));
    }

    final startTime = DateTime.now();
    var trace = Chain.current();
    trace = trace.foldFrames((f) => f.library.startsWith('package:webdriver/'),
        terse: true);

    Object? exception;
    T? response;
    try {
      return response = process(await sendRaw(request));
    } catch (e) {
      exception = e;
      rethrow;
    } finally {
      final event = WebDriverCommandEvent(
          method: request.method!.name,
          endPoint: resolve(request.uri!).toString(),
          params: request.body,
          startTime: startTime,
          endTime: DateTime.now(),
          exception: exception,
          result: response,
          stackTrace: trace);
      for (final listener in _commandListeners) {
        await listener(event);
      }
    }
  }

  Future<WebDriverResponse> sendRaw(WebDriverRequest request);
}
