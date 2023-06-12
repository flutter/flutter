import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';

final mp3Url =
    'https://files.freemusicarchive.org/storage-freemusicarchive-org/music/Music_for_Video/springtide/Sounds_strange_weird_but_unmistakably_romantic_Vol1/springtide_-_03_-_We_Are_Heading_to_the_East.mp3';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cache',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? downloadingProgress;

  final AssetsAudioPlayer _player = AssetsAudioPlayer.newPlayer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[playerWidget(context)],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _player.cacheDownloadInfos.listen((infos) {
      print(infos.percent);
    });
    _player.open(
      Audio.network(mp3Url, cached: true),
      autoStart: true,
    );
  }

  Widget playerWidget(BuildContext context) {
    return PlayerBuilder.current(
      player: _player,
      builder: (context, Playing? current) {
        if (current == null) {
          return SizedBox();
        }
        return PlayerBuilder.isPlaying(
          player: _player,
          builder: (context, isPlaying) {
            return FloatingActionButton(
              onPressed: () {
                _player.playOrPause();
              },
              child: isPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
            );
          },
        );
      },
    );
  }
}
