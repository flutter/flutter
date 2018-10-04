// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import '../base/version.dart';
import '../doctor.dart';
import 'vscode.dart';

class VsCodeValidator extends DoctorValidator {
  VsCodeValidator(this._vsCode) : super(_vsCode.productName);

  final VsCode _vsCode;

  static const String extensionMarketplaceUrl =
    'https://marketplace.visualstudio.com/items?itemName=${VsCode.extensionIdentifier}';

  static Iterable<DoctorValidator> get installedValidators {
    return VsCode
        .allInstalled()
        .map<DoctorValidator>((VsCode vsCode) => VsCodeValidator(vsCode));
  }

  @override
  Future<ValidationResult> validate() async {
    final List<ValidationMessage> messages = <ValidationMessage>[];
    ValidationType type = ValidationType.missing;
    final String vsCodeVersionText = _vsCode.version == Version.unknown
        ? null
        : 'version ${_vsCode.version}';
    messages.add(ValidationMessage('VS Code at ${_vsCode.directory}'));
    if (_vsCode.isValid) {
      type = ValidationType.installed;
      messages.addAll(_vsCode.validationMessages
          .map<ValidationMessage>((String m) => ValidationMessage(m)));
    } else {
      type = ValidationType.partial;
      messages.addAll(_vsCode.validationMessages
          .map<ValidationMessage>((String m) => ValidationMessage.error(m)));
      messages.add(ValidationMessage(
          'Flutter extension not installed; install from\n$extensionMarketplaceUrl'));
    }

    return ValidationResult(type, messages, statusInfo: vsCodeVersionText);
  }
}
