// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:device_info/device_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoCard extends StatelessWidget {
  const VideoCard({ super.key, this.controller, this.title, this.subtitle });

  final VideoPlayerController? controller;
  final String? title;
  final String? subtitle;

  Widget _buildInlineVideo() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
      child: Center(
        child: AspectRatio(
          aspectRatio: 3 / 2,
          child: Hero(
            tag: controller!,
            child: VideoPlayerLoading(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenVideo() {
    return Scaffold(
      appBar: AppBar(
        title: Text(title!),
      ),
      body: Center(
        child: AspectRatio(
          aspectRatio: 3 / 2,
          child: Hero(
            tag: controller!,
            child: VideoPlayPause(controller),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget fullScreenRoutePageBuilder(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      return _buildFullScreenVideo();
    }

    void pushFullScreenWidget() {
      final TransitionRoute<void> route = PageRouteBuilder<void>(
        settings: RouteSettings(name: title),
        pageBuilder: fullScreenRoutePageBuilder,
      );

      route.completed.then((void value) {
        controller!.setVolume(0.0);
      });

      controller!.setVolume(1.0);
      Navigator.of(context).push(route);
    }

    return SafeArea(
      top: false,
      bottom: false,
      child: Card(
        child: Column(
          children: <Widget>[
            ListTile(title: Text(title!), subtitle: Text(subtitle!)),
            GestureDetector(
              onTap: pushFullScreenWidget,
              child: _buildInlineVideo(),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerLoading extends StatefulWidget {
  const VideoPlayerLoading(this.controller, {super.key});

  final VideoPlayerController? controller;

  @override
  State<VideoPlayerLoading> createState() => _VideoPlayerLoadingState();
}

class _VideoPlayerLoadingState extends State<VideoPlayerLoading> {
  bool? _initialized;

  @override
  void initState() {
    super.initState();
    _initialized = widget.controller!.value.isInitialized;
    widget.controller!.addListener(() {
      if (!mounted) {
        return;
      }
      final bool controllerInitialized = widget.controller!.value.isInitialized;
      if (_initialized != controllerInitialized) {
        setState(() {
          _initialized = controllerInitialized;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized!) {
      return VideoPlayer(widget.controller!);
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        VideoPlayer(widget.controller!),
        const Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class VideoPlayPause extends StatefulWidget {
  const VideoPlayPause(this.controller, {super.key});

  final VideoPlayerController? controller;

  @override
  State createState() => _VideoPlayPauseState();
}

class _VideoPlayPauseState extends State<VideoPlayPause> {
  _VideoPlayPauseState() {
    listener = () {
      if (mounted)
        setState(() { });
    };
  }

  FadeAnimation? imageFadeAnimation;
  late VoidCallback listener;

  VideoPlayerController? get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    controller!.addListener(listener);
  }

  @override
  void deactivate() {
    controller!.removeListener(listener);
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      fit: StackFit.expand,
      children: <Widget>[
        GestureDetector(
          child: VideoPlayerLoading(controller),
          onTap: () {
            if (!controller!.value.isInitialized) {
              return;
            }
            if (controller!.value.isPlaying) {
              imageFadeAnimation = const FadeAnimation(
                child: Icon(Icons.pause, size: 100.0),
              );
              controller!.pause();
            } else {
              imageFadeAnimation = const FadeAnimation(
                child: Icon(Icons.play_arrow, size: 100.0),
              );
              controller!.play();
            }
          },
        ),
        Center(child: imageFadeAnimation),
      ],
    );
  }
}

class FadeAnimation extends StatefulWidget {
  const FadeAnimation({
    super.key,
    this.child,
    this.duration = const Duration(milliseconds: 500),
  });

  final Widget? child;
  final Duration duration;

  @override
  State<FadeAnimation> createState() => _FadeAnimationState();
}

class _FadeAnimationState extends State<FadeAnimation> with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    animationController.addListener(() {
      if (mounted) {
        setState(() { });
      }
    });
    animationController.forward(from: 0.0);
  }

  @override
  void deactivate() {
    animationController.stop();
    super.deactivate();
  }

  @override
  void didUpdateWidget(FadeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.child != widget.child) {
      animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return animationController.isAnimating
        ? Opacity(
            opacity: 1.0 - animationController.value,
            child: widget.child,
          )
        : Container();
  }
}

class ConnectivityOverlay extends StatefulWidget {
  const ConnectivityOverlay({
    super.key,
    this.child,
    this.connectedCompleter,
  });

  final Widget? child;
  final Completer<void>? connectedCompleter;

  @override
  State<ConnectivityOverlay> createState() => _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay> {
  StreamSubscription<ConnectivityResult>? connectivitySubscription;
  bool connected = true;

  static const SnackBar errorSnackBar = SnackBar(
    backgroundColor: Colors.red,
    content: ListTile(
      title: Text('No network'),
      subtitle: Text(
        'To load the videos you must have an active network connection',
      ),
    ),
  );

  Stream<ConnectivityResult> connectivityStream() async* {
    final Connectivity connectivity = Connectivity();
    ConnectivityResult previousResult = await connectivity.checkConnectivity();
    yield previousResult;
    await for (final ConnectivityResult result in connectivity.onConnectivityChanged) {
      if (result != previousResult) {
        yield result;
        previousResult = result;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Assume connectivity
      // TODO(ditman): Remove this shortcut when `connectivity` support for web
      // lands, https://github.com/flutter/flutter/issues/46735
      if (!widget.connectedCompleter!.isCompleted) {
        widget.connectedCompleter!.complete();
      }
      return;
    }
    connectivitySubscription = connectivityStream().listen(
      (ConnectivityResult connectivityResult) {
        if (!mounted) {
          return;
        }
        if (connectivityResult == ConnectivityResult.none) {
          ScaffoldMessenger.of(context).showSnackBar(errorSnackBar);
        } else {
          if (!widget.connectedCompleter!.isCompleted) {
            widget.connectedCompleter!.complete();
          }
        }
      },
    );
  }

  @override
  void dispose() {
    connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child!;
}

class VideoDemo extends StatefulWidget {
  const VideoDemo({ super.key });

  static const String routeName = '/video';

  @override
  State<VideoDemo> createState() => _VideoDemoState();
}

final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

Future<bool> isIOSSimulator() async {
  return !kIsWeb &&
      Platform.isIOS &&
      !(await deviceInfoPlugin.iosInfo).isPhysicalDevice;
}

class _VideoDemoState extends State<VideoDemo> with SingleTickerProviderStateMixin {
  final VideoPlayerController butterflyController = VideoPlayerController.asset(
    'videos/butterfly.mp4',
    package: 'flutter_gallery_assets',
    videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
  );

  // TODO(sigurdm): This should not be stored here.
  static const String beeUri = 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
  final VideoPlayerController beeController = VideoPlayerController.network(
    beeUri,
    videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
  );

  final Completer<void> connectedCompleter = Completer<void>();
  bool isSupported = true;
  bool isDisposed = false;

  @override
  void initState() {
    super.initState();

    Future<void> initController(VideoPlayerController controller, String name) async {
      controller.setLooping(true);
      controller.setVolume(0.0);
      controller.play();
      await connectedCompleter.future;
      await controller.initialize();
      if (mounted) {
        setState(() { });
      }
    }

    initController(butterflyController, 'butterfly');
    initController(beeController, 'bee');
    isIOSSimulator().then((bool result) {
      isSupported = !result;
    });
  }

  @override
  void dispose() {
    isDisposed  = true;
    butterflyController.dispose();
    beeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Videos'),
      ),
      body: isSupported
        ? ConnectivityOverlay(
            connectedCompleter: connectedCompleter,
            child: Scrollbar(
              child: ListView(
                children: <Widget>[
                  VideoCard(
                    title: 'Butterfly',
                    subtitle: '… flutters by',
                    controller: butterflyController,
                  ),
                  VideoCard(
                    title: 'Bee',
                    subtitle: '… gently buzzing',
                    controller: beeController,
                  ),
                ],
              ),
            ),
          )
        : const Center(
            child: Text(
              'Video playback not supported on the iOS Simulator.',
            ),
          ),
    );
  }
}
