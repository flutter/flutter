import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State {
  final AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();

  @override
  void initState() {
    _assetsAudioPlayer.playlistFinished.listen((data) {
      print('finished : $data');
    });
    _assetsAudioPlayer.playlistAudioFinished.listen((data) {
      print('playlistAudioFinished : $data');
    });
    _assetsAudioPlayer.current.listen((data) {
      print('current : $data');
    });
    _assetsAudioPlayer.onReadyToPlay.listen((audio) {
      print('onReadyToPlay : $audio');
    });
    _assetsAudioPlayer.open(
        Audio(
          'assets/audios/water.mp3',
        ),
        loopMode: LoopMode.playlist);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: _assetsAudioPlayer.builderCurrentPosition(
              builder: (BuildContext context, Duration position) {
            return Text(position.toString());
          }),
        ),
      ),
    );
  }
}
