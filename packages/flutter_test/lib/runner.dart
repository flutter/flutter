import 'dart:async';
import 'dart:isolate';

import 'package:stack_trace/stack_trace.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:async/async.dart';
import 'package:term_glyph/term_glyph.dart' as glyph;

import 'package:test_core/src/backend/declarer.dart'; // ignore: implementation_imports
import 'package:test_core/src/backend/group.dart'; // ignore: implementation_imports
import 'package:test_core/src/backend/invoker.dart'; // ignore: implementation_imports
import 'package:test_core/src/backend/live_test.dart'; // ignore: implementation_imports
import 'package:test_core/src/backend/metadata.dart'; // ignore: implementation_imports
import 'package:test_core/src/backend/stack_trace_formatter.dart'; // ignore: implementation_imports
import 'package:test_core/src/backend/suite.dart'; // ignore: implementation_imports
import 'package:test_core/src/backend/suite_platform.dart'; // ignore: implementation_imports
import 'package:test_core/src/backend/test.dart'; // ignore: implementation_imports
import 'package:test_core/src/util/remote_exception.dart'; // ignore: implementation_imports

/// Capture any top-level errors (mostly lazy syntax errors, since other are
/// caught below) and report them to the parent isolate.
void catchIsolateErrors() {
  final ReceivePort errorPort = ReceivePort();
  // Treat errors non-fatal because otherwise they'll be double-printed.
  Isolate.current.setErrorsFatal(false);
  Isolate.current.addErrorListener(errorPort.sendPort);
  errorPort.listen((dynamic message) {
    // Masquerade as an IsolateSpawnException because that's what this would
    // be if the error had been detected statically.
    final IsolateSpawnException error = IsolateSpawnException(message[0]);
    final Trace stackTrace =
        message[1] == null ? Trace(const <Frame>[]) : Trace.parse(message[1]);
    Zone.current.handleUncaughtError(error, stackTrace);
  });
}

StreamChannel serializeSuite(Function getMain(),
        {bool hidePrints = true, Future beforeLoad()}) =>
    RemoteListener.start(getMain,
        hidePrints: hidePrints, beforeLoad: beforeLoad);


class RemoteListener {
  /// The test suite to run.
  final Suite _suite;

  /// The zone to forward prints to, or `null` if prints shouldn't be forwarded.
  final Zone _printZone;

  /// Extracts metadata about all the tests in the function returned by
  /// [getMain] and returns a channel that will send information about them.
  ///
  /// The main function is wrapped in a closure so that we can handle it being
  /// undefined here rather than in the generated code.
  ///
  /// Once that's done, this starts listening for commands about which tests to
  /// run.
  ///
  /// If [hidePrints] is `true` (the default), calls to `print()` within this
  /// suite will not be forwarded to the parent zone's print handler. However,
  /// the caller may want them to be forwarded in (for example) a browser
  /// context where they'll be visible in the development console.
  ///
  /// If [beforeLoad] is passed, it's called before the tests have been declared
  /// for this worker.
  static StreamChannel<void> start(Function getMain(),
      {bool hidePrints = true, Future<void> beforeLoad()}) {
    // This has to be synchronous to work around sdk#25745. Otherwise, there'll
    // be an asynchronous pause before a syntax error notification is sent,
    // which will cause the send to fail entirely.
    final StreamChannelController<Object> controller =
        StreamChannelController<Object>(allowForeignErrors: false, sync: true);
    var channel = MultiChannel<Object>(controller.local);
    var verboseChain = true;
    var printZone = hidePrints ? null : Zone.current;
    var spec = ZoneSpecification(print: (_, __, ___, line) {
      if (printZone != null) printZone.print(line);
      channel.sink.add({"type": "print", "line": line});
    });

    // Work-around for https://github.com/dart-lang/sdk/issues/32556. Remove
    // once fixed.
    Stream<Object>.fromIterable([]).listen((_) {}).cancel();

    SuiteChannelManager().asCurrent(() {
      StackTraceFormatter().asCurrent(() {
        runZoned(() async {
          dynamic main;
          try {
            main = getMain();
          } on NoSuchMethodError catch (_) {
            _sendLoadException(
                channel, "No top-level main() function defined.");
            return;
          } catch (error, stackTrace) {
            _sendError(channel, error, stackTrace, verboseChain);
            return;
          }

          if (main is! Function) {
            _sendLoadException(
                channel, "Top-level main getter is not a function.");
            return;
          } else if (main is! Function()) {
            _sendLoadException(
                channel, "Top-level main() function takes arguments.");
            return;
          }

          var queue = StreamQueue<dynamic>(channel.stream);
          final dynamic message = await queue.next;
          assert(message['type'] == 'initial');

          queue.rest.listen((dynamic message) {
            assert(message["type"] == "suiteChannel");
            SuiteChannelManager.current.connectIn(message['name'] as String,
                channel.virtualChannel(message['id'] as int));
          });

          if ((message['asciiGlyphs'] as bool) ?? false) glyph.ascii = true;
          var metadata = Metadata.deserialize(message['metadata']);
          verboseChain = metadata.verboseTrace;
          var declarer = Declarer(
              metadata: metadata,
              platformVariables:
                  Set.from(message['platformVariables'] as Iterable),
              collectTraces: message['collectTraces'] as bool,
              noRetry: message['noRetry'] as bool);

          // StackTraceFormatter.current.configure(
          //     except: _deserializeSet(message['foldTraceExcept'] as List),
          //     only: _deserializeSet(message['foldTraceOnly'] as List)); fixme

          if (beforeLoad != null) await beforeLoad();

          await declarer.declare(main as Function());

          var suite = Suite(
              declarer.build(), SuitePlatform.deserialize(message['platform']),
              path: message['path'] as String);

          runZoned(() {
            Invoker.guard(
                () => RemoteListener._(suite, printZone)._listen(channel));
          },
              // Make the declarer visible to running tests so that they'll throw
              // useful errors when calling `test()` and `group()` within a test,
              // and so they can add to the declarer's `tearDownAll()` list.
              zoneValues: <Object, Object>{#test.declarer: declarer});
        }, onError: (dynamic error, StackTrace stackTrace) {
          _sendError(channel, error, stackTrace, verboseChain);
        }, zoneSpecification: spec);
      });
    });

    return controller.foreign;
  }

  /// Returns a [Set] from a JSON serialized list of strings.
  static Set<String> _deserializeSet(List list) {
    if (list == null) return null;
    if (list.isEmpty) return null;
    return Set.from(list);
  }

  /// Sends a message over [channel] indicating that the tests failed to load.
  ///
  /// [message] should describe the failure.
  static void _sendLoadException(StreamChannel channel, String message) {
    channel.sink.add({"type": "loadException", "message": message});
  }

  /// Sends a message over [channel] indicating an error from user code.
  static void _sendError(
      StreamChannel channel, dynamic error, StackTrace stackTrace, bool verboseChain) {
    channel.sink.add(<String, dynamic>{
      "type": "error",
      "error": RemoteException.serialize(
          error,
          StackTraceFormatter.current
              .formatStackTrace(stackTrace, verbose: verboseChain))
    });
  }

  RemoteListener._(this._suite, this._printZone);

  /// Send information about [_suite] across [channel] and start listening for
  /// commands to run the tests.
  void _listen(MultiChannel channel) {
    channel.sink.add({
      "type": "success",
      "root": _serializeGroup(channel, _suite.group, [])
    });
  }

  /// Serializes [group] into a JSON-safe map.
  ///
  /// [parents] lists the groups that contain [group].
  Map<String, dynamic> _serializeGroup(
      MultiChannel<Object> channel, Group group, Iterable<Group> parents) {
    parents = parents.toList()..add(group);
    return <String, dynamic>{
      "type": "group",
      "name": group.name,
      "metadata": group.metadata.serialize(),
      "trace": group.trace?.toString(),
      "setUpAll": _serializeTest(channel, group.setUpAll, parents),
      "tearDownAll": _serializeTest(channel, group.tearDownAll, parents),
      "entries": group.entries.map((entry) {
        return entry is Group
            ? _serializeGroup(channel, entry, parents)
            : _serializeTest(channel, entry as Test, parents);
      }).toList()
    };
  }

  /// Serializes [test] into a JSON-safe map.
  ///
  /// [groups] lists the groups that contain [test]. Returns `null` if [test]
  /// is `null`.
  Map _serializeTest(MultiChannel channel, Test test, Iterable<Group> groups) {
    if (test == null) return null;

    var testChannel = channel.virtualChannel();
    testChannel.stream.listen((dynamic message) {
      assert(message['command'] == 'run');
      _runLiveTest(test.load(_suite, groups: groups),
          channel.virtualChannel(message['channel'] as int));
    });

    return <String, dynamic>{
      "type": "test",
      "name": test.name,
      "metadata": test.metadata.serialize(),
      "trace": test.trace?.toString(),
      "channel": testChannel.id
    };
  }

  /// Runs [liveTest] and sends the results across [channel].
  void _runLiveTest(LiveTest liveTest, MultiChannel channel) {
    channel.stream.listen((dynamic message) {
      assert(message['command'] == 'close');
      liveTest.close();
    });

    liveTest.onStateChange.listen((state) {
      channel.sink.add({
        "type": "state-change",
        "status": state.status.name,
        "result": state.result.name
      });
    });

    liveTest.onError.listen((asyncError) {
      channel.sink.add(<String, Object>{
        "type": "error",
        "error": RemoteException.serialize(
            asyncError.error,
            StackTraceFormatter.current.formatStackTrace(asyncError.stackTrace,
                verbose: liveTest.test.metadata.verboseTrace))
      });
    });

    liveTest.onMessage.listen((message) {
      if (_printZone != null) _printZone.print(message.text);
      channel.sink.add({
        "type": "message",
        "message-type": message.type.name,
        "text": message.text
      });
    });

    runZoned(() {
      liveTest.run().then((void _) => channel.sink.add(<String, String>{"type": "complete"}));
    }, zoneValues: <Object, Object>{#test.runner.test_channel: channel});
  }
}

/// The key used to look up [SuiteChannelManager.current] in a zone.
final Object _currentKey = Object();

/// A class that connects incoming and outgoing channels with the same names.
class SuiteChannelManager {
  /// Connections from the test runner that have yet to connect to corresponding
  /// calls to [suiteChannel] within this worker.
  final _incomingConnections = <String, StreamChannel>{};

  /// Connections from calls to [suiteChannel] that have yet to connect to
  /// corresponding connections from the test runner.
  final _outgoingConnections = <String, StreamChannelCompleter>{};

  /// The channel names that have already been used.
  final _names = Set<String>();

  /// Returns the current manager, or `null` if this isn't called within a call
  /// to [asCurrent].
  static SuiteChannelManager get current =>
      Zone.current[_currentKey];

  /// Runs [body] with [this] as [SuiteChannelManager.current].
  ///
  /// This is zone-scoped, so [this] will be the current configuration in any
  /// asynchronous callbacks transitively created by [body].
  T asCurrent<T>(T body()) => runZoned(body, zoneValues: <Object, Object>{_currentKey: this});

  /// Creates a connection to the test runnner's channel with the given [name].
  StreamChannel connectOut(String name) {
    if (_incomingConnections.containsKey(name)) {
      return _incomingConnections[name];
    } else if (_names.contains(name)) {
      throw StateError('Duplicate suiteChannel() connection "$name".');
    } else {
      _names.add(name);
      var completer = StreamChannelCompleter<Object>();
      _outgoingConnections[name] = completer;
      return completer.channel;
    }
  }

  /// Connects [channel] to this worker's channel with the given [name].
  void connectIn(String name, StreamChannel channel) {
    if (_outgoingConnections.containsKey(name)) {
      _outgoingConnections.remove(name).setChannel(channel);
    } else if (_incomingConnections.containsKey(name)) {
      throw StateError('Duplicate RunnerSuite.channel() connection "$name".');
    } else {
      _incomingConnections[name] = channel;
    }
  }
}