// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/summary2/data_reader.dart';
import 'package:analyzer/src/summary2/data_writer.dart';
import 'package:meta/meta.dart';

/// An error during evaluating annotation arguments.
class ArgumentMacroApplicationError extends MacroApplicationError {
  final int argumentIndex;
  final String message;

  ArgumentMacroApplicationError({
    required super.annotationIndex,
    required this.argumentIndex,
    required this.message,
  }) : super._(
          kind: MacroApplicationErrorKind.argument,
        );

  factory ArgumentMacroApplicationError._read(
    SummaryDataReader reader,
    int annotationIndex,
  ) {
    return ArgumentMacroApplicationError(
      annotationIndex: annotationIndex,
      argumentIndex: reader.readUInt30(),
      message: reader.readStringUtf8(),
    );
  }

  @override
  String toStringForTest() {
    return 'Argument(annotation: $annotationIndex, '
        'argument: $argumentIndex, message: $message)';
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeUInt30(argumentIndex);
    sink.writeStringUtf8(message);
  }
}

/// An error that happened while applying a macro.
abstract class MacroApplicationError {
  /// The index of the annotation of the element that turned out to be a
  /// macro application. Can be used to associate the error with the location.
  final int annotationIndex;

  final MacroApplicationErrorKind kind;

  factory MacroApplicationError(SummaryDataReader reader) {
    final annotationIndex = reader.readUInt30();
    final kind = MacroApplicationErrorKind.values[reader.readUInt30()];
    switch (kind) {
      case MacroApplicationErrorKind.argument:
        return ArgumentMacroApplicationError._read(
          reader,
          annotationIndex,
        );
      case MacroApplicationErrorKind.unknown:
        return UnknownMacroApplicationError._read(
          reader,
          annotationIndex,
        );
    }
  }

  MacroApplicationError._({
    required this.annotationIndex,
    required this.kind,
  });

  String toStringForTest();

  @mustCallSuper
  void write(BufferedSink sink) {
    sink.writeUInt30(annotationIndex);
    sink.writeUInt30(kind.index);
  }
}

enum MacroApplicationErrorKind {
  /// An error while evaluating arguments.
  argument,

  /// Any other exception that happened during application.
  unknown,
}

/// Any other exception that happened during macro application.
class UnknownMacroApplicationError extends MacroApplicationError {
  final String message;
  final String stackTrace;

  UnknownMacroApplicationError({
    required super.annotationIndex,
    required this.message,
    required this.stackTrace,
  }) : super._(
          kind: MacroApplicationErrorKind.unknown,
        );

  factory UnknownMacroApplicationError._read(
    SummaryDataReader reader,
    int annotationIndex,
  ) {
    return UnknownMacroApplicationError(
      annotationIndex: annotationIndex,
      message: reader.readStringUtf8(),
      stackTrace: reader.readStringUtf8(),
    );
  }

  @override
  String toStringForTest() {
    return 'Unknown(annotation: $annotationIndex, message: $message)';
  }

  @override
  void write(BufferedSink sink) {
    super.write(sink);
    sink.writeStringUtf8(message);
    sink.writeStringUtf8(stackTrace);
  }
}
