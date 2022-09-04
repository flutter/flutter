import 'package:flutter/material.dart';

import 'package:flutter_swiper/flutter_swiper.dart';
import 'src/ExampleCustom.dart';
import 'src/config.dart';
import 'src/ExampleSwiperInScrollView.dart';

import 'package:flutter/cupertino.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Swiper'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Swiper(
        itemCount: 10,
        itemBuilder: (c, i) {
          return new Text("$i");
        },
        plugins: [],
      ),
    );
  }
}
