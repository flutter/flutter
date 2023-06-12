import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:flutter/foundation.dart';

/// Represents the current played audio asset
/// When the player opened a song, it will ping AssetsAudioPlayer.current with a `AssetsAudio`
///
/// ### Example
///     final assetAudio = AssetsAudio(
///       assets/audios/song1.mp3,
///     )
///
///     _assetsAudioPlayer.current.listen((PlayingAudio current){
///         //ex: retrieve the current song's total duration
///     });
///
///     _assetsAudioPlayer.open(assetAudio);
///
@immutable
class PlayingAudio {
  ///the opened asset
  final Audio audio;

  ///the current song's total duration
  final Duration duration;

  const PlayingAudio({
    required this.audio,
    this.duration = Duration.zero,
  });

  String get assetAudioPath => audio.path;

  @override
  String toString() {
    return 'PlayingAudio{audio: $audio, duration: $duration}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayingAudio &&
          runtimeType == other.runtimeType &&
          audio == other.audio &&
          duration == other.duration;

  @override
  int get hashCode => audio.hashCode ^ duration.hashCode;
}

@immutable
class ReadingPlaylist {
  final List<Audio> audios;
  final int? nextIndex;
  final int? previousIndex;
  final int currentIndex;

  const ReadingPlaylist({
    required this.audios,
    this.previousIndex,
    this.nextIndex,
    this.currentIndex = 0,
  });

  Audio get current => audios[currentIndex];

  @override
  String toString() {
    return 'ReadingPlaylist{audios: $audios, currentIndex: $currentIndex}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingPlaylist &&
          runtimeType == other.runtimeType &&
          audios == other.audios &&
          currentIndex == other.currentIndex;

  @override
  int get hashCode => audios.hashCode ^ currentIndex.hashCode;
}

@immutable
class Playing {
  /// the opened asset
  final PlayingAudio audio;

  /// this audio index in playlist
  final int index;

  /// if this audio has a next element (if no : last element)
  final bool hasNext;

  /// the parent playlist
  final ReadingPlaylist playlist;

  Playing({
    required this.audio,
    required this.index,
    required this.hasNext,
    required this.playlist,
  });

  @override
  String toString() {
    return 'Playing{audio: $audio, index: $index, hasNext: $hasNext, playlist: $playlist}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playing &&
          runtimeType == other.runtimeType &&
          audio == other.audio &&
          index == other.index &&
          hasNext == other.hasNext &&
          playlist == other.playlist;

  @override
  int get hashCode =>
      audio.hashCode ^ index.hashCode ^ hasNext.hashCode ^ playlist.hashCode;
}

@immutable
class RealtimePlayingInfos {
  final String playerId;

  final Playing? current;
  final Duration duration;
  final Duration currentPosition;
  final double volume;
  final bool isPlaying;
  final LoopMode loopMode;
  final bool isBuffering;
  final bool? isShuffling;

  RealtimePlayingInfos({
    required this.playerId,
    required this.current,
    required this.currentPosition,
    required this.volume,
    required this.isPlaying,
    required this.loopMode,
    required this.isBuffering,
    this.isShuffling,
  }) : duration = current?.audio.duration ?? Duration();

  double get playingPercent => duration.inMilliseconds == 0
      ? 0
      : currentPosition.inMilliseconds / duration.inMilliseconds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RealtimePlayingInfos &&
          runtimeType == other.runtimeType &&
          playerId == other.playerId &&
          current == other.current &&
          duration == other.duration &&
          currentPosition == other.currentPosition &&
          volume == other.volume &&
          isPlaying == other.isPlaying &&
          loopMode == other.loopMode &&
          isBuffering == other.isBuffering &&
          isShuffling == other.isShuffling;

  @override
  int get hashCode =>
      playerId.hashCode ^
      current.hashCode ^
      duration.hashCode ^
      currentPosition.hashCode ^
      volume.hashCode ^
      isPlaying.hashCode ^
      loopMode.hashCode ^
      isBuffering.hashCode ^
      isShuffling.hashCode;

  @override
  String toString() {
    return 'RealtimePlayingInfos{playerId: $playerId, current: $current, duration: $duration, currentPosition: $currentPosition, volume: $volume, isPlaying: $isPlaying, loopMode: $loopMode, isBuffering: $isBuffering, isShuffling: $isShuffling}';
  }
}
