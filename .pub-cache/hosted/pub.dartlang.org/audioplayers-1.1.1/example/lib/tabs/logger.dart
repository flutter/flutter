import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers_example/components/btn.dart';
import 'package:audioplayers_example/components/tab_wrapper.dart';
import 'package:flutter/material.dart';

class LoggerTab extends StatefulWidget {
  const LoggerTab({Key? key}) : super(key: key);

  @override
  _LoggerTabState createState() => _LoggerTabState();
}

class _LoggerTabState extends State<LoggerTab> {
  static GlobalPlatformInterface get _logger => AudioPlayer.global;

  LogLevel currentLogLevel = _logger.logLevel;

  @override
  Widget build(BuildContext context) {
    return TabWrapper(
      children: [
        Text('Log Level: $currentLogLevel'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: LogLevel.values
              .map(
                (e) => Btn(
                  txt: e.toString().replaceAll('LogLevel.', ''),
                  onPressed: () async {
                    await _logger.changeLogLevel(e);
                    setState(() => currentLogLevel = _logger.logLevel);
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
