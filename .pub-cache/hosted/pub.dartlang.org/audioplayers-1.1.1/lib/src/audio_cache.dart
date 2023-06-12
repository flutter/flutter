import 'dart:async';
import 'dart:io';
// TODO(gustl22): remove when upgrading min Flutter version to >=3.3.0
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// This class represents a cache for Local Assets to be played.
///
/// On desktop/mobile, Flutter can only play audios on device folders, so first
/// this class copies asset files to a temporary folder, and then holds a
/// reference to the file.
///
/// On web, it just stores a reference to the URL of the audio, but it gets
/// preloaded by making a simple GET request (the browser then takes care of
/// caching).
///
/// You can pre-cache your audio, or clear the cache, as desired.
/// For most normal uses, the static instance is used. But if you want to
/// control multiple caches, you can create your own instances.
class AudioCache {
  /// A globlally accessible instance used by default by all players.
  static AudioCache instance = AudioCache();

  /// A reference to the loaded files absolute URLs.
  ///
  /// This is a map of fileNames to pre-loaded URIs.
  /// On mobile/desktop, the URIs are from local files where the bytes have been
  /// copied.
  /// On web, the URIs are external links for pre-loaded files.
  Map<String, Uri> loadedFiles = {};

  /// This is the path inside your assets folder where your files lie.
  ///
  /// For example, Flame uses the prefix 'assets/audio/'
  /// (you must include the final slash!).
  /// The default prefix (if not provided) is 'assets/'
  /// Your files will be found at <prefix><fileName> (so the trailing slash is
  /// crucial).
  String prefix;

  AudioCache({this.prefix = 'assets/'});

  /// Clears the cache for the file [fileName].
  ///
  /// Does nothing if the file was not on cache.
  /// Note: web relies on the browser cache which is handled entirely by the
  /// browser, thus this will no-op.
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
    if (tryAbsolute?.isAbsolute ?? false) {
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

  /// Loads a single [fileName] to the cache but returns it as a list of bytes.
  Future<Uint8List> loadAsBytes(String fileName) async {
    return (await loadAsFile(fileName)).readAsBytes();
  }

  /// Loads all the [fileNames] provided to the cache.
  ///
  /// Also returns a list of [Future]s for those files.
  Future<List<Uri>> loadAll(List<String> fileNames) async {
    return Future.wait(fileNames.map(load));
  }
}
