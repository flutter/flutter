import 'package:flutter/material.dart';
import 'package:ubuntu_summit_demo/popup_menu.dart';

class Satellite extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Toolbox'),
            actions: [PopupMenu()],
          ),
          body: const Center(child: CardExample())),
    );
  }
}

class CardExample extends StatelessWidget {
  const CardExample({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Satellite Window'),
            subtitle:
                Text('This content is being rendered in a satellite window.'),
          )
        ],
      ),
    );
  }
}
