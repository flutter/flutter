// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/doctor_validator.dart';
import 'package:flutter_tools/src/windows/topaz_ofd_validator.dart';
import 'package:test/fake.dart';

import '../../src/common.dart';

FakeProcessLister OfdRunning() {
  return FakeProcessLister(result: r'Path: "C:\Program Files\Topaz OFD\Warsaw\core.exe"');
}

FakeProcessLister OfdNotRunning() {
  return FakeProcessLister(result: r'Path: "C:\Program Files\Google\Chrome\Application\chrome.exe');
}

void main() {
  testWithoutContext('Successfully checks for Topaz OFD when it is not running', () async {
    final FakeProcessLister processLister = OfdNotRunning();
    final TopazOfdValidator validator = TopazOfdValidator(processLister: processLister);
    final ValidationResult result = await validator.validate();
    expect(result.type, ValidationType.success);
    expect(result.statusInfo, null);
  });
  testWithoutContext('Successfully checks for Topaz OFD when it is running', () async {
    final FakeProcessLister processLister = OfdRunning();
    final TopazOfdValidator validator = TopazOfdValidator(processLister: processLister);
    final ValidationResult result = await validator.validate();
    expect(result.type, ValidationType.partial);
    expect(result.statusInfo, 'Topaz OFD may be running');
  });
}

class FakeProcessLister extends Fake implements ProcessLister {
  FakeProcessLister({required this.result});
  final String result;

  @override
  Future<String> getProcessesWithPath(String? filter) async {
    return result;
  }
}
