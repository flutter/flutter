import 'dart:convert';

import 'package:device_preview/src/state/state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../storage.dart';

/// A storage that keeps all preferences stored as json in the
/// preference entry with the [preferenceKey] key.
class PreferencesDevicePreviewStorage extends DevicePreviewStorage {
  PreferencesDevicePreviewStorage({
    this.preferenceKey = defaultPreferencesKey,
  });

  /// The preferences key used to save the user configuration.
  final String preferenceKey;

  /// The default preferences key used to save the user configuration.
  static const String defaultPreferencesKey = 'device_preview.settings';

  /// Load the last saved preferences (until [ignore] is `true`).
  @override
  Future<DevicePreviewData?> load() async {
    final shared = await SharedPreferences.getInstance();
    final json = shared.getString(preferenceKey);
    if (json == null || json.isEmpty) return null;
    return DevicePreviewData.fromJson(jsonDecode(json));
  }

  /// Save the current preferences (until [ignore] is `true`).
  @override
  Future<void> save(DevicePreviewData data) async {
    _saveData = data;
    _saveTask ??= _save();
    await _saveTask;
  }

  Future<void>? _saveTask;
  DevicePreviewData? _saveData;

  Future _save() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (_saveData != null) {
      final shared = await SharedPreferences.getInstance();
      await shared.setString(preferenceKey, jsonEncode(_saveData!.toJson()));
    }
    _saveTask = null;
  }
}
