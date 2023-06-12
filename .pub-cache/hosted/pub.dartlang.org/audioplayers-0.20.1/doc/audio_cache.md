# Audio Cache

In order to play Local Assets, you must use the `AudioCache` class. AudioCache is not available for Flutter Web.

Flutter does not provide an easy way to play audio on your assets, but this class helps a lot. It actually copies the asset to a temporary folder in the device, where it is then played as a Local File.

It works as a cache because it keeps track of the copied files so that you can replay them without delay; you can also pre-load files.

Each instance has its own independent cache, so, if you want to optimize your load times, create a singleton.

To play an audio, just run:

```dart
    // import in the begining of the file
    import 'package:audioplayers/audioplayers.dart';

    // add it to your class as a static member
    static AudioCache player = AudioCache();
    // or as a local variable
    final player = AudioCache();

    // call this method when desired
    player.play('explosion.mp3');
```

This will play the `explosion.mp3` file in your project's `assets` folder.

The file structure would be something like this:

```
.
└── assets
    └── explosion.mp3
```

Don't forget to add these files to your `pubspec.yaml` file:

```
flutter:
  assets:
   - assets/explosion.mp3
```

You can optionally pass a prefix to the constructor if all of your audios are in a specific folder inside the assets folder. [Flame](https://github.com/luanpotter/flame), for instance, uses the 'assets/audio/' prefix:

```dart
    AudioCache player = AudioCache(prefix: 'assets/audio/');
    player.play('explosion.mp3');
    // now this file will be loaded from assets/audio/explosion.mp3
```

If you want to play indefinitely, just use the `loop` function:

```dart
    player.loop('music.mp3');
```

Finally, you can pre-load your audios. Audios need to be copied the first time they are requested; therefore, the first time you play each mp3 you might get a delay. In order to pre-load your audios, just use:

```dart
    player.load('explosion.mp3');
```

You can load all your audios in the beginning so that they always play smoothly; to load multiple audios, use the `loadAll` method:

```dart
    player.loadAll(['explosion.mp3', 'music.mp3'])
```

Finally, you can use the `clear` method to remove something from the cache:

```dart
    player.clear('explosion.mp3');
```

There is also a `clearAll` method, that clears the whole cache.

This might be useful if, for instance, your game has multiple levels and each has a different soundtrack.

Both load methods return a `Future` for the loaded `File`s.

Both on `play` and `loop` you can pass an additional optional double parameter, the `volume` (defaults to `1.0`).

Both the `play` and `loop` methods return a new instance of `AudioPlayer`, that allows you to stop, pause and configure other specifications.
