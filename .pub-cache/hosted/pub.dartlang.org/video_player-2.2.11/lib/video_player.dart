// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

export 'package:video_player_platform_interface/video_player_platform_interface.dart'
    show DurationRange, DataSourceType, VideoFormat, VideoPlayerOptions;

import 'src/closed_caption_file.dart';
export 'src/closed_caption_file.dart';

VideoPlayerPlatform? _lastVideoPlayerPlatform;

VideoPlayerPlatform get _videoPlayerPlatform {
  VideoPlayerPlatform currentInstance = VideoPlayerPlatform.instance;
  if (_lastVideoPlayerPlatform != currentInstance) {
    // This will clear all open videos on the platform when a full restart is
    // performed.
    currentInstance.init();
    _lastVideoPlayerPlatform = currentInstance;
  }
  return currentInstance;
}

/// The duration, current position, buffering state, error state and settings
/// of a [VideoPlayerController].
class VideoPlayerValue {
  /// Constructs a video with the given values. Only [duration] is required. The
  /// rest will initialize with default values when unset.
  VideoPlayerValue({
    required this.duration,
    this.size = Size.zero,
    this.position = Duration.zero,
    this.caption = Caption.none,
    this.buffered = const <DurationRange>[],
    this.isInitialized = false,
    this.isPlaying = false,
    this.isLooping = false,
    this.isBuffering = false,
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.errorDescription,
  });

  /// Returns an instance for a video that hasn't been loaded.
  VideoPlayerValue.uninitialized()
      : this(duration: Duration.zero, isInitialized: false);

  /// Returns an instance with the given [errorDescription].
  VideoPlayerValue.erroneous(String errorDescription)
      : this(
            duration: Duration.zero,
            isInitialized: false,
            errorDescription: errorDescription);

  /// The total duration of the video.
  ///
  /// The duration is [Duration.zero] if the video hasn't been initialized.
  final Duration duration;

  /// The current playback position.
  final Duration position;

  /// The [Caption] that should be displayed based on the current [position].
  ///
  /// This field will never be null. If there is no caption for the current
  /// [position], this will be a [Caption.none] object.
  final Caption caption;

  /// The currently buffered ranges.
  final List<DurationRange> buffered;

  /// True if the video is playing. False if it's paused.
  final bool isPlaying;

  /// True if the video is looping.
  final bool isLooping;

  /// True if the video is currently buffering.
  final bool isBuffering;

  /// The current volume of the playback.
  final double volume;

  /// The current speed of the playback.
  final double playbackSpeed;

  /// A description of the error if present.
  ///
  /// If [hasError] is false this is `null`.
  final String? errorDescription;

  /// The [size] of the currently loaded video.
  final Size size;

  /// Indicates whether or not the video has been loaded and is ready to play.
  final bool isInitialized;

  /// Indicates whether or not the video is in an error state. If this is true
  /// [errorDescription] should have information about the problem.
  bool get hasError => errorDescription != null;

  /// Returns [size.width] / [size.height].
  ///
  /// Will return `1.0` if:
  /// * [isInitialized] is `false`
  /// * [size.width], or [size.height] is equal to `0.0`
  /// * aspect ratio would be less than or equal to `0.0`
  double get aspectRatio {
    if (!isInitialized || size.width == 0 || size.height == 0) {
      return 1.0;
    }
    final double aspectRatio = size.width / size.height;
    if (aspectRatio <= 0) {
      return 1.0;
    }
    return aspectRatio;
  }

  /// Returns a new instance that has the same values as this current instance,
  /// except for any overrides passed in as arguments to [copyWidth].
  VideoPlayerValue copyWith({
    Duration? duration,
    Size? size,
    Duration? position,
    Caption? caption,
    List<DurationRange>? buffered,
    bool? isInitialized,
    bool? isPlaying,
    bool? isLooping,
    bool? isBuffering,
    double? volume,
    double? playbackSpeed,
    String? errorDescription,
  }) {
    return VideoPlayerValue(
      duration: duration ?? this.duration,
      size: size ?? this.size,
      position: position ?? this.position,
      caption: caption ?? this.caption,
      buffered: buffered ?? this.buffered,
      isInitialized: isInitialized ?? this.isInitialized,
      isPlaying: isPlaying ?? this.isPlaying,
      isLooping: isLooping ?? this.isLooping,
      isBuffering: isBuffering ?? this.isBuffering,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      errorDescription: errorDescription ?? this.errorDescription,
    );
  }

  @override
  String toString() {
    return '$runtimeType('
        'duration: $duration, '
        'size: $size, '
        'position: $position, '
        'caption: $caption, '
        'buffered: [${buffered.join(', ')}], '
        'isInitialized: $isInitialized, '
        'isPlaying: $isPlaying, '
        'isLooping: $isLooping, '
        'isBuffering: $isBuffering, '
        'volume: $volume, '
        'playbackSpeed: $playbackSpeed, '
        'errorDescription: $errorDescription)';
  }
}

/// Controls a platform video player, and provides updates when the state is
/// changing.
///
/// Instances must be initialized with initialize.
///
/// The video is displayed in a Flutter app by creating a [VideoPlayer] widget.
///
/// To reclaim the resources used by the player call [dispose].
///
/// After [dispose] all further calls are ignored.
class VideoPlayerController extends ValueNotifier<VideoPlayerValue> {
  /// Constructs a [VideoPlayerController] playing a video from an asset.
  ///
  /// The name of the asset is given by the [dataSource] argument and must not be
  /// null. The [package] argument must be non-null when the asset comes from a
  /// package and null otherwise.
  VideoPlayerController.asset(this.dataSource,
      {this.package, this.closedCaptionFile, this.videoPlayerOptions})
      : dataSourceType = DataSourceType.asset,
        formatHint = null,
        httpHeaders = const {},
        super(VideoPlayerValue(duration: Duration.zero));

  /// Constructs a [VideoPlayerController] playing a video from obtained from
  /// the network.
  ///
  /// The URI for the video is given by the [dataSource] argument and must not be
  /// null.
  /// **Android only**: The [formatHint] option allows the caller to override
  /// the video format detection code.
  /// [httpHeaders] option allows to specify HTTP headers
  /// for the request to the [dataSource].
  VideoPlayerController.network(
    this.dataSource, {
    this.formatHint,
    this.closedCaptionFile,
    this.videoPlayerOptions,
    this.httpHeaders = const {},
  })  : dataSourceType = DataSourceType.network,
        package = null,
        super(VideoPlayerValue(duration: Duration.zero));

  /// Constructs a [VideoPlayerController] playing a video from a file.
  ///
  /// This will load the file from the file-URI given by:
  /// `'file://${file.path}'`.
  VideoPlayerController.file(File file,
      {this.closedCaptionFile, this.videoPlayerOptions})
      : dataSource = 'file://${file.path}',
        dataSourceType = DataSourceType.file,
        package = null,
        formatHint = null,
        httpHeaders = const {},
        super(VideoPlayerValue(duration: Duration.zero));

  /// Constructs a [VideoPlayerController] playing a video from a contentUri.
  ///
  /// This will load the video from the input content-URI.
  /// This is supported on Android only.
  VideoPlayerController.contentUri(Uri contentUri,
      {this.closedCaptionFile, this.videoPlayerOptions})
      : assert(defaultTargetPlatform == TargetPlatform.android,
            'VideoPlayerController.contentUri is only supported on Android.'),
        dataSource = contentUri.toString(),
        dataSourceType = DataSourceType.contentUri,
        package = null,
        formatHint = null,
        httpHeaders = const {},
        super(VideoPlayerValue(duration: Duration.zero));

  /// The URI to the video file. This will be in different formats depending on
  /// the [DataSourceType] of the original video.
  final String dataSource;

  /// HTTP headers used for the request to the [dataSource].
  /// Only for [VideoPlayerController.network].
  /// Always empty for other video types.
  final Map<String, String> httpHeaders;

  /// **Android only**. Will override the platform's generic file format
  /// detection with whatever is set here.
  final VideoFormat? formatHint;

  /// Describes the type of data source this [VideoPlayerController]
  /// is constructed with.
  final DataSourceType dataSourceType;

  /// Provide additional configuration options (optional). Like setting the audio mode to mix
  final VideoPlayerOptions? videoPlayerOptions;

  /// Only set for [asset] videos. The package that the asset was loaded from.
  final String? package;

  /// Optional field to specify a file containing the closed
  /// captioning.
  ///
  /// This future will be awaited and the file will be loaded when
  /// [initialize()] is called.
  final Future<ClosedCaptionFile>? closedCaptionFile;

  ClosedCaptionFile? _closedCaptionFile;
  Timer? _timer;
  bool _isDisposed = false;
  Completer<void>? _creatingCompleter;
  StreamSubscription<dynamic>? _eventSubscription;
  late _VideoAppLifeCycleObserver _lifeCycleObserver;

  /// The id of a texture that hasn't been initialized.
  @visibleForTesting
  static const int kUninitializedTextureId = -1;
  int _textureId = kUninitializedTextureId;

  /// This is just exposed for testing. It shouldn't be used by anyone depending
  /// on the plugin.
  @visibleForTesting
  int get textureId => _textureId;

  /// Attempts to open the given [dataSource] and load metadata about the video.
  Future<void> initialize() async {
    _lifeCycleObserver = _VideoAppLifeCycleObserver(this);
    _lifeCycleObserver.initialize();
    _creatingCompleter = Completer<void>();

    late DataSource dataSourceDescription;
    switch (dataSourceType) {
      case DataSourceType.asset:
        dataSourceDescription = DataSource(
          sourceType: DataSourceType.asset,
          asset: dataSource,
          package: package,
        );
        break;
      case DataSourceType.network:
        dataSourceDescription = DataSource(
          sourceType: DataSourceType.network,
          uri: dataSource,
          formatHint: formatHint,
          httpHeaders: httpHeaders,
        );
        break;
      case DataSourceType.file:
        dataSourceDescription = DataSource(
          sourceType: DataSourceType.file,
          uri: dataSource,
        );
        break;
      case DataSourceType.contentUri:
        dataSourceDescription = DataSource(
          sourceType: DataSourceType.contentUri,
          uri: dataSource,
        );
        break;
    }

    if (videoPlayerOptions?.mixWithOthers != null) {
      await _videoPlayerPlatform
          .setMixWithOthers(videoPlayerOptions!.mixWithOthers);
    }

    _textureId = (await _videoPlayerPlatform.create(dataSourceDescription)) ??
        kUninitializedTextureId;
    _creatingCompleter!.complete(null);
    final Completer<void> initializingCompleter = Completer<void>();

    void eventListener(VideoEvent event) {
      if (_isDisposed) {
        return;
      }

      switch (event.eventType) {
        case VideoEventType.initialized:
          value = value.copyWith(
            duration: event.duration,
            size: event.size,
            isInitialized: event.duration != null,
          );
          initializingCompleter.complete(null);
          _applyLooping();
          _applyVolume();
          _applyPlayPause();
          break;
        case VideoEventType.completed:
          // In this case we need to stop _timer, set isPlaying=false, and
          // position=value.duration. Instead of setting the values directly,
          // we use pause() and seekTo() to ensure the platform stops playing
          // and seeks to the last frame of the video.
          pause().then((void pauseResult) => seekTo(value.duration));
          break;
        case VideoEventType.bufferingUpdate:
          value = value.copyWith(buffered: event.buffered);
          break;
        case VideoEventType.bufferingStart:
          value = value.copyWith(isBuffering: true);
          break;
        case VideoEventType.bufferingEnd:
          value = value.copyWith(isBuffering: false);
          break;
        case VideoEventType.unknown:
          break;
      }
    }

    if (closedCaptionFile != null) {
      if (_closedCaptionFile == null) {
        _closedCaptionFile = await closedCaptionFile;
      }
      value = value.copyWith(caption: _getCaptionAt(value.position));
    }

    void errorListener(Object obj) {
      final PlatformException e = obj as PlatformException;
      value = VideoPlayerValue.erroneous(e.message!);
      _timer?.cancel();
      if (!initializingCompleter.isCompleted) {
        initializingCompleter.completeError(obj);
      }
    }

    _eventSubscription = _videoPlayerPlatform
        .videoEventsFor(_textureId)
        .listen(eventListener, onError: errorListener);
    return initializingCompleter.future;
  }

  @override
  Future<void> dispose() async {
    if (_creatingCompleter != null) {
      await _creatingCompleter!.future;
      if (!_isDisposed) {
        _isDisposed = true;
        _timer?.cancel();
        await _eventSubscription?.cancel();
        await _videoPlayerPlatform.dispose(_textureId);
      }
      _lifeCycleObserver.dispose();
    }
    _isDisposed = true;
    super.dispose();
  }

  /// Starts playing the video.
  ///
  /// If the video is at the end, this method starts playing from the beginning.
  ///
  /// This method returns a future that completes as soon as the "play" command
  /// has been sent to the platform, not when playback itself is totally
  /// finished.
  Future<void> play() async {
    if (value.position == value.duration) {
      await seekTo(const Duration());
    }
    value = value.copyWith(isPlaying: true);
    await _applyPlayPause();
  }

  /// Sets whether or not the video should loop after playing once. See also
  /// [VideoPlayerValue.isLooping].
  Future<void> setLooping(bool looping) async {
    value = value.copyWith(isLooping: looping);
    await _applyLooping();
  }

  /// Pauses the video.
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
    await _applyPlayPause();
  }

  Future<void> _applyLooping() async {
    if (_isDisposedOrNotInitialized) {
      return;
    }
    await _videoPlayerPlatform.setLooping(_textureId, value.isLooping);
  }

  Future<void> _applyPlayPause() async {
    if (_isDisposedOrNotInitialized) {
      return;
    }
    if (value.isPlaying) {
      await _videoPlayerPlatform.play(_textureId);

      // Cancel previous timer.
      _timer?.cancel();
      _timer = Timer.periodic(
        const Duration(milliseconds: 500),
        (Timer timer) async {
          if (_isDisposed) {
            return;
          }
          final Duration? newPosition = await position;
          if (newPosition == null) {
            return;
          }
          _updatePosition(newPosition);
        },
      );

      // This ensures that the correct playback speed is always applied when
      // playing back. This is necessary because we do not set playback speed
      // when paused.
      await _applyPlaybackSpeed();
    } else {
      _timer?.cancel();
      await _videoPlayerPlatform.pause(_textureId);
    }
  }

  Future<void> _applyVolume() async {
    if (_isDisposedOrNotInitialized) {
      return;
    }
    await _videoPlayerPlatform.setVolume(_textureId, value.volume);
  }

  Future<void> _applyPlaybackSpeed() async {
    if (_isDisposedOrNotInitialized) {
      return;
    }

    // Setting the playback speed on iOS will trigger the video to play. We
    // prevent this from happening by not applying the playback speed until
    // the video is manually played from Flutter.
    if (!value.isPlaying) return;

    await _videoPlayerPlatform.setPlaybackSpeed(
      _textureId,
      value.playbackSpeed,
    );
  }

  /// The position in the current video.
  Future<Duration?> get position async {
    if (_isDisposed) {
      return null;
    }
    return await _videoPlayerPlatform.getPosition(_textureId);
  }

  /// Sets the video's current timestamp to be at [moment]. The next
  /// time the video is played it will resume from the given [moment].
  ///
  /// If [moment] is outside of the video's full range it will be automatically
  /// and silently clamped.
  Future<void> seekTo(Duration position) async {
    if (_isDisposedOrNotInitialized) {
      return;
    }
    if (position > value.duration) {
      position = value.duration;
    } else if (position < const Duration()) {
      position = const Duration();
    }
    await _videoPlayerPlatform.seekTo(_textureId, position);
    _updatePosition(position);
  }

  /// Sets the audio volume of [this].
  ///
  /// [volume] indicates a value between 0.0 (silent) and 1.0 (full volume) on a
  /// linear scale.
  Future<void> setVolume(double volume) async {
    value = value.copyWith(volume: volume.clamp(0.0, 1.0));
    await _applyVolume();
  }

  /// Sets the playback speed of [this].
  ///
  /// [speed] indicates a speed value with different platforms accepting
  /// different ranges for speed values. The [speed] must be greater than 0.
  ///
  /// The values will be handled as follows:
  /// * On web, the audio will be muted at some speed when the browser
  ///   determines that the sound would not be useful anymore. For example,
  ///   "Gecko mutes the sound outside the range `0.25` to `5.0`" (see https://developer.mozilla.org/en-US/docs/Web/API/HTMLMediaElement/playbackRate).
  /// * On Android, some very extreme speeds will not be played back accurately.
  ///   Instead, your video will still be played back, but the speed will be
  ///   clamped by ExoPlayer (but the values are allowed by the player, like on
  ///   web).
  /// * On iOS, you can sometimes not go above `2.0` playback speed on a video.
  ///   An error will be thrown for if the option is unsupported. It is also
  ///   possible that your specific video cannot be slowed down, in which case
  ///   the plugin also reports errors.
  Future<void> setPlaybackSpeed(double speed) async {
    if (speed < 0) {
      throw ArgumentError.value(
        speed,
        'Negative playback speeds are generally unsupported.',
      );
    } else if (speed == 0) {
      throw ArgumentError.value(
        speed,
        'Zero playback speed is generally unsupported. Consider using [pause].',
      );
    }

    value = value.copyWith(playbackSpeed: speed);
    await _applyPlaybackSpeed();
  }

  /// The closed caption based on the current [position] in the video.
  ///
  /// If there are no closed captions at the current [position], this will
  /// return an empty [Caption].
  ///
  /// If no [closedCaptionFile] was specified, this will always return an empty
  /// [Caption].
  Caption _getCaptionAt(Duration position) {
    if (_closedCaptionFile == null) {
      return Caption.none;
    }

    // TODO: This would be more efficient as a binary search.
    for (final caption in _closedCaptionFile!.captions) {
      if (caption.start <= position && caption.end >= position) {
        return caption;
      }
    }

    return Caption.none;
  }

  void _updatePosition(Duration position) {
    value = value.copyWith(position: position);
    value = value.copyWith(caption: _getCaptionAt(position));
  }

  @override
  void removeListener(VoidCallback listener) {
    // Prevent VideoPlayer from causing an exception to be thrown when attempting to
    // remove its own listener after the controller has already been disposed.
    if (!_isDisposed) {
      super.removeListener(listener);
    }
  }

  bool get _isDisposedOrNotInitialized => _isDisposed || !value.isInitialized;
}

class _VideoAppLifeCycleObserver extends Object with WidgetsBindingObserver {
  _VideoAppLifeCycleObserver(this._controller);

  bool _wasPlayingBeforePause = false;
  final VideoPlayerController _controller;

  void initialize() {
    _ambiguate(WidgetsBinding.instance)!.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _wasPlayingBeforePause = _controller.value.isPlaying;
        _controller.pause();
        break;
      case AppLifecycleState.resumed:
        if (_wasPlayingBeforePause) {
          _controller.play();
        }
        break;
      default:
    }
  }

  void dispose() {
    _ambiguate(WidgetsBinding.instance)!.removeObserver(this);
  }
}

/// Widget that displays the video controlled by [controller].
class VideoPlayer extends StatefulWidget {
  /// Uses the given [controller] for all video rendered in this widget.
  VideoPlayer(this.controller);

  /// The [VideoPlayerController] responsible for the video being rendered in
  /// this widget.
  final VideoPlayerController controller;

  @override
  _VideoPlayerState createState() => _VideoPlayerState();
}

class _VideoPlayerState extends State<VideoPlayer> {
  _VideoPlayerState() {
    _listener = () {
      final int newTextureId = widget.controller.textureId;
      if (newTextureId != _textureId) {
        setState(() {
          _textureId = newTextureId;
        });
      }
    };
  }

  late VoidCallback _listener;

  late int _textureId;

  @override
  void initState() {
    super.initState();
    _textureId = widget.controller.textureId;
    // Need to listen for initialization events since the actual texture ID
    // becomes available after asynchronous initialization finishes.
    widget.controller.addListener(_listener);
  }

  @override
  void didUpdateWidget(VideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.controller.removeListener(_listener);
    _textureId = widget.controller.textureId;
    widget.controller.addListener(_listener);
  }

  @override
  void deactivate() {
    super.deactivate();
    widget.controller.removeListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    return _textureId == VideoPlayerController.kUninitializedTextureId
        ? Container()
        : _videoPlayerPlatform.buildView(_textureId);
  }
}

/// Used to configure the [VideoProgressIndicator] widget's colors for how it
/// describes the video's status.
///
/// The widget uses default colors that are customizeable through this class.
class VideoProgressColors {
  /// Any property can be set to any color. They each have defaults.
  ///
  /// [playedColor] defaults to red at 70% opacity. This fills up a portion of
  /// the [VideoProgressIndicator] to represent how much of the video has played
  /// so far.
  ///
  /// [bufferedColor] defaults to blue at 20% opacity. This fills up a portion
  /// of [VideoProgressIndicator] to represent how much of the video has
  /// buffered so far.
  ///
  /// [backgroundColor] defaults to gray at 50% opacity. This is the background
  /// color behind both [playedColor] and [bufferedColor] to denote the total
  /// size of the video compared to either of those values.
  const VideoProgressColors({
    this.playedColor = const Color.fromRGBO(255, 0, 0, 0.7),
    this.bufferedColor = const Color.fromRGBO(50, 50, 200, 0.2),
    this.backgroundColor = const Color.fromRGBO(200, 200, 200, 0.5),
  });

  /// [playedColor] defaults to red at 70% opacity. This fills up a portion of
  /// the [VideoProgressIndicator] to represent how much of the video has played
  /// so far.
  final Color playedColor;

  /// [bufferedColor] defaults to blue at 20% opacity. This fills up a portion
  /// of [VideoProgressIndicator] to represent how much of the video has
  /// buffered so far.
  final Color bufferedColor;

  /// [backgroundColor] defaults to gray at 50% opacity. This is the background
  /// color behind both [playedColor] and [bufferedColor] to denote the total
  /// size of the video compared to either of those values.
  final Color backgroundColor;
}

class _VideoScrubber extends StatefulWidget {
  _VideoScrubber({
    required this.child,
    required this.controller,
  });

  final Widget child;
  final VideoPlayerController controller;

  @override
  _VideoScrubberState createState() => _VideoScrubberState();
}

class _VideoScrubberState extends State<_VideoScrubber> {
  bool _controllerWasPlaying = false;

  VideoPlayerController get controller => widget.controller;

  @override
  Widget build(BuildContext context) {
    void seekToRelativePosition(Offset globalPosition) {
      final RenderBox box = context.findRenderObject() as RenderBox;
      final Offset tapPos = box.globalToLocal(globalPosition);
      final double relative = tapPos.dx / box.size.width;
      final Duration position = controller.value.duration * relative;
      controller.seekTo(position);
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: widget.child,
      onHorizontalDragStart: (DragStartDetails details) {
        if (!controller.value.isInitialized) {
          return;
        }
        _controllerWasPlaying = controller.value.isPlaying;
        if (_controllerWasPlaying) {
          controller.pause();
        }
      },
      onHorizontalDragUpdate: (DragUpdateDetails details) {
        if (!controller.value.isInitialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        if (_controllerWasPlaying &&
            controller.value.position != controller.value.duration) {
          controller.play();
        }
      },
      onTapDown: (TapDownDetails details) {
        if (!controller.value.isInitialized) {
          return;
        }
        seekToRelativePosition(details.globalPosition);
      },
    );
  }
}

/// Displays the play/buffering status of the video controlled by [controller].
///
/// If [allowScrubbing] is true, this widget will detect taps and drags and
/// seek the video accordingly.
///
/// [padding] allows to specify some extra padding around the progress indicator
/// that will also detect the gestures.
class VideoProgressIndicator extends StatefulWidget {
  /// Construct an instance that displays the play/buffering status of the video
  /// controlled by [controller].
  ///
  /// Defaults will be used for everything except [controller] if they're not
  /// provided. [allowScrubbing] defaults to false, and [padding] will default
  /// to `top: 5.0`.
  VideoProgressIndicator(
    this.controller, {
    this.colors = const VideoProgressColors(),
    required this.allowScrubbing,
    this.padding = const EdgeInsets.only(top: 5.0),
  });

  /// The [VideoPlayerController] that actually associates a video with this
  /// widget.
  final VideoPlayerController controller;

  /// The default colors used throughout the indicator.
  ///
  /// See [VideoProgressColors] for default values.
  final VideoProgressColors colors;

  /// When true, the widget will detect touch input and try to seek the video
  /// accordingly. The widget ignores such input when false.
  ///
  /// Defaults to false.
  final bool allowScrubbing;

  /// This allows for visual padding around the progress indicator that can
  /// still detect gestures via [allowScrubbing].
  ///
  /// Defaults to `top: 5.0`.
  final EdgeInsets padding;

  @override
  _VideoProgressIndicatorState createState() => _VideoProgressIndicatorState();
}

class _VideoProgressIndicatorState extends State<VideoProgressIndicator> {
  _VideoProgressIndicatorState() {
    listener = () {
      if (!mounted) {
        return;
      }
      setState(() {});
    };
  }

  late VoidCallback listener;

  VideoPlayerController get controller => widget.controller;

  VideoProgressColors get colors => widget.colors;

  @override
  void initState() {
    super.initState();
    controller.addListener(listener);
  }

  @override
  void deactivate() {
    controller.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    Widget progressIndicator;
    if (controller.value.isInitialized) {
      final int duration = controller.value.duration.inMilliseconds;
      final int position = controller.value.position.inMilliseconds;

      int maxBuffering = 0;
      for (DurationRange range in controller.value.buffered) {
        final int end = range.end.inMilliseconds;
        if (end > maxBuffering) {
          maxBuffering = end;
        }
      }

      progressIndicator = Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          LinearProgressIndicator(
            value: maxBuffering / duration,
            valueColor: AlwaysStoppedAnimation<Color>(colors.bufferedColor),
            backgroundColor: colors.backgroundColor,
          ),
          LinearProgressIndicator(
            value: position / duration,
            valueColor: AlwaysStoppedAnimation<Color>(colors.playedColor),
            backgroundColor: Colors.transparent,
          ),
        ],
      );
    } else {
      progressIndicator = LinearProgressIndicator(
        value: null,
        valueColor: AlwaysStoppedAnimation<Color>(colors.playedColor),
        backgroundColor: colors.backgroundColor,
      );
    }
    final Widget paddedProgressIndicator = Padding(
      padding: widget.padding,
      child: progressIndicator,
    );
    if (widget.allowScrubbing) {
      return _VideoScrubber(
        child: paddedProgressIndicator,
        controller: controller,
      );
    } else {
      return paddedProgressIndicator;
    }
  }
}

/// Widget for displaying closed captions on top of a video.
///
/// If [text] is null, this widget will not display anything.
///
/// If [textStyle] is supplied, it will be used to style the text in the closed
/// caption.
///
/// Note: in order to have closed captions, you need to specify a
/// [VideoPlayerController.closedCaptionFile].
///
/// Usage:
///
/// ```dart
/// Stack(children: <Widget>[
///   VideoPlayer(_controller),
///   ClosedCaption(text: _controller.value.caption.text),
/// ]),
/// ```
class ClosedCaption extends StatelessWidget {
  /// Creates a a new closed caption, designed to be used with
  /// [VideoPlayerValue.caption].
  ///
  /// If [text] is null or empty, nothing will be displayed.
  const ClosedCaption({Key? key, this.text, this.textStyle}) : super(key: key);

  /// The text that will be shown in the closed caption, or null if no caption
  /// should be shown.
  /// If the text is empty the caption will not be shown.
  final String? text;

  /// Specifies how the text in the closed caption should look.
  ///
  /// If null, defaults to [DefaultTextStyle.of(context).style] with size 36
  /// font colored white.
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final text = this.text;
    if (text == null || text.isEmpty) {
      return SizedBox.shrink();
    }

    final TextStyle effectiveTextStyle = textStyle ??
        DefaultTextStyle.of(context).style.copyWith(
              fontSize: 36.0,
              color: Colors.white,
            );

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.only(bottom: 24.0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Color(0xB8000000),
            borderRadius: BorderRadius.circular(2.0),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.0),
            child: Text(text, style: effectiveTextStyle),
          ),
        ),
      ),
    );
  }
}

/// This allows a value of type T or T? to be treated as a value of type T?.
///
/// We use this so that APIs that have become non-nullable can still be used
/// with `!` and `?` on the stable branch.
// TODO(ianh): Remove this once we roll stable in late 2021.
T? _ambiguate<T>(T? value) => value;
