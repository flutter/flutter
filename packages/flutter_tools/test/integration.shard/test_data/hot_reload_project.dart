// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../test_utils.dart';
import 'project.dart';

class HotReloadProject extends Project {
  HotReloadProject({super.indexHtml});

  @override
  final String pubspec = '''
  name: test
  environment:
    sdk: ">=2.12.0-0 <3.0.0"

  dependencies:
    flutter:
      sdk: flutter
  ''';

  @override
  final String main = r'''
  import 'package:flutter/material.dart';
  import 'package:flutter/scheduler.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter/widgets.dart';
  import 'package:flutter/foundation.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final ByteData message = const StringCodec().encodeMessage('AppLifecycleState.resumed')!;
    await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
    // See https://github.com/flutter/flutter/issues/86202
    if (kIsWeb) {
      while (true) {
        runApp(MyApp());
        await Future.delayed(const Duration(seconds: 1));
      }
    } else {
     runApp(MyApp());
    }
  }

  int count = 1;

  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      // This method gets called each time we hot reload, during reassemble.

      // Do not remove the next line, it's uncommented by a test to verify that
      // hot reloading worked:
      // printHotReloadWorked();

      print('((((TICK $count))))');
      // tick 1 = startup warmup frame
      // tick 2 = hot reload warmup reassemble frame
      // after that there's a post-hot-reload frame scheduled by the tool that
      // doesn't trigger this to rebuild, but does trigger the first callback
      // below, then that callback schedules another frame on which we do the
      // breakpoint.
      // tick 3 = second hot reload warmup reassemble frame (pre breakpoint)
      if (count == 2) {
        SchedulerBinding.instance!.scheduleFrameCallback((Duration timestamp) {
          SchedulerBinding.instance!.scheduleFrameCallback((Duration timestamp) {
            print('breakpoint line'); // SCHEDULED BREAKPOINT
          });
        });
      }
      count += 1;

      return MaterialApp( // BUILD BREAKPOINT
        title: 'Flutter Demo',
        home: Container(),
      );
    }
  }

  void printHotReloadWorked() {
    // The call to this function is uncommented by a test to verify that hot
    // reloading worked.
    print('(((((RELOAD WORKED)))))');
  }
  ''';

  Uri get scheduledBreakpointUri => mainDart;
  int get scheduledBreakpointLine => lineContaining(main, '// SCHEDULED BREAKPOINT');

  Uri get buildBreakpointUri => mainDart;
  int get buildBreakpointLine => lineContaining(main, '// BUILD BREAKPOINT');

  void uncommentHotReloadPrint() {
    final String newMainContents = main.replaceAll(
      '// printHotReloadWorked();',
      'printHotReloadWorked();',
    );
    writeFile(
      fileSystem.path.join(dir.path, 'lib', 'main.dart'),
      newMainContents,
      writeFutureModifiedDate: true,
    );
  }
}
