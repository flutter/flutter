// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:async/async.dart';
import 'package:logging/logging.dart';

import 'remote_debugger.dart';

abstract class ExecutionContext {
  /// Returns the context ID that contains the running Dart application.
  Future<int> get id;
}

/// The execution context in which to do remote evaluations.
class RemoteDebuggerExecutionContext extends ExecutionContext {
  final RemoteDebugger _remoteDebugger;
  final _logger = Logger('RemoteDebuggerExecutionContext');

  /// Contexts that may contain a Dart application.
  ///
  /// Context can be null if an error has occured and we cannot detect
  /// and parse the context ID.
  late StreamQueue<int> _contexts;

  int? _id;

  @override
  Future<int> get id async {
    if (_id != null) return _id!;
    _logger.fine('Looking for Dart execution context...');
    const timeoutInMs = 100;
    while (await _contexts.hasNext
        .timeout(const Duration(milliseconds: timeoutInMs), onTimeout: () {
      _logger.warning(
          'Timed out finding an execution context after $timeoutInMs ms.');
      return false;
    })) {
      final context = await _contexts.next;
      _logger.fine('Checking context id: $context');
      try {
        final result =
            await _remoteDebugger.sendCommand('Runtime.evaluate', params: {
          'expression': r'window["$dartAppInstanceId"];',
          'contextId': context,
        });
        if (result.result?['result']?['value'] != null) {
          _logger.fine('Found valid execution context: $context');
          _id = context;
          break;
        }
      } catch (_) {
        // Errors may be thrown if we attempt to evaluate in a stale a context.
        // Ignore and continue.
        _logger.fine('Invalid execution context: $context');
      }
    }
    if (_id == null) {
      throw StateError('No context with the running Dart application.');
    }
    return _id!;
  }

  RemoteDebuggerExecutionContext(this._id, this._remoteDebugger) {
    final contextController = StreamController<int>();
    _remoteDebugger
        .eventStream('Runtime.executionContextsCleared', (e) => e)
        .listen((_) => _id = null);
    _remoteDebugger.eventStream('Runtime.executionContextCreated', (e) {
      // Parse and add the context ID to the stream.
      // If we cannot detect or parse the context ID, add `null` to the stream
      // to indicate an error context - those will be skipped when trying to find
      // the dart context, with a warning.
      final id = e.params?['context']?['id']?.toString();
      final parsedId = id == null ? null : int.parse(id);
      if (id == null) {
        _logger.warning('Cannot find execution context id: $e');
      } else if (parsedId == null) {
        _logger.warning('Cannot parse execution context id: $id');
      }
      return parsedId;
    }).listen((e) {
      if (e != null) contextController.add(e);
    });
    _contexts = StreamQueue(contextController.stream);
  }
}
