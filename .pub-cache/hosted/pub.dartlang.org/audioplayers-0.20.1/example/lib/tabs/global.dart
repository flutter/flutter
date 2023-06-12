import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audioplayers_api.dart';
import 'package:flutter/material.dart';

import '../components/btn.dart';
import '../components/tab_wrapper.dart';

class GlobalTab extends StatefulWidget {
  const GlobalTab({Key? key}) : super(key: key);

  @override
  _GlobalTabState createState() => _GlobalTabState();
}

class _GlobalTabState extends State<GlobalTab> {
  LogLevel currentLogLevel = Logger.logLevel;
  @override
  Widget build(BuildContext context) {
    return TabWrapper(
      children: [
        Text('Log Level: $currentLogLevel'),
        Row(
          children: LogLevel.values
              .map(
                (e) => Btn(
                  txt: e.toString(),
                  onPressed: () async {
                    await Logger.changeLogLevel(e);
                    setState(() => currentLogLevel = Logger.logLevel);
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
