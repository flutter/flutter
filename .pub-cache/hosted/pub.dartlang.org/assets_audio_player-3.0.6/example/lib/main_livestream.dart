import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/material.dart';

final streamUrl =
    'http://media.emit.com/pbs/tomorrow-land/202005081300/aac_mid.m4a';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'From File path',
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
  String? downloadedFilePath;
  String? downloadingProgress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Player(streamUrl),
          ],
        ),
      ),
    );
  }
}

class Player extends StatefulWidget {
  final String streamPath;

  Player(this.streamPath);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  final AssetsAudioPlayer _player = AssetsAudioPlayer.newPlayer();

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    try {
      _player.onErrorDo = (error) {
        error.player.stop();
      };
      await _player.open(
        Audio.liveStream(widget.streamPath,
            metas: Metas(
                title: 'title',
                album: 'album',
                artist: 'artist',
                image: MetasImage.network(
                    'https://i.pinimg.com/564x/e3/77/94/e377940a4c2417221d04c47e5a52d2d4.jpg'))),
        autoStart: false,
        showNotification: true,
        notificationSettings: NotificationSettings(
            nextEnabled: false, prevEnabled: false, stopEnabled: false),
      );
    } catch (t) {
      print(t);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PlayerBuilder.isBuffering(
          player: _player,
          builder: (context, isBuffering) {
            if (isBuffering) {
              return Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 8,
                  ),
                  Text('Buffering'),
                ],
              );
            } else {
              return SizedBox(); //empty
            }
          },
        ),
        PlayerBuilder.isPlaying(
          player: _player,
          builder: (context, isPlaying) {
            return FloatingActionButton(
              onPressed: () async {
                try {
                  await _player.playOrPause();
                } catch (t) {
                  print(t);
                }
              },
              child: isPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
            );
          },
        ),
      ],
    );
  }
}
