import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

import 'player/PlayingControls.dart';

void main() => runApp(
      NeumorphicTheme(
        theme: NeumorphicThemeData(
          intensity: 0.8,
          lightSource: LightSource.topLeft,
        ),
        child: MyApp(),
      ),
    );

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final audios = <Audio>[
    Audio.network(
      'https://files.freemusicarchive.org/storage-freemusicarchive-org/music/Music_for_Video/springtide/Sounds_strange_weird_but_unmistakably_romantic_Vol1/springtide_-_03_-_We_Are_Heading_to_the_East.mp3',
      metas: Metas(
        title: 'Online',
        artist: 'Florent Champigny',
        album: 'OnlineAlbum',
        image: MetasImage.network(
            'https://image.shutterstock.com/image-vector/pop-music-text-art-colorful-600w-515538502.jpg'),
      ),
    ),
    Audio(
      'assets/audios/rock.mp3',
      metas: Metas(
        title: 'Rock',
        artist: 'Florent Champigny',
        album: 'RockAlbum',
        image: MetasImage.network(
            'https://static.radio.fr/images/broadcasts/cb/ef/2075/c300.png'),
      ),
    ),
    Audio(
      'assets/audios/country.mp3',
      metas: Metas(
        title: 'Country',
        artist: 'Florent Champigny',
        album: 'CountryAlbum',
        image: MetasImage.asset('assets/images/country.jpg'),
      ),
    ),
    Audio(
      'assets/audios/electronic.mp3',
      metas: Metas(
        title: 'Electronic',
        artist: 'Florent Champigny',
        album: 'ElectronicAlbum',
        image: MetasImage.network(
            'https://99designs-blog.imgix.net/blog/wp-content/uploads/2017/12/attachment_68585523.jpg'),
      ),
    ),
  ];

  final AssetsAudioPlayerGroup _assetsAudioPlayerGroup =
      AssetsAudioPlayerGroup(updateNotification: (player, playing) async {
    return PlayerGroupMetas(
      title: 'title',
      subTitle: 'subtitle ${playing.length}',
      image: MetasImage.asset('assets/images/country.jpg'),
    );
  });
  //final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    /*
    _subscriptions.add(_assetsAudioPlayer.playlistFinished.listen((data) {
      print('finished : $data');
    }));
    _subscriptions.add(_assetsAudioPlayer.playlistAudioFinished.listen((data) {
      print('playlistAudioFinished : $data');
    }));
    _subscriptions.add(_assetsAudioPlayer.current.listen((data) {
      print('current : $data');
    }));
    _subscriptions.add(_assetsAudioPlayer.onReadyToPlay.listen((audio) {
      print('onRedayToPlay : $audio');
    }));
    _subscriptions.add(_assetsAudioPlayer.playerState.listen((playerState) {
      print('playerState : $playerState');
    }));
    */
    _assetsAudioPlayerGroup.addAll(audios);
    super.initState();
  }

  @override
  void dispose() {
    _assetsAudioPlayerGroup.dispose();
    super.dispose();
  }

  Audio find(List<Audio> source, String fromPath) {
    return source.firstWhere((element) => element.path == fromPath);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: NeumorphicTheme.baseColor(context),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 48.0),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                    height: 20,
                  ),
                  _assetsAudioPlayerGroup.builderIsPlaying(
                      builder: (context, bool? isPlaying) {
                    if (isPlaying == null) {
                      return SizedBox();
                    }
                    return Column(
                      children: <Widget>[
                        PlayingControls(
                          isPlaying: isPlaying,
                          isPlaylist: true,
                          onPlay: () {
                            _assetsAudioPlayerGroup.playOrPause();
                          },
                        )
                      ],
                    );
                  }),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
