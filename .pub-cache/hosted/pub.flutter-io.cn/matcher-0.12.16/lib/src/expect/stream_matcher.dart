// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async/async.dart';
import 'package:test_api/hooks.dart';

import '../interfaces.dart';
import 'async_matcher.dart';
import 'expect.dart';
import 'util/pretty_print.dart';

/// A matcher that matches events from [Stream]s or [StreamQueue]s.
///
/// Stream matchers are designed to make it straightforward to create complex
/// expectations for streams, and to interleave expectations with the rest of a
/// test. They can be used on a [Stream] to match all events it emits:
///
/// ```dart
/// expect(stream, emitsInOrder([
///   // Values match individual events.
///   "Ready.",
///
///   // Matchers also run against individual events.
///   startsWith("Loading took"),
///
///   // Stream matchers can be nested. This asserts that one of two events are
///   // emitted after the "Loading took" line.
///   emitsAnyOf(["Succeeded!", "Failed!"]),
///
///   // By default, more events are allowed after the matcher finishes
///   // matching. This asserts instead that the stream emits a done event and
///   // nothing else.
///   emitsDone
/// ]));
/// ```
///
/// It can also match a [StreamQueue], in which case it consumes the matched
/// events. The call to [expect] returns a [Future] that completes when the
/// matcher is done matching. You can `await` this to consume different events
/// at different times:
///
/// ```dart
/// var stdout = StreamQueue(stdoutLineStream);
///
/// // Ignore lines from the process until it's about to emit the URL.
/// await expectLater(stdout, emitsThrough('WebSocket URL:'));
///
/// // Parse the next line as a URL.
/// var url = Uri.parse(await stdout.next);
/// expect(url.host, equals('localhost'));
///
/// // You can match against the same StreamQueue multiple times.
/// await expectLater(stdout, emits('Waiting for connection...'));
/// ```
///
/// Users can call [StreamMatcher] to create custom matchers.
abstract class StreamMatcher extends Matcher {
  /// The description of this matcher.
  ///
  /// This is in the subjunctive mood, which means it can be used after the word
  /// "should". For example, it might be "emit the right events".
  String get description;

  /// Creates a new [StreamMatcher] described by [description] that matches
  /// events with [matchQueue].
  ///
  /// The [matchQueue] callback is used to implement [StreamMatcher.matchQueue],
  /// and should follow all the guarantees of that method. In particular:
  ///
  /// * If it matches successfully, it should return `null` and possibly consume
  ///   events.
  /// * If it fails to match, consume no events and return a description of the
  ///   failure.
  /// * The description should be in past tense.
  /// * The description should be grammatically valid when used after "the
  ///   stream"—"emitted the wrong events", for example.
  ///
  /// The [matchQueue] callback may return the empty string to indicate a
  /// failure if it has no information to add beyond the description of the
  /// failure and the events actually emitted by the stream.
  ///
  /// The [description] should be in the subjunctive mood. This means that it
  /// should be grammatically valid when used after the word "should". For
  /// example, it might be "emit the right events".
  factory StreamMatcher(Future<String?> Function(StreamQueue) matchQueue,
      String description) = _StreamMatcher;

  /// Tries to match events emitted by [queue].
  ///
  /// If this matches successfully, it consumes the matching events from [queue]
  /// and returns `null`.
  ///
  /// If this fails to match, it doesn't consume any events and returns a
  /// description of the failure. This description is in the past tense, and
  /// could grammatically be used after "the stream". For example, it might
  /// return "emitted the wrong events".
  ///
  /// The description string may also be empty, which indicates that the
  /// matcher's description and the events actually emitted by the stream are
  /// enough to understand the failure.
  ///
  /// If the queue emits an error, that error is re-thrown unless otherwise
  /// indicated by the matcher.
  Future<String?> matchQueue(StreamQueue queue);
}

/// A concrete implementation of [StreamMatcher].
///
/// This is separate from the original type to hide the private [AsyncMatcher]
/// interface.
class _StreamMatcher extends AsyncMatcher implements StreamMatcher {
  @override
  final String description;

  /// The callback used to implement [matchQueue].
  final Future<String?> Function(StreamQueue) _matchQueue;

  _StreamMatcher(this._matchQueue, this.description);

  @override
  Future<String?> matchQueue(StreamQueue queue) => _matchQueue(queue);

  @override
  dynamic /*FutureOr<String>*/ matchAsync(Object? item) {
    StreamQueue queue;
    var shouldCancelQueue = false;
    if (item is StreamQueue) {
      queue = item;
    } else if (item is Stream) {
      queue = StreamQueue(item);
      shouldCancelQueue = true;
    } else {
      return 'was not a Stream or a StreamQueue';
    }

    // Avoid async/await in the outer method so that we synchronously error out
    // for an invalid argument type.
    var transaction = queue.startTransaction();
    var copy = transaction.newQueue();
    return matchQueue(copy).then((result) async {
      // Accept the transaction if the result is null, indicating that the match
      // succeeded.
      if (result == null) {
        transaction.commit(copy);
        return null;
      }

      // Get a list of events emitted by the stream so we can emit them as part
      // of the error message.
      var replay = transaction.newQueue();
      var events = <Result?>[];
      var subscription = Result.captureStreamTransformer
          .bind(replay.rest.cast())
          .listen(events.add, onDone: () => events.add(null));

      // Wait on a timer tick so all buffered events are emitted.
      await Future.delayed(Duration.zero);
      _unawaited(subscription.cancel());

      var eventsString = events.map((event) {
        if (event == null) {
          return 'x Stream closed.';
        } else if (event.isValue) {
          return addBullet(event.asValue!.value.toString());
        } else {
          var error = event.asError!;
          var chain = TestHandle.current.formatStackTrace(error.stackTrace);
          var text = '${error.error}\n$chain';
          return indent(text, first: '! ');
        }
      }).join('\n');
      if (eventsString.isEmpty) eventsString = 'no events';

      transaction.reject();

      var buffer = StringBuffer();
      buffer.writeln(indent(eventsString, first: 'emitted '));
      if (result.isNotEmpty) buffer.writeln(indent(result, first: '  which '));
      return buffer.toString().trimRight();
    }, onError: (Object error) {
      transaction.reject();
      // ignore: only_throw_errors
      throw error;
    }).then((result) {
      if (shouldCancelQueue) queue.cancel();
      return result;
    });
  }

  @override
  Description describe(Description description) =>
      description.add('should ').add(this.description);
}

void _unawaited(Future<void> f) {}
