// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Annotations to mark interfaces to JavaScript.
library js;

import 'package:meta/meta.dart';

export 'dart:js' show allowInterop, allowInteropCaptureThis;

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

class _Anonymous {
  const _Anonymous();
}

class _StaticInterop {
  const _StaticInterop();
}

/// An annotation that indicates a [JS] annotated class is structural and does
/// not have a known JavaScript prototype.
///
/// A class marked with [anonymous] must have an unnamed factory constructor
/// with no positional arguments, only named arguments. Invoking the constructor
/// desugars to creating a JavaScript object literal with name-value pairs
/// corresponding to the parameter names and values.
const _Anonymous anonymous = _Anonymous();

/// [staticInterop] enables the [JS] annotated class to be treated as a "static"
/// interop class.
///
/// These classes allow interop with native types, like the ones in `dart:html`.
/// These classes should not contain any instance members, inherited or
/// otherwise, and should instead use static extension members.
const _StaticInterop staticInterop = _StaticInterop();

/// NOTE: [trustTypes] is an experimental annotation that may disappear at any
/// point in time. It exists solely to help users who wish to migrate classes
/// from the older style of JS interop to the new static interop model but wish
/// to preserve the older semantics for type checks. This annotation must be
/// used alongside [staticInterop] and it affects any external methods in any
/// extension to the static interop class.
@experimental
class _TrustTypes {
  const _TrustTypes();
}

const _TrustTypes trustTypes = _TrustTypes();
