// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../base/logging.dart';
import '../runner/flutter_command.dart';
import 'start.dart';
import 'stop.dart';

const String protocolVersion = '0.0.1';

/// A @domain annotation.
const String domain = 'domain';

/// A domain @command annotation.
const String command = 'command';

// TODO: Create a `device` domain in order to list devices and fire events when
// devices are added or removed.

/// A server process command. This command will start up a long-lived server.
/// It reads JSON-RPC based commands from stdin, executes them, and returns
/// JSON-RPC based responses and events to stdout.
///
/// It can be shutdown with a `daemon.shutdown` command (or by killing the
/// process).
class DaemonCommand extends FlutterCommand {
  final String name = 'daemon';
  final String description =
      'Run a persistent, JSON-RPC based server to communicate with devices.';
  final String usageFooter =
      '\nThis command is intended to be used by tooling environments that need '
      'a programatic interface into launching Flutter applications.';

  @override
  Future<int> runInProject() async {
    print('Starting device daemon...');

    Stream<Map> commandStream = stdin
      .transform(UTF8.decoder)
      .transform(const LineSplitter())
      .where((String line) => line.startsWith('[{') && line.endsWith('}]'))
      .map((String line) {
        line = line.substring(1, line.length - 1);
        return JSON.decode(line);
      });

    await downloadApplicationPackagesAndConnectToDevices();

    Daemon daemon = new Daemon(commandStream, (Map command) {
      stdout.writeln('[${JSON.encode(command)}]');
    }, daemonCommand: this);

    return await daemon.onExit;
  }
}

typedef void DispatchComand(Map command);

typedef Future<dynamic> CommandHandler(dynamic args);

class Daemon {
  final DispatchComand sendCommand;
  final DaemonCommand daemonCommand;

  final Completer<int> _onExitCompleter = new Completer();
  final Map<String, Domain> _domains = {};

  Daemon(Stream<Map> commandStream, this.sendCommand, {this.daemonCommand}) {
    // Set up domains.
    _registerDomain(new DaemonDomain(this));
    _registerDomain(new AppDomain(this));

    // Start listening.
    commandStream.listen(
      (Map command) => _handleCommand(command),
      onDone: () => _onExitCompleter.complete(0)
    );
  }

  void _registerDomain(Domain domain) {
    _domains[domain.name] = domain;
  }

  Future<int> get onExit => _onExitCompleter.future;

  void _handleCommand(Map command) {
    // {id, event, params}
    var id = command['id'];

    if (id == null) {
      logging.severe('no id for command: $command');
      return;
    }

    try {
      String event = command['event'];
      if (event.indexOf('.') == -1)
        throw 'command not understood: $event';

      String prefix = event.substring(0, event.indexOf('.'));
      String name = event.substring(event.indexOf('.') + 1);
      if (_domains[prefix] == null)
        throw 'no domain for command: $command';

      _domains[prefix].handleEvent(name, id, command['params']);
    } catch (error, trace) {
      _send({'id': id, 'error': _toJsonable(error)});
      logging.warning('error handling ${command['event']}', error, trace);
    }
  }

  void _send(Map map) => sendCommand(map);

  void shutdown() {
    if (!_onExitCompleter.isCompleted)
      _onExitCompleter.complete(0);
  }
}

abstract class Domain {
  final Daemon daemon;
  final String name;
  final Map<String, CommandHandler> _handlers = {};

  Domain(this.daemon, this.name);

  void registerHandler(String name, CommandHandler handler) {
    _handlers[name] = handler;
  }

  String toString() => name;

  void handleEvent(String name, dynamic id, dynamic args) {
    new Future.sync(() {
      if (_handlers.containsKey(name))
        return _handlers[name](args);
      throw 'command not understood: $name';
    }).then((result) {
      if (result == null) {
        _send({'id': id});
      } else {
        _send({'id': id, 'result': _toJsonable(result)});
      }
    }).catchError((error, trace) {
      _send({'id': id, 'error': _toJsonable(error)});
      logging.warning('error handling $name', error, trace);
    });
  }

  void _send(Map map) => daemon._send(map);
}

/// This domain responds to methods like [version] and [shutdown].
@domain
class DaemonDomain extends Domain {
  DaemonDomain(Daemon daemon) : super(daemon, 'daemon') {
    registerHandler('version', version);
    registerHandler('shutdown', shutdown);
  }

  @command
  Future<dynamic> version(dynamic args) {
    return new Future.value(protocolVersion);
  }

  @command
  Future<dynamic> shutdown(dynamic args) {
    Timer.run(() => daemon.shutdown());
    return new Future.value();
  }
}

/// This domain responds to methods like [start] and [stopAll].
///
/// It'll be extended to fire events for when applications start, stop, and
/// log data.
@domain
class AppDomain extends Domain {
  AppDomain(Daemon daemon) : super(daemon, 'app') {
    registerHandler('start', start);
    registerHandler('stopAll', stopAll);
  }

  @command
  Future<dynamic> start(dynamic args) {
    // TODO: Add the ability to pass args: target, http, checked
    StartCommand startComand = new StartCommand();
    startComand.inheritFromParent(daemon.daemonCommand);
    return startComand.runInProject().then((_) => null);
  }

  @command
  Future<bool> stopAll(dynamic args) {
    StopCommand stopCommand = new StopCommand();
    stopCommand.inheritFromParent(daemon.daemonCommand);
    return stopCommand.stop();
  }
}

dynamic _toJsonable(dynamic obj) {
  if (obj is String || obj is int || obj is bool || obj is Map || obj is List || obj == null)
    return obj;
  return '$obj';
}
