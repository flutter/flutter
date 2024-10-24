import 'dart:async';

import 'popup_menu.dart';

import 'toolbar.dart';
import 'package:flutter/material.dart';

StreamController<ThemeData> _themeStream = StreamController();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ThemeData>(
        initialData: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        stream: _themeStream.stream,
        builder: (BuildContext context, AsyncSnapshot<ThemeData> data) {
          return MaterialApp(
            title: 'Ubuntu Summit Demo 2024.10',
            theme: data.data!,
            home: const Home(),
          );
        });
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: <Widget>[
        Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Toolbar(onBackgroundColorSelected: _onColorChanged),
        ]),
        Expanded(
            child: Center(
                child: ListView(shrinkWrap: true, children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                  child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[PopupMenu()],
                  ),
                  const ListTile(
                    leading: Tooltip(message: "I am a very long and interesting tooltip!", child: Icon(Icons.info)),
                    title: Text('Ubuntu Summit Multi-Window Demo'),
                    subtitle: Text('Brought to you buy the Mir team.'),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      TextButton(
                        child: const Text('About'),
                        onPressed: () {
                          showAboutDialog(context: context);
                        },
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        child: const Text('Open Toolbar'),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        child: const Text('Open Second Window'),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 8)
                    ],
                  ),
                ],
              )))
        ]))),
      ],
    ));
  }

  void _onColorChanged(Color color) {
    _themeStream.add(ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: color),
      useMaterial3: true,
    ));
  }
}
