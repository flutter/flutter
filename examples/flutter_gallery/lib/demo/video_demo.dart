// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:device_info/device_info.dart';

// TODO(sigurdm): These should not be stored here.
const String butterflyUri =
    'https://flutter.github.io/assets-for-api-docs/videos/butterfly.mp4';

const String beeUri =
    'https://flutter.github.io/assets-for-api-docs/videos/bee.mp4';

class VideoCard extends StatelessWidget {
  final VideoPlayerController controller;
  final String title;
  final String subtitle;

  const VideoCard({Key key, this.controller, this.title, this.subtitle})
      : super(key: key);

  Widget _buildInlineVideo() {
    return new Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 30.0),
      child: new Center(
        child: new AspectRatio(
          aspectRatio: 3 / 2,
          child: new Hero(
            tag: controller,
            child: new VideoPlayerLoading(controller),
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenVideo() {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(title),
      ),
      body: new Center(
        child: new AspectRatio(
          aspectRatio: 3 / 2,
          child: new Hero(
            tag: controller,
            child: new VideoPlayPause(controller),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget fullScreenRoutePageBuilder(BuildContext context,
        Animation<double> animation, Animation<double> secondaryAnimation) {
      return _buildFullScreenVideo();
    }

    void pushFullScreenWidget() {
      final TransitionRoute<Null> route = new PageRouteBuilder<Null>(
        settings: new RouteSettings(name: title, isInitialRoute: false),
        pageBuilder: fullScreenRoutePageBuilder,
      );

      route.completed.then((Null _) {
        controller.setVolume(0.0);
      });

      controller.setVolume(1.0);
      Navigator.of(context).push(route);
    }

    return new SafeArea(
      top: false,
      bottom: false,
      child: new Card(
        child: new Column(
          children: <Widget>[
            new ListTile(title: new Text(title), subtitle: new Text(subtitle)),
            new GestureDetector(
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
  final VideoPlayerController controller;

  const VideoPlayerLoading(this.controller);

  @override
  _VideoPlayerLoadingState createState() => new _VideoPlayerLoadingState();
}

class _VideoPlayerLoadingState extends State<VideoPlayerLoading> {
  bool _initialized;

  @override
  void initState() {
    super.initState();
    _initialized = widget.controller.value.initialized;
    widget.controller.addListener(() {
      if (!mounted) {
        return;
      }
      final bool controllerInitialized = widget.controller.value.initialized;
      if (_initialized != controllerInitialized) {
        setState(() {
          _initialized = controllerInitialized;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized) {
      return new VideoPlayer(widget.controller);
    }
    return new Stack(
      children: <Widget>[
        new VideoPlayer(widget.controller),
        const Center(child: const CircularProgressIndicator()),
      ],
      fit: StackFit.expand,
    );
  }
}

class VideoPlayPause extends StatefulWidget {
  final VideoPlayerController controller;

  const VideoPlayPause(this.controller);

  @override
  State createState() => new _VideoPlayPauseState();
}

class _VideoPlayPauseState extends State<VideoPlayPause> {
  FadeAnimation imageFadeAnimation;
  VoidCallback listener;

  _VideoPlayPauseState() {
    listener = () {
      setState(() {});
    };
  }

  VideoPlayerController get controller => widget.controller;

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
    return new Stack(
      alignment: Alignment.bottomCenter,
      fit: StackFit.expand,
      children: <Widget>[
        new GestureDetector(
          child: new VideoPlayerLoading(controller),
          onTap: () {
            if (!controller.value.initialized) {
              return;
            }
            if (controller.value.isPlaying) {
              imageFadeAnimation = new FadeAnimation(
                child: new Icon(Icons.pause, size: 100.0),
              );
              controller.pause();
            } else {
              imageFadeAnimation = new FadeAnimation(
                child: new Icon(Icons.play_arrow, size: 100.0),
              );
              controller.play();
            }
          },
        ),
        new Center(child: imageFadeAnimation),
      ],
    );
  }
}

class FadeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FadeAnimation({
    this.child,
    this.duration: const Duration(milliseconds: 500),
  });

  @override
  _FadeAnimationState createState() => new _FadeAnimationState();
}

class _FadeAnimationState extends State<FadeAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController = new AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    animationController.addListener(() {
      if (mounted) {
        setState(() {});
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
        ? new Opacity(
            opacity: 1.0 - animationController.value,
            child: widget.child,
          )
        : new Container();
  }
}

class ConnectivityOverlay extends StatefulWidget {
  final Widget child;
  final Completer<Null> connectedCompleter;
  final GlobalKey<ScaffoldState> scaffoldKey;

  const ConnectivityOverlay({
    this.child,
    this.connectedCompleter,
    this.scaffoldKey,
  });

  @override
  _ConnectivityOverlayState createState() => new _ConnectivityOverlayState();
}

class _ConnectivityOverlayState extends State<ConnectivityOverlay> {
  StreamSubscription<ConnectivityResult> connectivitySubscription;
  bool connected = true;

  static const Widget errorSnackBar = const SnackBar(
    backgroundColor: Colors.red,
    content: const ListTile(
      title: const Text('No network'),
      subtitle: const Text(
        'To load the videos you must have an active network connection',
      ),
    ),
  );

  Stream<ConnectivityResult> connectivityStream() async* {
    final Connectivity connectivity = new Connectivity();
    ConnectivityResult previousResult = await connectivity.checkConnectivity();
    yield previousResult;
    await for (ConnectivityResult result
        in connectivity.onConnectivityChanged) {
      if (result != previousResult) {
        yield result;
        previousResult = result;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    connectivitySubscription = connectivityStream().listen(
      (ConnectivityResult connectivityResult) {
        if (!mounted) {
          return;
        }
        if (connectivityResult == ConnectivityResult.none) {
          widget.scaffoldKey.currentState.showSnackBar(errorSnackBar);
        } else {
          if (!widget.connectedCompleter.isCompleted) {
            widget.connectedCompleter.complete(null);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class VideoDemo extends StatefulWidget {
  const VideoDemo({Key key}) : super(key: key);

  static const String routeName = '/video';

  @override
  _VideoDemoState createState() => new _VideoDemoState();
}

final DeviceInfoPlugin deviceInfoPlugin = new DeviceInfoPlugin();

Future<bool> isIOSSimulator() async {
  return Platform.isIOS && !(await deviceInfoPlugin.iosInfo).isPhysicalDevice;
}

class _VideoDemoState extends State<VideoDemo>
    with SingleTickerProviderStateMixin {
  final VideoPlayerController butterflyController = new VideoPlayerController(
    butterflyUri,
  );
  final VideoPlayerController beeController = new VideoPlayerController(
    beeUri,
  );

  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
  final Completer<Null> connectedCompleter = new Completer<Null>();
  bool isSupported = true;

  @override
  void initState() {
    super.initState();

    Future<Null> initController(VideoPlayerController controller) async {
      controller.setLooping(true);
      controller.setVolume(0.0);
      controller.play();
      await connectedCompleter.future;
      await controller.initialize();
      setState(() {});
    }

    initController(butterflyController);
    initController(beeController);
    isIOSSimulator().then((bool result) {
      isSupported = !result;
    });
  }

  @override
  void dispose() {
    butterflyController.dispose();
    beeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: scaffoldKey,
      appBar: new AppBar(
        title: const Text('Videos'),
      ),
      body: isSupported
          ? new ConnectivityOverlay(
              child: new ListView(
                children: <Widget>[
                  new VideoCard(
                    title: 'Butterfly',
                    subtitle: '… flutters by',
                    controller: butterflyController,
                  ),
                  new VideoCard(
                    title: 'Bee',
                    subtitle: '… gently buzzing',
                    controller: beeController,
                  ),
                ],
              ),
              connectedCompleter: connectedCompleter,
              scaffoldKey: scaffoldKey,
            )
          : const Center(
              child: const Text(
                'The video demo is not supported on the iOS Simulator.',
              ),
            ),
    );
  }
}
