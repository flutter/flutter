import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// This class contains flags to control several secondary, platform-specific
/// aspects of audio playback, like how this audio interact with other audios,
/// how is it played by the device and what happens when the app is
/// backgrounded.
/// However, note that each platform has its nuances on how to configure audio.
/// This class is a generic abstraction of some parameters that can be useful
/// across the board.
/// Its flags are simple abstractions that are then translated to an
/// [AudioContext] containing platform specific configurations:
/// [AudioContextAndroid] and [AudioContextIOS].
/// If these simplified flags cannot fully reflect your goals, you must create
/// an [AudioContext] configuring each platform separately.
class AudioContextConfig {
  /// Normally, audio played will respect the devices configured preferences.
  /// However, if you want to bypass that and flag the system to use the
  /// built-in speakers, you can set this flag.
  ///
  /// On android, it will set `audioManager.isSpeakerphoneOn`.
  ///
  /// On iOS, it will either:
  ///
  /// * set the `.defaultToSpeaker` option OR
  /// * call `overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)`
  ///
  /// Note that, on iOS, this forces the category to be `.playAndRecord`, and
  /// thus is forbidden when [respectSilence] is set.
  final bool forceSpeaker;

  /// This flag determines how your audio interacts with other audio playing on
  /// the device.
  /// If your audio is playing, and another audio plays on top (like an alarm,
  /// gps, etc), this determines what happens with your audio.
  ///
  /// On Android, this will make an Audio Focus request with
  /// AUDIOFOCUS_GAIN_TRANSIENT_MAY_DUCK when your audio starts playing.
  ///
  /// On iOS, this will set the option `.duckOthers` option
  /// (the option `.mixWithOthers` is always set, regardless of these flags).
  /// Note that, on iOS, this forces the category to be `.playAndRecord`, and
  /// thus is forbidden when [respectSilence] is set.
  final bool duckAudio;

  /// Whether the "silent" mode of the device should be respect.
  /// By default (false), if the device is on silent mode, the audio will not be
  /// played.
  ///
  /// On Android, this will mandate the `USAGE_NOTIFICATION_RINGTONE` usage
  /// type.
  ///
  /// On iOS, setting this mandates the `.ambient` category, and it will be:
  ///  * silenced by rings
  ///  * silenced by the Silent switch
  ///  * silenced by screen locking (note: read [stayAwake] for details on
  ///    this).
  final bool respectSilence;

  /// By default, when the screen is locked, all the app's processing stops,
  /// including audio playback.
  /// You can set this flag to keep your audio playing even when locked.
  ///
  /// On Android, this sets the player "wake mode" to `PARTIAL_WAKE_LOCK`.
  ///
  /// On iOS, this will happen automatically as long as:
  ///  * the category is `.playAndRecord` (thus setting this is forbidden when
  ///    [respectSilence] is set)
  ///  * the UIBackgroundModes audio key has been added to your app’s
  ///    Info.plist (check our FAQ for more details on that)
  final bool stayAwake;

  AudioContextConfig({
    this.forceSpeaker = false,
    this.duckAudio = false,
    this.respectSilence = false,
    this.stayAwake = true,
  });

  AudioContextConfig copy({
    bool? forceSpeaker,
    bool? duckAudio,
    bool? respectSilence,
    bool? stayAwake,
  }) {
    return AudioContextConfig(
      forceSpeaker: forceSpeaker ?? this.forceSpeaker,
      duckAudio: duckAudio ?? this.duckAudio,
      respectSilence: respectSilence ?? this.respectSilence,
      stayAwake: stayAwake ?? this.stayAwake,
    );
  }

  AudioContext build() {
    return AudioContext(
      android: buildAndroid(),
      iOS: buildIOS(),
    );
  }

  AudioContextAndroid buildAndroid() {
    return AudioContextAndroid(
      isSpeakerphoneOn: forceSpeaker,
      stayAwake: stayAwake,
      contentType: AndroidContentType.music,
      usageType: respectSilence
          ? AndroidUsageType.notificationRingtone
          : AndroidUsageType.media,
      audioFocus: duckAudio
          ? AndroidAudioFocus.gainTransientMayDuck
          : AndroidAudioFocus.gain,
    );
  }

  AudioContextIOS buildIOS() {
    if (Platform.isIOS) {
      validateIOS();
    }
    return AudioContextIOS(
      defaultToSpeaker: forceSpeaker,
      category: respectSilence
          ? AVAudioSessionCategory.ambient
          : AVAudioSessionCategory.playback,
      options: [AVAudioSessionOptions.mixWithOthers] +
          (duckAudio ? [AVAudioSessionOptions.duckOthers] : []),
    );
  }

  void validateIOS() {
    // Please create a custom [AudioContextIOS] if the generic flags cannot
    // represent your needs.
    if (respectSilence && forceSpeaker) {
      throw 'On iOS it is impossible to set both respectSilence and '
          'forceSpeaker';
    }
  }
}

class AudioContext {
  final AudioContextAndroid android;
  final AudioContextIOS iOS;

  AudioContext({
    required this.android,
    required this.iOS,
  });

  AudioContext copy({
    AudioContextAndroid? android,
    AudioContextIOS? iOS,
  }) {
    return AudioContext(
      android: android ?? this.android,
      iOS: iOS ?? this.iOS,
    );
  }

  Map<String, dynamic> toJson() {
    // we need to check web first because `Platform.isX` fails on web
    if (kIsWeb) {
      return <String, dynamic>{};
    } else if (Platform.isAndroid) {
      return android.toJson();
    } else if (Platform.isIOS) {
      return iOS.toJson();
    } else {
      return <String, dynamic>{};
    }
  }
}

class AudioContextAndroid {
  /// audioManager.isSpeakerphoneOn
  final bool isSpeakerphoneOn;
  final bool stayAwake;
  final AndroidContentType contentType;
  final AndroidUsageType usageType;
  final AndroidAudioFocus? audioFocus;

  AudioContextAndroid({
    required this.isSpeakerphoneOn,
    required this.stayAwake,
    required this.contentType,
    required this.usageType,
    required this.audioFocus,
  });

  AudioContextAndroid copy({
    bool? isSpeakerphoneOn,
    bool? stayAwake,
    AndroidContentType? contentType,
    AndroidUsageType? usageType,
    AndroidAudioFocus? audioFocus,
  }) {
    return AudioContextAndroid(
      isSpeakerphoneOn: isSpeakerphoneOn ?? this.isSpeakerphoneOn,
      stayAwake: stayAwake ?? this.stayAwake,
      contentType: contentType ?? this.contentType,
      usageType: usageType ?? this.usageType,
      audioFocus: audioFocus ?? this.audioFocus,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isSpeakerphoneOn': isSpeakerphoneOn,
      'stayAwake': stayAwake,
      'contentType': contentType.value,
      'usageType': usageType.value,
      'audioFocus': audioFocus?.value,
    };
  }
}

class AudioContextIOS {
  final bool defaultToSpeaker;
  final AVAudioSessionCategory category;
  final List<AVAudioSessionOptions> options;

  AudioContextIOS({
    required this.defaultToSpeaker,
    required this.category,
    required this.options,
  });

  AudioContextIOS copy({
    bool? defaultToSpeaker,
    AVAudioSessionCategory? category,
    List<AVAudioSessionOptions>? options,
  }) {
    return AudioContextIOS(
      defaultToSpeaker: defaultToSpeaker ?? this.defaultToSpeaker,
      category: category ?? this.category,
      options: options ?? this.options,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'defaultToSpeaker': defaultToSpeaker,
      'category': category.name,
      'options': options.map((e) => e.name).toList(),
    };
  }
}

enum AndroidContentType {
  /// Content type value to use when the content type is unknown, or other than
  /// the ones defined.
  unknown,

  /// Content type value to use when the content type is speech.
  speech,

  /// Content type value to use when the content type is music.
  music,

  /// Content type value to use when the content type is a soundtrack, typically
  /// accompanying a movie or TV program.
  movie,

  /// Content type value to use when the content type is a sound used to
  /// accompany a user action, such as a beep or sound effect expressing a key
  /// click, or event, such as the type of a sound for a bonus being received in
  /// a game. These sounds are mostly synthesized or short Foley sounds.
  sonification,
}

extension AndroidContentTypeValue on AndroidContentType {
  int get value {
    switch (this) {
      case AndroidContentType.unknown:
        return 0;
      case AndroidContentType.speech:
        return 1;
      case AndroidContentType.music:
        return 2;
      case AndroidContentType.movie:
        return 3;
      case AndroidContentType.sonification:
        return 4;
    }
  }
}

enum AndroidUsageType {
  /// Usage value to use when the usage is unknown.
  unknown,

  /// Usage value to use when the usage is media, such as music, or movie
  /// soundtracks.
  media,

  /// Usage value to use when the usage is voice communications, such as
  /// telephony or VoIP.
  voiceCommunication,

  /// Usage value to use when the usage is in-call signalling, such as with a
  /// "busy" beep, or DTMF tones.
  voiceCommunicationSignalling,

  /// Usage value to use when the usage is an alarm (e.g. wake-up alarm).
  alarm,

  /// Usage value to use when the usage is notification. See other notification
  /// usages for more specialized uses.
  notification,

  /// Usage value to use when the usage is telephony ringtone.
  notificationRingtone,

  /// Usage value to use when the usage is a request to enter/end a
  /// communication, such as a VoIP communication or video-conference.
  notificationCommunicationRequest,

  /// Usage value to use when the usage is notification for an "instant"
  /// communication such as a chat, or SMS.
  notificationCommunicationInstant,

  /// Usage value to use when the usage is notification for a non-immediate type
  /// of communication such as e-mail.
  notificationCommunicationDelayed,

  /// Usage value to use when the usage is to attract the user's attention, such
  /// as a reminder or low battery warning.
  notificationEvent,

  /// Usage value to use when the usage is for accessibility, such as with a
  /// screen reader.
  assistanceAccessibility,

  /// Usage value to use when the usage is driving or navigation directions.
  assistanceNavigationGuidance,

  /// Usage value to use when the usage is sonification, such as  with user
  /// interface sounds.
  assistanceSonification,

  /// Usage value to use when the usage is for game audio.
  game,

  /// @hide
  ///
  /// Usage value to use when feeding audio to the platform and replacing
  /// "traditional" audio source, such as audio capture devices.
  virtualSource,

  /// Usage value to use for audio responses to user queries, audio instructions
  /// or help utterances.
  assistant,
}

extension AndroidUsageTypeValue on AndroidUsageType {
  int get value {
    switch (this) {
      case AndroidUsageType.unknown:
        return 0;
      case AndroidUsageType.media:
        return 1;
      case AndroidUsageType.voiceCommunication:
        return 2;
      case AndroidUsageType.voiceCommunicationSignalling:
        return 3;
      case AndroidUsageType.alarm:
        return 4;
      case AndroidUsageType.notification:
        return 5;
      case AndroidUsageType.notificationRingtone:
        return 6;
      case AndroidUsageType.notificationCommunicationRequest:
        return 7;
      case AndroidUsageType.notificationCommunicationInstant:
        return 8;
      case AndroidUsageType.notificationCommunicationDelayed:
        return 9;
      case AndroidUsageType.notificationEvent:
        return 10;
      case AndroidUsageType.assistanceAccessibility:
        return 11;
      case AndroidUsageType.assistanceNavigationGuidance:
        return 12;
      case AndroidUsageType.assistanceSonification:
        return 13;
      case AndroidUsageType.game:
        return 14;
      case AndroidUsageType.virtualSource:
        return 15;
      case AndroidUsageType.assistant:
        return 16;
    }
  }
}

enum AndroidAudioFocus {
  /// Used to indicate no audio focus has been gained or lost, or requested.
  none,

  /// Used to indicate a gain of audio focus, or a request of audio focus, of
  /// unknown duration.
  ///
  /// @see OnAudioFocusChangeListener#onAudioFocusChange(int)
  /// @see #requestAudioFocus(OnAudioFocusChangeListener, int, int)
  gain,

  /// Used to indicate a temporary gain or request of audio focus, anticipated
  /// to last a short amount of time. Examples of temporary changes are the
  /// playback of driving directions, or an event notification.
  ///
  /// @see OnAudioFocusChangeListener#onAudioFocusChange(int)
  /// @see #requestAudioFocus(OnAudioFocusChangeListener, int, int)
  gainTransient,

  /// Used to indicate a temporary request of audio focus, anticipated to last a
  /// short amount of time, and where it is acceptable for other audio
  /// applications to keep playing after having lowered their output level
  /// (also referred to as "ducking").
  /// Examples of temporary changes are the playback of driving directions where
  /// playback of music in the background is acceptable.
  ///
  /// @see OnAudioFocusChangeListener#onAudioFocusChange(int)
  /// @see #requestAudioFocus(OnAudioFocusChangeListener, int, int)
  gainTransientMayDuck,

  /// Used to indicate a temporary request of audio focus, anticipated to last a
  /// short amount of time, during which no other applications, or system
  /// components, should play anything. Examples of exclusive and transient
  /// audio focus requests are voice memo recording and speech recognition,
  /// during which the system shouldn't play any notifications, and media
  /// playback should have paused.
  ///
  /// @see #requestAudioFocus(OnAudioFocusChangeListener, int, int)
  gainTransientExclusive,
}

extension AndroidAudioFocusValue on AndroidAudioFocus {
  int get value {
    switch (this) {
      case AndroidAudioFocus.none:
        return 0;
      case AndroidAudioFocus.gain:
        return 1;
      case AndroidAudioFocus.gainTransient:
        return 2;
      case AndroidAudioFocus.gainTransientMayDuck:
        return 3;
      case AndroidAudioFocus.gainTransientExclusive:
        return 4;
    }
  }
}

/// This is a Dart representation of the equivalent enum on Swift.
///
/// Audio session category identifiers.
/// An audio session category defines a set of audio behaviors.
/// Choose a category that most accurately describes the audio behavior you
/// require.
enum AVAudioSessionCategory {
  /// Silenced by the Ring/Silent switch and by screen locking = Yes
  /// Interrupts nonmixable app’s audio = No
  /// Output only
  ambient,

  /// Silenced by the Ring/Silent switch and by screen locking = Yes
  /// Interrupts nonmixable app’s audio = Yes
  /// Output only
  /// This is the platform's default (not AP's default witch is playAndRecord).
  soloAmbient,

  /// Silenced by the Ring/Silent switch and by screen locking = No
  /// Interrupts nonmixable app’s audio = Yes by default; no by using override
  /// switch.
  /// Note: the switch is the `.mixWithOthers` option
  /// (+ other options like `.duckOthers`).
  /// Output only
  playback,

  /// Silenced by the Ring/Silent switch and by screen locking = No (recording
  /// continues with screen locked)
  /// Interrupts nonmixable app’s audio = Yes
  /// Input only
  record,

  /// Silenced by the Ring/Silent switch and by screen locking = No
  /// Interrupts nonmixable app’s audio = Yes by default; no by using override
  /// switch.
  /// Note: the switch is the `.mixWithOthers` option
  /// (+ other options like `.duckOthers`).
  /// Input and output
  playAndRecord,

  /// Silenced by the Ring/Silent switch and by screen locking = No
  /// Interrupts nonmixable app’s audio = Yes
  /// Input and output
  multiRoute,
}

/// This is a Dart representation of the equivalent enum on Swift.
///
/// Constants that specify optional audio behaviors. Each option is valid only
/// for specific audio session categories.
enum AVAudioSessionOptions {
  /// An option that indicates whether audio from this session mixes with audio
  /// from active sessions in other audio apps.
  mixWithOthers,

  /// An option that reduces the volume of other audio sessions while audio from
  /// this session plays.
  duckOthers,

  /// An option that determines whether to pause spoken audio content from other
  /// sessions when your app plays its audio.
  interruptSpokenAudioAndMixWithOthers,

  /// An option that determines whether Bluetooth hands-free devices appear as
  /// available input routes.
  allowBluetooth,

  /// An option that determines whether you can stream audio from this session
  /// to Bluetooth devices that support the Advanced Audio Distribution Profile
  /// (A2DP).
  allowBluetoothA2DP,

  /// An option that determines whether you can stream audio from this session
  /// to AirPlay devices.
  allowAirPlay,

  /// An option that determines whether audio from the session defaults to the
  /// built-in speaker instead of the receiver.
  defaultToSpeaker,

  /// An option that indicates whether the system interrupts the audio session
  /// when it mutes the built-in microphone.
  overrideMutedMicrophoneInterruption,
}
