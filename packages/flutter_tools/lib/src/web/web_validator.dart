// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';
import 'package:platform/platform.dart';

import '../base/file_system.dart';
import '../doctor.dart';
import 'chrome.dart';

/// A validator that checks whether chrome is installed and can run.
class WebValidator extends DoctorValidator {
  const WebValidator({
    @required Platform platform,
    @required ChromeLauncher chromeLauncher,
    @required FileSystem fileSystem,
  }) : _platform = platform,
       _chromeLauncher = chromeLauncher,
       _fileSystem = fileSystem,
       super('Chrome - develop for the web');

  final Platform _platform;
  final ChromeLauncher _chromeLauncher;
  final FileSystem _fileSystem;

  @override
  Future<ValidationResult> validate() async {
    final String chrome = findChromeExecutable(_platform, _fileSystem);
    final bool canRunChrome = _chromeLauncher.canFindChrome();
    final List<ValidationMessage> messages = <ValidationMessage>[
      if (_platform.environment.containsKey(kChromeEnvironment))
        if (!canRunChrome)
          ValidationMessage.hint('$chrome is not executable.')
        else
          ValidationMessage('$kChromeEnvironment = $chrome')
      else
        if (!canRunChrome)
          ValidationMessage.hint('Cannot find Chrome. Try setting '
            '$kChromeEnvironment to a Chrome executable.')
        else
          ValidationMessage('Chrome at $chrome'),
    ];
    if (!canRunChrome) {
      return ValidationResult(
        ValidationType.missing,
        messages,
        statusInfo: 'Cannot find chrome executable at $chrome',
      );
    }
    return ValidationResult(
      ValidationType.installed,
      messages,
    );
  }
}
