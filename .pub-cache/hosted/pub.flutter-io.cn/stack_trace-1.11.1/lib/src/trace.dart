// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'chain.dart';
import 'frame.dart';
import 'lazy_trace.dart';
import 'unparsed_frame.dart';
import 'utils.dart';
import 'vm_trace.dart';

final _terseRegExp = RegExp(r'(-patch)?([/\\].*)?$');

/// A RegExp to match V8's stack traces.
///
/// V8's traces start with a line that's either just "Error" or else is a
/// description of the exception that occurred. That description can be multiple
/// lines, so we just look for any line other than the first that begins with
/// three or four spaces and "at".
final _v8Trace = RegExp(r'\n    ?at ');

/// A RegExp to match indidual lines of V8's stack traces.
///
/// This is intended to filter out the leading exception details of the trace
/// though it is possible for the message to match this as well.
final _v8TraceLine = RegExp(r'    ?at ');

/// A RegExp to match Firefox's eval and Function stack traces.
///
/// https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Error/stack
///
/// These stack traces looks like:
///     anonymous/<@https://example.com/stuff.js line 693 > Function:3:40
///     anonymous/<@https://example.com/stuff.js line 693 > eval:3:40
final _firefoxEvalTrace = RegExp(r'@\S+ line \d+ >.* (Function|eval):\d+:\d+');

/// A RegExp to match Firefox and Safari's stack traces.
///
/// Firefox and Safari have very similar stack trace formats, so we use the same
/// logic for parsing them.
///
/// Firefox's trace frames start with the name of the function in which the
/// error occurred, possibly including its parameters inside `()`. For example,
/// `.VW.call$0("arg")@https://example.com/stuff.dart.js:560`.
///
/// Safari traces occasionally don't include the initial method name followed by
/// "@", and they always have both the line and column number (or just a
/// trailing colon if no column number is available). They can also contain
/// empty lines or lines consisting only of `[native code]`.
final _firefoxSafariTrace = RegExp(
    r'^'
    r'(' // Member description. Not present in some Safari frames.
    r'([.0-9A-Za-z_$/<]|\(.*\))*' // Member name and arguments.
    r'@'
    r')?'
    r'[^\s]*' // Frame URL.
    r':\d*' // Line or column number. Some older frames only have a line number.
    r'$',
    multiLine: true);

/// A RegExp to match this package's stack traces.
final _friendlyTrace =
    RegExp(r'^[^\s<][^\s]*( \d+(:\d+)?)?[ \t]+[^\s]+$', multiLine: true);

/// A stack trace, comprised of a list of stack frames.
class Trace implements StackTrace {
  /// The stack frames that comprise this stack trace.
  final List<Frame> frames;

  /// The original stack trace from which this trace was parsed.
  final StackTrace original;

  /// Returns a human-readable representation of [stackTrace]. If [terse] is
  /// set, this folds together multiple stack frames from the Dart core
  /// libraries, so that only the core library method directly called from user
  /// code is visible (see [Trace.terse]).
  static String format(StackTrace stackTrace, {bool terse = true}) {
    var trace = Trace.from(stackTrace);
    if (terse) trace = trace.terse;
    return trace.toString();
  }

  /// Returns the current stack trace.
  ///
  /// By default, the first frame of this trace will be the line where
  /// [Trace.current] is called. If [level] is passed, the trace will start that
  /// many frames up instead.
  factory Trace.current([int level = 0]) {
    if (level < 0) {
      throw ArgumentError('Argument [level] must be greater than or equal '
          'to 0.');
    }

    var trace = Trace.from(StackTrace.current);
    return LazyTrace(
      () =>
          // JS includes a frame for the call to StackTrace.current, but the VM
          // doesn't, so we skip an extra frame in a JS context.
          Trace(trace.frames.skip(level + (inJS ? 2 : 1)),
              original: trace.original.toString()),
    );
  }

  /// Returns a new stack trace containing the same data as [trace].
  ///
  /// If [trace] is a native [StackTrace], its data will be parsed out; if it's
  /// a [Trace], it will be returned as-is.
  factory Trace.from(StackTrace trace) {
    if (trace is Trace) return trace;
    if (trace is Chain) return trace.toTrace();
    return LazyTrace(() => Trace.parse(trace.toString()));
  }

  /// Parses a string representation of a stack trace.
  ///
  /// [trace] should be formatted in the same way as a Dart VM or browser stack
  /// trace. If it's formatted as a stack chain, this will return the equivalent
  /// of [Chain.toTrace].
  factory Trace.parse(String trace) {
    try {
      if (trace.isEmpty) return Trace(<Frame>[]);
      if (trace.contains(_v8Trace)) return Trace.parseV8(trace);
      if (trace.contains('\tat ')) return Trace.parseJSCore(trace);
      if (trace.contains(_firefoxSafariTrace) ||
          trace.contains(_firefoxEvalTrace)) {
        return Trace.parseFirefox(trace);
      }
      if (trace.contains(chainGap)) return Chain.parse(trace).toTrace();
      if (trace.contains(_friendlyTrace)) {
        return Trace.parseFriendly(trace);
      }

      // Default to parsing the stack trace as a VM trace. This is also hit on
      // IE and Safari, where the stack trace is just an empty string (issue
      // 11257).
      return Trace.parseVM(trace);
    } on FormatException catch (error) {
      throw FormatException('${error.message}\nStack trace:\n$trace');
    }
  }

  /// Parses a string representation of a Dart VM stack trace.
  Trace.parseVM(String trace) : this(_parseVM(trace), original: trace);

  static List<Frame> _parseVM(String trace) {
    // Ignore [vmChainGap]. This matches the behavior of
    // `Chain.parse().toTrace()`.
    var lines = trace
        .trim()
        .replaceAll(vmChainGap, '')
        .split('\n')
        .where((line) => line.isNotEmpty);

    if (lines.isEmpty) {
      return [];
    }

    var frames = lines.take(lines.length - 1).map(Frame.parseVM).toList();

    // TODO(nweiz): Remove this when issue 23614 is fixed.
    if (!lines.last.endsWith('.da')) {
      frames.add(Frame.parseVM(lines.last));
    }

    return frames;
  }

  /// Parses a string representation of a Chrome/V8 stack trace.
  Trace.parseV8(String trace)
      : this(
            trace
                .split('\n')
                .skip(1)
                // It's possible that an Exception's description contains a line
                // that looks like a V8 trace line, which will screw this up.
                // Unfortunately, that's impossible to detect.
                .skipWhile((line) => !line.startsWith(_v8TraceLine))
                .map(Frame.parseV8),
            original: trace);

  /// Parses a string representation of a JavaScriptCore stack trace.
  Trace.parseJSCore(String trace)
      : this(
            trace
                .split('\n')
                .where((line) => line != '\tat ')
                .map(Frame.parseV8),
            original: trace);

  /// Parses a string representation of an Internet Explorer stack trace.
  ///
  /// IE10+ traces look just like V8 traces. Prior to IE10, stack traces can't
  /// be retrieved.
  Trace.parseIE(String trace) : this.parseV8(trace);

  /// Parses a string representation of a Firefox stack trace.
  Trace.parseFirefox(String trace)
      : this(
            trace
                .trim()
                .split('\n')
                .where((line) => line.isNotEmpty && line != '[native code]')
                .map(Frame.parseFirefox),
            original: trace);

  /// Parses a string representation of a Safari stack trace.
  Trace.parseSafari(String trace) : this.parseFirefox(trace);

  /// Parses a string representation of a Safari 6.1+ stack trace.
  @Deprecated('Use Trace.parseSafari instead.')
  Trace.parseSafari6_1(String trace) : this.parseSafari(trace);

  /// Parses a string representation of a Safari 6.0 stack trace.
  @Deprecated('Use Trace.parseSafari instead.')
  Trace.parseSafari6_0(String trace)
      : this(
            trace
                .trim()
                .split('\n')
                .where((line) => line != '[native code]')
                .map(Frame.parseFirefox),
            original: trace);

  /// Parses this package's string representation of a stack trace.
  ///
  /// This also parses string representations of [Chain]s. They parse to the
  /// same trace that [Chain.toTrace] would return.
  Trace.parseFriendly(String trace)
      : this(
            trace.isEmpty
                ? []
                : trace
                    .trim()
                    .split('\n')
                    // Filter out asynchronous gaps from [Chain]s.
                    .where((line) => !line.startsWith('====='))
                    .map(Frame.parseFriendly),
            original: trace);

  /// Returns a new [Trace] comprised of [frames].
  Trace(Iterable<Frame> frames, {String? original})
      : frames = List<Frame>.unmodifiable(frames),
        original = StackTrace.fromString(original ?? '');

  /// Returns a VM-style [StackTrace] object.
  ///
  /// The return value's [toString] method will always return a string
  /// representation in the Dart VM's stack trace format, regardless of what
  /// platform is being used.
  StackTrace get vmTrace => VMTrace(frames);

  /// Returns a terser version of this trace.
  ///
  /// This is accomplished by folding together multiple stack frames from the
  /// core library or from this package, as in [foldFrames]. Remaining core
  /// library frames have their libraries, "-patch" suffixes, and line numbers
  /// removed. If the outermost frame of the stack trace is a core library
  /// frame, it's removed entirely.
  ///
  /// This won't do anything with a raw JavaScript trace, since there's no way
  /// to determine which frames come from which Dart libraries. However, the
  /// [`source_map_stack_trace`][https://pub.dev/packages/source_map_stack_trace]
  /// package can be used to convert JavaScript traces into Dart-style traces.
  ///
  /// For custom folding, see [foldFrames].
  Trace get terse => foldFrames((_) => false, terse: true);

  /// Returns a new [Trace] based on `this` where multiple stack frames matching
  /// [predicate] are folded together.
  ///
  /// This means that whenever there are multiple frames in a row that match
  /// [predicate], only the last one is kept. This is useful for limiting the
  /// amount of library code that appears in a stack trace by only showing user
  /// code and code that's called by user code.
  ///
  /// If [terse] is true, this will also fold together frames from the core
  /// library or from this package, simplify core library frames, and
  /// potentially remove the outermost frame as in [Trace.terse].
  Trace foldFrames(bool Function(Frame) predicate, {bool terse = false}) {
    if (terse) {
      var oldPredicate = predicate;
      predicate = (frame) {
        if (oldPredicate(frame)) return true;

        if (frame.isCore) return true;
        if (frame.package == 'stack_trace') return true;

        // Ignore async stack frames without any line or column information.
        // These come from the VM's async/await implementation and represent
        // internal frames. They only ever show up in stack chains and are
        // always surrounded by other traces that are actually useful, so we can
        // just get rid of them.
        // TODO(nweiz): Get rid of this logic some time after issue 22009 is
        // fixed.
        if (!frame.member!.contains('<async>')) return false;
        return frame.line == null;
      };
    }

    var newFrames = <Frame>[];
    for (var frame in frames.reversed) {
      if (frame is UnparsedFrame || !predicate(frame)) {
        newFrames.add(frame);
      } else if (newFrames.isEmpty || !predicate(newFrames.last)) {
        newFrames.add(Frame(frame.uri, frame.line, frame.column, frame.member));
      }
    }

    if (terse) {
      newFrames = newFrames.map((frame) {
        if (frame is UnparsedFrame || !predicate(frame)) return frame;
        var library = frame.library.replaceAll(_terseRegExp, '');
        return Frame(Uri.parse(library), null, null, frame.member);
      }).toList();

      if (newFrames.length > 1 && predicate(newFrames.first)) {
        newFrames.removeAt(0);
      }
    }

    return Trace(newFrames.reversed, original: original.toString());
  }

  @override
  String toString() {
    // Figure out the longest path so we know how much to pad.
    var longest =
        frames.map((frame) => frame.location.length).fold(0, math.max);

    // Print out the stack trace nicely formatted.
    return frames.map((frame) {
      if (frame is UnparsedFrame) return '$frame\n';
      return '${frame.location.padRight(longest)}  ${frame.member}\n';
    }).join();
  }
}
