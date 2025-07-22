// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Helper library used by `dart:js`.
///
/// This library hides any logic that is specific to the web, and allows us to
/// support `dart:js` for compiling to javascript on the server (e.g. to target
/// nodejs).
library dart._js;

/// Whether `o` is a browser object such as `Blob`, `Event`, `KeyRange`,
/// `ImageData`, `Node`, and `Window`.
///
/// On non-web targets, this function always returns false.
external bool isBrowserObject(dynamic o);

/// Convert a browser object to it's Dart counterpart. None of these types are
/// wrapped, but this function is needed to inform dart2js about the possible
/// types that are used and that therefore cannot be tree-shaken.
external Object convertFromBrowserObject(dynamic o);
