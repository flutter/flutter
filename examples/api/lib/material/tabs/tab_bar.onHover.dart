import 'package:flutter/material.dart';

/// Flutter code sample for [TabBar.onFocusChange].

void main() => runApp(const TabBarApp());

class TabBarApp extends StatelessWidget {
  const TabBarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: ThemeData(useMaterial3: true), home: TabBarExample());
  }
}

class TabBarExample extends StatefulWidget {
  TabBarExample({super.key});

  @override
  State<TabBarExample> createState() => _TabBarExampleState();
}

class _TabBarExampleState extends State<TabBarExample> {
  final List<Color> tabColors = <Color>[Colors.purple, Colors.purple, Colors.purple];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 1,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TabBar Sample'),
          bottom: TabBar(
            onHover: (bool value, int index) {
              setState(() {
                tabColors[index] = switch (value) {
                  true => Colors.pink,
                  false => Colors.purple,
                };
              });
            },
            tabs: <Widget>[
              Tab(icon: Icon(Icons.cloud_outlined, color: tabColors[0])),
              Tab(icon: Icon(Icons.beach_access_sharp, color: tabColors[1])),
              Tab(icon: Icon(Icons.brightness_5_sharp, color: tabColors[2])),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            Center(child: Text("It's cloudy here")),
            Center(child: Text("It's rainy here")),
            Center(child: Text("It's sunny here")),
          ],
        ),
      ),
    );
  }
}
