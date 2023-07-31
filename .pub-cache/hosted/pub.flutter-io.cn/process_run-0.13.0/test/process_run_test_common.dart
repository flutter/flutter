import 'dart:async';
import 'dart:io';

import 'package:async/async.dart';
import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:test/test.dart';

String get projectTop => '.';

String get testDir => join('.dart_tool', 'process_run', 'test');

String get echoScriptPath => join(projectTop, 'example', 'echo.dart');
String get streamerScriptPath => join(projectTop, 'example', 'streamer.dart');

// does not exists
String get dummyExecutable => join(dirname(testDir), 'example', 'dummy');

final String dummyCommand = '_tekartik_process_run_dummy';

Stream<List<int>> testStdin = stdin.asBroadcastStream();

/// A [StreamSink] that collects all events added to it as results.
///
/// This is used for testing code that interacts with sinks.
class TestSink<T> implements StreamSink<T> {
  /// The results corresponding to events that have been added to the sink.
  final results = <Result<T>>[];

  /// Whether [close] has been called.
  bool get isClosed => _isClosed;
  var _isClosed = false;

  @override
  Future get done => _doneCompleter.future;
  final _doneCompleter = Completer<dynamic>();

  final Func0 _onDone;

  /// Creates a new sink.
  ///
  /// If [onDone] is passed, it's called when the user calls [close]. Its result
  /// is piped to the [done] future.
  TestSink({Object? Function()? onDone}) : _onDone = onDone ?? (() {});

  @override
  void add(T event) {
    results.add(Result<T>.value(event));
  }

  @override
  void addError(error, [StackTrace? stackTrace]) {
    results.add(Result<T>.error(error, stackTrace));
  }

  @override
  Future addStream(Stream<T> stream) {
    var completer = Completer<void>.sync();
    stream.listen(add, onError: addError, onDone: completer.complete);
    return completer.future;
  }

  @override
  Future close() {
    _isClosed = true;
    _doneCompleter.complete(Future.microtask(_onDone));
    return done;
  }
}

final basicScriptExecutableExtension = Platform.isWindows ? '.bat' : '';

// Create a basic echo executable
Future createEchoExecutable(String path) async {
  try {
    await Directory(dirname(path)).create(recursive: true);
  } catch (_) {}
  var fullPath = '$path$basicScriptExecutableExtension';
  await File(fullPath)
      .writeAsString(Platform.isWindows ? '@echo Hello' : 'echo Hello');
  if (Platform.isLinux || Platform.isMacOS) {
    await Shell().run('chmod +x ${shellArgument(fullPath)}');
  }
}
