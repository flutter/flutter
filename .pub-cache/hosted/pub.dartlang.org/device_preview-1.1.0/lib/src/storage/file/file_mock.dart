import 'package:device_preview/src/state/state.dart';

import '../storage.dart';

/// A storage that saves device preview user preferences into
/// a single [file] as json content.
class FileDevicePreviewStorage extends DevicePreviewStorage {
  FileDevicePreviewStorage({
    required this.filePath,
  });

  /// The file to which the json content is saved to.
  final String filePath;

  @override
  Future<DevicePreviewData?> load() => Future<DevicePreviewData?>.value(null);

  @override
  Future<void> save(DevicePreviewData data) => Future.value();
}
