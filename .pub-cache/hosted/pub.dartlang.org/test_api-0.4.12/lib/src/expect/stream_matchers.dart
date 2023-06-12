// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async/async.dart';
import 'package:matcher/matcher.dart';

import 'async_matcher.dart';
import 'stream_matcher.dart';
import 'throws_matcher.dart';
import 'util/pretty_print.dart';

/// Returns a [StreamMatcher] that asserts that the stream emits a "done" event.
final emitsDone = StreamMatcher(
    (queue) async => (await queue.hasNext) ? '' : null, 'be done');

/// Returns a [StreamMatcher] for [matcher].
///
/// If [matcher] is already a [StreamMatcher], it's returned as-is. If it's any
/// other [Matcher], this matches a single event that matches that matcher. If
/// it's any other Object, this matches a single event that's equal to that
/// object.
///
/// This functions like [wrapMatcher] for [StreamMatcher]s: it can convert any
/// matcher-like value into a proper [StreamMatcher].
StreamMatcher emits(matcher) {
  if (matcher is StreamMatcher) return matcher;
  var wrapped = wrapMatcher(matcher);

  var matcherDescription = wrapped.describe(StringDescription());

  return StreamMatcher((queue) async {
    if (!await queue.hasNext) return '';

    var matchState = {};
    var actual = await queue.next;
    if (wrapped.matches(actual, matchState)) return null;

    var mismatchDescription = StringDescription();
    wrapped.describeMismatch(actual, mismatchDescription, matchState, false);

    if (mismatchDescription.length == 0) return '';
    return 'emitted an event that $mismatchDescription';
  },
      // TODO(nweiz): add "should" once matcher#42 is fixed.
      'emit an event that $matcherDescription');
}

/// Returns a [StreamMatcher] that matches a single error event that matches
/// [matcher].
StreamMatcher emitsError(matcher) {
  var wrapped = wrapMatcher(matcher);
  var matcherDescription = wrapped.describe(StringDescription());
  var throwsMatcher = throwsA(wrapped) as AsyncMatcher;

  return StreamMatcher(
      (queue) => throwsMatcher.matchAsync(queue.next) as Future<String?>,
      // TODO(nweiz): add "should" once matcher#42 is fixed.
      'emit an error that $matcherDescription');
}

/// Returns a [StreamMatcher] that allows (but doesn't require) [matcher] to
/// match the stream.
///
/// This matcher always succeeds; if [matcher] doesn't match, this just consumes
/// no events.
StreamMatcher mayEmit(matcher) {
  var streamMatcher = emits(matcher);
  return StreamMatcher((queue) async {
    await queue.withTransaction(
        (copy) async => (await streamMatcher.matchQueue(copy)) == null);
    return null;
  }, 'maybe ${streamMatcher.description}');
}

/// Returns a [StreamMatcher] that matches the stream if at least one of
/// [matchers] matches.
///
/// If multiple matchers match the stream, this chooses the matcher that
/// consumes as many events as possible.
///
/// If any matchers match the stream, no errors from other matchers are thrown.
/// If no matchers match and multiple matchers threw errors, the first error is
/// re-thrown.
StreamMatcher emitsAnyOf(Iterable matchers) {
  var streamMatchers = matchers.map(emits).toList();
  if (streamMatchers.isEmpty) {
    throw ArgumentError('matcher may not be empty');
  }

  if (streamMatchers.length == 1) return streamMatchers.first;
  var description = 'do one of the following:\n'
      '${bullet(streamMatchers.map((matcher) => matcher.description))}';

  return StreamMatcher((queue) async {
    var transaction = queue.startTransaction();

    // Allocate the failures list ahead of time so that its order matches the
    // order of [matchers], and thus the order the matchers will be listed in
    // the description.
    var failures = List<String?>.filled(matchers.length, null);

    // The first error thrown. If no matchers match and this exists, we rethrow
    // it.
    Object? firstError;
    StackTrace? firstStackTrace;

    var futures = <Future>[];
    StreamQueue? consumedMost;
    for (var i = 0; i < matchers.length; i++) {
      futures.add(() async {
        var copy = transaction.newQueue();

        String? result;
        try {
          result = await streamMatchers[i].matchQueue(copy);
        } catch (error, stackTrace) {
          if (firstError == null) {
            firstError = error;
            firstStackTrace = stackTrace;
          }
          return;
        }

        if (result != null) {
          failures[i] = result;
        } else if (consumedMost == null ||
            consumedMost!.eventsDispatched < copy.eventsDispatched) {
          consumedMost = copy;
        }
      }());
    }

    await Future.wait(futures);

    if (consumedMost == null) {
      transaction.reject();
      if (firstError != null) {
        await Future.error(firstError!, firstStackTrace);
      }

      var failureMessages = <String>[];
      for (var i = 0; i < matchers.length; i++) {
        var message = 'failed to ${streamMatchers[i].description}';
        if ((failures[i])!.isNotEmpty) {
          message += message.contains('\n') ? '\n' : ' ';
          message += 'because it ${failures[i]}';
        }

        failureMessages.add(message);
      }

      return 'failed all options:\n${bullet(failureMessages)}';
    } else {
      transaction.commit(consumedMost!);
      return null;
    }
  }, description);
}

/// Returns a [StreamMatcher] that matches the stream if each matcher in
/// [matchers] matches, one after another.
///
/// If any matcher fails to match, this fails and consumes no events.
StreamMatcher emitsInOrder(Iterable matchers) {
  var streamMatchers = matchers.map(emits).toList();
  if (streamMatchers.length == 1) return streamMatchers.first;

  var description = 'do the following in order:\n'
      '${bullet(streamMatchers.map((matcher) => matcher.description))}';

  return StreamMatcher((queue) async {
    for (var i = 0; i < streamMatchers.length; i++) {
      var matcher = streamMatchers[i];
      var result = await matcher.matchQueue(queue);
      if (result == null) continue;

      var newResult = "didn't ${matcher.description}";
      if (result.isNotEmpty) {
        newResult += newResult.contains('\n') ? '\n' : ' ';
        newResult += 'because it $result';
      }
      return newResult;
    }
    return null;
  }, description);
}

/// Returns a [StreamMatcher] that matches any number of events followed by
/// events that match [matcher].
///
/// This consumes all events matched by [matcher], as well as all events before.
/// If the stream emits a done event without matching [matcher], this fails and
/// consumes no events.
StreamMatcher emitsThrough(matcher) {
  var streamMatcher = emits(matcher);
  return StreamMatcher((queue) async {
    var failures = <String>[];

    Future<bool> tryHere() => queue.withTransaction((copy) async {
          var result = await streamMatcher.matchQueue(copy);
          if (result == null) return true;
          failures.add(result);
          return false;
        });

    while (await queue.hasNext) {
      if (await tryHere()) return null;
      await queue.next;
    }

    // Try after the queue is done in case the matcher can match an empty
    // stream.
    if (await tryHere()) return null;

    var result = 'never did ${streamMatcher.description}';

    var failureMessages =
        bullet(failures.where((failure) => failure.isNotEmpty));
    if (failureMessages.isNotEmpty) {
      result += result.contains('\n') ? '\n' : ' ';
      result += 'because it:\n$failureMessages';
    }

    return result;
  }, 'eventually ${streamMatcher.description}');
}

/// Returns a [StreamMatcher] that matches any number of events that match
/// [matcher].
///
/// This consumes events until [matcher] no longer matches. It always succeeds;
/// if [matcher] doesn't match, this just consumes no events. It never rethrows
/// errors.
StreamMatcher mayEmitMultiple(matcher) {
  var streamMatcher = emits(matcher);

  var description = streamMatcher.description;
  description += description.contains('\n') ? '\n' : ' ';
  description += 'zero or more times';

  return StreamMatcher((queue) async {
    while (await _tryMatch(queue, streamMatcher)) {
      // Do nothing; the matcher presumably already consumed events.
    }
    return null;
  }, description);
}

/// Returns a [StreamMatcher] that matches a stream that never matches
/// [matcher].
///
/// This doesn't complete until the stream emits a done event. It never consumes
/// any events. It never re-throws errors.
StreamMatcher neverEmits(matcher) {
  var streamMatcher = emits(matcher);
  return StreamMatcher((queue) async {
    var events = 0;
    var matched = false;
    await queue.withTransaction((copy) async {
      while (await copy.hasNext) {
        matched = await _tryMatch(copy, streamMatcher);
        if (matched) return false;

        events++;

        try {
          await copy.next;
        } catch (_) {
          // Ignore errors events.
        }
      }

      matched = await _tryMatch(copy, streamMatcher);
      return false;
    });

    if (!matched) return null;
    return "after $events ${pluralize('event', events)} did "
        '${streamMatcher.description}';
  }, 'never ${streamMatcher.description}');
}

/// Returns whether [matcher] matches [queue] at its current position.
///
/// This treats errors as failures to match.
Future<bool> _tryMatch(StreamQueue queue, StreamMatcher matcher) {
  return queue.withTransaction((copy) async {
    try {
      return (await matcher.matchQueue(copy)) == null;
    } catch (_) {
      return false;
    }
  });
}

/// Returns a [StreamMatcher] that matches the stream if each matcher in
/// [matchers] matches, in any order.
///
/// If any matcher fails to match, this fails and consumes no events. If the
/// matchers match in multiple different possible orders, this chooses the order
/// that consumes as many events as possible.
///
/// If any sequence of matchers matches the stream, no errors from other
/// sequences are thrown. If no sequences match and multiple sequences throw
/// errors, the first error is re-thrown.
///
/// Note that checking every ordering of [matchers] is O(n!) in the worst case,
/// so this should only be called when there are very few [matchers].
StreamMatcher emitsInAnyOrder(Iterable matchers) {
  var streamMatchers = matchers.map(emits).toSet();
  if (streamMatchers.length == 1) return streamMatchers.first;
  var description = 'do the following in any order:\n'
      '${bullet(streamMatchers.map((matcher) => matcher.description))}';

  return StreamMatcher(
      (queue) async => await _tryInAnyOrder(queue, streamMatchers) ? null : '',
      description);
}

/// Returns whether [queue] matches [matchers] in any order.
Future<bool> _tryInAnyOrder(
    StreamQueue queue, Set<StreamMatcher> matchers) async {
  if (matchers.length == 1) {
    return await matchers.first.matchQueue(queue) == null;
  }

  var transaction = queue.startTransaction();
  StreamQueue? consumedMost;

  // The first error thrown. If no matchers match and this exists, we rethrow
  // it.
  Object? firstError;
  StackTrace? firstStackTrace;

  await Future.wait(matchers.map((matcher) async {
    var copy = transaction.newQueue();
    try {
      if (await matcher.matchQueue(copy) != null) return;
    } catch (error, stackTrace) {
      if (firstError == null) {
        firstError = error;
        firstStackTrace = stackTrace;
      }
      return;
    }

    var rest = Set<StreamMatcher>.from(matchers);
    rest.remove(matcher);

    try {
      if (!await _tryInAnyOrder(copy, rest)) return;
    } catch (error, stackTrace) {
      if (firstError == null) {
        firstError = error;
        firstStackTrace = stackTrace;
      }
      return;
    }

    if (consumedMost == null ||
        consumedMost!.eventsDispatched < copy.eventsDispatched) {
      consumedMost = copy;
    }
  }));

  if (consumedMost == null) {
    transaction.reject();
    if (firstError != null) await Future.error(firstError!, firstStackTrace);
    return false;
  } else {
    transaction.commit(consumedMost!);
    return true;
  }
}
