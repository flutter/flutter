import 'dart:async';

import 'package:audio_session/src/util.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

/// If you test any feature listed as UNTESTED, consider sharing whether it
/// works on GitHub.
class AndroidAudioManager {
  static const MethodChannel _channel =
      const MethodChannel('com.ryanheise.android_audio_manager');
  static AndroidAudioManager? _instance;

  final _becomingNoisyEventSubject = PublishSubject<void>();
  AndroidOnAudioFocusChanged? _onAudioFocusChanged;
  AndroidOnAudioDevicesChanged? _onAudioDevicesAdded;
  AndroidOnAudioDevicesChanged? _onAudioDevicesRemoved;

  factory AndroidAudioManager() {
    return _instance ??= AndroidAudioManager._();
  }

  void setAudioDevicesAddedListener(
      AndroidOnAudioDevicesChanged onAudioDevicesAdded) {
    _onAudioDevicesAdded = onAudioDevicesAdded;
  }

  void setAudioDevicesRemovedListener(
      AndroidOnAudioDevicesChanged onAudioDevicesRemoved) {
    _onAudioDevicesRemoved = onAudioDevicesRemoved;
  }

  AndroidAudioManager._() {
    _channel.setMethodCallHandler((MethodCall call) async {
      final List args = call.arguments;
      switch (call.method) {
        case 'onAudioFocusChanged':
          if (_onAudioFocusChanged != null) {
            _onAudioFocusChanged!(decodeMapEnum(
                AndroidAudioFocus.values, args[0],
                defaultValue: AndroidAudioFocus.gain));
          }
          break;
        case 'onBecomingNoisy':
          _becomingNoisyEventSubject.add(null);
          break;
        case 'onAudioDevicesAdded':
          if (_onAudioDevicesAdded != null) {
            _onAudioDevicesAdded!(_decodeAudioDevices(args[0]));
          }
          break;
        case 'onAudioDevicesRemoved':
          if (_onAudioDevicesRemoved != null) {
            _onAudioDevicesRemoved!(_decodeAudioDevices(args[0]));
          }
          break;
      }
    });
  }

  Stream<void> get becomingNoisyEventStream =>
      _becomingNoisyEventSubject.stream;

  Future<bool> requestAudioFocus(AndroidAudioFocusRequest focusRequest) async {
    _onAudioFocusChanged = focusRequest.onAudioFocusChanged;
    return (await _channel
        .invokeMethod<bool>('requestAudioFocus', [focusRequest.toJson()]))!;
  }

  Future<bool> abandonAudioFocus() async {
    return (await _channel.invokeMethod<bool>('abandonAudioFocus'))!;
  }

  /// (UNTESTED) Requires API level 19
  Future<void> dispatchMediaKeyEvent(AndroidKeyEvent keyEvent) async {
    await _channel.invokeMethod('dispatchMediaKeyEvent', [keyEvent._toMap()]);
  }

  /// (UNTESTED) Requires API level 21
  Future<bool> isVolumeFixed() async {
    return (await _channel.invokeMethod<bool>('isVolumeFixed'))!;
  }

  /// (UNTESTED)
  Future<void> adjustStreamVolume(AndroidStreamType streamType,
      AndroidAudioAdjustment direction, AndroidAudioVolumeFlags flags) async {
    await _channel.invokeMethod(
        'adjustStreamVolume', [streamType.index, direction.index, flags.value]);
  }

  /// (UNTESTED)
  Future<void> adjustVolume(
      AndroidAudioAdjustment direction, AndroidAudioVolumeFlags flags) async {
    await _channel.invokeMethod('adjustVolume', [direction.index, flags.value]);
  }

  /// (UNTESTED)
  Future<void> adjustSuggestedStreamVolume(
      AndroidAudioAdjustment direction,
      AndroidStreamType? suggestedStreamType,
      AndroidAudioVolumeFlags flags) async {
    const useDefaultStreamType = 0x80000000;
    await _channel.invokeMethod('adjustSuggestedStreamVolume', [
      direction.index,
      suggestedStreamType?.index ?? useDefaultStreamType,
      flags.value
    ]);
  }

  /// (UNTESTED)
  Future<AndroidRingerMode> getRingerMode() async {
    return decodeEnum(AndroidRingerMode.values,
        (await _channel.invokeMethod<int>('getRingerMode'))!,
        defaultValue: AndroidRingerMode.normal);
  }

  /// (UNTESTED)
  Future<int> getStreamMaxVolume(AndroidStreamType streamType) async {
    return (await _channel
        .invokeMethod<int>('getStreamMaxVolume', [streamType.index]))!;
  }

  /// (UNTESTED) Requires API level 28
  Future<int> getStreamMinVolume(AndroidStreamType streamType) async {
    return (await _channel
        .invokeMethod<int>('getStreamMinVolume', [streamType.index]))!;
  }

  /// (UNTESTED)
  Future<int> getStreamVolume(AndroidStreamType streamType) async {
    return (await _channel
        .invokeMethod<int>('getStreamVolume', [streamType.index]))!;
  }

  /// (UNTESTED) Requires API level 28
  Future<double> getStreamVolumeDb(AndroidStreamType streamType, int index,
      AndroidAudioDeviceType deviceType) async {
    return (await _channel.invokeMethod<double>('getStreamVolumeDb', [
      streamType.index,
      index,
      deviceType.index,
    ]))!;
  }

  /// (UNTESTED)
  Future<void> setRingerMode(AndroidRingerMode ringerMode) async {
    await _channel.invokeMethod<int>('setRingerMode', [ringerMode.index]);
  }

  /// (UNTESTED)
  Future<void> setStreamVolume(AndroidStreamType streamType, int index,
      AndroidAudioVolumeFlags flags) async {
    await _channel.invokeMethod(
        'setStreamVolume', [streamType.index, index, flags.value]);
  }

  /// (UNTESTED) Requires API level 23
  Future<bool> isStreamMute(AndroidStreamType streamType) async {
    return (await _channel
        .invokeMethod<bool>('isStreamMute', [streamType.index]))!;
  }

  /// (UNTESTED) Requires API level 31
  Future<List<AndroidAudioDeviceInfo>>
      getAvailableCommunicationDevices() async =>
          _decodeAudioDevices((await _channel.invokeMethod<List<dynamic>>(
              'getAvailableCommunicationDevices')));

  /// (UNTESTED) Requires API level 31
  Future<bool> setCommunicationDevice(AndroidAudioDeviceInfo device) async =>
      (await _channel
          .invokeMethod<bool>('setCommunicationDevice', [device.id]))!;

  /// (UNTESTED) Requires API level 31
  Future<AndroidAudioDeviceInfo> getCommunicationDevice() async =>
      _decodeAudioDevice(
          await _channel.invokeMethod<dynamic>('getCommunicationDevice'));

  /// (UNTESTED) Requires API level 31
  Future<void> clearCommunicationDevice() async =>
      await _channel.invokeMethod('clearCommunicationDevice');

  Future<void> setSpeakerphoneOn(bool enabled) async {
    await _channel.invokeMethod<bool>('setSpeakerphoneOn', [enabled]);
  }

  /// (UNTESTED)
  Future<bool> isSpeakerphoneOn() async {
    return (await _channel.invokeMethod<bool>('isSpeakerphoneOn'))!;
  }

  /// (UNTESTED) Requires API level 29
  Future<void> setAllowedCapturePolicy(
      AndroidAudioCapturePolicy capturePolicy) async {
    await _channel
        .invokeMethod<bool>('setAllowedCapturePolicy', [capturePolicy.index]);
  }

  /// (UNTESTED) Requires API level 29
  Future<AndroidAudioCapturePolicy> getAllowedCapturePolicy() async {
    return decodeMapEnum(AndroidAudioCapturePolicy.values,
        (await _channel.invokeMethod<int>('getAllowedCapturePolicy'))!,
        defaultValue: AndroidAudioCapturePolicy.allowAll);
  }

  // TODO: isOffloadedPlaybackSupported

  /// (UNTESTED)
  Future<bool> isBluetoothScoAvailableOffCall() async {
    return (await _channel
        .invokeMethod<bool>('isBluetoothScoAvailableOffCall'))!;
  }

  /// (UNTESTED)
  Future<void> startBluetoothSco() async {
    await _channel.invokeMethod('startBluetoothSco');
  }

  /// (UNTESTED)
  Future<void> stopBluetoothSco() async {
    await _channel.invokeMethod('stopBluetoothSco');
  }

  /// (UNTESTED)
  Future<void> setBluetoothScoOn(bool enabled) async {
    await _channel.invokeMethod<bool>('setBluetoothScoOn', [enabled]);
  }

  /// (UNTESTED)
  Future<bool> isBluetoothScoOn() async {
    return (await _channel.invokeMethod<bool>('isBluetoothScoOn'))!;
  }

  /// (UNTESTED)
  Future<void> setMicrophoneMute(bool enabled) async {
    await _channel.invokeMethod<bool>('setMicrophoneMute', [enabled]);
  }

  /// (UNTESTED)
  Future<bool> isMicrophoneMute() async {
    return (await _channel.invokeMethod<bool>('isMicrophoneMute'))!;
  }

  /// (UNTESTED)
  Future<void> setMode(AndroidAudioHardwareMode mode) async {
    await _channel.invokeMethod('setMode', [mode.index]);
  }

  /// (UNTESTED)
  Future<AndroidAudioHardwareMode> getMode() async {
    return decodeMapEnum(AndroidAudioHardwareMode.values,
        (await _channel.invokeMethod<int>('getMode'))!,
        defaultValue: AndroidAudioHardwareMode.normal);
  }

  /// (UNTESTED)
  Future<bool> isMusicActive() async {
    return (await _channel.invokeMethod<bool>('isMusicActive'))!;
  }

  /// (UNTESTED) Requires API level 21
  Future<int> generateAudioSessionId() async {
    return (await _channel.invokeMethod<int>('generateAudioSessionId'))!;
  }

  // TODO?: AUDIO_SESSION_ID_GENERATE

  /// (UNTESTED)
  Future<void> setParameters(Map<String, String> parameters) async {
    await _channel.invokeMethod(
        'setParameters',
        parameters.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .join(';'));
  }

  /// (UNTESTED)
  Future<Map<String, String>> getParameters(String keys) async {
    // What is the format of keys?
    return Map.fromEntries(
        (await _channel.invokeMethod<String>('getParameters', [keys]))!
            .split(';')
            .map((s) => s.split('='))
            .map((pair) => MapEntry(pair[0], pair[1])));
  }

  /// (UNTESTED)
  Future<void> playSoundEffect(AndroidSoundEffectType effectType,
      {double? volume}) async {
    // TODO: support variant with userId parameter.
    await _channel.invokeMethod('playSoundEffect', [effectType.index, volume]);
  }

  /// (UNTESTED)
  Future<void> loadSoundEffects() async {
    await _channel.invokeMethod('loadSoundEffects');
  }

  /// (UNTESTED)
  Future<void> unloadSoundEffects() async {
    await _channel.invokeMethod('unloadSoundEffects');
  }

  // TODO: (un)registerAudioPlaybackCallback
  // TODO: getActivePlaybackConfigurations
  // TODO: (un)registerAudioRecordingCallback
  // TODO: getActiveRecordingConfigurations

  /// (UNTESTED) Requires API level 17
  Future<int?> getOutputSampleRate() =>
      _getIntProperty('android.media.property.OUTPUT_SAMPLE_RATE');

  /// (UNTESTED) Requires API level 17
  Future<int?> getOutputFramesPerBuffer() =>
      _getIntProperty('android.media.property.OUTPUT_FRAMES_PER_BUFFER');

  /// (UNTESTED) Requires API level 17
  Future<bool> getSupportMicNearUltrasound() =>
      _getBoolProperty('android.media.property.SUPPORT_MIC_NEAR_ULTRASOUND');

  /// (UNTESTED) Requires API level 17
  Future<bool> getSupportSpeakerNearUltrasound() => _getBoolProperty(
      'android.media.property.SUPPORT_SPEAKER_NEAR_ULTRASOUND');

  /// (UNTESTED) Requires API level 17
  Future<bool> getSupportAudioSourceUnprocessed() => _getBoolProperty(
      'android.media.property.SUPPORT_AUDIO_SOURCE_UNPROCESSED');

  /// (UNTESTED) Requires API level 17
  Future<bool> _getBoolProperty(String key) async {
    final s = await _getProperty(key);
    return s == 'true';
  }

  /// (UNTESTED) Requires API level 17
  Future<int?> _getIntProperty(String key) async {
    final s = await _getProperty(key);
    return s != null ? int.parse(s) : null;
  }

  /// (UNTESTED) Requires API level 17
  Future<String?> _getProperty(String key) async {
    return await _channel.invokeMethod<String>('getProperty', [key]);
  }

  /// Requires API level 23
  Future<List<AndroidAudioDeviceInfo>> getDevices(
      AndroidGetAudioDevicesFlags flags) async {
    return _decodeAudioDevices(
        (await _channel.invokeMethod<dynamic>('getDevices', [flags.value]))!);
  }

  /// (UNTESTED) Requires API level 28
  Future<List<AndroidMicrophoneInfo>> getMicrophones() async {
    return ((await _channel.invokeMethod<List<dynamic>>('getMicrophones'))!)
        .map((raw) => Map<String, dynamic>.from(raw))
        .map((raw) => AndroidMicrophoneInfo(
              description: raw['description'],
              id: raw['id'],
              type: raw['type'],
              address: raw['address'],
              location: decodeEnum(
                  AndroidMicrophoneLocation.values, raw['location'],
                  defaultValue: AndroidMicrophoneLocation.unknown),
              group: raw['group'],
              indexInTheGroup: raw['indexInTheGroup'],
              position: (raw['position'] as List<dynamic>).cast<double>(),
              orientation: (raw['orientation'] as List<dynamic>).cast<double>(),
              frequencyResponse: (raw['frequencyResponse'] as List<dynamic>)
                  .map((dynamic item) => (item as List<dynamic>).cast<double>())
                  .toList(),
              channelMapping: (raw['channelMapping'] as List<dynamic>)
                  .map((dynamic item) => (item as List<dynamic>).cast<int>())
                  .toList(),
              sensitivity: raw['sensitivity'],
              maxSpl: raw['maxSpl'],
              minSpl: raw['minSpl'],
              directionality: decodeEnum(
                  AndroidMicrophoneDirectionality.values, raw['directionality'],
                  defaultValue: AndroidMicrophoneDirectionality.unknown),
            ))
        .toList();
  }

  /// (UNTESTED) Requires API level 29
  Future<bool> isHapticPlaybackSupported() async {
    return (await _channel.invokeMethod<bool>('isHapticPlaybackSupported'))!;
  }

  void close() {
    _becomingNoisyEventSubject.close();
  }

  List<AndroidAudioDeviceInfo> _decodeAudioDevices(dynamic rawList) {
    return (rawList as List<dynamic>).map(_decodeAudioDevice).toList();
  }

  AndroidAudioDeviceInfo _decodeAudioDevice(dynamic raw) {
    return AndroidAudioDeviceInfo(
      id: raw['id'],
      productName: raw['productName'],
      address: raw['address'],
      isSource: raw['isSource'],
      isSink: raw['isSink'],
      sampleRates: (raw['sampleRates'] as List<dynamic>).cast<int>(),
      channelMasks: (raw['channelMasks'] as List<dynamic>).cast<int>(),
      channelIndexMasks:
          (raw['channelIndexMasks'] as List<dynamic>).cast<int>(),
      channelCounts: (raw['channelCounts'] as List<dynamic>).cast<int>(),
      encodings: (raw['encodings'] as List<dynamic>).cast<int>(),
      type: decodeEnum(AndroidAudioDeviceType.values, raw['type'],
          defaultValue: AndroidAudioDeviceType.unknown),
    );
  }
}

/// Describes to the Android platform what kind of audio you intend to play.
class AndroidAudioAttributes {
  /// What type of audio you intend to play.
  final AndroidAudioContentType contentType;

  /// How the playback is to be affected.
  final AndroidAudioFlags flags;

  /// Why you intend to play the audio.
  final AndroidAudioUsage usage;

  const AndroidAudioAttributes({
    this.contentType = AndroidAudioContentType.unknown,
    this.flags = AndroidAudioFlags.none,
    this.usage = AndroidAudioUsage.unknown,
  });

  AndroidAudioAttributes.fromJson(Map data)
      : this(
          contentType: decodeEnum(
              AndroidAudioContentType.values, data['contentType'],
              defaultValue: AndroidAudioContentType.unknown),
          flags: AndroidAudioFlags(data['flags']),
          usage: decodeMapEnum(AndroidAudioUsage.values, data['usage'],
              defaultValue: AndroidAudioUsage.unknown),
        );

  Map toJson() => {
        'contentType': contentType.index,
        'flags': flags.value,
        'usage': usage.value,
      };

  @override
  bool operator ==(Object other) =>
      other is AndroidAudioAttributes &&
      contentType == other.contentType &&
      flags == other.flags &&
      usage == other.usage;

  int get hashCode =>
      '${contentType.index}-${flags.value}-${usage.value}'.hashCode;
}

/// The audio flags for [AndroidAudioAttributes].
// TODO: Rename this to AndroidAudioAttributeFlags?
class AndroidAudioFlags {
  static const AndroidAudioFlags none = AndroidAudioFlags(0);
  static const AndroidAudioFlags audibilityEnforced = AndroidAudioFlags(1 << 0);

  final int value;

  const AndroidAudioFlags(this.value);

  AndroidAudioFlags operator |(AndroidAudioFlags flag) =>
      AndroidAudioFlags(value | flag.value);

  AndroidAudioFlags operator &(AndroidAudioFlags flag) =>
      AndroidAudioFlags(value & flag.value);

  bool contains(AndroidAudioFlags flags) => flags.value & value == flags.value;

  @override
  bool operator ==(Object flag) =>
      flag is AndroidAudioFlags && value == flag.value;

  int get hashCode => value.hashCode;
}

/// The content type options for [AndroidAudioAttributes].
enum AndroidAudioContentType { unknown, speech, music, movie, sonification }

/// The usage options for [AndroidAudioAttributes].
class AndroidAudioUsage {
  static const unknown = AndroidAudioUsage._(0);
  static const media = AndroidAudioUsage._(1);
  static const voiceCommunication = AndroidAudioUsage._(2);
  static const voiceCommunicationSignalling = AndroidAudioUsage._(3);
  static const alarm = AndroidAudioUsage._(4);
  static const notification = AndroidAudioUsage._(5);
  static const notificationRingtone = AndroidAudioUsage._(6);
  static const notificationCommunicationRequest = AndroidAudioUsage._(7);
  static const notificationCommunicationInstant = AndroidAudioUsage._(8);
  static const notificationCommunicationDelayed = AndroidAudioUsage._(9);
  static const notificationEvent = AndroidAudioUsage._(10);
  static const assistanceAccessibility = AndroidAudioUsage._(11);
  static const assistanceNavigationGuidance = AndroidAudioUsage._(12);
  static const assistanceSonification = AndroidAudioUsage._(13);
  static const game = AndroidAudioUsage._(14);
  static const assistant = AndroidAudioUsage._(16);
  static const values = {
    0: unknown,
    1: media,
    2: voiceCommunication,
    3: voiceCommunicationSignalling,
    4: alarm,
    5: notification,
    6: notificationRingtone,
    7: notificationCommunicationRequest,
    8: notificationCommunicationInstant,
    9: notificationCommunicationDelayed,
    10: notificationEvent,
    11: assistanceAccessibility,
    12: assistanceNavigationGuidance,
    13: assistanceSonification,
    14: game,
    16: assistant,
  };

  final int value;

  const AndroidAudioUsage._(this.value);

  @override
  bool operator ==(Object other) =>
      other is AndroidAudioUsage && value == other.value;

  int get hashCode => value.hashCode;
}

class AndroidAudioFocusGainType {
  static const gain = AndroidAudioFocusGainType._(1);
  static const gainTransient = AndroidAudioFocusGainType._(2);
  static const gainTransientMayDuck = AndroidAudioFocusGainType._(3);

  /// Requires API level 19
  static const gainTransientExclusive = AndroidAudioFocusGainType._(4);
  static const values = {
    1: gain,
    2: gainTransient,
    3: gainTransientMayDuck,
    4: gainTransientExclusive,
  };

  final int index;

  const AndroidAudioFocusGainType._(this.index);
}

class AndroidAudioFocusRequest {
  final AndroidAudioFocusGainType gainType;
  final AndroidAudioAttributes? audioAttributes;
  final bool? willPauseWhenDucked;
  final AndroidOnAudioFocusChanged? onAudioFocusChanged;

  const AndroidAudioFocusRequest({
    required this.gainType,
    this.audioAttributes,
    this.willPauseWhenDucked,
    this.onAudioFocusChanged,
  });

  Map toJson() => {
        'gainType': gainType.index,
        'audioAttribute': audioAttributes?.toJson(),
        'willPauseWhenDucked': willPauseWhenDucked,
      };
}

typedef AndroidOnAudioFocusChanged = void Function(AndroidAudioFocus focus);
typedef AndroidOnAudioDevicesChanged = void Function(
    List<AndroidAudioDeviceInfo> devices);

class AndroidAudioFocus {
  static const gain = AndroidAudioFocus._(1);
  static const loss = AndroidAudioFocus._(-1);
  static const lossTransient = AndroidAudioFocus._(-2);
  static const lossTransientCanDuck = AndroidAudioFocus._(-3);
  static const values = {
    1: gain,
    -1: loss,
    -2: lossTransient,
    -3: lossTransientCanDuck,
  };

  final int index;

  const AndroidAudioFocus._(this.index);
}

enum AndroidStreamType {
  voiceCall,
  system,
  ring,
  music,
  alarm,
  notification,

  /// Unsupported
  bluetoothSco,

  /// Unsupported
  systemEnforced,
  dtmf,

  /// Unsupported
  tts,

  /// Requires API level 26
  accessibility,
}

class AndroidAudioAdjustment {
  static const lower = AndroidAudioAdjustment._(-1);
  static const same = AndroidAudioAdjustment._(0);
  static const raise = AndroidAudioAdjustment._(1);

  /// Requires API level 23
  static const mute = AndroidAudioAdjustment._(-100);

  /// Requires API level 23
  static const unmute = AndroidAudioAdjustment._(100);

  /// Requires API level 23
  static const toggleMute = AndroidAudioAdjustment._(101);
  static const values = {
    -1: lower,
    0: same,
    -2: raise,
    -100: mute,
    100: unmute,
    101: toggleMute,
  };

  final int index;

  const AndroidAudioAdjustment._(this.index);
}

class AndroidAudioVolumeFlags {
  static const AndroidAudioVolumeFlags showUi =
      const AndroidAudioVolumeFlags(1 << 0);
  static const AndroidAudioVolumeFlags allowRinger_modes =
      const AndroidAudioVolumeFlags(1 << 1);
  static const AndroidAudioVolumeFlags playSound =
      const AndroidAudioVolumeFlags(1 << 2);
  static const AndroidAudioVolumeFlags removeSoundAndVibrate =
      const AndroidAudioVolumeFlags(1 << 3);
  static const AndroidAudioVolumeFlags vibrate =
      const AndroidAudioVolumeFlags(1 << 4);
  static const AndroidAudioVolumeFlags fixedVolume =
      const AndroidAudioVolumeFlags(1 << 5);
  static const AndroidAudioVolumeFlags bluetoothAbsVolume =
      const AndroidAudioVolumeFlags(1 << 6);
  static const AndroidAudioVolumeFlags show_silent_hint =
      const AndroidAudioVolumeFlags(1 << 7);
  static const AndroidAudioVolumeFlags hdmiSystemAudioVolume =
      const AndroidAudioVolumeFlags(1 << 8);
  static const AndroidAudioVolumeFlags activeMediaOnly =
      const AndroidAudioVolumeFlags(1 << 9);
  static const AndroidAudioVolumeFlags showUiWarnings =
      const AndroidAudioVolumeFlags(1 << 10);
  static const AndroidAudioVolumeFlags showVibrateHint =
      const AndroidAudioVolumeFlags(1 << 11);
  static const AndroidAudioVolumeFlags fromKey =
      const AndroidAudioVolumeFlags(1 << 12);

  final int value;

  const AndroidAudioVolumeFlags(this.value);

  AndroidAudioVolumeFlags operator |(AndroidAudioVolumeFlags option) =>
      AndroidAudioVolumeFlags(value | option.value);

  AndroidAudioVolumeFlags operator &(AndroidAudioVolumeFlags option) =>
      AndroidAudioVolumeFlags(value & option.value);

  bool contains(AndroidAudioVolumeFlags options) =>
      options.value & value == options.value;

  @override
  bool operator ==(Object option) =>
      option is AndroidAudioVolumeFlags && value == option.value;

  int get hashCode => value.hashCode;
}

enum AndroidRingerMode {
  silent,
  vibrate,
  normal,
}

enum AndroidAudioDeviceType {
  unknown,
  builtInEarpiece,
  builtInSpeaker,
  wiredHeadset,
  wiredHeadphones,
  lineAnalog,
  lineDigital,
  bluetoothSco,
  bluetoothA2dp,
  hdmi,
  hdmiArc,
  usbDevice,
  usbAccessory,
  dock,
  fm,
  builtInMic,
  fmTuner,
  tvTuner,
  telephony,
  auxLine,
  ip,
  bus,
  usbHeadset,
  hearingAid,
  builtInSpeakerSafe,

  /// Android internal
  remoteSubmix,
}

class AndroidAudioCapturePolicy {
  static const allowAll = AndroidAudioCapturePolicy._(1);
  static const allowSystem = AndroidAudioCapturePolicy._(2);
  static const allowNone = AndroidAudioCapturePolicy._(3);
  static const values = {
    1: allowAll,
    2: allowSystem,
    3: allowNone,
  };

  final int index;

  const AndroidAudioCapturePolicy._(this.index);
}

class AndroidAudioHardwareMode {
  static const invalid = AndroidAudioHardwareMode._(-2);
  static const current = AndroidAudioHardwareMode._(-1);
  static const normal = AndroidAudioHardwareMode._(0);
  static const ringtone = AndroidAudioHardwareMode._(1);
  static const inCall = AndroidAudioHardwareMode._(2);
  static const inCommunication = AndroidAudioHardwareMode._(3);
  static const values = {
    -2: invalid,
    -1: current,
    0: normal,
    1: ringtone,
    2: inCall,
    3: inCommunication,
  };

  final int index;

  const AndroidAudioHardwareMode._(this.index);
}

enum AndroidSoundEffectType {
  keyClick,
  focusNavigationUp,
  focusNavigationDown,
  focusNavigationLeft,
  focusNavigationRight,
  keypressStandard,
  keypressSpacebar,
  keypressDelete,
  keypressReturn,
  keypressInvalid,
}

class AndroidAudioDeviceInfo {
  final int id;
  final String productName;
  final String? address;
  final bool isSource;
  final bool isSink;
  final List<int> sampleRates;
  final List<int> channelMasks;
  final List<int> channelIndexMasks;
  final List<int> channelCounts;
  final List<int> encodings;
  final AndroidAudioDeviceType type;

  AndroidAudioDeviceInfo({
    required this.id,
    required this.productName,
    required this.address,
    required this.isSource,
    required this.isSink,
    required this.sampleRates,
    required this.channelMasks,
    required this.channelIndexMasks,
    required this.channelCounts,
    required this.encodings,
    required this.type,
  });
}

/// Requires API level 28
class AndroidMicrophoneInfo {
  final String description;
  final int id;
  final int type;
  final String address;
  final AndroidMicrophoneLocation location;
  final int group;
  final int indexInTheGroup;
  final List<double> position;
  final List<double> orientation;
  final List<List<double>> frequencyResponse;
  final List<List<int>> channelMapping;
  final double sensitivity;
  final double maxSpl;
  final double minSpl;
  final AndroidMicrophoneDirectionality directionality;

  AndroidMicrophoneInfo({
    required this.description,
    required this.id,
    required this.type,
    required this.address,
    required this.location,
    required this.group,
    required this.indexInTheGroup,
    required this.position,
    required this.orientation,
    required this.frequencyResponse,
    required this.channelMapping,
    required this.sensitivity,
    required this.maxSpl,
    required this.minSpl,
    required this.directionality,
  });
}

/// Requires API level 28
enum AndroidMicrophoneLocation {
  unknown,
  mainBody,
  mainBodyMovable,
  peripheral,
}

/// Requires API level 28
enum AndroidMicrophoneDirectionality {
  unknown,
  omni,
  bidirectional,
  cardioid,
  hyperCardioid,
  superCardioid,
}

/// Requires API level 23
class AndroidGetAudioDevicesFlags {
  static const AndroidGetAudioDevicesFlags none =
      AndroidGetAudioDevicesFlags(0);
  static const AndroidGetAudioDevicesFlags inputs =
      AndroidGetAudioDevicesFlags(1 << 0);
  static const AndroidGetAudioDevicesFlags outputs =
      AndroidGetAudioDevicesFlags(1 << 1);
  static final AndroidGetAudioDevicesFlags all =
      AndroidGetAudioDevicesFlags.inputs | AndroidGetAudioDevicesFlags.outputs;

  final int value;

  const AndroidGetAudioDevicesFlags(this.value);

  AndroidGetAudioDevicesFlags operator |(AndroidGetAudioDevicesFlags flag) =>
      AndroidGetAudioDevicesFlags(value | flag.value);

  AndroidGetAudioDevicesFlags operator &(AndroidGetAudioDevicesFlags flag) =>
      AndroidGetAudioDevicesFlags(value & flag.value);

  bool contains(AndroidGetAudioDevicesFlags flags) =>
      flags.value & value == flags.value;

  @override
  bool operator ==(Object flag) =>
      flag is AndroidGetAudioDevicesFlags && value == flag.value;

  int get hashCode => value.hashCode;
}

class AndroidKeyEvent {
  final int deviceId;
  final int source;
  final int displayId;
  final int metaState;
  final int action;
  final int keyCode;
  final int scanCode;
  final int repeatCount;
  final int flags;
  final int downTime;
  final int eventTime;

  AndroidKeyEvent({
    required this.deviceId,
    required this.source,
    required this.displayId,
    required this.metaState,
    required this.action,
    required this.keyCode,
    required this.scanCode,
    required this.repeatCount,
    required this.flags,
    required this.downTime,
    required this.eventTime,
  });

  Map<String, dynamic> _toMap() => <String, dynamic>{
        'deviceId': deviceId,
        'source': source,
        'displayId': displayId,
        'metaState': metaState,
        'action': action,
        'keyCode': keyCode,
        'scanCode': scanCode,
        'repeatCount': repeatCount,
        'flags': flags,
        'downTime': downTime,
        'eventTime': eventTime,
      };
}
