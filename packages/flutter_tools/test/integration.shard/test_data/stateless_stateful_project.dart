// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_tools/src/globals.dart' as globals;

import '../test_utils.dart';
import 'project.dart';

class HotReloadProject extends Project {
  @override
  final String pubspec = '''
  name: test
  environment:
    sdk: ">=2.0.0-dev.68.0 <3.0.0"

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

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final ByteData message = const StringCodec().encodeMessage('AppLifecycleState.resumed');
    await ServicesBinding.instance.defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
    runApp(MyApp());
  }

  class MyApp extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        title: 'Flutter Demo',
        home: Child(),
      );
    }
  }


  class Child extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      print('STATELESS');
      return Container();
    }
  }

  class Other extends StatefulWidget {
    State createState() => _State();
  }

  class _State extends State<Other>{
    @override
    Widget build(BuildContext context) {
      print('STATEFUL');
      return Container();
    }
  }
  ''';

  void toggleState() {
    final String main = globals.fs.file(globals.fs.path.join(dir.path, 'lib', 'main.dart')).readAsStringSync();
    String newMainContents = main.replaceAll('Child', 'Temp');
    newMainContents = newMainContents.replaceAll('Other', 'Child');
    newMainContents = newMainContents.replaceAll('Temp', 'Other');
    newMainContents = newMainContents.replaceAll('Other()', 'Child()');
    writeFile(globals.fs.path.join(dir.path, 'lib', 'main.dart'), newMainContents);
  }
}
