import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_driver/driver_extension.dart';

void main() {
  enableFlutterDriverExtension(handler: dataHandler);
  runApp(new TestApp());
}

const MethodChannel kSemanticsChannel = const MethodChannel('semantics');

Future<String> dataHandler(String message) async {
  if (message.contains('getSemanticsNode')) {
    final int id = int.tryParse(message.split('#')[1]) ?? 0;
    final dynamic result = await kSemanticsChannel.invokeMethod('getSemanticsNode', <String, dynamic>{
      'id': id,
    });
    return json.encode(result);
  }
  throw new UnimplementedError();
}


const List<String> kTestData = const <String>[
  'California',
  'Oregon',
  'Washington',
  'Nevada',
  'Arizona',
  'Nebraska',
  'Kansas',
  'Idaho',
];

class TestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(title: const Text('test app')),
        body: new ListView(
          children: kTestData.map<Widget>((String data) {
            return new Row(children: <Widget>[
              new Text(data),
              new Checkbox(key: new ValueKey<String>(data), value: data.length.isEven, onChanged: (bool value) {}),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}