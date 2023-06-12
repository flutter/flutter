import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../api/player_state.dart';
import 'player_control_command.dart';

/// Note: this is an iOS only feature (so far). Does not work with android/
/// web/macOS.
///
/// This bundles together all the notification related features from AP.
class NotificationService {
  /// Enable the notifications feature. This is a global toggle.
  ///
  /// Note: for best effects if you want to disable this, do it at the start
  /// of your app.
  /// TODO(luan) consider making this false by default.
  static bool enableNotificationService = true;

  final Future<void> Function(
    String,
    Map<String, dynamic>,
  ) platformChannelInvoke;

  NotificationService(this.platformChannelInvoke) {
    if (enableNotificationService) {
      startHeadlessService();
    }
  }

  final StreamController<PlayerControlCommand> _commandController =
      StreamController<PlayerControlCommand>.broadcast();

  /// Stream of remote player command sent by native side
  ///
  /// Events are sent when the user taps the system control commands on the
  /// notification page.
  // TODO(luan) improve communication with the notification widget
  Stream<PlayerControlCommand> get onPlayerCommand => _commandController.stream;

  /// This should be called after initiating AudioPlayer only if you want to
  /// listen for notification changes in the background.
  ///
  /// Only for iOS (not implemented on macOS, android, web)
  Future<void> startHeadlessService() async {
    return _callWithHandle(
      'startHeadlessService',
      _backgroundCallbackDispatcher,
    );
  }

  /// Start getting significant audio updates through `callback`.
  ///
  /// `callback` is invoked on a background isolate and will not have direct
  /// access to the state held by the main isolate (or any other isolate).
  Future<void> monitorStateChanges(
    void Function(PlayerState value) callback,
  ) async {
    return _callWithHandle('monitorNotificationStateChanges', callback);
  }

  /// Sets the notification bar for lock screen and notification area in iOS for now.
  ///
  /// At least the [title] is required.
  Future<void> setNotification({
    String title = '',
    String albumTitle = '',
    String artist = '',
    String imageUrl = '',
    Duration forwardSkipInterval = Duration.zero,
    Duration backwardSkipInterval = Duration.zero,
    Duration duration = Duration.zero,
    Duration elapsedTime = Duration.zero,
    bool enablePreviousTrackButton = false,
    bool enableNextTrackButton = false,
  }) async {
    return _call(
      'setNotification',
      <String, dynamic>{
        'title': title,
        'albumTitle': albumTitle,
        'artist': artist,
        'imageUrl': imageUrl,
        'forwardSkipInterval': forwardSkipInterval.inSeconds,
        'backwardSkipInterval': backwardSkipInterval.inSeconds,
        'duration': duration.inSeconds,
        'elapsedTime': elapsedTime.inSeconds,
        'enablePreviousTrackButton': enablePreviousTrackButton,
        'enableNextTrackButton': enableNextTrackButton,
      },
    );
  }

  Future<void> clearNotification() {
    return _call('clearNotification', <String, dynamic>{});
  }

  Future<void> _callWithHandle(String methodName, Function callback) async {
    if (!enableNotificationService) {
      throw 'The notifications feature was disabled.';
    }
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    await platformChannelInvoke(
      methodName,
      <String, dynamic>{
        'handleKey': _getBgHandleKey(callback),
      },
    );
  }

  Future<void> _call(String methodName, Map<String, dynamic> args) async {
    if (!enableNotificationService) {
      throw 'The notifications feature was disabled.';
    }
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    await platformChannelInvoke(methodName, args);
  }

  Future<void> dispose() async {
    if (!_commandController.isClosed) {
      await _commandController.close();
    }
  }

  void notifyNextTrack() {
    _commandController.add(PlayerControlCommand.NEXT_TRACK);
  }

  void notifyPreviousTrack() {
    _commandController.add(PlayerControlCommand.PREVIOUS_TRACK);
  }
}

List<dynamic> _getBgHandleKey(Function callback) {
  final handle = PluginUtilities.getCallbackHandle(callback);
  assert(handle != null, 'Unable to lookup callback.');
  return <dynamic>[handle!.toRawHandle()];
}

/// When we start the background service isolate, we only ever enter it once.
/// To communicate between the native plugin and this entrypoint, we'll use
/// MethodChannels to open a persistent communication channel to trigger
/// callbacks.
void _backgroundCallbackDispatcher() {
  const _channel = MethodChannel('xyz.luan/audioplayers_callback');

  // Setup Flutter state needed for MethodChannels.
  WidgetsFlutterBinding.ensureInitialized();

  // Reference to the onAudioChangeBackgroundEvent callback.
  Function(PlayerState)? onAudioChangeBackgroundEvent;

  // This is where the magic happens and we handle background events from the
  // native portion of the plugin. Here we message the audio notification data
  // which we then pass to the provided callback.
  _channel.setMethodCallHandler((MethodCall call) async {
    final args = call.arguments as Map<String, dynamic>;
    Function(PlayerState) _performCallbackLookup() {
      final handle = CallbackHandle.fromRawHandle(
        args['updateHandleMonitorKey'] as int,
      );

      // PluginUtilities.getCallbackFromHandle performs a lookup based on the
      // handle we retrieved earlier.
      final closure = PluginUtilities.getCallbackFromHandle(handle);

      if (closure == null) {
        throw 'Fatal Error: Callback lookup failed!';
      }
      return closure as Function(PlayerState);
    }

    if (call.method == 'audio.onNotificationBackgroundPlayerStateChanged') {
      onAudioChangeBackgroundEvent ??= _performCallbackLookup();
      final playerState = args['value'] as String;
      if (playerState == 'playing') {
        onAudioChangeBackgroundEvent!(PlayerState.PLAYING);
      } else if (playerState == 'paused') {
        onAudioChangeBackgroundEvent!(PlayerState.PAUSED);
      } else if (playerState == 'completed') {
        onAudioChangeBackgroundEvent!(PlayerState.COMPLETED);
      }
    } else {
      assert(false, "No handler defined for method type: '${call.method}'");
    }
  });
}
