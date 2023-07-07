import 'package:fluttertoast_example/toast_context.dart';
import 'package:fluttertoast_example/toast_no_context.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() => runApp(
      MaterialApp(
        builder: FToastBuilder(),
        home: MyApp(),
        navigatorKey: navigatorKey,
      ),
    );

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Toast"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ToastNoContext(),
              ));
            },
            child: Text("Flutter Toast No Context"),
          ),
          SizedBox(
            height: 24.0,
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => ToastContext(),
              ));
            },
            child: Text("Flutter Toast Context"),
          ),
        ],
      ),
    );
  }
}
