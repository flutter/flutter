// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of '../api.dart';

/// A diagnostic reported from a [Macro].
class Diagnostic {
  /// Additional [DiagnosticMessage]s related to this one, to help with the
  /// context.
  final Iterable<DiagnosticMessage> contextMessages;

  /// An optional message describing to the user how they might fix this
  /// diagnostic.
  final String? correctionMessage;

  /// The primary message for this diagnostic.
  final DiagnosticMessage message;

  /// The severity of this diagnostic.
  final Severity severity;

  /// General diagnostics for the current macro application.
  ///
  /// These will be attached to the macro application itself.
  Diagnostic(this.message, this.severity,
      {List<DiagnosticMessage> contextMessages = const [],
      this.correctionMessage})
      : contextMessages = UnmodifiableListView(contextMessages);
}

/// A message and optional target for a [Diagnostic] reported by a [Macro].
class DiagnosticMessage {
  /// The primary message for this diagnostic message.
  final String message;

  /// The optional target for this diagnostic message.
  ///
  /// If provided, the diagnostic should be linked to this target.
  ///
  /// If not provided, it should be implicitly linked to the macro application
  /// that generated this diagnostic.
  final DiagnosticTarget? target;

  DiagnosticMessage(this.message, {this.target});
}

/// A target for a [DiagnosticMessage]. We use a sealed class to represent a
/// union type of the valid target types.
sealed class DiagnosticTarget {}

/// A [DiagnosticMessage] target which is a [Declaration].
final class DeclarationDiagnosticTarget extends DiagnosticTarget {
  final Declaration declaration;

  DeclarationDiagnosticTarget(this.declaration);
}

/// A simplified way of creating a [DiagnosticTarget] target for a
/// [Declaration].
extension DeclarationAsTarget on Declaration {
  DeclarationDiagnosticTarget get asDiagnosticTarget =>
      DeclarationDiagnosticTarget(this);
}

/// A [DiagnosticMessage] target which is a [TypeAnnotation].
final class TypeAnnotationDiagnosticTarget extends DiagnosticTarget {
  final TypeAnnotation typeAnnotation;

  TypeAnnotationDiagnosticTarget(this.typeAnnotation);
}

/// A simplified way of creating a [DiagnosticTarget] target for a
/// [TypeAnnotation].
extension TypeAnnotationAsTarget on TypeAnnotation {
  TypeAnnotationDiagnosticTarget get asDiagnosticTarget =>
      TypeAnnotationDiagnosticTarget(this);
}

/// A [DiagnosticMessage] target which is a [MetadataAnnotation].
final class MetadataAnnotationDiagnosticTarget extends DiagnosticTarget {
  final MetadataAnnotation metadataAnnotation;

  MetadataAnnotationDiagnosticTarget(this.metadataAnnotation);
}

extension MetadataAnnotationAsTarget on MetadataAnnotation {
  MetadataAnnotationDiagnosticTarget get asDiagnosticTarget =>
      MetadataAnnotationDiagnosticTarget(this);
}

/// The severities supported for [Diagnostic]s.
enum Severity {
  /// Informational message only, for example a style guideline is not being
  /// followed. These may not always be shown to the user depending on how the
  /// app is being compiled and with what flags.
  info,

  /// Not a critical failure, but something is likely wrong and the code should
  /// be changed. Always shown to the user by default, but may be silenceable by
  /// some tools.
  warning,

  /// Critical failure, the macro could not proceed. Cannot be silenced and will
  /// always prevent the app from compiling successfully. These are always shown
  /// to the user and cannot be silenced.
  error,
}
