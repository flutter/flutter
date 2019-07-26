// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:fidl_fuchsia_examples_hello/fidl_async.dart';
import 'package:fidl_fuchsia_io/fidl_async.dart';
import 'package:fidl_fuchsia_sys/fidl_async.dart';
import 'package:fuchsia_services/services.dart';
import 'package:test/test.dart';

void main(List<String> args) {
  final StartupContext context = StartupContext.fromStartupInfo();
  LauncherProxy launcher;

  setUp(() {
    launcher = LauncherProxy();
    context.incoming.connectToService(launcher);
  });

  tearDown(() {
    launcher.ctrl.close();
    launcher = null;
  });

  // TODO(rosswang): nested environments and determinism

  test('schedule delayed futures',
      () => Future<Null>.delayed(const Duration(seconds: 1)));

  test('start hello_dart', () async {
    const LaunchInfo info = LaunchInfo(
        url:
            'fuchsia-pkg://fuchsia.com/hello_dart_jit#meta/hello_dart_jit.cmx');
    await launcher.createComponent(
        info, ComponentControllerProxy().ctrl.request());
  });

  test('communicate with a fidl service (hello_app_dart)', () async {
    final HelloProxy service = HelloProxy();
    final dirProxy = DirectoryProxy();

    final ComponentControllerProxy actl = ComponentControllerProxy();

    final LaunchInfo info = LaunchInfo(
        url:
            'fuchsia-pkg://fuchsia.com/hello_app_dart_jit#meta/hello_app_dart_jit.cmx',
        directoryRequest: dirProxy.ctrl.request().passChannel());
    await launcher.createComponent(info, actl.ctrl.request());
    Incoming(dirProxy).connectToService(service);

    expect(await service.say('hello'), equals('hola from Dart!'));

    actl.ctrl.close();
  });

  test('dart:io exit() throws UnsupportedError', () {
    expect(() => io.exit(-1), throwsUnsupportedError);
  });
}
