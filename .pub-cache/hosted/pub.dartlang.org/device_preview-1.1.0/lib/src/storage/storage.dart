import 'package:device_preview/src/state/state.dart';

import 'preferences/preferences.dart';

/// A storage for device preview user's preferences.
abstract class DevicePreviewStorage {
  const DevicePreviewStorage();

  /// A storage that keep preferences only in memory : all preferences are reset on each
  /// fresh start of the app.
  factory DevicePreviewStorage.none() => const NoDevicePreviewStorage();

  /// A storage that keeps all preferences stored as json in the
  /// preferences entry with the [preferenceKey] key.
  factory DevicePreviewStorage.preferences({
    String preferenceKey =
        PreferencesDevicePreviewStorage.defaultPreferencesKey,
  }) =>
      PreferencesDevicePreviewStorage(
        preferenceKey: preferenceKey,
      );

  /// Save the given [data] to the storage so that it can be loaded
  /// later with the [load] method.
  Future<void> save(DevicePreviewData data);

  /// Load data from the storage that has been saved previously with
  /// the [save] method.
  Future<DevicePreviewData?> load();
}

/// A storage that keep preferences only in memory : they are reset on each
/// fresh start of the app.
class NoDevicePreviewStorage extends DevicePreviewStorage {
  const NoDevicePreviewStorage();

  @override
  Future<DevicePreviewData?> load() => Future<DevicePreviewData?>.value(null);

  @override
  Future<void> save(DevicePreviewData data) => Future.value();
}
