// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Annotations to mark interfaces to JavaScript. All of these annotations are
/// exported via `package:js`.
library _js_annotations;

export 'dart:js_interop' show anonymous, staticInterop, JSExport;
export 'dart:js_util' show allowInterop, allowInteropCaptureThis;

/// An annotation that indicates a library, class, or member is implemented
/// directly in JavaScript.
///
/// All external members of a class or library with this annotation implicitly
/// have it as well.
///
/// Specifying [name] customizes the JavaScript name to use. By default the
/// dart name is used. It is not valid to specify a custom [name] for class
/// instance members.
class JS {
  final String? name;
  const JS([this.name]);
}

/// NOTE: [trustTypes] is an experimental annotation that may disappear at any
/// point in time. It exists solely to help users who wish to migrate classes
/// from the older style of JS interop to the new static interop model but wish
/// to preserve the older semantics for type checks. This annotation must be
/// used alongside [staticInterop] and it affects any external methods in any
/// extension to the static interop class.
class _TrustTypes {
  const _TrustTypes();
}

const _TrustTypes trustTypes = _TrustTypes();
