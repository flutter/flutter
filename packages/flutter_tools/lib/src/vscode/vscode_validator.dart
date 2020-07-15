// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/user_messages.dart';
import '../base/version.dart';
import '../doctor.dart';
import '../globals.dart' as globals;
import 'vscode.dart';

class VsCodeValidator extends DoctorValidator {
  VsCodeValidator(this._vsCode) : super(_vsCode.productName);

  final VsCode _vsCode;

  static Iterable<DoctorValidator> get installedValidators {
    return VsCode
        .allInstalled(globals.fs, globals.platform)
        .map<DoctorValidator>((VsCode vsCode) => VsCodeValidator(vsCode));
  }

  @override
  Future<ValidationResult> validate() async {
    final String vsCodeVersionText = _vsCode.version == Version.unknown
        ? null
        : userMessages.vsCodeVersion(_vsCode.version.toString());

    final ValidationType validationType = _vsCode.isValid
        ? ValidationType.installed
        : ValidationType.partial;

    return ValidationResult(
      validationType,
      _vsCode.validationMessages.toList(),
      statusInfo: vsCodeVersionText,
    );
  }
}
