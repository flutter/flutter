import 'package:win32/win32.dart';

void main() {
  final hr = RoInitialize(RO_INIT_TYPE.RO_INIT_SINGLETHREADED);
  if (FAILED(hr)) throw WindowsException(hr);

  // Requires a package identity.
  final currAppData = ApplicationData.Current();
  print(currAppData.trustLevel);
  final localFolder = IStorageItem(currAppData.LocalFolder);
  final localPath = localFolder.Path;

  print('Local folder path: $localPath');

  RoUninitialize();
}
