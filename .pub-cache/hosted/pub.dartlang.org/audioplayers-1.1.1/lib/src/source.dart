import 'dart:typed_data';

import 'package:audioplayers/src/audioplayer.dart';

/// A generic representation of a source from where audio can be pulled.
///
/// This can be a remote or local URL, an application asset, or the file bytes.
abstract class Source {
  Future<void> setOnPlayer(AudioPlayer player);
}

/// Source representing a remote URL to be played from the Internet.
/// This can be an audio file to be downloaded or an audio stream.
class UrlSource extends Source {
  final String url;
  UrlSource(this.url);

  @override
  Future<void> setOnPlayer(AudioPlayer player) {
    return player.setSourceUrl(url);
  }
}

/// Source representing the absolute path of a file in the user's device.
class DeviceFileSource extends Source {
  final String path;
  DeviceFileSource(this.path);

  @override
  Future<void> setOnPlayer(AudioPlayer player) {
    return player.setSourceDeviceFile(path);
  }
}

/// Source representing the path of an application asset in your Flutter
/// "assets" folder.
/// Note that a prefix might be applied by your [AudioPlayer]'s audio cache
/// instance.
class AssetSource extends Source {
  final String path;
  AssetSource(this.path);

  @override
  Future<void> setOnPlayer(AudioPlayer player) {
    return player.setSourceAsset(path);
  }
}

/// Source containing the actual bytes of the media to be played.
///
/// This is currently only supported for Android (SDK >= 23).
class BytesSource extends Source {
  final Uint8List bytes;
  BytesSource(this.bytes);

  @override
  Future<void> setOnPlayer(AudioPlayer player) {
    return player.setSourceBytes(bytes);
  }
}
