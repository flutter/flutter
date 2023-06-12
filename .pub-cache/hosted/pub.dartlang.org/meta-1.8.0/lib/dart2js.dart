// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Constants for use in metadata annotations to provide hints to dart2js.
///
/// This is an experimental feature and not expected to be useful except for low
/// level framework authors.
///
/// Added at sdk version 2.0.0-dev.6.0
library meta_dart2js;

/// An annotation for methods to request that dart2js does not inline the
/// method.
///
///     import 'package:meta/dart2js.dart' as dart2js;
///
///     @dart2js.noInline
///     String text() => 'A String of unusual size';
const noInline = pragma('dart2js:noInline');

/// An annotation for methods to request that dart2js always inline the
/// method.
///
/// dart2js will attempt to inline the method regardless of its size. Even with
/// this annotation, there are conditions that can prevent dart2js from inlining
/// a method, including complex control flow.
///
///     import 'package:meta/dart2js.dart' as dart2js;
///
///     @dart2js.tryInline
///     String bigMethod() {
///       for (int i in "Hello".runes) print(i);
///     }
///
/// It is an error to use both `@noInline` and `@tryInline` on the same method.
const tryInline = pragma('dart2js:tryInline');
