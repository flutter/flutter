import 'dart:async';

import 'package:flutter/widgets.dart';

import '../assets_audio_player.dart';

class AudioWidget extends StatefulWidget {
  final Widget child;

  final Audio audio;

  final double volume;
  final bool play;
  final LoopMode loopMode;
  final Function(Duration current, Duration total)? onPositionChanged;

  final Function(Duration totalDuration)? onReadyToPlay;
  final Function()? onFinished;
  final Duration initialPosition;

  AudioWidget({
    Key? key,
    required this.audio,
    required this.child,
    this.volume = 1.0,
    this.play = true,
    this.loopMode = LoopMode.none,
    this.onPositionChanged,
    this.initialPosition = const Duration(),
    this.onReadyToPlay,
    this.onFinished,
  }) : super(key: key);

  AudioWidget.assets({
    Key? key,
    required this.child,
    required String path,
    String? package,
    this.volume = 1.0,
    this.play = true,
    this.loopMode = LoopMode.none,
    this.onPositionChanged,
    this.initialPosition = const Duration(),
    this.onReadyToPlay,
    this.onFinished,
  })  : audio = Audio(path, package: package),
        super(key: key);

  AudioWidget.network({
    Key? key,
    required this.child,
    required String url,
    this.volume = 1.0,
    this.play = true,
    this.loopMode = LoopMode.none,
    this.onPositionChanged,
    this.initialPosition = const Duration(),
    this.onReadyToPlay,
    this.onFinished,
  })  : audio = Audio.network(url),
        super(key: key);

  AudioWidget.file({
    Key? key,
    required this.child,
    required String path,
    this.volume = 1.0,
    this.play = true,
    this.loopMode = LoopMode.none,
    this.onPositionChanged,
    this.initialPosition = const Duration(),
    this.onReadyToPlay,
    this.onFinished,
  })  : audio = Audio.network(path),
        super(key: key);

  @override
  _AudioWidgetState createState() => _AudioWidgetState();

  AudioWidget copyWith({
    Widget? child,
    Audio? audio,
    double? volume,
    bool? play,
    LoopMode? loopMode,
    Function(Duration current, Duration total)? onPositionChanged,
    Function(Duration totalDuration)? onReadyToPlay,
    Function()? onFinished,
    Duration? initialPosition,
  }) {
    return AudioWidget(
      audio: audio ?? this.audio,
      loopMode: loopMode ?? this.loopMode,
      volume: volume ?? this.volume,
      play: play ?? this.play,
      onPositionChanged: onPositionChanged ?? this.onPositionChanged,
      onReadyToPlay: onReadyToPlay ?? this.onReadyToPlay,
      onFinished: onFinished ?? this.onFinished,
      initialPosition: initialPosition ?? this.initialPosition,
      child: child ?? this.child,
    );
  }
}

class _AudioWidgetState extends State<AudioWidget> {
  late AssetsAudioPlayer _player;
  StreamSubscription? _currentPositionSubscription;
  StreamSubscription? _onReadyToPlaySubscription;
  StreamSubscription? _playlistAudioFinishedSubscription;
  late Duration _totalDuration;

  @override
  void initState() {
    super.initState();
    _player = AssetsAudioPlayer.newPlayer();
    _open();
  }

  void _open() {
    _player.open(widget.audio,
        autoStart: widget.play,
        volume: widget.volume,
        seek: widget.initialPosition,
        loopMode: widget.loopMode);

    _onReadyToPlaySubscription?.cancel();
    _onReadyToPlaySubscription = null;
    _onReadyToPlaySubscription = _player.onReadyToPlay.listen((audio) {
      _totalDuration = audio?.duration ?? const Duration();
      if (widget.onReadyToPlay != null) {
        widget.onReadyToPlay!(_totalDuration);
      }
    });

    _playlistAudioFinishedSubscription?.cancel();
    _playlistAudioFinishedSubscription = null;
    _playlistAudioFinishedSubscription =
        _player.playlistAudioFinished.listen((event) {
      if (widget.onFinished != null) {
        widget.onFinished!();
      }
    });

    _currentPositionSubscription = _player.currentPosition.listen((current) {
      if (widget.onPositionChanged != null) {
        widget.onPositionChanged!(current, _totalDuration);
      }
    });
  }

  @override
  void didUpdateWidget(AudioWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    //if it's not the same path -> open the new one
    if (widget.audio != oldWidget.audio) {
      _player.stop();
      _clearSubscriptions();
      _open();
    } else {
      //handle pause/play
      if (widget.play != oldWidget.play) {
        if (widget.play) {
          _player.play();
        } else {
          _player.pause();
        }
      }

      //handle volume
      if (widget.volume != oldWidget.volume) {
        _player.setVolume(widget.volume);
      }

      //handle loop
      if (widget.loopMode != oldWidget.loopMode) {
        _player.setLoopMode(widget.loopMode);
      }

      //handle seek
      if (widget.initialPosition != oldWidget.initialPosition) {
        _player.seek(widget.initialPosition);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  void _clearSubscriptions() {
    _currentPositionSubscription?.cancel();
    _currentPositionSubscription = null;

    _playlistAudioFinishedSubscription?.cancel();
    _playlistAudioFinishedSubscription = null;

    _onReadyToPlaySubscription?.cancel();
    _onReadyToPlaySubscription = null;
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    _clearSubscriptions();
    super.dispose();
  }
}
