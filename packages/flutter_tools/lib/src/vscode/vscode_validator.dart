// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:process/process.dart';

import '../base/file_system.dart';
import '../base/platform.dart';
import '../base/user_messages.dart';
import '../doctor_validator.dart';
import 'vscode.dart';

class VsCodeValidator extends DoctorValidator {
  VsCodeValidator(this._vsCode) : super(_vsCode.productName);

  final VsCode _vsCode;

  static Iterable<DoctorValidator> installedValidators(FileSystem fileSystem, Platform platform, ProcessManager processManager) {
    return VsCode
        .allInstalled(fileSystem, platform, processManager)
        .map<DoctorValidator>((VsCode vsCode) => VsCodeValidator(vsCode));
  }

  @override
  Future<ValidationResult> validate() async {
    final String? vsCodeVersionText = _vsCode.version == null
        ? null
        : userMessages.vsCodeVersion(_vsCode.version.toString());

    return ValidationResult(
      ValidationType.success,
      _vsCode.validationMessages.toList(),
      statusInfo: vsCodeVersionText,
    );
  }
}
