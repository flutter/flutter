import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'api/player_mode.dart';
import 'api/release_mode.dart';
import 'audioplayer.dart';

/// This class represents a cache for Local Assets to be played.
///
/// On desktop/mobile, Flutter can only play audios on device folders, so first
/// this class copies the files to a temporary folder, and then plays them.
/// On web, it just stores a reference to the URL of the audio, but it gets
/// preloaded by making a simple GET request (the browser then takes care of
/// caching).
///
/// You can pre-cache your audio, or clear the cache, as desired.
class AudioCache {
  /// A reference to the loaded files absolute URLs.
  ///
  /// This is a map of fileNames to pre-loaded URIs.
  /// On mobile/desktop, the URIs are from local files where the bytes have been copied.
  /// On web, the URIs are external links for pre-loaded files.
  Map<String, Uri> loadedFiles = {};

  /// This is the path inside your assets folder where your files lie.
  ///
  /// For example, Flame uses the prefix 'assets/audio/' (you must include the final slash!).
  /// The default prefix (if not provided) is 'assets/'
  /// Your files will be found at <prefix><fileName> (so the trailing slash is crucial).
  String prefix;

  /// This is an instance of AudioPlayer that, if present, will always be used.
  ///
  /// If not set, the AudioCache will create and return a new instance of AudioPlayer every call, allowing for simultaneous calls.
  /// If this is set, every call will overwrite previous calls.
  AudioPlayer? fixedPlayer;

  /// This flag should be set to true, if player is used for playing internal notifications
  ///
  /// This flag will have influence of stream type, and will respect silent mode if set to true.
  ///
  /// Not implemented on macOS.
  bool respectSilence;

  /// This flag should be set to true, if player is used for playing sound while there may be music
  ///
  /// Defaults to false, meaning the audio will be paused while playing on iOS and continue playing on Android.
  bool duckAudio;

  AudioCache({
    this.prefix = 'assets/',
    this.fixedPlayer,
    this.respectSilence = false,
    this.duckAudio = false,
  });

  /// Clears the cache for the file [fileName].
  ///
  /// Does nothing if the file was not on cache.
  /// Note: web relies on browser cache which is handled entirely by the browser.
  Future<void> clear(Uri fileName) async {
    final uri = loadedFiles.remove(fileName);
    if (uri != null && !kIsWeb) {
      await File(uri.toFilePath()).delete();
    }
  }

  /// Clears the whole cache.
  Future<void> clearAll() async {
    await Future.wait(loadedFiles.values.map(clear));
  }

  Future<Uri> fetchToMemory(String fileName) async {
    if (kIsWeb) {
      final uri = _sanitizeURLForWeb(fileName);
      // We rely on browser caching here. Once the browser downloads this file,
      // the native side implementation should be able to access it from cache.
      await http.get(uri);
      return uri;
    }

    // read local asset from rootBundle
    final byteData = await rootBundle.load('$prefix$fileName');

    // create a temporary file on the device to be read by the native side
    final file = File('${(await getTemporaryDirectory()).path}/$fileName');
    await file.create(recursive: true);
    await file.writeAsBytes(byteData.buffer.asUint8List());

    // returns the local file uri
    return file.uri;
  }

  Uri _sanitizeURLForWeb(String fileName) {
    final tryAbsolute = Uri.tryParse(fileName);
    if (tryAbsolute?.isAbsolute == true) {
      return tryAbsolute!;
    }

    // local asset
    return Uri.parse('assets/$prefix$fileName');
  }

  /// Loads a single [fileName] to the cache.
  ///
  /// Also returns a [Future] to access that file.
  Future<Uri> load(String fileName) async {
    if (!loadedFiles.containsKey(fileName)) {
      loadedFiles[fileName] = await fetchToMemory(fileName);
    }
    return loadedFiles[fileName]!;
  }

  /// Loads a single [fileName] to the cache but returns it as a File.
  ///
  /// Note: this is not available for web, as File doesn't make sense on the
  /// browser!
  Future<File> loadAsFile(String fileName) async {
    if (kIsWeb) {
      throw 'This method cannot be used on web!';
    }
    final uri = await load(fileName);
    return File(uri.toFilePath());
  }

  /// Loads all the [fileNames] provided to the cache.
  ///
  /// Also returns a list of [Future]s for those files.
  Future<List<Uri>> loadAll(List<String> fileNames) async {
    return Future.wait(fileNames.map(load));
  }

  AudioPlayer _player(PlayerMode mode) {
    return fixedPlayer ?? AudioPlayer(mode: mode);
  }

  /// Plays the given [fileName].
  ///
  /// If the file is already cached, it plays immediately. Otherwise, first waits for the file to load (might take a few milliseconds).
  /// It creates a new instance of [AudioPlayer], so it does not affect other audios playing (unless you specify a [fixedPlayer], in which case it always use the same).
  /// The instance is returned, to allow later access (either way), like pausing and resuming.
  ///
  /// isNotification and stayAwake are not implemented on macOS
  Future<AudioPlayer> play(
    String fileName, {
    double volume = 1.0,
    bool? isNotification,
    PlayerMode mode = PlayerMode.MEDIA_PLAYER,
    bool stayAwake = false,
    bool recordingActive = false,
    bool? duckAudio,
  }) async {
    final uri = await load(fileName);
    final player = _player(mode);
    if (fixedPlayer != null) {
      await player.setReleaseMode(ReleaseMode.STOP);
    }
    await player.play(
      uri.toString(),
      volume: volume,
      respectSilence: isNotification ?? respectSilence,
      stayAwake: stayAwake,
      recordingActive: recordingActive,
      duckAudio: duckAudio ?? this.duckAudio,
    );
    return player;
  }

  /// Plays the given [fileBytes] by a byte source.
  ///
  /// This is no different than calling this API via AudioPlayer, except it will return (if applicable) the cached AudioPlayer.
  Future<AudioPlayer> playBytes(
    Uint8List fileBytes, {
    double volume = 1.0,
    bool? isNotification,
    PlayerMode mode = PlayerMode.MEDIA_PLAYER,
    bool loop = false,
    bool stayAwake = false,
    bool recordingActive = false,
  }) async {
    final player = _player(mode);

    if (loop) {
      await player.setReleaseMode(ReleaseMode.LOOP);
    } else if (fixedPlayer != null) {
      await player.setReleaseMode(ReleaseMode.STOP);
    }

    await player.playBytes(
      fileBytes,
      volume: volume,
      respectSilence: isNotification ?? respectSilence,
      stayAwake: stayAwake,
      recordingActive: recordingActive,
    );
    return player;
  }

  /// Like [play], but loops the audio (starts over once finished).
  ///
  /// The instance of [AudioPlayer] created is returned, so you can use it to stop the playback as desired.
  ///
  /// isNotification and stayAwake are not implemented on macOS.
  Future<AudioPlayer> loop(
    String fileName, {
    double volume = 1.0,
    bool? isNotification,
    PlayerMode mode = PlayerMode.MEDIA_PLAYER,
    bool stayAwake = false,
  }) async {
    final url = await load(fileName);
    final player = _player(mode);
    await player.setReleaseMode(ReleaseMode.LOOP);
    await player.play(
      url.toString(),
      volume: volume,
      respectSilence: isNotification ?? respectSilence,
      stayAwake: stayAwake,
    );
    return player;
  }
}
