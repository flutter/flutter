import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:meta/meta.dart' show experimental;
import 'package:rxdart/rxdart.dart';

import 'android.dart';
import 'darwin.dart';

/// Manages a single audio session to be used across different audio plugins in
/// your app. [AudioSession] will configure your app by describing to the operating
/// system the nature of the audio that your app intends to play.
///
/// You obtain the singleton [instance] of this class, [configure] it during
/// your app's startup, and then use other plugins to play or record audio. An
/// app will typically not call [setActive] directly since individual audio
/// plugins will call this before they play or record audio.
class AudioSession {
  static const MethodChannel _channel =
      const MethodChannel('com.ryanheise.audio_session');
  static AudioSession? _instance;

  /// The singleton instance across all Flutter engines.
  static Future<AudioSession> get instance async {
    if (_instance == null) {
      _instance = AudioSession._();
      try {
        // TODO: Use this code without the '?' once a Dart bug is fixed.
        // (similar instances occur elsewhere)
        //Map? data = await _channel.invokeMethod<Map>('getConfiguration');
        Map? data = await _channel.invokeMethod<Map?>('getConfiguration');
        if (data != null) {
          _instance!._configuration = AudioSessionConfiguration.fromJson(data);
        }
      } catch (e) {
        // Unsupported platform, so default to null.
        // TODO: We should at least try share the config between isolates on the
        // Dart side.
      }
    }
    return _instance!;
  }

  AndroidAudioManager? _androidAudioManager =
      !kIsWeb && Platform.isAndroid ? AndroidAudioManager() : null;
  AVAudioSession? _avAudioSession =
      !kIsWeb && Platform.isIOS ? AVAudioSession() : null;
  AudioSessionConfiguration? _configuration;
  final _configurationSubject = BehaviorSubject<AudioSessionConfiguration>();
  final _interruptionEventSubject = PublishSubject<AudioInterruptionEvent>();
  final _becomingNoisyEventSubject = PublishSubject<void>();
  final _devicesChangedEventSubject =
      PublishSubject<AudioDevicesChangedEvent>();
  late final BehaviorSubject<Set<AudioDevice>> _devicesSubject;
  AVAudioSessionRouteDescription? _previousAVAudioSessionRoute;

  AudioSession._() {
    _devicesSubject = BehaviorSubject<Set<AudioDevice>>(
      onListen: () async {
        _devicesSubject.add(await getDevices());
      },
    );
    _avAudioSession?.interruptionNotificationStream.listen((notification) {
      switch (notification.type) {
        case AVAudioSessionInterruptionType.began:
          if (notification.wasSuspended != true) {
            _interruptionEventSubject.add(
                AudioInterruptionEvent(true, AudioInterruptionType.unknown));
          }
          break;
        case AVAudioSessionInterruptionType.ended:
          _interruptionEventSubject.add(AudioInterruptionEvent(
              false,
              notification.options
                      .contains(AVAudioSessionInterruptionOptions.shouldResume)
                  ? AudioInterruptionType.pause
                  : AudioInterruptionType.unknown));
          break;
      }
    });
    _avAudioSession?.routeChangeStream
        .where((routeChange) =>
            routeChange.reason ==
                AVAudioSessionRouteChangeReason.oldDeviceUnavailable ||
            routeChange.reason ==
                AVAudioSessionRouteChangeReason.newDeviceAvailable)
        .listen((routeChange) async {
      if (routeChange.reason ==
          AVAudioSessionRouteChangeReason.oldDeviceUnavailable) {
        // TODO: Check specifically if headphones were unplugged.
        _becomingNoisyEventSubject.add(null);
      }
      final currentRoute = await _avAudioSession!.currentRoute;
      final previousRoute = _previousAVAudioSessionRoute ?? currentRoute;
      _previousAVAudioSessionRoute = currentRoute;
      final inputPortsAdded =
          currentRoute.inputs.difference(previousRoute.inputs);
      final outputPortsAdded =
          currentRoute.outputs.difference(previousRoute.outputs);
      final inputPortsRemoved =
          previousRoute.inputs.difference(currentRoute.inputs);
      final outputPortsRemoved =
          previousRoute.outputs.difference(currentRoute.outputs);
      final inputPorts = inputPortsAdded.union(inputPortsRemoved);
      final outputPorts = outputPortsAdded.union(outputPortsRemoved);

      final devicesAdded = inputPortsAdded
          .union(outputPortsAdded)
          .map((port) => _darwinPort2device(port,
              inputPorts: inputPorts, outputPorts: outputPorts))
          .toSet();
      final devicesRemoved = inputPortsRemoved
          .union(outputPortsRemoved)
          .map((port) => _darwinPort2device(port,
              inputPorts: inputPorts, outputPorts: outputPorts))
          .toSet();

      _devicesChangedEventSubject.add(AudioDevicesChangedEvent(
        devicesAdded: devicesAdded,
        devicesRemoved: devicesRemoved,
      ));

      if (_devicesSubject.hasListener) {
        _devicesSubject.add(await getDevices());
      }
    });
    _androidAudioManager?.becomingNoisyEventStream
        .listen((event) => _becomingNoisyEventSubject.add(null));

    _androidAudioManager?.setAudioDevicesAddedListener((devices) async {
      _devicesChangedEventSubject.add(AudioDevicesChangedEvent(
        devicesAdded: devices.map(_androidDevice2device).toSet(),
        devicesRemoved: {},
      ));
      if (_devicesSubject.hasListener) {
        _devicesSubject.add(await getDevices());
      }
    });
    _androidAudioManager?.setAudioDevicesRemovedListener((devices) async {
      _devicesChangedEventSubject.add(AudioDevicesChangedEvent(
        devicesAdded: {},
        devicesRemoved: devices.map(_androidDevice2device).toSet(),
      ));
      if (_devicesSubject.hasListener) {
        _devicesSubject.add(await getDevices());
      }
    });
    _channel.setMethodCallHandler((MethodCall call) async {
      final List? args = call.arguments;
      switch (call.method) {
        case 'onConfigurationChanged':
          _configurationSubject.add(
              _configuration = AudioSessionConfiguration.fromJson(args![0]));
          break;
      }
    });
  }

  /// The current configuration.
  AudioSessionConfiguration? get configuration => _configuration;

  /// A stream broadcasting the current configuration.
  Stream<AudioSessionConfiguration> get configurationStream =>
      _configurationSubject.stream;

  /// Whether the audio session is configured.
  bool get isConfigured => _configuration != null;

  /// The configured [AndroidAudioAttributes].
  AndroidAudioAttributes? get androidAudioAttributes =>
      _configuration?.androidAudioAttributes;

  /// The configured [AndroidAudioFocusGainType].
  AndroidAudioFocusGainType? get androidAudioFocusGainType =>
      _configuration?.androidAudioFocusGainType;

  /// A stream of [AudioInterruptionEvent]s.
  Stream<AudioInterruptionEvent> get interruptionEventStream =>
      _interruptionEventSubject.stream;

  /// A stream of events that occur when audio becomes noisy (e.g. due to
  /// unplugging the headphones).
  Stream<void> get becomingNoisyEventStream =>
      _becomingNoisyEventSubject.stream;

  /// A stream emitting events whenever devices are added or removed to the set
  /// of available devices.
  Stream<AudioDevicesChangedEvent> get devicesChangedEventStream =>
      _devicesChangedEventSubject.stream;

  /// A stream emitting the set of connected devices whenever there is a change.
  Stream<Set<AudioDevice>> get devicesStream => _devicesSubject.stream;

  /// Configures the audio session. It is useful to call this method during
  /// your app's initialisation before you start playing or recording any
  /// audio. However, you may also call this method afterwards to change the
  /// current configuration at any time.
  Future<void> configure(AudioSessionConfiguration configuration) async {
    await _avAudioSession?.setCategory(
      configuration.avAudioSessionCategory,
      configuration.avAudioSessionCategoryOptions,
      configuration.avAudioSessionMode,
      configuration.avAudioSessionRouteSharingPolicy,
    );
    _configuration = configuration;
    try {
      await _channel.invokeMethod('setConfiguration', [configuration.toJson()]);
    } catch (e) {
      // Unsupported platform - ignore.
    }
  }

  /// Activates or deactivates this audio session. Typically an audio plugin
  /// should call this method when it begins playing audio. If the audio
  /// session is not yet configured at the time this is called, the
  /// [fallbackConfiguration] will be set. If any of
  /// [avAudioSessionSetActiveOptions], [androidAudioFocusGainType],
  /// [androidAudioAttributesttributes] and [androidWillPauseWhenDucked] are
  /// speficied, they will override the configuration.
  Future<bool> setActive(
    bool active, {
    AVAudioSessionSetActiveOptions? avAudioSessionSetActiveOptions,
    AndroidAudioFocusGainType? androidAudioFocusGainType,
    AndroidAudioAttributes? androidAudioAttributes,
    bool? androidWillPauseWhenDucked,
    AudioSessionConfiguration fallbackConfiguration =
        const AudioSessionConfiguration.music(),
  }) async {
    final configuration = _configuration ?? fallbackConfiguration;
    if (!isConfigured) {
      await configure(fallbackConfiguration);
    }
    if (!kIsWeb && Platform.isIOS) {
      return await _avAudioSession!.setActive(active,
          avOptions: avAudioSessionSetActiveOptions ??
              configuration.avAudioSessionSetActiveOptions);
    } else if (!kIsWeb && Platform.isAndroid) {
      if (active) {
        // Activate
        final pauseWhenDucked =
            configuration.androidWillPauseWhenDucked ?? false;
        var ducked = false;
        final success = await _androidAudioManager!
            .requestAudioFocus(AndroidAudioFocusRequest(
          gainType: androidAudioFocusGainType ??
              configuration.androidAudioFocusGainType,
          audioAttributes:
              androidAudioAttributes ?? configuration.androidAudioAttributes,
          willPauseWhenDucked: androidWillPauseWhenDucked ??
              configuration.androidWillPauseWhenDucked,
          onAudioFocusChanged: (focus) {
            print("core onAudioFocusChanged");
            switch (focus) {
              case AndroidAudioFocus.gain:
                _interruptionEventSubject.add(AudioInterruptionEvent(
                    false,
                    ducked
                        ? AudioInterruptionType.duck
                        : AudioInterruptionType.pause));
                ducked = false;
                break;
              case AndroidAudioFocus.loss:
                _interruptionEventSubject.add(AudioInterruptionEvent(
                    true, AudioInterruptionType.unknown));
                ducked = false;
                break;
              case AndroidAudioFocus.lossTransient:
                _interruptionEventSubject.add(
                    AudioInterruptionEvent(true, AudioInterruptionType.pause));
                ducked = false;
                break;
              case AndroidAudioFocus.lossTransientCanDuck:
                // We enforce the "will pause when ducked" configuration by
                // sending the app a pause event instead of a duck event.
                _interruptionEventSubject.add(AudioInterruptionEvent(
                    true,
                    pauseWhenDucked
                        ? AudioInterruptionType.pause
                        : AudioInterruptionType.duck));
                if (!pauseWhenDucked) ducked = true;
                break;
            }
          },
        ));
        return success;
      } else {
        // Deactivate
        final success = await _androidAudioManager!.abandonAudioFocus();
        return success;
      }
    }
    return true;
  }

  /// Completes with a list of available audio devices.
  Future<Set<AudioDevice>> getDevices(
      {bool includeInputs = true, bool includeOutputs = true}) async {
    final devices = <AudioDevice>{};
    if (_androidAudioManager != null) {
      var flags = AndroidGetAudioDevicesFlags.none;
      if (includeInputs) flags |= AndroidGetAudioDevicesFlags.inputs;
      if (includeOutputs) flags |= AndroidGetAudioDevicesFlags.outputs;
      final androidDevices = await _androidAudioManager!.getDevices(flags);
      devices.addAll(androidDevices.map(_androidDevice2device).toSet());
    } else if (_avAudioSession != null) {
      final currentRoute = await _avAudioSession!.currentRoute;
      if (includeInputs) {
        final darwinInputs = await _avAudioSession!.availableInputs;
        devices.addAll(darwinInputs
            .map((port) => _darwinPort2device(port, inputPorts: darwinInputs))
            .toSet());
        devices.addAll(currentRoute.inputs.map((port) => _darwinPort2device(
              port,
              inputPorts: currentRoute.inputs,
              outputPorts: currentRoute.outputs,
            )));
      }
      if (includeOutputs) {
        devices.addAll(currentRoute.outputs.map((port) => _darwinPort2device(
              port,
              inputPorts: currentRoute.inputs,
              outputPorts: currentRoute.outputs,
            )));
      }
    }
    return devices;
  }

  static AudioDeviceType _darwinPort2type(AVAudioSessionPort port,
      {Set<AVAudioSessionPortDescription> inputPorts = const {}}) {
    switch (port) {
      case AVAudioSessionPort.builtInMic:
        return AudioDeviceType.builtInMic;
      case AVAudioSessionPort.headsetMic:
        return AudioDeviceType.wiredHeadset;
      case AVAudioSessionPort.lineIn:
        return AudioDeviceType.dock;
      case AVAudioSessionPort.airPlay:
        return AudioDeviceType.airPlay;
      case AVAudioSessionPort.bluetoothA2dp:
        return AudioDeviceType.bluetoothA2dp;
      case AVAudioSessionPort.bluetoothLe:
        return AudioDeviceType.bluetoothLe;
      case AVAudioSessionPort.builtInReceiver:
        return AudioDeviceType.builtInEarpiece;
      case AVAudioSessionPort.builtInSpeaker:
        return AudioDeviceType.builtInSpeaker;
      case AVAudioSessionPort.hdmi:
        return AudioDeviceType.hdmi;
      case AVAudioSessionPort.headphones:
        return inputPorts
                .map((desc) => desc.portType)
                .contains(AVAudioSessionPort.headsetMic)
            ? AudioDeviceType.wiredHeadset
            : AudioDeviceType.wiredHeadphones;
      case AVAudioSessionPort.lineOut:
        return AudioDeviceType.dock;
      case AVAudioSessionPort.avb:
        return AudioDeviceType.avb;
      case AVAudioSessionPort.bluetoothHfp:
        return AudioDeviceType.bluetoothSco;
      case AVAudioSessionPort.displayPort:
        return AudioDeviceType.displayPort;
      case AVAudioSessionPort.carAudio:
        return AudioDeviceType.carAudio;
      case AVAudioSessionPort.fireWire:
        return AudioDeviceType.fireWire;
      case AVAudioSessionPort.pci:
        return AudioDeviceType.pci;
      case AVAudioSessionPort.thunderbolt:
        return AudioDeviceType.thunderbolt;
      case AVAudioSessionPort.usbAudio:
        return AudioDeviceType.usbAudio;
      case AVAudioSessionPort.virtual:
        return AudioDeviceType.virtual;
    }
  }

  static AudioDevice _darwinPort2device(
    AVAudioSessionPortDescription port, {
    Set<AVAudioSessionPortDescription> inputPorts = const {},
    Set<AVAudioSessionPortDescription> outputPorts = const {},
  }) {
    return AudioDevice(
      id: port.uid,
      name: port.portName,
      isInput: inputPorts.contains(port),
      isOutput: outputPorts.contains(port),
      type: _darwinPort2type(port.portType, inputPorts: inputPorts),
    );
  }

  static AudioDeviceType _androidType2type(AndroidAudioDeviceType type) {
    switch (type) {
      case AndroidAudioDeviceType.unknown:
        return AudioDeviceType.unknown;
      case AndroidAudioDeviceType.builtInEarpiece:
        return AudioDeviceType.builtInEarpiece;
      case AndroidAudioDeviceType.builtInSpeaker:
        return AudioDeviceType.builtInSpeaker;
      case AndroidAudioDeviceType.wiredHeadset:
        return AudioDeviceType.wiredHeadset;
      case AndroidAudioDeviceType.wiredHeadphones:
        return AudioDeviceType.wiredHeadphones;
      case AndroidAudioDeviceType.lineAnalog:
        return AudioDeviceType.lineAnalog;
      case AndroidAudioDeviceType.lineDigital:
        return AudioDeviceType.lineDigital;
      case AndroidAudioDeviceType.bluetoothSco:
        return AudioDeviceType.bluetoothSco;
      case AndroidAudioDeviceType.bluetoothA2dp:
        return AudioDeviceType.bluetoothA2dp;
      case AndroidAudioDeviceType.hdmi:
        return AudioDeviceType.hdmi;
      case AndroidAudioDeviceType.hdmiArc:
        return AudioDeviceType.hdmiArc;
      case AndroidAudioDeviceType.usbDevice:
        return AudioDeviceType.usbAudio;
      case AndroidAudioDeviceType.usbAccessory:
        return AudioDeviceType.usbAudio;
      case AndroidAudioDeviceType.dock:
        return AudioDeviceType.dock;
      case AndroidAudioDeviceType.fm:
        return AudioDeviceType.fm;
      case AndroidAudioDeviceType.builtInMic:
        return AudioDeviceType.builtInMic;
      case AndroidAudioDeviceType.fmTuner:
        return AudioDeviceType.fmTuner;
      case AndroidAudioDeviceType.tvTuner:
        return AudioDeviceType.tvTuner;
      case AndroidAudioDeviceType.telephony:
        return AudioDeviceType.telephony;
      case AndroidAudioDeviceType.auxLine:
        return AudioDeviceType.auxLine;
      case AndroidAudioDeviceType.ip:
        return AudioDeviceType.ip;
      case AndroidAudioDeviceType.bus:
        return AudioDeviceType.bus;
      case AndroidAudioDeviceType.usbHeadset:
        return AudioDeviceType.usbAudio;
      case AndroidAudioDeviceType.hearingAid:
        return AudioDeviceType.hearingAid;
      case AndroidAudioDeviceType.builtInSpeakerSafe:
        return AudioDeviceType.builtInSpeakerSafe;
      case AndroidAudioDeviceType.remoteSubmix:
        return AudioDeviceType.remoteSubmix;
    }
  }

  static AudioDevice _androidDevice2device(AndroidAudioDeviceInfo device) {
    return AudioDevice(
      id: device.id.toString(),
      name: device.productName,
      isInput: device.isSource,
      isOutput: device.isSink,
      type: _androidType2type(device.type),
    );
  }
}

/// A configuration for [AudioSession] describing what type of audio your app
/// intends to play, and how it interacts with other audio apps. You can either
/// create your own configuration or use the following recipes:
///
/// * [AudioSessionConfiguration.music]: Useful for music player apps.
/// * [AudioSessionConfiguration.speech]: Useful for podcast and audiobook
/// apps.
///
/// You can suggest additional recipes via the GitHub issues page.
class AudioSessionConfiguration {
  final AVAudioSessionCategory? avAudioSessionCategory;
  final AVAudioSessionCategoryOptions? avAudioSessionCategoryOptions;
  final AVAudioSessionMode? avAudioSessionMode;
  final AVAudioSessionRouteSharingPolicy? avAudioSessionRouteSharingPolicy;
  final AVAudioSessionSetActiveOptions? avAudioSessionSetActiveOptions;
  final AndroidAudioAttributes? androidAudioAttributes;
  final AndroidAudioFocusGainType androidAudioFocusGainType;
  final bool? androidWillPauseWhenDucked;

  /// Creates an audio session configuration from scratch.
  ///
  /// Options prefixed with `av` correspond to classes in Apple's AVFoundation
  /// library and their values will be ignored on all platforms other than iOS.
  /// Only certain combinations of these configuration options are permitted,
  /// and you should consult [Apple's
  /// documentation](https://developer.apple.com/documentation/avfoundation/avaudiosession?language=objc)
  /// for further information.
  ///
  /// Options prefixed with `android` correspond to options in Android's SDK
  /// and their values are ignored on all platforms other than Android. Note
  /// that the underlying Android platform allows different audio players to
  /// use different audio attributes, and so the values supplied here act as
  /// hints on the type of configuration you would like audio plugins in your
  /// session to adopt by default.
  const AudioSessionConfiguration({
    this.avAudioSessionCategory,
    this.avAudioSessionCategoryOptions,
    this.avAudioSessionMode,
    this.avAudioSessionRouteSharingPolicy,
    this.avAudioSessionSetActiveOptions,
    this.androidAudioAttributes,
    this.androidAudioFocusGainType = AndroidAudioFocusGainType.gain,
    this.androidWillPauseWhenDucked,
  });

  AudioSessionConfiguration.fromJson(Map data)
      : this(
          avAudioSessionCategory: data['avAudioSessionCategory'] == null
              ? null
              : AVAudioSessionCategory.values[data['avAudioSessionCategory']],
          avAudioSessionCategoryOptions:
              data['avAudioSessionCategoryOptions'] == null
                  ? null
                  : AVAudioSessionCategoryOptions(
                      data['avAudioSessionCategoryOptions']),
          avAudioSessionMode: data['avAudioSessionMode'] == null
              ? null
              : AVAudioSessionMode.values[data['avAudioSessionMode']],
          avAudioSessionRouteSharingPolicy:
              data['avAudioSessionRouteSharingPolicy'] == null
                  ? null
                  : AVAudioSessionRouteSharingPolicy
                      .values[data['avAudioSessionRouteSharingPolicy']],
          avAudioSessionSetActiveOptions:
              data['avAudioSessionSetActiveOptions'] == null
                  ? null
                  : AVAudioSessionSetActiveOptions(
                      data['avAudioSessionSetActiveOptions']),
          androidAudioAttributes: data['androidAudioAttributes'] == null
              ? null
              : AndroidAudioAttributes.fromJson(data['androidAudioAttributes']),
          androidAudioFocusGainType: AndroidAudioFocusGainType
              .values[data['androidAudioFocusGainType']]!,
          androidWillPauseWhenDucked: data['androidWillPauseWhenDucked'],
        );

  /// A recipe for creating an audio configuration for a music player.
  const AudioSessionConfiguration.music()
      : this(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        );

  /// A recipe for creating an audio configuration for an app that
  /// predominantly plays continuous speech such as a podcast or audiobook app.
  const AudioSessionConfiguration.speech()
      : this(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionMode: AVAudioSessionMode.spokenAudio,
          androidAudioAttributes: const AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        );

  /// Creates a copy of this configuration with the given fields replaced by
  /// new values.
  AudioSessionConfiguration copyWith({
    AVAudioSessionCategory? avAudioSessionCategory,
    AVAudioSessionCategoryOptions? avAudioSessionCategoryOptions,
    AVAudioSessionMode? avAudioSessionMode,
    AVAudioSessionRouteSharingPolicy? avAudioSessionRouteSharingPolicy,
    AVAudioSessionSetActiveOptions? avAudioSessionSetActiveOptions,
    AndroidAudioAttributes? androidAudioAttributes,
    AndroidAudioFocusGainType? androidAudioFocusGainType,
    bool? androidWillPauseWhenDucked,
  }) =>
      AudioSessionConfiguration(
        avAudioSessionCategory:
            avAudioSessionCategory ?? this.avAudioSessionCategory,
        avAudioSessionCategoryOptions:
            avAudioSessionCategoryOptions ?? this.avAudioSessionCategoryOptions,
        avAudioSessionMode: avAudioSessionMode ?? this.avAudioSessionMode,
        avAudioSessionRouteSharingPolicy: avAudioSessionRouteSharingPolicy ??
            this.avAudioSessionRouteSharingPolicy,
        avAudioSessionSetActiveOptions: avAudioSessionSetActiveOptions ??
            this.avAudioSessionSetActiveOptions,
        androidAudioAttributes:
            androidAudioAttributes ?? this.androidAudioAttributes,
        androidAudioFocusGainType:
            androidAudioFocusGainType ?? this.androidAudioFocusGainType,
        androidWillPauseWhenDucked:
            androidWillPauseWhenDucked ?? this.androidWillPauseWhenDucked,
      );

  // Converts this instance to JSON.
  Map toJson() => {
        'avAudioSessionCategory': avAudioSessionCategory?.index,
        'avAudioSessionCategoryOptions': avAudioSessionCategoryOptions?.value,
        'avAudioSessionMode': avAudioSessionMode?.index,
        'avAudioSessionRouteSharingPolicy':
            avAudioSessionRouteSharingPolicy?.index,
        'avAudioSessionSetActiveOptions': avAudioSessionSetActiveOptions?.value,
        'androidAudioAttributes': androidAudioAttributes?.toJson(),
        'androidAudioFocusGainType': androidAudioFocusGainType.index,
        'androidWillPauseWhenDucked': androidWillPauseWhenDucked,
      };
}

/// An audio interruption event.
class AudioInterruptionEvent {
  /// Whether the interruption is beginning or ending.
  final bool begin;

  /// The type of interruption.
  final AudioInterruptionType type;

  AudioInterruptionEvent(this.begin, this.type);
}

/// The type of audio interruption.
enum AudioInterruptionType {
  /// Audio should be paused during the interruption.
  pause,

  /// Audio should be ducked during the interruption.
  duck,

  /// Audio should be paused, possibly indefinitely.
  unknown
}

/// An event capturing the addition or removal of connected devices.
class AudioDevicesChangedEvent {
  /// The audio devices just made available.
  final Set<AudioDevice> devicesAdded;

  /// The audio devices just made unavailable.
  final Set<AudioDevice> devicesRemoved;

  AudioDevicesChangedEvent({
    this.devicesAdded = const {},
    this.devicesRemoved = const {},
  });
}

/// Information about an audio device. If you require platform specific device
/// details, use [AVAudioSession] and [AndroidAudioManager] directly.
class AudioDevice {
  /// The unique ID of the device.
  final String id;

  /// The name of the device.
  final String name;

  /// Whether this device is an input.
  final bool isInput;

  /// Whether this device is an output.
  final bool isOutput;

  /// The type of this device.
  final AudioDeviceType type;

  AudioDevice({
    required this.id,
    required this.name,
    required this.isInput,
    required this.isOutput,
    required this.type,
  });

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) => other is AudioDevice && id == other.id;

  @override
  String toString() =>
      'AudioDevice(id:$id,name:$name,isInput:$isInput,isOutput:$isOutput,type:$type)';
}

/// An enumeration of the different audio device types.
@experimental
enum AudioDeviceType {
  /// Unknown type.
  unknown,

  /// The phone earpiece used for listening to calls.
  builtInEarpiece,

  /// The built-in speaker.
  builtInSpeaker,

  /// A wired headset with both microphone and earphones.
  wiredHeadset,

  /// Wired headphones.
  wiredHeadphones,

  /// The microphone on a headset.
  headsetMic,

  /// An analog line connection.
  lineAnalog,

  /// A digital line connection.
  lineDigital,

  /// A bluetooth device typically used for telephony.
  bluetoothSco,

  /// A bluetooth device supporting the A2DP profile.
  bluetoothA2dp,

  /// An HDMI connection.
  hdmi,

  /// The audio return channel of an HDMI connection.
  hdmiArc,

  /// A USB audio device.
  usbAudio,

  /// A device associated with a dock.
  dock,

  /// An FM transmission device.
  fm,

  /// The built-in microphone.
  builtInMic,

  /// An FM receiver device.
  fmTuner,

  /// A TV receiver device.
  tvTuner,

  /// A transmitter for the telephony network.
  telephony,

  /// An auxiliary line connector.
  auxLine,

  /// A device connected over IP.
  ip,

  /// A device used to communicate with external audio systems.
  bus,

  /// A hearing aid.
  hearingAid,

  /// An AirPlay device.
  airPlay,

  /// A Bluetooth LE device.
  bluetoothLe,

  /// An Audio Video Bridging device.
  avb,

  /// A DisplayPort device.
  displayPort,

  /// A Car Audio connection.
  carAudio,

  /// A FireWire device.
  fireWire,

  /// A PCI device.
  pci,

  /// A Thunderbolt device.
  thunderbolt,

  /// A connection not corresponding to a physical device.
  virtual,

  /// A built-in speaker used for outputting sounds like notifications and
  /// alarms.
  builtInSpeakerSafe,

  /// Android internal
  remoteSubmix,
}
