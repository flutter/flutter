import 'dart:io';

import 'package:flutter/foundation.dart';

/// Specify supported features for a platform.
class PlatformFeatures {
  static const webPlatformFeatures = PlatformFeatures(
    hasBytesSource: false,
    hasPlaylistSourceType: false,
    hasLowLatency: false,
    hasDuckAudio: false,
    hasRespectSilence: false,
    hasStayAwake: false,
    hasRecordingActive: false,
    hasPlayingRoute: false,
    hasErrorEvent: false,
    hasBalance: false,
  );

  static const androidPlatformFeatures = PlatformFeatures(
    hasRecordingActive: false,
    hasBalance: false,
  );

  static const iosPlatformFeatures = PlatformFeatures(
    hasBytesSource: false,
    hasPlaylistSourceType: false,
    hasReleaseModeRelease: false,
    hasLowLatency: false,
    hasDuckAudio: false,
    hasBalance: false,
  );

  static const macPlatformFeatures = PlatformFeatures(
    hasBytesSource: false,
    hasPlaylistSourceType: false,
    hasLowLatency: false,
    hasDuckAudio: false,
    hasRespectSilence: false,
    hasStayAwake: false,
    hasRecordingActive: false,
    hasPlayingRoute: false,
    hasBalance: false,
  );

  static const linuxPlatformFeatures = PlatformFeatures(
    hasBytesSource: false,
    hasLowLatency: false,
    hasReleaseModeRelease: false,
    // MP3 duration is estimated: https://bugzilla.gnome.org/show_bug.cgi?id=726144
    // Use GstDiscoverer to get duration before playing: https://gstreamer.freedesktop.org/documentation/pbutils/gstdiscoverer.html?gi-language=c
    hasMp3Duration: false,
    hasDuckAudio: false,
    hasRespectSilence: false,
    hasStayAwake: false,
    hasRecordingActive: false,
    hasPlayingRoute: false,
  );

  static const windowsPlatformFeatures = PlatformFeatures(
    hasBytesSource: false,
    hasPlaylistSourceType: false,
    hasLowLatency: false,
    hasDuckAudio: false,
    hasRespectSilence: false,
    hasStayAwake: false,
    hasRecordingActive: false,
    hasPlayingRoute: false,
  );

  final bool hasUrlSource;
  final bool hasAssetSource;
  final bool hasBytesSource;

  final bool hasPlaylistSourceType;

  final bool hasLowLatency;
  final bool hasReleaseModeRelease;
  final bool hasReleaseModeLoop;
  final bool hasVolume;
  final bool hasBalance;
  final bool hasSeek;
  final bool hasMp3Duration;

  final bool hasPlaybackRate;
  final bool hasDuckAudio; // Not yet tested
  final bool hasRespectSilence; // Not yet tested
  final bool hasStayAwake; // Not yet tested
  final bool hasRecordingActive; // Not yet tested
  final bool hasPlayingRoute; // Not yet tested

  final bool hasDurationEvent;
  final bool hasPositionEvent;
  final bool hasPlayerStateEvent;
  final bool hasErrorEvent; // Not yet tested

  const PlatformFeatures({
    this.hasUrlSource = true,
    this.hasAssetSource = true,
    this.hasBytesSource = true,
    this.hasPlaylistSourceType = true,
    this.hasLowLatency = true,
    this.hasReleaseModeRelease = true,
    this.hasReleaseModeLoop = true,
    this.hasMp3Duration = true,
    this.hasVolume = true,
    this.hasBalance = true,
    this.hasSeek = true,
    this.hasPlaybackRate = true,
    this.hasDuckAudio = true,
    this.hasRespectSilence = true,
    this.hasStayAwake = true,
    this.hasRecordingActive = true,
    this.hasPlayingRoute = true,
    this.hasDurationEvent = true,
    this.hasPositionEvent = true,
    this.hasPlayerStateEvent = true,
    this.hasErrorEvent = true,
  });

  factory PlatformFeatures.instance() {
    return kIsWeb
        ? webPlatformFeatures
        : Platform.isAndroid
            ? androidPlatformFeatures
            : Platform.isIOS
                ? iosPlatformFeatures
                : Platform.isMacOS
                    ? macPlatformFeatures
                    : Platform.isLinux
                        ? linuxPlatformFeatures
                        : Platform.isWindows
                            ? windowsPlatformFeatures
                            : const PlatformFeatures();
  }
}
