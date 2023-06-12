import 'package:flutter/material.dart';
import 'package:watch_ble_connection/watch_ble_connection.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  TextEditingController _controller;
  String value = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();

    WatchListener.listenForMessage((msg) {
      print(msg);
    });
    WatchListener.listenForDataLayer((msg) {
      print(msg);
    });
  }

  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Example app'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                      border: InputBorder.none, labelText: 'Enter some text'),
                  onChanged: (String val) async {
                    setState(() {
                      value = val;
                    });
                  },
                ),
                OutlinedButton(
                  child: Text('Send message to Watch'),
                  onPressed: () {
                    primaryFocus.unfocus(disposition: UnfocusDisposition.scope);
                    WatchConnection.sendMessage({
                      "text": value
                    });
                  },
                ),
                OutlinedButton(
                  child: Text('Set data on Watch'),
                  onPressed: () {
                    primaryFocus.unfocus(disposition: UnfocusDisposition.scope);
                    WatchConnection.setData("message", {
                      "text": value != ""
                          ? value
                          : "test", // ensure we have at least empty string
                      "integerValue": 1,
                      "intList": [1, 2, 3],
                      "stringList": ["one", "two", "three"],
                      "floatList": [1.0, 2.4, 3.6],
                      "longList": []
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
