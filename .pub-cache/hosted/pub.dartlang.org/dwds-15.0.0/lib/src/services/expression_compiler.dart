// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Result of compilation of dart expression to JavaScript
class ExpressionCompilationResult {
  final bool isError;
  final String result;

  /// Result of compilation from dart to JavaScript
  ///
  /// [result] JavaScript expression as String, or error message
  /// if compilation has failed
  /// [isError] true if compilation has failed, false otherwise
  ExpressionCompilationResult(this.result, this.isError);

  @override
  String toString() => 'result: $result, isError:$isError';
}

/// Interface to provide means of compiling expressions from dart to JavaScript
/// used to implement expression evaluation in any tools using dwds
abstract class ExpressionCompiler {
  /// Compiles [expression] in [libraryUri] at [line]:[column] to JavaScript
  /// in [moduleName].
  ///
  /// Values listed in [jsFrameValues] are substituted for their names in the
  /// [expression].
  ///
  /// Ensures that all [jsModules] are loaded and accessible inside the
  /// expression.
  ///
  /// Returns [ExpressionCompilationResult]
  /// Errors are reported using onDiagnostic function
  /// [moduleName] is of the form '/packages/hello_world_main.dart'
  /// [jsFrameValues] is a map from js variable name to its primitive value
  /// or another variable name, for example
  /// { 'x': '1', 'y': 'y', 'o': 'null' }
  /// [jsModules] is a map from variable name to the module name, where
  /// variable name is the name originally used in JavaScript to contain the
  /// module object, for example:
  /// { 'dart':'dart_sdk', 'main': '/packages/hello_world_main.dart' }
  ///
  /// Should wait for the dependencies to update if called during a call to
  /// [updateDependencies].
  Future<ExpressionCompilationResult> compileExpressionToJs(
      String isolateId,
      String libraryUri,
      int line,
      int column,
      Map<String, String> jsModules,
      Map<String, String> jsFrameValues,
      String moduleName,
      String expression);

  /// Trigger (re-)load of kernel files for modules.
  ///
  /// (Re-)load summaries for changed modules and trigger reload
  /// of full dill file for module on first expression evaluation
  /// in the module.
  ///
  /// [modules]: moduleName -> moduleInfo
  ///
  /// [updateDependencies] is called during isolate creation.
  Future<bool> updateDependencies(Map<String, ModuleInfo> modules);

  /// Initializes the compiler with null safety mode and module format.
  ///
  /// May be called multiple times and always before [updateDependencies].
  Future<void> initialize({
    required String moduleFormat,
    bool soundNullSafety = false,
  });
}

class ModuleInfo {
  final String fullDillPath;
  final String summaryPath;

  ModuleInfo(this.fullDillPath, this.summaryPath);

  @override
  String toString() => '{ $fullDillPath, $summaryPath }';
}
