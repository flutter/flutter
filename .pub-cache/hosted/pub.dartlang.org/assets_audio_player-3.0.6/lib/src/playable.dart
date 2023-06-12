import 'dart:convert';
import 'dart:typed_data';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'utils.dart';

class Playable {
  final Set<PlayerEditor> _currentlyOpenedIn = {};

  Set<PlayerEditor> get currentlyOpenedIn => Set.from(_currentlyOpenedIn);

  void setCurrentlyOpenedIn(PlayerEditor? player) {
    if (player != null) _currentlyOpenedIn.add(player);
  }

  void removeCurrentlyOpenedIn(PlayerEditor? player) {
    _currentlyOpenedIn.remove(player);
  }
}

enum AudioType {
  network,
  liveStream,
  file,
  asset,
}

String audioTypeDescription(AudioType audioType) {
  switch (audioType) {
    case AudioType.network:
      return 'network';
    case AudioType.liveStream:
      return 'liveStream';
    case AudioType.file:
      return 'file';
    case AudioType.asset:
      return 'asset';
  }
}

enum ImageType {
  network,
  file,
  asset,
}

String imageTypeDescription(ImageType imageType) {
  switch (imageType) {
    case ImageType.network:
      return 'network';
    case ImageType.file:
      return 'file';
    case ImageType.asset:
      return 'asset';
  }
}

@immutable
class MetasImage {
  const MetasImage({
    required this.path,
    required this.type,
    this.package,
  });

  final String path;
  final ImageType type;
  final String? package;

  const MetasImage.network(this.path)
      : type = ImageType.network,
        package = null;

  const MetasImage.asset(
    this.path, {
    this.package,
  }) : type = ImageType.asset;

  const MetasImage.file(this.path)
      : type = ImageType.file,
        package = null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetasImage &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          package == other.package &&
          type == other.type;

  @override
  int get hashCode => path.hashCode ^ package.hashCode ^ type.hashCode;
}

class Metas {
  String? id;
  final String? title;
  final String? artist;
  final String? album;
  final Map<String, dynamic>? extra;
  final MetasImage? image;
  final MetasImage? onImageLoadFail;

  Metas({
    this.id,
    this.title,
    this.artist,
    this.album,
    this.image,
    this.extra,
    this.onImageLoadFail,
  }) {
    id ??= Uuid().v4();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Metas &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          artist == other.artist &&
          album == other.album &&
          image == other.image &&
          onImageLoadFail == onImageLoadFail;

  @override
  int get hashCode =>
      title.hashCode ^
      artist.hashCode ^
      album.hashCode ^
      image.hashCode ^
      onImageLoadFail.hashCode;

  Metas copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Map<String, dynamic>? extra,
    MetasImage? image,
    MetasImage? onImageLoadFail,
  }) {
    return Metas(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      extra: extra ?? this.extra,
      image: image ?? this.image,
      onImageLoadFail: onImageLoadFail ?? this.onImageLoadFail,
    );
  }
}

//Placeholder for future DRM Types
enum DrmType{ token, widevine, fairplay, clearKey }

class DrmConfiguration{
   final DrmType drmType;
   final String? clearKey;

   DrmConfiguration._(this.drmType,{this.clearKey});

   factory DrmConfiguration.clearKey({String? clearKey, Map<String,String>? keys}){
     if(keys!=null) clearKey  = _generate(keys);
     var drmConfiguration = DrmConfiguration._(DrmType.clearKey,clearKey: clearKey);
     return drmConfiguration;
   }


    static String _generate(Map<String, String> keys,
       {String type = 'temporary'}) {
     Map keyMap = <String, dynamic>{'type': type};
     keyMap['keys'] = <Map<String, String>>[];
     keys.forEach((key, value) => keyMap['keys']
         .add({'kty': 'oct', 'kid': _base64(key), 'k': _base64(value)}));
     return jsonEncode(keyMap);
   }

   static String _base64(String source) {
     return base64
         .encode(_encodeBigInt(BigInt.parse(source, radix: 16)))
         .replaceAll('=', '');
   }

    static final _byteMask = BigInt.from(0xff);

    static Uint8List _encodeBigInt(BigInt number) {
     var size = (number.bitLength + 7) >> 3;

     final result = Uint8List(size);
     var pos = size - 1;
     for (var i = 0; i < size; i++) {
       result[pos--] = (number & _byteMask).toInt();
       number = number >> 8;
     }
     return result;
   }

}

class Audio extends Playable {
  final String path;
  final String? package;
  final AudioType audioType;
  Metas _metas;
  final Map<String, String>? _networkHeaders;
  final bool? cached; // download audio then play it
  final double? playSpeed;
  final double? pitch;
  final DrmConfiguration? drmConfiguration;

  Metas get metas => _metas;

  Map<String, String>? get networkHeaders => _networkHeaders;

  Audio._({
    required this.path,
    required this.audioType,
    this.package,
    this.cached,
    this.playSpeed,
    this.pitch,
    Map<String, String>? headers,
    Metas? metas,
    this.drmConfiguration
  })  : _metas = metas ?? Metas(),
        _networkHeaders = headers;

  Audio(
    this.path, {
    Metas? metas,
    this.package,
    this.playSpeed,
    this.pitch,
  })  : audioType = AudioType.asset,
        _networkHeaders = null,
        cached = false,
        _metas = metas ?? Metas(),
        drmConfiguration = null;

  Audio.file(
    this.path, {
    Metas? metas,
    this.playSpeed,
    this.pitch,
    this.drmConfiguration,
  })  : audioType = AudioType.file,
        package = null,
        _networkHeaders = null,
        cached = false,
        _metas = metas ?? Metas();

  Audio.network(
    this.path, {
    Metas? metas,
    Map<String, String>? headers,
    this.cached = false,
    this.playSpeed,
    this.pitch,
    this.drmConfiguration
  })  : audioType = AudioType.network,
        package = null,
        _networkHeaders = headers,
        _metas = metas ?? Metas();

  Audio.liveStream(
    this.path, {
    Metas? metas,
    this.playSpeed,
    this.pitch,
    Map<String, String>? headers,
    this.drmConfiguration
  })  : audioType = AudioType.liveStream,
        package = null,
        _networkHeaders = headers,
        cached = false,
        _metas = metas ?? Metas();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Audio &&
          runtimeType == other.runtimeType &&
          path == other.path &&
          package == other.package &&
          audioType == other.audioType &&
          cached == other.cached &&
          playSpeed == other.playSpeed &&
          metas == other.metas;

  @override
  int get hashCode =>
      path.hashCode ^
      package.hashCode ^
      audioType.hashCode ^
      metas.hashCode ^
      playSpeed.hashCode ^
      cached.hashCode;

  @override
  String toString() {
    return 'Audio{path: $path, package: $package, audioType: $audioType, _metas: $_metas, _networkHeaders: $_networkHeaders}';
  }

  void updateMetas({
    String? title,
    String? artist,
    String? album,
    Map<String, dynamic>? extra,
    MetasImage? image,
  }) {
    _metas = _metas.copyWith(
      title: title,
      artist: artist,
      album: album,
      extra: extra,
      image: image,
    );
    super.currentlyOpenedIn.forEach((playerEditor) {
      playerEditor.onAudioMetasUpdated(this);
    });
  }

  Audio copyWith({
    String? path,
    String? package,
    AudioType? audioType,
    Metas? metas,
    double? playSpeed,
    Map<String, String>? headers,
    bool? cached,
    DrmConfiguration? drmConfiguration
  }) {
    return Audio._(
      path: path ?? this.path,
      package: package ?? this.package,
      audioType: audioType ?? this.audioType,
      metas: metas ?? _metas,
      headers: headers ?? _networkHeaders,
      playSpeed: playSpeed ?? this.playSpeed,
      cached: cached ?? this.cached,
      drmConfiguration: drmConfiguration??this.drmConfiguration
    );
  }
}

typedef PlaylistAudioReplacer = Audio Function(Audio oldAudio);

class Playlist extends Playable {
  final List<Audio> audios = [];

  int _startIndex = 0;

  int get startIndex => _startIndex;

  set startIndex(int newValue) {
    if (newValue < audios.length) {
      _startIndex = newValue;
    }
  }

  Playlist({List<Audio>? audios, int startIndex = 0}) {
    if (audios != null) {
      this.audios.addAll(audios);
    }
    this.startIndex = startIndex;
  }

  Playlist copyWith({
    List<Audio>? audios,
    int? startIndex,
  }) {
    return Playlist(
      audios: audios ?? this.audios,
      startIndex: startIndex ?? _startIndex,
    );
  }

  int get numberOfItems => audios.length;

  Playlist add(Audio audio) {
    audios.add(audio);
    final index = audios.length - 1;
    super.currentlyOpenedIn.forEach((playerEditor) {
      playerEditor.onAudioAddedAt(index);
    });
    return this;
  }

  Playlist insert(int index, Audio audio) {
    if (index >= 0) {
      if (index < audios.length) {
        audios.insert(index, audio);
        super.currentlyOpenedIn.forEach((playerEditor) {
          playerEditor.onAudioAddedAt(index);
        });
      } else {
        return add(audio);
      }
    }
    return this;
  }

  Playlist replaceAt(int index, PlaylistAudioReplacer replacer,
      {bool keepPlayingPositionIfCurrent = false}) {
    if (index < audios.length) {
      final oldElement = audios.elementAt(index);
      final newElement = replacer(oldElement);
      audios[index] = newElement;
      super.currentlyOpenedIn.forEach((playerEditor) {
        playerEditor.onAudioReplacedAt(index, keepPlayingPositionIfCurrent);
      });
    }
    return this;
  }

  Playlist addAll(List<Audio> audios) {
    this.audios.addAll(audios);
    return this;
  }

  bool remove(Audio audio) {
    final index = audios.indexOf(audio);
    final removed = audios.remove(audio);
    super.currentlyOpenedIn.forEach((playerEditor) {
      playerEditor.onAudioRemovedAt(index);
    });
    // here maybe stop the player if playing this index
    return removed;
  }

  Audio removeAtIndex(int index) {
    final removedAudio = audios.removeAt(index);
    super.currentlyOpenedIn.forEach((playerEditor) {
      playerEditor.onAudioRemovedAt(index);
    });
    return removedAudio;
  }

  bool contains(Audio audio) {
    return audios.contains(audio);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist &&
          runtimeType == other.runtimeType &&
          audios == other.audios &&
          startIndex == other.startIndex;

  @override
  int get hashCode => audios.hashCode ^ startIndex.hashCode;
}

void writeAudioMetasInto(Map<String, dynamic> params, Metas? metas) {
  if (metas != null) {
    if (metas.title != null) params['song.title'] = metas.title;
    if (metas.artist != null) params['song.artist'] = metas.artist;
    if (metas.album != null) params['song.album'] = metas.album;
    writeAudioImageMetasInto(params, metas.image);
    writeAudioImageMetasInto(params, metas.onImageLoadFail,
        suffix: '.onLoadFail');
    if (metas.id != null) {
      params['song.trackID'] = metas.id;
    }
  }
}

void writeAudioImageMetasInto(
    Map<String, dynamic> params, MetasImage? metasImage,
    {String suffix = ''}) {
  if (metasImage != null) {
    params['song.image$suffix'] = metasImage.path;
    params['song.imageType$suffix'] = imageTypeDescription(metasImage.type);
    params.addIfNotNull('song.imagePackage$suffix', metasImage.package);
  }
}

class PlayerGroupMetas {
  final String? title;
  final String? subTitle;
  final MetasImage? image;

  PlayerGroupMetas({
    this.title,
    this.subTitle,
    this.image,
  });
}
