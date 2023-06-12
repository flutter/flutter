import 'dart:async';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:assets_audio_player_example/player/PlaySpeedSelector.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';

import 'player/ForwardRewindSelector.dart';
import 'player/PlayingControls.dart';
import 'player/PositionSeekWidget.dart';
import 'player/SongsSelector.dart';
import 'player/VolumeSelector.dart';

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
    Audio(
      'assets/audios/hiphop.mp3',
      metas: Metas(
        title: 'HipHop',
        artist: 'Florent Champigny',
        album: 'HipHopAlbum',
        image: MetasImage.network(
            'https://beyoudancestudio.ch/wp-content/uploads/2019/01/apprendre-danser.hiphop-1.jpg'),
      ),
    ),
    Audio(
      'assets/audios/pop.mp3',
      metas: Metas(
        title: 'Pop',
        artist: 'Florent Champigny',
        album: 'PopAlbum',
        image: MetasImage.network(
            'https://image.shutterstock.com/image-vector/pop-music-text-art-colorful-600w-515538502.jpg'),
      ),
    ),
    Audio(
      'assets/audios/instrumental.mp3',
      metas: Metas(
        title: 'Instrumental',
        artist: 'Florent Champigny',
        album: 'InstrumentalAlbum',
        image: MetasImage.network(
            'https://99designs-blog.imgix.net/blog/wp-content/uploads/2017/12/attachment_68585523.jpg'),
      ),
    ),
  ];

  final AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
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
    super.initState();
  }

  @override
  void dispose() {
    _assetsAudioPlayer.dispose();
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
          child: Padding(
            padding: const EdgeInsets.only(bottom: 48.0),
            child: Column(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  height: 20,
                ),
                Stack(
                  fit: StackFit.passthrough,
                  children: <Widget>[
                    StreamBuilder(
                      stream: _assetsAudioPlayer.current,
                      builder: (BuildContext context,
                          AsyncSnapshot<Playing?> snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final playing = snapshot.data!;
                        final myAudio =
                            find(audios, playing.audio.assetAudioPath);
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Neumorphic(
                            style: NeumorphicStyle(
                              depth: 8,
                              surfaceIntensity: 1,
                              shape: NeumorphicShape.concave,
                              boxShape: NeumorphicBoxShape.circle(),
                            ),
                            child: myAudio.metas.image?.path == null
                                ? const SizedBox()
                                : myAudio.metas.image?.type == ImageType.network
                                    ? Image.network(
                                        myAudio.metas.image!.path,
                                        height: 150,
                                        width: 150,
                                        fit: BoxFit.contain,
                                      )
                                    : Image.asset(
                                        myAudio.metas.image!.path,
                                        height: 150,
                                        width: 150,
                                        fit: BoxFit.contain,
                                      ),
                          ),
                        );
                      },
                    ),
                    Align(
                      alignment: Alignment.topRight,
                      child: NeumorphicButton(
                        style: NeumorphicStyle(
                          boxShape: NeumorphicBoxShape.circle(),
                        ),
                        padding: EdgeInsets.all(18),
                        margin: EdgeInsets.all(18),
                        onPressed: () {
                          AssetsAudioPlayer.playAndForget(
                              Audio('assets/audios/horn.mp3'));
                        },
                        child: Icon(
                          Icons.add_alert,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 20,
                ),
                SizedBox(
                  height: 20,
                ),
                StreamBuilder(
                    stream: _assetsAudioPlayer.current,
                    builder: (context, AsyncSnapshot<Playing?> snapshot) {
                      if (!snapshot.hasData) return const SizedBox();

                      final playing = snapshot.data!;
                      return Column(
                        children: <Widget>[
                          StreamBuilder(
                            stream: _assetsAudioPlayer.loopMode,
                            initialData: LoopMode.none,
                            builder: (context,
                                AsyncSnapshot<LoopMode> snapshotLooping) {
                              if (!snapshotLooping.hasData) {
                                return const SizedBox();
                              }
                              final loopMode = snapshotLooping.data!;
                              return StreamBuilder(
                                  stream: _assetsAudioPlayer.isPlaying,
                                  initialData: false,
                                  builder: (context,
                                      AsyncSnapshot<bool> snapshotPlaying) {
                                    if (!snapshotPlaying.hasData) {
                                      return const SizedBox();
                                    }
                                    final isPlaying = snapshotPlaying.data!;
                                    return PlayingControls(
                                      loopMode: loopMode,
                                      isPlaying: isPlaying,
                                      isPlaylist:
                                          playing.playlist.audios.length > 1,
                                      toggleLoop: () {
                                        _assetsAudioPlayer.toggleLoop();
                                      },
                                      onPlay: () {
                                        _assetsAudioPlayer.playOrPause();
                                      },
                                      onNext: () {
                                        //_assetsAudioPlayer.forward(Duration(seconds: 10));
                                        _assetsAudioPlayer.next();
                                      },
                                      onPrevious: () {
                                        _assetsAudioPlayer.previous();
                                      },
                                    );
                                  });
                            },
                          ),
                          StreamBuilder(
                              stream: _assetsAudioPlayer.realtimePlayingInfos,
                              builder: (context,
                                  AsyncSnapshot<RealtimePlayingInfos>
                                      snapshot) {
                                if (!snapshot.hasData) {
                                  return const SizedBox();
                                }
                                final infos = snapshot.data!;
                                // print('infos: $infos');
                                return PositionSeekWidget(
                                  currentPosition: infos.currentPosition,
                                  duration: infos.duration,
                                  seekTo: (to) {
                                    _assetsAudioPlayer.seek(to);
                                  },
                                );
                              }),
                        ],
                      );
                    }),
                SizedBox(
                  height: 20,
                ),
                Expanded(
                  child: StreamBuilder(
                      stream: _assetsAudioPlayer.current,
                      builder: (BuildContext context,
                          AsyncSnapshot<Playing?> snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        final playing = snapshot.data!;
                        return SongsSelector(
                          audios: audios,
                          onPlaylistSelected: (myAudios) {
                            _assetsAudioPlayer.open(
                              Playlist(audios: myAudios),
                              showNotification: true,
                            );
                          },
                          onSelected: (myAudio) {
                            _assetsAudioPlayer.open(
                              myAudio,
                              autoStart: false,
                              respectSilentMode: true,
                              showNotification: true,
                            );
                          },
                          playing: playing,
                        );
                      }),
                ),
                StreamBuilder(
                    stream: _assetsAudioPlayer.volume,
                    initialData: AssetsAudioPlayer.defaultVolume,
                    builder: (context, AsyncSnapshot<double> snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final volume = snapshot.data!;
                      return VolumeSelector(
                        volume: volume,
                        onChange: (v) {
                          _assetsAudioPlayer.setVolume(v);
                        },
                      );
                    }),
                StreamBuilder(
                    stream: _assetsAudioPlayer.forwardRewindSpeed,
                    initialData: null,
                    builder: (context, AsyncSnapshot<double?> snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final speed = snapshot.data!;
                      return ForwardRewindSelector(
                        speed: speed,
                        onChange: (v) {
                          _assetsAudioPlayer.forwardOrRewind(v);
                        },
                      );
                    }),
                StreamBuilder(
                    stream: _assetsAudioPlayer.playSpeed,
                    initialData: AssetsAudioPlayer.defaultPlaySpeed,
                    builder: (context, AsyncSnapshot<double> snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final playSpeed = snapshot.data!;
                      return PlaySpeedSelector(
                        playSpeed: playSpeed,
                        onChange: (v) {
                          _assetsAudioPlayer.setPlaySpeed(v);
                        },
                      );
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
