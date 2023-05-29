@TestOn('windows')

import 'package:test/test.dart';
import 'package:win32/win32.dart';

void main() {
  test('Win32 error', () {
    expect(WindowsException(ERROR_INVALID_HANDLE).toString(),
        endsWith('The handle is invalid.'));
  });

  test('Invalid argument error', () {
    expect(WindowsException(E_INVALIDARG).toString(),
        endsWith('The parameter is incorrect.'));
  });

  test('COM error CO_E_ALREADYINITIALIZED', () {
    expect(WindowsException(CO_E_ALREADYINITIALIZED).toString(),
        endsWith('CoInitialize has already been called.'));
  });

  test('HRESULT_FROM_WIN32 should give a valid result', () {
    final hr = HRESULT_FROM_WIN32(ERROR_INVALID_HANDLE);
    expect(WindowsException(hr).toString(), endsWith('The handle is invalid.'));
  });

  test('STATUS_SUCCESS should be a success after conversion to HRESULT', () {
    final hr = HRESULT_FROM_WIN32(STATUS_SUCCESS);
    expect(SUCCEEDED(hr), equals(true));
    expect(FAILED(hr), equals(false));
  });

  test('S_OK succeeds', () {
    expect(SUCCEEDED(S_OK), equals(true));
    expect(FAILED(S_OK), equals(false));
  });

  test('S_FALSE succeeds', () {
    expect(SUCCEEDED(S_FALSE), equals(true));
    expect(FAILED(S_FALSE), equals(false));
  });

  test('E_FAIL fails', () {
    expect(SUCCEEDED(E_FAIL), equals(false));
    expect(FAILED(E_FAIL), equals(true));
  });
}
