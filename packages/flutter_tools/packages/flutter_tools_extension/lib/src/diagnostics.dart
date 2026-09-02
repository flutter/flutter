// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'protocol_base/service.dart';

/// Extension service interface for running diagnostic validation checks (e.g. for `flutter doctor`).
abstract class DiagnosticsExtension extends ToolExtensionService {
  /// Service namespace identifier for diagnostics.
  static const String serviceNamespace = 'diagnostics';

  /// RPC method identifier to execute diagnostic checks.
  static const String runDiagnosticsMethod = 'diagnostics.runDiagnostics';

  /// RPC method identifier to retrieve the validator title.
  static const String getTitleMethod = 'diagnostics.getTitle';

  @override
  String get namespace => serviceNamespace;

  /// The human-readable title of the doctor validator provided by this extension.
  String get title;

  /// Runs all diagnostic checks and returns the validation results.
  Future<List<ValidationResult>> runDiagnostics();

  @override
  Future<Map<String, ExtensionRpcHandler>> initialize() async {
    return <String, ExtensionRpcHandler>{
      'getTitle': _getTitleRpc,
      'runDiagnostics': _runDiagnosticsRpc,
    };
  }

  Future<String> _getTitleRpc(Map<String, Object?> params) async => title;

  Future<List<Map<String, Object?>>> _runDiagnosticsRpc(Map<String, Object?> params) async {
    final List<ValidationResult> results = await runDiagnostics();
    return results.map((ValidationResult r) => r.toMap()).toList();
  }
}
