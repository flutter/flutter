import 'package:flutter/material.dart';
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    // Trigger the second route.
    // https://github.com/flutter/flutter/issues/40126
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => SecondPage()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold();
  }
}

class SecondPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          TextFormField(),
          const Expanded(
            child: InAppWebView(
              initialUrl: 'https://google.com',
            ),
          ),
        ],
      ),
    );
  }
}