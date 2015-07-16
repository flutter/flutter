// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library lazy_trace;

import 'frame.dart';
import 'trace.dart';

/// A thunk for lazily constructing a [Trace].
typedef Trace TraceThunk();

/// A wrapper around a [TraceThunk]. This works around issue 9579 by avoiding
/// the conversion of native [StackTrace]s to strings until it's absolutely
/// necessary.
class LazyTrace implements Trace {
  final TraceThunk _thunk;
  Trace _inner;

  LazyTrace(this._thunk);

  Trace get _trace {
    if (_inner == null) _inner = _thunk();
    return _inner;
  }

  List<Frame> get frames => _trace.frames;
  StackTrace get vmTrace => _trace.vmTrace;
  Trace get terse => new LazyTrace(() => _trace.terse);
  Trace foldFrames(bool predicate(frame)) =>
    new LazyTrace(() => _trace.foldFrames(predicate));
  String toString() => _trace.toString();

  // Work around issue 14075.
  set frames(_) => throw new UnimplementedError();
}
