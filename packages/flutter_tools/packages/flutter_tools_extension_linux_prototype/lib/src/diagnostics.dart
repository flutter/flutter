// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools_core/flutter_tools_core.dart';
import 'package:flutter_tools_extension/flutter_tools_extension.dart';

/// Prototype Linux platform extension diagnostic validator check for `flutter doctor`.
class LinuxExtensionDiagnostics extends DiagnosticsExtension {
  @override
  String get title => 'Linux Custom Extension Prototype';

  @override
  Future<List<ValidationResult>> runDiagnostics() async {
    // TODO(bkonyi): perform Linux-specific environment and toolchain validation.
    final messages = <ValidationMessage>[
      const ValidationMessage('Linux custom extension toolchain is operational'),
      const ValidationMessage('GTK 3.0 headers and libraries detected'),
      const ValidationMessage('Ninja build target generator available'),
    ];

    return <ValidationResult>[
      ValidationResult(
        ValidationType.success,
        messages,
        statusInfo: 'Linux Prototype Extension OK',
      ),
    ];
  }
}
