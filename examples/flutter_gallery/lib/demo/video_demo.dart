// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

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
            child: new VideoPlayer(controller),
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
    return new Card(
      child: new Column(
        children: <Widget>[
          new GestureDetector(
            onTap: () {
              final TransitionRoute<Null> route = new PageRouteBuilder<Null>(
                pageBuilder: (BuildContext context, Animation<double> animation,
                    Animation<double> secondaryAnimation) {
                  return _buildFullScreenVideo();
                },
                transitionsBuilder: (BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                    Widget child) {
                  controller.setVolume(animation.value);
                  return child;
                },
              );
              route.completed.then((Null _) {
                controller.setVolume(0.0);
              });
              Navigator.of(context).push(route);
            },
            child: _buildInlineVideo(),
          ),
        ],
      ),
    );
  }
}

class FadeVolumePageRoute extends PageRouteBuilder<Null> {
  final VideoPlayerController videoController;
  FadeVolumePageRoute({
    RouteSettings settings: const RouteSettings(),
    RoutePageBuilder pageBuilder,
    RouteTransitionsBuilder transitionsBuilder,
    this.videoController,
  })
      : super(
            settings: settings,
            pageBuilder: pageBuilder,
            transitionsBuilder: transitionsBuilder);

  @override
  void dispose() {
    videoController.setVolume(0.0);
    super.dispose();
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
    final List<Widget> children = <Widget>[
      new GestureDetector(
        child: new VideoPlayer(controller),
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
                child: new Icon(Icons.play_arrow, size: 100.0));
            controller.play();
          }
        },
      ),
      new Align(
          alignment: Alignment.bottomCenter,
          child: new SizedBox(
              height: 20.0,
              width: double.INFINITY,
              child: new VideoProgressBar(controller))),
      new Center(child: imageFadeAnimation),
    ];

    if (!controller.value.initialized) {
      children.add(new Container());
    }

    return new Stack(
      alignment: Alignment.bottomCenter,
      fit: StackFit.passthrough,
      children: children,
    );
  }
}

class FadeAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const FadeAnimation(
      {this.child, this.duration: const Duration(milliseconds: 500)});

  @override
  _FadeAnimationState createState() => new _FadeAnimationState();
}

class _FadeAnimationState extends State<FadeAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController =
        new AnimationController(duration: widget.duration, vsync: this);
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

class VideoDemo extends StatefulWidget {
  const VideoDemo({Key key}) : super(key: key);

  static const String routeName = '/video';

  @override
  _VideoDemoState createState() => new _VideoDemoState();
}

class _VideoDemoState extends State<VideoDemo> {
  final VideoPlayerController butterflyController =
      new VideoPlayerController(butterflyUri);
  final VideoPlayerController beeController = new VideoPlayerController(beeUri);

  @override
  void initState() {
    super.initState();

    Future<Null> initController(VideoPlayerController controller) async {
      controller.setLooping(true);
      controller.setVolume(0.0);
      controller.play();
      await controller.initialize();
      setState(() {});
    }

    initController(butterflyController);
    initController(beeController);
  }

  @override
  void dispose() {
    butterflyController.dispose();
    beeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget inset(Widget child) {
      return new Padding(padding: const EdgeInsets.all(10.0), child: child);
    }

    final TextTheme textTheme = Theme.of(context).textTheme;

    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Videos'),
      ),
      body: new ListView(
        children: <Widget>[
          inset(
            new Text(
              'The Butterfly and the Bee',
              style: textTheme.headline,
            ),
          ),
          inset(new RichText(
              text: new TextSpan(style: textTheme.body1, children: [
            new TextSpan(text: 'Methought', style: textTheme.body2),
            const TextSpan(text: '''
I heard a butterfly
Say to a labouring bee:
"Thou hast no colours of the sky
On painted wings like me."''')
          ]))),
          new VideoCard(
            controller: butterflyController,
            title: 'The Butterfly',
            subtitle: '''''',
          ),
          inset(const Text('''
"Poor child of vanity! those dyes,
And colours bright and rare,"
With mild reproach, the bee replies,
"Are all beneath my care."''')),
          new VideoCard(
            controller: beeController,
            title: 'The Bee',
            subtitle: '''''',
          ),
          inset(
            const Text('''
"Content I toil from morn to eve,
And scorning idleness,
To tribes of gaudy sloth I leave
The vanity of dress."'''),
          ),
          inset(const Text('– William Lisle Bowles')),
        ],
      ),
    );
  }
}
