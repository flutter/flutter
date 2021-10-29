// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../test_utils.dart';
import 'project.dart';

class HotReloadProject extends Project {
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
  final String main = getCode(false);

  static String getCode(bool stateful) {
    return '''
  import 'package:flutter/material.dart';
  import 'package:flutter/scheduler.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter/widgets.dart';

  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    final ByteData message = const StringCodec().encodeMessage('AppLifecycleState.resumed')!;
    await ServicesBinding.instance!.defaultBinaryMessenger.handlePlatformMessage('flutter/lifecycle', message, (_) { });
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


  class ${stateful ? 'Other' : 'Child'} extends StatelessWidget {
    @override
    Widget build(BuildContext context) {
      print('STATELESS');
      return Container();
    }
  }

  class ${stateful ? 'Child' : 'Other'}  extends StatefulWidget {
    State createState() => _State();
  }

  class _State extends State<${stateful ? 'Child' : 'Other'}>{
    @override
    Widget build(BuildContext context) {
      print('STATEFUL');
      return Container();
    }
  }
  ''';
  }

  /// Whether the template is currently stateful.
  bool stateful = false;

  void toggleState() {
    stateful = !stateful;
    writeFile(
      fileSystem.path.join(dir.path, 'lib', 'main.dart'),
      getCode(stateful),
      writeFutureModifiedDate: true,
    );
  }
}
