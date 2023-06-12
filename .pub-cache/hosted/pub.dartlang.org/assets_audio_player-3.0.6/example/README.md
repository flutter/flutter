# assets_audio_player_example

Demonstrates how to use the assets_audio_player plugin.

```Dart
class _MyAppState extends State<MyApp> {
  
  final assets = <String>[
    "song1.mp3",
    "song2.mp3",
    "song3.mp3",
  ];
  final AssetsAudioPlayer _assetsAudioPlayer = AssetsAudioPlayer();

  var _currentAssetPosition = -1;

  void _open(int assetIndex) {
    _currentAssetPosition = assetIndex % assets.length;
    _assetsAudioPlayer.open(
      AssetsAudio(
        asset: assets[_currentAssetPosition],
        folder: "assets/audios/",
      ),
    );
  }

  void _playPause() {
    _assetsAudioPlayer.playOrPause();
  }

  void _next() {
    _currentAssetPosition++;
    _open(_currentAssetPosition);
  }

  void _prev() {
    _currentAssetPosition--;
    _open(_currentAssetPosition);
  }

  @override
  void dispose() {
    _assetsAudioPlayer.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Padding(
          padding: const EdgeInsets.only(bottom: 48.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: StreamBuilder(
                  stream: _assetsAudioPlayer.current,
                  initialData: const PlayingAudio(),
                  builder: (BuildContext context,
                      AsyncSnapshot<PlayingAudio> snapshot) {
                    final PlayingAudio currentAudio = snapshot.data;
                    return ListView.builder(
                      itemBuilder: (context, position) {
                        return ListTile(
                            title: Text(assets[position],
                                style: TextStyle(
                                    color: assets[position] ==
                                            currentAudio.assetAudio.asset
                                        ? Colors.blue
                                        : Colors.black)),
                            onTap: () {
                              _open(position);
                            });
                      },
                      itemCount: assets.length,
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  StreamBuilder(
                    stream: _assetsAudioPlayer.currentPosition,
                    initialData: const Duration(),
                    builder: (BuildContext context,
                        AsyncSnapshot<Duration> snapshot) {
                      Duration duration = snapshot.data;
                      return Text(durationToString(duration));
                    },
                  ),
                  Text(" - "),
                  StreamBuilder(
                    stream: _assetsAudioPlayer.current,
                    builder: (BuildContext context,
                        AsyncSnapshot<PlayingAudio> snapshot) {
                      Duration duration = Duration();
                      if (snapshot.hasData) {
                        duration = snapshot.data.duration;
                      }
                      return Text(durationToString(duration));
                    },
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
                  IconButton(
                    onPressed: _prev,
                    icon: Icon(AssetAudioPlayerIcons.to_start),
                  ),
                  StreamBuilder(
                    stream: _assetsAudioPlayer.isPlaying,
                    initialData: false,
                    builder:
                        (BuildContext context, AsyncSnapshot<bool> snapshot) {
                      return IconButton(
                        onPressed: _playPause,
                        icon: Icon(snapshot.data
                            ? AssetAudioPlayerIcons.pause
                            : AssetAudioPlayerIcons.play),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(AssetAudioPlayerIcons.to_end),
                    onPressed: _next,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.io/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.io/docs/cookbook)

For help getting started with Flutter, view our 
[online documentation](https://flutter.io/docs), which offers tutorials, 
samples, guidance on mobile development, and a full API reference.

