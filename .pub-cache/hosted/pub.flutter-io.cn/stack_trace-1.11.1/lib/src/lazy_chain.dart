// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'chain.dart';
import 'frame.dart';
import 'lazy_trace.dart';
import 'trace.dart';

/// A thunk for lazily constructing a [Chain].
typedef ChainThunk = Chain Function();

/// A wrapper around a [ChainThunk]. This works around issue 9579 by avoiding
/// the conversion of native [StackTrace]s to strings until it's absolutely
/// necessary.
class LazyChain implements Chain {
  final ChainThunk _thunk;
  late final Chain _chain = _thunk();

  LazyChain(this._thunk);

  @override
  List<Trace> get traces => _chain.traces;
  @override
  Chain get terse => _chain.terse;
  @override
  Chain foldFrames(bool Function(Frame) predicate, {bool terse = false}) =>
      LazyChain(() => _chain.foldFrames(predicate, terse: terse));
  @override
  Trace toTrace() => LazyTrace(_chain.toTrace);
  @override
  String toString() => _chain.toString();
}
