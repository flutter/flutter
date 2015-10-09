// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mojo/mojo/url_response.mojom.dart';
import 'package:sky_services/media/media.mojom.dart';
import 'package:sky/material.dart';
import 'package:sky/rendering.dart';
import 'package:sky/services.dart';

// All of these sounds are marked as public domain at soundbible.
const String chimes = "http://soundbible.com/grab.php?id=2030&type=wav";
const String chainsaw = "http://soundbible.com/grab.php?id=1391&type=wav";
const String stag = "http://soundbible.com/grab.php?id=2073&type=wav";
const String frogs = "http://soundbible.com/grab.php?id=2033&type=wav";
const String rattle = "http://soundbible.com/grab.php?id=2037&type=wav";
const String iLoveYou = "http://soundbible.com/grab.php?id=2045&type=wav";

class Key {
  Key(this.color, this.soundUrl);

  final Color color;
  final String soundUrl;
  MediaPlayerProxy player;

  void down() {
    if (player == null)
      return;
    player.ptr.seekTo(0);
    player.ptr.start();
  }

  void up() {
    if (player == null)
      return;
    player.ptr.pause();
  }
}

class PianoApp extends StatelessComponent {
  final List<Key> keys = [
    new Key(Colors.red[500], chimes),
    new Key(Colors.orange[500], chainsaw),
    new Key(Colors.yellow[500], stag),
    new Key(Colors.green[500], frogs),
    new Key(Colors.blue[500], rattle),
    new Key(Colors.purple[500], iLoveYou),
  ];

  PianoApp() {
    loadSounds();
  }

  loadSounds() async {
    MediaServiceProxy mediaService = new MediaServiceProxy.unbound();
    shell.requestService(null, mediaService);

    for (Key key in keys) {
      MediaPlayerProxy player = new MediaPlayerProxy.unbound();
      mediaService.ptr.createPlayer(player);

      UrlResponse response = await fetchUrl(key.soundUrl);
      await player.ptr.prepare(response.body);
      key.player = player;
    }
    mediaService.close();
    // Are we leaking all the player connections?
  }

  Widget build(BuildContext context) {
    List<Widget> children = [];
    for (Key key in keys) {
      children.add(
        new Flexible(
          child: new Listener(
            child: new Container(
              decoration: new BoxDecoration(backgroundColor: key.color)
            ),
            onPointerCancel: (_) => key.up(),
            onPointerDown: (_) => key.down(),
            onPointerUp: (_) => key.up()
          )
        )
      );
    }

    return new Column(children);
  }
}

void main() {
  runApp(new PianoApp());
}
