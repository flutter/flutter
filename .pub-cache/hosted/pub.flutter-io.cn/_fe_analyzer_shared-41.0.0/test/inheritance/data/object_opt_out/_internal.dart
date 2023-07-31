// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

/*library: nnbd=false*/

import 'dart:core' as core;
import 'dart:core' show Iterable;

/*cfe.class: Symbol:Object,Symbol,Symbol*/
/*cfe:builder.class: Symbol:Object,Symbol*/
class Symbol extends core.Symbol {}

/*cfe|cfe:builder.class: EfficientLengthIterable:EfficientLengthIterable<T*>,Iterable<T*>,Object*/
abstract class EfficientLengthIterable<T> extends Iterable<T> {}
