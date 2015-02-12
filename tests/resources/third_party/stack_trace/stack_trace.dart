// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Stack trace generation and parsing.
 *
 * ## Installing ##
 *
 * Use [pub][] to install this package. Add the following to your `pubspec.yaml`
 * file.
 *
 *     dependencies:
 *       stack_trace: any
 *
 * Then run `pub install`.
 *
 * For more information, see the
 * [stack_trace package on pub.dartlang.org][pkg].
 *
 * [pub]: http://pub.dartlang.org
 * [pkg]: http://pub.dartlang.org/packages/stack_trace
 */
library stack_trace;

export 'src/trace.dart';
export 'src/frame.dart';
export 'src/chain.dart';
