// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:mojo/mojo/url_response.mojom.dart';
import 'package:sky_services/media/media.mojom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

// All of these sounds are marked as public domain at soundbible.
const String chimes = "http://soundbible.com/grab.php?id=2030&type=wav";
const String chainsaw = "http://soundbible.com/grab.php?id=1391&type=wav";
const String stag = "http://soundbible.com/grab.php?id=2073&type=wav";
const String frogs = "http://soundbible.com/grab.php?id=2033&type=wav";
const String rattle = "http://soundbible.com/grab.php?id=2037&type=wav";
const String iLoveYou = "http://soundbible.com/grab.php?id=2045&type=wav";

class PianoKey {
  PianoKey(this.color, this.soundUrl);

  final Color color;
  final String soundUrl;

  final MediaPlayerProxy player = new MediaPlayerProxy.unbound();

  bool get isPlayerOpen => player.impl.isOpen;

  void down() {
    if (!isPlayerOpen) return;
    player.ptr.seekTo(0);
    player.ptr.start();
  }

  void up() {
    if (!isPlayerOpen) return;
    player.ptr.pause();
  }

  Future load(MediaServiceProxy mediaService) async {
    try {
      mediaService.ptr.createPlayer(player);
      UrlResponse response = await fetchUrl(soundUrl);
      await player.ptr.prepare(response.body);
    } catch (e) {
      print("Error: failed to load sound file $soundUrl");
      player.close();
    }
  }
}

class PianoApp extends StatelessComponent {
  final List<PianoKey> keys = <PianoKey>[
    new PianoKey(Colors.red[500], chimes),
    new PianoKey(Colors.orange[500], chainsaw),
    new PianoKey(Colors.yellow[500], stag),
    new PianoKey(Colors.green[500], frogs),
    new PianoKey(Colors.blue[500], rattle),
    new PianoKey(Colors.purple[500], iLoveYou),
  ];

  Future loadSounds() async {
    MediaServiceProxy mediaService = new MediaServiceProxy.unbound();
    try {
      shell.connectToService(null, mediaService);
      List<Future<MediaPlayerPrepareResponseParams>> pending = <Future<MediaPlayerPrepareResponseParams>>[];
      for (PianoKey key in keys)
        pending.add(key.load(mediaService));
      await Future.wait(pending);
    } finally {
      mediaService.close();
    }
  }

  Widget build(BuildContext context) {
    List<Widget> children = <Widget>[];
    for (PianoKey key in keys) {
      children.add(new Flexible(
        child: new Listener(
          child: new Container(
            decoration: new BoxDecoration(backgroundColor: key.color)
          ),
          onPointerCancel: (_) => key.up(),
          onPointerDown: (_) => key.down(),
          onPointerUp: (_) => key.up()
        )
      ));
    }
    return new Column(children);
  }
}

Widget statusBox(Widget child) {
  const mediumGray = const Color(0xff555555);
  const darkGray = const Color(0xff222222);
  return new Center(
    child: new Container(
      decoration: const BoxDecoration(
        boxShadow: const <BoxShadow>[
          const BoxShadow(
            color: mediumGray, offset: const Offset(6.0, 6.0), blurRadius: 5.0)
        ],
        backgroundColor: darkGray
      ),
      height: 90.0,
      padding: const EdgeDims.all(8.0),
      margin: const EdgeDims.symmetric(horizontal: 50.0),
      child: new Center(child: child)
    )
  );
}

Widget splashScreen() {
  return statusBox(
    new Text(
      'Loading sound files!',
      style: new TextStyle(fontSize: 18.0)
    )
  );
}

main() async {
  runApp(splashScreen());

  PianoApp app = new PianoApp();
  // use "await" to make sure the sound files are loaded before we show the ui.
  await app.loadSounds();
  runApp(app);
  // runApp() returns immediately so you can't put application cleanup code
  // here.  Android apps can be killed at any time, so there's also no way to
  // catch a close event to do cleanup. Therefore, although we appear to be
  // leaking the "player" handles, this is working as intended and the operating
  // system will clean up when the activity is killed.
}
