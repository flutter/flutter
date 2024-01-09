// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/windows/topaz_ofd_validator.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

FakeProcessLister ofdRunning() {
  return FakeProcessLister(result: r'Path: "C:\Program Files\Topaz OFD\Warsaw\core.exe"');
}

FakeProcessLister ofdNotRunning() {
  return FakeProcessLister(result: r'Path: "C:\Program Files\Google\Chrome\Application\chrome.exe');
}

FakeProcessLister failure() {
  return FakeProcessLister(result: r'Path: "C:\Program Files\Google\Chrome\Application\chrome.exe', exitCode: 10);
}

void main() {
  testWithoutContext('Successfully checks for Topaz OFD when it is not running', () async {
    final FakeProcessLister processLister = ofdNotRunning();
    final TopazOfdValidator validator = TopazOfdValidator(processLister: processLister);
    final ValidationResult result = await validator.validate();
    expect(result.type, ValidationType.success);
    expect(result.statusInfo, null);
  });
  testWithoutContext('Successfully checks for Topaz OFD when it is running', () async {
    final FakeProcessLister processLister = ofdRunning();
    final TopazOfdValidator validator = TopazOfdValidator(processLister: processLister);
    final ValidationResult result = await validator.validate();
    expect(result.type, ValidationType.missing);
    expect(result.statusInfo, 'Topaz OFD may be running');
  });
  testWithoutContext('Reports failure of Get-Process', () async {
    final FakeProcessLister processLister = failure();
    final TopazOfdValidator validator = TopazOfdValidator(processLister: processLister);
    final ValidationResult result = await validator.validate();
    expect(result.type, ValidationType.missing);
    expect(result.statusInfo, 'Get-Process failed to complete');
  });
}

class FakeProcessLister extends Fake implements ProcessLister {
  FakeProcessLister({required this.result, this.exitCode = 0});
  final String result;
  final int exitCode;

  @override
  Future<ProcessResult> getProcessesWithPath(String? filter) async {
    return ProcessResult(0, exitCode, result, null);
  }
}
