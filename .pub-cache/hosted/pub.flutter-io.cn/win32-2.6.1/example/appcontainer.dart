import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

bool isAppContainer() {
  final phToken = calloc<HANDLE>();
  final tokenInfo = calloc<DWORD>();
  final bytesReturned = calloc<DWORD>();

  try {
    final hProcess = GetCurrentProcess();
    if (OpenProcessToken(hProcess, TOKEN_READ, phToken) == FALSE) {
      OutputDebugString(
          "Error: Couldn't open the process token\n".toNativeUtf16());
    }

    if (GetTokenInformation(
            phToken.value,
            TOKEN_INFORMATION_CLASS.TokenIsAppContainer,
            tokenInfo,
            sizeOf<DWORD>(),
            bytesReturned) !=
        FALSE) {
      return tokenInfo.value != 0;
    }
    return false;
  } finally {
    free(phToken);
    free(tokenInfo);
    free(bytesReturned);
  }
}

void main() {
  final hr = RoInitialize(RO_INIT_TYPE.RO_INIT_SINGLETHREADED);
  if (FAILED(hr)) {
    throw WindowsException(hr);
  }

  OutputDebugString(
      '${!isAppContainer() ? '!' : ''}isAppContainer'.toNativeUtf16());

  final userData = UserDataPaths.GetDefault();
  final hstrRoamingAppData = userData.RoamingAppData;

  final roamingAppData =
      WindowsGetStringRawBuffer(hstrRoamingAppData, nullptr).toDartString();

  print('RoamingAppData: $roamingAppData');
  RoUninitialize();
}
