// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/analysis_options.dart';
import 'package:analyzer/dart/analysis/code_style_options.dart';

/// The concrete implementation of [CodeStyleOptions].
class CodeStyleOptionsImpl implements CodeStyleOptions {
  /// The analysis options that owns this instance.
  final AnalysisOptions options;

  @override
  final bool useFormatter;

  CodeStyleOptionsImpl(this.options, {required this.useFormatter});

  @override
  bool get makeLocalsFinal => _isLintEnabled('prefer_final_locals');

  @override
  bool get useRelativeUris => _isLintEnabled('prefer_relative_imports');

  /// Return `true` if the lint with the given [name] is enabled.
  bool _isLintEnabled(String name) => options.isLintEnabled(name);
}
