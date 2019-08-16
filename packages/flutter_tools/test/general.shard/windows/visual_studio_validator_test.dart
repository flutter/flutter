// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/doctor.dart';
import 'package:flutter_tools/src/windows/visual_studio.dart';
import 'package:flutter_tools/src/windows/visual_studio_validator.dart';
import 'package:mockito/mockito.dart';

import '../../src/common.dart';
import '../../src/context.dart';

class MockVisualStudio extends Mock implements VisualStudio {}

void main() {
  group('Visual Studio validation', () {
    MockVisualStudio mockVisualStudio;

    setUp(() {
      mockVisualStudio = MockVisualStudio();
    });

    testUsingContext('Emits missing status when Visual Studio is not installed', () async {
      when(visualStudio.isInstalled).thenReturn(false);
      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      expect(result.type, ValidationType.missing);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });

    testUsingContext('Emits partial status when Visual Studio is installed without necessary components', () async {
      when(visualStudio.isInstalled).thenReturn(true);
      when(visualStudio.hasNecessaryComponents).thenReturn(false);
      when(visualStudio.workloadDescription).thenReturn('Desktop development');
      when(visualStudio.necessaryComponentDescriptions(any)).thenReturn(<String>['A', 'B']);
      when(visualStudio.fullVersion).thenReturn('15.1');
      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      expect(result.type, ValidationType.partial);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });

    testUsingContext('Emits installed status when Visual Studio is installed with necessary components', () async {
      when(visualStudio.isInstalled).thenReturn(true);
      when(visualStudio.hasNecessaryComponents).thenReturn(true);
      const VisualStudioValidator validator = VisualStudioValidator();
      final ValidationResult result = await validator.validate();
      expect(result.type, ValidationType.installed);
    }, overrides: <Type, Generator>{
      VisualStudio: () => mockVisualStudio,
    });
  });
}
