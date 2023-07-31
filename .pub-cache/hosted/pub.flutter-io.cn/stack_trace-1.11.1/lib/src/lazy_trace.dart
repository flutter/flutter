// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'frame.dart';
import 'trace.dart';

/// A thunk for lazily constructing a [Trace].
typedef TraceThunk = Trace Function();

/// A wrapper around a [TraceThunk]. This works around issue 9579 by avoiding
/// the conversion of native [StackTrace]s to strings until it's absolutely
/// necessary.
class LazyTrace implements Trace {
  final TraceThunk _thunk;
  late final Trace _trace = _thunk();

  LazyTrace(this._thunk);

  @override
  List<Frame> get frames => _trace.frames;
  @override
  StackTrace get original => _trace.original;
  @override
  StackTrace get vmTrace => _trace.vmTrace;
  @override
  Trace get terse => LazyTrace(() => _trace.terse);
  @override
  Trace foldFrames(bool Function(Frame) predicate, {bool terse = false}) =>
      LazyTrace(() => _trace.foldFrames(predicate, terse: terse));
  @override
  String toString() => _trace.toString();
}
