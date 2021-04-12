// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/fuchsia/fuchsia_kernel_compiler.dart';

import '../../src/common.dart';

void main() {
  group('Fuchsia Kernel Compiler', () {
    test('provide correct flags for release mode', () {
      expect(
        FuchsiaKernelCompiler.getBuildInfoFlags(
          buildInfo: BuildInfo.release,
          manifestPath: '',
        ),
        allOf(<Matcher>[
          contains('-Ddart.vm.profile=false'),
          contains('-Ddart.vm.product=true'),
        ]));
    });

    test('provide correct flags for profile mode', () {
      expect(
        FuchsiaKernelCompiler.getBuildInfoFlags(
          buildInfo: BuildInfo.profile,
          manifestPath: '',
        ),
        allOf(<Matcher>[
          contains('-Ddart.vm.profile=true'),
          contains('-Ddart.vm.product=false'),
        ]),
      );
    });

    test('provide correct flags for custom dart define', () {
      expect(
        FuchsiaKernelCompiler.getBuildInfoFlags(
          buildInfo: const BuildInfo(
            BuildMode.debug,
            null,
            treeShakeIcons: true,
            dartDefines: <String>['abc=efg'],
          ),
          manifestPath: ''),
          allOf(<Matcher>[
            contains('-Dabc=efg'),
          ]));
    });
  });
}
