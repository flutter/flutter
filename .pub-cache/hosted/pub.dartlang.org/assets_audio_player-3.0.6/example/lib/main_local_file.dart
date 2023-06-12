import 'dart:io';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

final mp3Url =
    'https://files.freemusicarchive.org/storage-freemusicarchive-org/music/Music_for_Video/springtide/Sounds_strange_weird_but_unmistakably_romantic_Vol1/springtide_-_03_-_We_Are_Heading_to_the_East.mp3';
var dio = Dio();

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

  Widget _downloadButton() {
    return ElevatedButton.icon(
      onPressed: () async {
        final tempDir = await getTemporaryDirectory();
        final downloadPath = tempDir.path + '/#downloaded.mp3';
        print('full path $downloadPath');

        await downloadFileTo(
            dio: dio,
            url: mp3Url,
            savePath: downloadPath,
            progressFunction: (received, total) {
              if (total != -1) {
                setState(() {
                  downloadingProgress =
                      (received / total * 100).toStringAsFixed(0) + '%';
                });
              }
            });
        setState(() {
          downloadingProgress = null;
          downloadedFilePath = downloadPath;
        });
      },
      icon: Icon(
        Icons.file_download,
        color: Colors.white,
      ),
      style: ElevatedButton.styleFrom(primary: Colors.green),
      label: Text(
        'Dowload',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

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
            if (downloadedFilePath == null && downloadingProgress == null)
              _downloadButton()
            else if (downloadingProgress != null)
              Text(downloadingProgress!)
            else if (downloadedFilePath != null)
              Player(downloadedFilePath!),
          ],
        ),
      ),
    );
  }
}

class Player extends StatefulWidget {
  final String localPath;

  Player(this.localPath);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  final AssetsAudioPlayer _player = AssetsAudioPlayer.newPlayer();

  @override
  void initState() {
    super.initState();
    _player.open(
        Audio.file(widget.localPath, metas: Metas(title: 'hello world')),
        autoStart: false,
        showNotification: true);
  }

  @override
  Widget build(BuildContext context) {
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
  }
}

Future downloadFileTo(
    {required Dio dio,
    required String url,
    required String savePath,
    Function(int received, int total)? progressFunction}) async {
  try {
    final response = await dio.get(
      url,
      onReceiveProgress: progressFunction,
      //Received data with List<int>
      options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) {
            return (status ?? 0) < 500;
          }),
    );
    print(response.headers);
    final file = File(savePath);
    var raf = file.openSync(mode: FileMode.write);
    // response.data is List<int> type
    raf.writeFromSync(response.data);
    await raf.close();
  } catch (e) {
    print(e);
  }
}
