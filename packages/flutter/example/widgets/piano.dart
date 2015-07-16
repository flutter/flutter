// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:mojom/media/media.mojom.dart';
import 'package:mojom/mojo/url_response.mojom.dart';
import 'package:sky/mojo/net/fetch.dart';
import 'package:sky/mojo/shell.dart' as shell;
import 'package:sky/rendering/box.dart';
import 'package:sky/rendering/flex.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets/basic.dart';

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

class PianoApp extends App {
  final List<Key> keys = [
    new Key(colors.Red[500], chimes),
    new Key(colors.Orange[500], chainsaw),
    new Key(colors.Yellow[500], stag),
    new Key(colors.Green[500], frogs),
    new Key(colors.Blue[500], rattle),
    new Key(colors.Purple[500], iLoveYou),
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
    scheduleBuild();
  }

  Widget build() {
    List<Widget> children = [];
    for (Key key in keys) {
      children.add(
        new Listener(
          child: new Flexible(
            child: new Container(
              decoration: new BoxDecoration(backgroundColor: key.color)
            )
          ),
          onPointerCancel: (_) => key.up(),
          onPointerDown: (_) => key.down(),
          onPointerUp: (_) => key.up()
        )
      );
    }

    return new Flex(
      children,
      direction: FlexDirection.vertical
    );
  }
}

void main() {
  runApp(new PianoApp());
}
