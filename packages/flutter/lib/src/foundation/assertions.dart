// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
library;

import 'ui_primitives.dart';

export 'basic_types.dart' show IterableFilter;

// Examples can assume:
// late String runtimeType;
// late bool draconisAlive;
// late bool draconisAmulet;
// late Diagnosticable draconis;
// void methodThatMayThrow() { }
// class Trace implements StackTrace { late StackTrace vmTrace; }
// class Chain implements StackTrace { Trace toTrace() => Trace(); }

/// Signature for [FlutterError.onError] handler.
typedef FlutterExceptionHandler = void Function(FlutterErrorDetails details);

/// Signature for [DiagnosticPropertiesBuilder] transformer.
typedef DiagnosticPropertiesTransformer =
    Iterable<DiagnosticsNode> Function(Iterable<DiagnosticsNode> properties);

/// Signature for [FlutterErrorDetails.informationCollector] callback
/// and other callbacks that collect information describing an error.
typedef InformationCollector = Iterable<DiagnosticsNode> Function();

/// Signature for a function that demangles [StackTrace] objects into a format
/// that can be parsed by [StackFrame].
///
/// See also:
///
///   * [FlutterError.demangleStackTrace], which shows an example implementation.
typedef StackTraceDemangler = StackTrace Function(StackTrace details);
