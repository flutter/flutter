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
  final audio = Audio.liveStream(
    'http://bbcmedia.ic.llnwd.net/stream/bbcmedia_radio1_mf_p',
    metas: Metas(
      title: 'Online',
      artist: 'Florent Champigny',
      album: 'OnlineAlbum',
      image: MetasImage.network(
          'https://image.shutterstock.com/image-vector/pop-music-text-art-colorful-600w-515538502.jpg'),
    ),
  );

  final AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();

  @override
  void initState() {
    _assetsAudioPlayer.open(audio, showNotification: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              audio.updateMetas(
                title: 'Online 2',
                artist: 'My artist',
              );
            },
            child: Text('Click'),
          ),
        ),
      ),
    );
  }
}
