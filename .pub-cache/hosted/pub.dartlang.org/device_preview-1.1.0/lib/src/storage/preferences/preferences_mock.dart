import 'package:device_preview/src/state/state.dart';

import '../storage.dart';

/// Since share_preferences makes pub considering the package as not supported we should
/// remove this functionnality from the web version to get the maximum score.
class PreferencesDevicePreviewStorage extends DevicePreviewStorage {
  PreferencesDevicePreviewStorage({
    this.preferenceKey = defaultPreferencesKey,
  });

  /// The preferences key used to save the user configuration.
  final String preferenceKey;

  /// The default preferences key used to save the user configuration.
  static const String defaultPreferencesKey = 'device_preview.settings';

  @override
  Future<DevicePreviewData?> load() => Future<DevicePreviewData?>.value(null);

  @override
  Future<void> save(DevicePreviewData data) => Future.value();
}
